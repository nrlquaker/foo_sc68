# Makefile to build foo_sc68.component for macOS (arm64) foobar2000.
# Bypasses autotools entirely: file68/libsc68/unice68 normally get their
# per-package config.h from a configure run, but every source in those
# libraries guards the include with `#ifdef HAVE_CONFIG_H`, so we simply
# never define HAVE_CONFIG_H and instead supply the handful of macros
# they need via -D flags below (mirrors the approach already used by the
# Windows build in ../sc68-msvc, which hand-writes config.h instead of
# running autotools).
#
# Prerequisite: the foobar2000 SDK, unpacked at ../SDK-2025-03-07 (i.e. the
# "SDK-2025-03-07" release from https://www.foobar2000.org/SDK). It is not
# committed to this repo (see .gitignore) -- unlike ../sc68-msvc, which
# checks in prebuilt .lib files instead, this Makefile compiles the SDK's
# pfc/SDK/helpers/shared/component_client sources directly, so the SDK
# folder must be present on disk (any subdirectory layout works as long as
# it matches the one inside the official SDK zip).

ROOT       := $(abspath ..)
SDK        := $(ROOT)/SDK-2025-03-07
BUILD      := $(abspath build)
OBJ        := $(BUILD)/obj

CC         := clang
CXX        := clang++
DEPLOY     := -mmacosx-version-min=11.0
ARCH       := -arch arm64
# matches the SDK's own foo_sample.xcodeproj Release config: Xcode applies
# -Os to any configuration literally named "Release" even though the
# pbxproj doesn't spell out GCC_OPTIMIZATION_LEVEL, and keeps debug info
# (DEBUG_INFORMATION_FORMAT = dwarf-with-dsym) rather than stripping it.
RELEASE    := -Os -g

CSTD       := -std=gnu11
CXXSTD     := -std=gnu++20

COMPONENT  := $(BUILD)/foo_sc68.component
COMP_MACOS := $(COMPONENT)/Contents/MacOS
COMP_BIN   := $(COMP_MACOS)/foo_sc68

# ---------------------------------------------------------------------
# sc68 core libraries (file68 / libsc68 / unice68)
# ---------------------------------------------------------------------

FILE68_SRC := $(addprefix $(ROOT)/file68/src/, \
	endian68.c error68.c file68.c gzip68.c ice68.c init68.c msg68.c \
	option68.c registry68.c replay68.c rsc68.c string68.c timedb68.c \
	uri68.c vfs68.c vfs68_ao.c vfs68_curl.c vfs68_fd.c vfs68_file.c \
	vfs68_mem.c vfs68_null.c vfs68_z.c)

LIBSC68_SRC := $(addprefix $(ROOT)/libsc68/, api68.c conf68.c mixer68.c libsc68.c)

IO68_SRC := $(addprefix $(ROOT)/libsc68/io68/, \
	io68.c mfpemul.c mfp_io.c mwemul.c mw_io.c paulaemul.c paula_io.c \
	shifter_io.c ymemul.c ym_blep.c ym_dump.c ym_envel.c ym_io.c ym_puls.c)

EMU68_SRC := $(addprefix $(ROOT)/libsc68/emu68/, \
	emu68.c error68.c getea68.c inst68.c ioplug68.c lines68.c mem68.c)

DIAL68_SRC := $(ROOT)/libsc68/dial68/dial68.c

UNICE68_SRC := $(addprefix $(ROOT)/unice68/, \
	unice68_pack.c unice68_unpack.c unice68_version.c)

SC68LIB_SRC := $(FILE68_SRC) $(LIBSC68_SRC) $(IO68_SRC) $(EMU68_SRC) $(DIAL68_SRC) $(UNICE68_SRC)

# LIBSC68_SRC + IO68_SRC + EMU68_SRC + DIAL68_SRC are all part of the same
# "libsc68" package (see libsc68/Makefile.am), as opposed to file68/unice68.
LIBSC68_ALL_SRC := $(LIBSC68_SRC) $(IO68_SRC) $(EMU68_SRC) $(DIAL68_SRC)

