#!/usr/bin/env python3
"""Embed every rebuilt abs_sources replay into file68/src/replay.inc.h.

The script reads abs_sources from this directory's Makefile, takes the newly
built binaries from bin/abs, synchronizes them to ../Replay, and updates (or
adds) their deterministic gzip arrays and replay table entries.

Use --dry-run to validate and preview the changes without writing anything.
Use --repo-root when the script is run against another checkout.
"""

from __future__ import annotations

import argparse
import gzip
import re
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ReplayData:
    name: str
    ident: str
    raw: bytes
    packed: bytes


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_root,
        help=f"sc68 repository root (default: {default_root})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="validate and report changes without writing files",
    )
    return parser.parse_args()


def read_abs_names(makefile: Path) -> list[str]:
    source = makefile.read_text(encoding="ascii")
    logical_lines = re.sub(r"\\\r?\n", " ", source)
    match = re.search(r"^abs_sources\s*:=\s*(.*)$", logical_lines, re.MULTILINE)
    if not match:
        raise RuntimeError(f"abs_sources was not found in {makefile}")

    names = [Path(token).stem for token in match.group(1).split() if token.endswith(".s")]
    if not names:
        raise RuntimeError(f"abs_sources is empty in {makefile}")
    if len(names) != len(set(names)):
        raise RuntimeError(f"abs_sources contains duplicate names in {makefile}")
    return names


def make_array(replay: ReplayData, newline: str) -> str:
    lines = [
        "  " + ",".join(str(value) for value in replay.packed[offset : offset + 16]) + ","
        for offset in range(0, len(replay.packed), 16)
    ]
    return (
        f"static const unsigned char dat_{replay.ident}[] = {{{newline}"
        + newline.join(lines)
        + f"{newline}}};"
    )


def update_arrays(text: str, replays: list[ReplayData], newline: str) -> tuple[str, set[str]]:
    added: list[str] = []
    updated: set[str] = set()

    for replay in replays:
        pattern = re.compile(
            rf"static const unsigned char dat_{re.escape(replay.ident)}\[\]\s*=\s*"
            rf"\{{.*?\r?\n\}};",
            re.DOTALL,
        )
        replacement = make_array(replay, newline)
        text, count = pattern.subn(lambda _: replacement, text, count=1)
        if count == 1:
            updated.add(replay.name)
        elif count == 0:
            added.append(
                f"/* {replay.name} data */{newline}{replacement}{newline}"
            )
        else:
            raise RuntimeError(f"multiple arrays found for {replay.name}")

    if added:
        marker = "static const struct replay {"
        offset = text.find(marker)
        if offset < 0:
            raise RuntimeError("replay table marker was not found")
        text = text[:offset] + newline.join(added) + text[offset:]

    return text, updated


def update_table(text: str, replays: list[ReplayData], newline: str) -> str:
    table_pattern = re.compile(
        r"(?P<prefix>\}\s+replays)\[(?P<count>\d+)\]"
        r"(?P<assign>\s*=\s*\{\r?\n)"
        r"(?P<body>.*?)"
        r"(?P<suffix>\r?\n\};)",
        re.DOTALL,
    )
    match = table_pattern.search(text)
    if not match:
        raise RuntimeError("replays[] table was not found")

    entry_pattern = re.compile(
        r'^\s*\{\s*"(?P<name>[^"]+)",\s*'
        r"(?P<ident>dat_[A-Za-z0-9_]+),\s*"
        r"sizeof\((?P=ident)\),\s*"
        r"(?P<size>\d+)\s*\},\s*$",
        re.MULTILINE,
    )

    entries: dict[str, tuple[str, int]] = {}
    for entry in entry_pattern.finditer(match.group("body")):
        name = entry.group("name")
        if name in entries:
            raise RuntimeError(f"duplicate replay table entry: {name}")
        entries[name] = (entry.group("ident"), int(entry.group("size")))

    declared_count = int(match.group("count"))
    if len(entries) != declared_count:
        raise RuntimeError(
            f"parsed {len(entries)} replay entries, but table declares {declared_count}"
        )

    for replay in replays:
        entries[replay.name] = (f"dat_{replay.ident}", len(replay.raw))

    ordered = sorted(entries.items(), key=lambda item: item[0].casefold())
    name_width = max(len(f'"{name}"') for name, _ in ordered)
    ident_width = max(len(ident) for _, (ident, _) in ordered)
    body_lines: list[str] = []
    for name, (ident, size) in ordered:
        quoted_name = f'"{name}"'
        body_lines.append(
            "  { "
            + f"{quoted_name:>{name_width}}, "
            + f"{ident:>{ident_width}}, sizeof({ident}), {size:6d} }},"
        )
    body = newline.join(body_lines)

    assign = re.sub(r"\r?\n$", newline, match.group("assign"))
    replacement = (
        f'{match.group("prefix")}[{len(ordered)}]'
        f"{assign}"
        f"{body}{newline}}};"
    )
    return text[: match.start()] + replacement + text[match.end() :]


def main() -> int:
    args = parse_args()
    root = args.repo_root.resolve()
    players = root / "file68" / "data68" / "Players"
    makefile = players / "Makefile"
    built_dir = players / "bin" / "abs"
    replay_dir = root / "file68" / "data68" / "Replay"
    header = root / "file68" / "src" / "replay.inc.h"

    names = read_abs_names(makefile)
    replays: list[ReplayData] = []
    for name in names:
        source = built_dir / f"{name}.bin"
        if not source.is_file():
            raise FileNotFoundError(f"rebuilt replay is missing: {source}")
        raw = source.read_bytes()
        if not raw:
            raise RuntimeError(f"rebuilt replay is empty: {source}")
        packed = gzip.compress(raw, compresslevel=9, mtime=0)
        if gzip.decompress(packed) != raw:
            raise RuntimeError(f"gzip verification failed: {source}")
        replays.append(
            ReplayData(name=name, ident=name.replace("-", "_"), raw=raw, packed=packed)
        )

    with header.open("r", encoding="ascii", newline="") as stream:
        text = stream.read()
    newline = "\r\n" if "\r\n" in text else "\n"

    text, previously_embedded = update_arrays(text, replays, newline)
    text = update_table(text, replays, newline)

    for replay in replays:
        action = "update" if replay.name in previously_embedded else "add"
        target = replay_dir / f"{replay.name}.bin"
        sync = "unchanged" if target.is_file() and target.read_bytes() == replay.raw else "replace"
        print(
            f"{replay.name}: {action} header, {sync} Replay bin, "
            f"{len(replay.raw)} bytes -> {len(replay.packed)} gzip bytes"
        )

    if args.dry_run:
        print(f"dry-run: would update {header}")
        return 0

    backup = header.with_name(header.name + ".bak")
    if not backup.exists():
        shutil.copy2(header, backup)

    replay_dir.mkdir(parents=True, exist_ok=True)
    for replay in replays:
        target = replay_dir / f"{replay.name}.bin"
        if not target.is_file() or target.read_bytes() != replay.raw:
            shutil.copy2(built_dir / f"{replay.name}.bin", target)

    with header.open("w", encoding="ascii", newline="") as stream:
        stream.write(text)

    print(f"updated: {header}")
    print(f"backup:  {backup}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