# Common feature/portability flags shared by file68, libsc68 and unice68
# (see task 1 in the conversation history for how this list was derived).
# PACKAGE_NAME/VERSION/STRING/TARNAME are deliberately NOT here: each
# library reports its own via sc68_versionstr()/file68_versionstr(), which
# just `return PACKAGE_STRING` -- giving all three the same PACKAGE_STRING
# made those two calls (shown together in the component's About text)
# print an identical "sc68 3.0.0a" line twice instead of distinct
# "file68 ..." / "libsc68 ..." lines, matching sc68-msvc's separate
# per-package config.h files (file68/config.h vs sc68/config.h).
COMMON_LIB_DEFS := \
	-DHAVE_ASSERT_H=1 -DHAVE_LIMITS_H=1 -DHAVE_STDIO_H=1 -DHAVE_STDLIB_H=1 \
	-DHAVE_STRING_H=1 -DHAVE_STRINGS_H=1 -DHAVE_STDINT_H=1 -DHAVE_INTTYPES_H=1 \
	-DHAVE_MEMORY_H=1 -DHAVE_UNISTD_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_SYS_TYPES_H=1 \
	-DHAVE_GETENV=1 -DHAVE_MALLOC=1 -DHAVE_FREE=1 -DHAVE_VSNPRINTF=1 \
	-DHAVE_VSPRINTF=1 -DHAVE_STRTOL=1 -DHAVE_STRTOUL=1 -DHAVE_USLEEP=1 \
	-DSTDC_HEADERS=1 -DHAVE_INTMAX_T=1 -DHAVE_UINTMAX_T=1 \
	-DHAVE_LONG_LONG_INT=1 -DHAVE_UNSIGNED_LONG_LONG_INT=1 \
	-DPACKAGE_BUGREPORT='""' -DPACKAGE_URL='"http://sc68.atari.org"' \
	-DFILE68_EXPORT=1 -DUSE_REPLAY68=1 -DFILE68_UNICE68=1 -DUSE_UNICE68=1 \
	-DFILE68_Z=1 -DUSE_Z=1 -DISTREAM68_NO_FD=1 \
	-DSC68_EXPORT=1 -DEMU68_MONOLITIC=1 -DEMU68_EXPORT=1 -DUSE_FILE68=1 \
	-DUNICE68_EXPORT=1 -DNDEBUG=1

FILE68_PKG_DEFS := \
	-DPACKAGE_NAME='"file68"' -DPACKAGE_VERSION='"3.0.0a"' -DPACKAGE_VERNUM=300 \
	-DPACKAGE_STRING='"file68 3.0.0a"' -DPACKAGE_TARNAME='"libfile68"'

LIBSC68_PKG_DEFS := \
	-DPACKAGE_NAME='"libsc68"' -DPACKAGE_VERSION='"3.0.0a"' -DPACKAGE_VERNUM=300 \
	-DPACKAGE_STRING='"libsc68 3.0.0a"' -DPACKAGE_TARNAME='"libsc68"'

UNICE68_PKG_DEFS := \
	-DPACKAGE_NAME='"unice68"' -DPACKAGE_VERSION='"3.0.0a"' -DPACKAGE_VERNUM=300 \
	-DPACKAGE_STRING='"unice68 3.0.0a"' -DPACKAGE_TARNAME='"unice68"'

FILE68_DEFS  := $(COMMON_LIB_DEFS) $(FILE68_PKG_DEFS)
LIBSC68_DEFS := $(COMMON_LIB_DEFS) $(LIBSC68_PKG_DEFS)
UNICE68_DEFS := $(COMMON_LIB_DEFS) $(UNICE68_PKG_DEFS)

SC68LIB_INC := \
	-I$(ROOT)/sc68-fb2k-mac/shim \
	-I$(ROOT)/file68 -I$(ROOT)/file68/sc68 \
	-I$(ROOT)/libsc68 -I$(ROOT)/libsc68/sc68 \
	-I$(ROOT)/libsc68/emu68 -I$(ROOT)/libsc68/io68 -I$(ROOT)/libsc68/dial68 \
	-I$(ROOT)/unice68 -I$(ROOT)/sc68-libc

# ---------------------------------------------------------------------
# foobar2000 SDK static pieces (pfc, SDK, helpers, shared, component_client)
# ---------------------------------------------------------------------

PFC_SRC := $(addprefix $(SDK)/pfc/, \
	SmartStrStr.cpp audio_math.cpp audio_sample.cpp base64.cpp bigmem.cpp \
	bit_array.cpp bsearch.cpp charDownConvert.cpp cpuid.cpp \
	crashWithMessage.cpp filehandle.cpp filetimetools.cpp guid.cpp \
	nix-objects.cpp obj-c.mm other.cpp pathUtils.cpp \
	printf.cpp selftest.cpp sort.cpp splitString2.cpp stdafx.cpp \
	string-compare.cpp string-conv-lite.cpp string-lite.cpp string_base.cpp \
	string_conv.cpp synchro_nix.cpp threads.cpp timers.cpp \
	unicode-normalize.cpp utf8.cpp wildcard.cpp win-objects.cpp)

FBSDK_SRC := $(addprefix $(SDK)/foobar2000/SDK/, \
	abort_callback.cpp advconfig.cpp album_art.cpp app_close_blocker.cpp \
	audio_chunk.cpp \
	audio_chunk_channel_config.cpp cfg_var.cpp cfg_var_legacy.cpp \
	chapterizer.cpp commandline.cpp commonObjects-Apple.mm commonObjects.cpp \
	completion_notify.cpp componentversion.cpp configStore.cpp \
	config_io_callback.cpp config_object.cpp console.cpp dsp.cpp \
	dsp_manager.cpp file_cached_impl.cpp file_info.cpp \
	file_info_const_impl.cpp file_info_impl.cpp file_info_merge.cpp \
	file_operation_callback.cpp filesystem.cpp filesystem_helper.cpp \
	foosort.cpp fsItem.cpp guids.cpp hasher_md5.cpp image.cpp input.cpp \
	input_file_type.cpp link_resolver.cpp main_thread_callback.cpp \
	mainmenu.cpp mem_block_container.cpp menu_helpers.cpp menu_item.cpp \
	menu_manager.cpp metadb.cpp metadb_handle.cpp metadb_handle_list.cpp \
	output.cpp packet_decoder.cpp playable_location.cpp playback_control.cpp \
	playlist.cpp playlist_loader.cpp popup_message.cpp preferences_page.cpp \
	replaygain.cpp replaygain_info.cpp service.cpp stdafx.cpp \
	tag_processor.cpp tag_processor_id3v2.cpp threaded_process.cpp \
	titleformat.cpp track_property.cpp ui.cpp ui_element.cpp utility.cpp)

HELPERS_SRC := $(addprefix $(SDK)/foobar2000/helpers/, \
	StdAfx.cpp ThreadUtils.cpp VisUtils.cpp VolumeMap.cpp \
	album_art_helpers.cpp cfg_guidlist.cpp cfg_var_import.cpp \
	create_directory_helper.cpp cue_creator.cpp cue_parser.cpp \
	cue_parser_embedding.cpp cuesheet_index_list.cpp dialog_resize_helper.cpp \
	dropdown_helper.cpp dynamic_bitrate_helper.cpp file_list_helper.cpp \
	file_move_helper.cpp file_win32_wrapper.cpp filetimetools.cpp \
	input_helper_cue.cpp input_helpers.cpp mp3_utils.cpp \
	packet_decoder_aac_common.cpp packet_decoder_mp3_common.cpp readers.cpp \
	seekabilizer.cpp stream_buffer_helper.cpp text_file_loader.cpp \
	text_file_loader_v2.cpp track_property_callback_impl.cpp \
	win-systemtime.cpp win32_misc.cpp writer_wav.cpp)

SHARED_SRC := $(addprefix $(SDK)/foobar2000/shared/, \
	audio_math.cpp shared-apple.mm shared-nix.cpp stdafx.cpp utf8.cpp)

COMPCLIENT_SRC := $(SDK)/foobar2000/foobar2000_component_client/component_client.cpp

FBSDK_ALL_SRC := $(PFC_SRC) $(FBSDK_SRC) $(HELPERS_SRC) $(SHARED_SRC) $(COMPCLIENT_SRC)

FBSDK_DEFS := -DNDEBUG=1
FBSDK_INC  := -I$(SDK) -I$(SDK)/foobar2000

# ---------------------------------------------------------------------
# foo_sc68 plugin sources
# ---------------------------------------------------------------------

PLUGIN_DIR := $(ROOT)/sc68-fb2k/foo_sc68

PLUGIN_SRC := \
	$(PLUGIN_DIR)/fb2k_sc68.cpp \
	$(PLUGIN_DIR)/initquit_sc68.cpp \
	$(PLUGIN_DIR)/input_sc68.cpp \
	$(PLUGIN_DIR)/vfs_sc68.cpp \
	$(ROOT)/sc68-fb2k-mac/pref_sc68_mac.mm

PLUGIN_DEFS := -DNDEBUG=1
PLUGIN_INC  := -I$(PLUGIN_DIR) $(FBSDK_INC) $(SC68LIB_INC)

# ---------------------------------------------------------------------
# Object file plumbing
# ---------------------------------------------------------------------

ALL_SRC := $(SC68LIB_SRC) $(FBSDK_ALL_SRC) $(PLUGIN_SRC)

define obj_for
$(OBJ)/$(subst /,_,$(patsubst $(ROOT)/%,%,$(1))).o
endef

SC68LIB_OBJ    := $(foreach f,$(SC68LIB_SRC),$(call obj_for,$(f)))
FBSDK_ALL_OBJ  := $(foreach f,$(FBSDK_ALL_SRC),$(call obj_for,$(f)))
PLUGIN_OBJ     := $(foreach f,$(PLUGIN_SRC),$(call obj_for,$(f)))

.PHONY: all clean component package
all: component

$(OBJ):
	mkdir -p $(OBJ)

# sc68 core libs: plain C
$(OBJ)/%.o:
	@mkdir -p $(dir $@)

define COMPILE_C_TEMPLATE
$(call obj_for,$(1)): $(1) | $(OBJ)
	@mkdir -p $$(dir $$@)
	$(CC) $(ARCH) $(DEPLOY) $(RELEASE) $(CSTD) -MMD -MP $(2) $(SC68LIB_INC) -c $(1) -o $$@
endef
$(foreach f,$(FILE68_SRC),$(eval $(call COMPILE_C_TEMPLATE,$(f),$(FILE68_DEFS))))
$(foreach f,$(LIBSC68_ALL_SRC),$(eval $(call COMPILE_C_TEMPLATE,$(f),$(LIBSC68_DEFS))))
$(foreach f,$(UNICE68_SRC),$(eval $(call COMPILE_C_TEMPLATE,$(f),$(UNICE68_DEFS))))

# foobar2000 SDK pieces: C++ / Objective-C++
define COMPILE_CXX_TEMPLATE
$(call obj_for,$(1)): $(1) | $(OBJ)
	@mkdir -p $$(dir $$@)
	$(CXX) $(ARCH) $(DEPLOY) $(RELEASE) $(CXXSTD) -fobjc-arc -MMD -MP $(FBSDK_DEFS) $(FBSDK_INC) -c $(1) -o $$@
endef
$(foreach f,$(FBSDK_ALL_SRC),$(eval $(call COMPILE_CXX_TEMPLATE,$(f))))

# plugin sources: C++ / Objective-C++ (pref_sc68_mac.mm needs ARC)
define COMPILE_PLUGIN_TEMPLATE
$(call obj_for,$(1)): $(1) | $(OBJ)
	@mkdir -p $$(dir $$@)
	$(CXX) $(ARCH) $(DEPLOY) $(RELEASE) $(CXXSTD) -fobjc-arc -MMD -MP $(PLUGIN_DEFS) $(PLUGIN_INC) -c $(1) -o $$@
endef
$(foreach f,$(PLUGIN_SRC),$(eval $(call COMPILE_PLUGIN_TEMPLATE,$(f))))

component: $(COMPONENT)

$(COMPONENT): $(SC68LIB_OBJ) $(FBSDK_ALL_OBJ) $(PLUGIN_OBJ)
	@mkdir -p $(COMP_MACOS)
	$(CXX) $(ARCH) $(DEPLOY) $(RELEASE) -bundle -fobjc-arc \
		-o $(COMP_BIN) \
		$(SC68LIB_OBJ) $(FBSDK_ALL_OBJ) $(PLUGIN_OBJ) \
		-framework Cocoa -framework Foundation -lz
	$(MAKE) --no-print-directory infoplist
	codesign --force --sign - $(COMPONENT)
	# a directory's own mtime doesn't advance when files nested inside it
	# change, only when a direct child is added/removed -- without this,
	# $(COMPONENT) would look permanently stale to package/install below
	@touch $(COMPONENT)
	@echo "Built $(COMPONENT)"

infoplist:
	@/usr/bin/plutil -create xml1 $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string foo_sc68" $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.sc68.foo-sc68" $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName string foo_sc68" $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string BNDL" $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.1" $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1.0.1" $(COMPONENT)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 11.0" $(COMPONENT)/Contents/Info.plist

# Distributable .fb2k-component archive: a zip with the built bundle under
# a "mac/" subfolder, the layout foobar2000 expects when installing a
# component package (see e.g. https://github.com/JendaT/fb2k-components-mac-suite,
# Scripts/package.sh, and how official .fb2k-component archives are laid
# out -- a top-level "mac/<name>.component/" next to any Windows arch
# subfolders, which we don't build here).
PKG_FILE := $(BUILD)/foo_sc68.fb2k-component
package: $(PKG_FILE)

$(PKG_FILE): $(COMPONENT)
	rm -f $(PKG_FILE)
	tmpdir=$$(mktemp -d) && \
	mkdir -p "$$tmpdir/mac" && \
	cp -R $(COMPONENT) "$$tmpdir/mac/" && \
	(cd "$$tmpdir" && zip -r -q "$(PKG_FILE)" mac) && \
	rm -rf "$$tmpdir"
	@echo "Packaged $(PKG_FILE)"

clean:
	rm -rf $(BUILD)

# Copies the built bundle into the current user's foobar2000 profile, the
# same layout used by other user-components (see foo_openmpt54, foo_deaf).
INSTALL_DIR := $(HOME)/Library/foobar2000-v2/user-components/foo_sc68
install: component
	mkdir -p $(INSTALL_DIR)
	rm -rf $(INSTALL_DIR)/foo_sc68.component
	cp -R $(COMPONENT) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/foo_sc68.component -- (re)start foobar2000 to load it."

# Auto-generated header dependencies (via -MMD -MP on every compile rule
# above), so editing a shared header correctly triggers a rebuild of every
# .o that includes it -- not just files whose own .c/.cpp changed.
-include $(wildcard $(OBJ)/*.d)
