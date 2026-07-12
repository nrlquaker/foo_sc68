/*
 * @file    pref_sc68_mac.mm
 * @brief   sc68 foobar2000 (macOS) - preferences page + persistent settings
 *
 * Mirrors sc68-fb2k/foo_sc68/pref_sc68.cpp (the Win32 dialog build) but
 * follows the macOS foobar2000 SDK convention instead of a Win32 dialog:
 * preferences_page::instantiate() returns an NSViewController (see
 * foo_sample/Mac/fooSampleMacPreferences.mm), built entirely in code
 * (no .xib) and applying each change immediately, the same "no separate
 * Apply step" pattern the SDK sample itself uses on mac.
 *
 * The persistent cfg_int variables below use the same GUIDs as the
 * Windows preferences page, so a config synced from Windows round-trips.
 */

#include "stdafx.h"
#include "sc68/file68_opt.h"

#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------
   Configuration variable GUIDs (must match sc68-fb2k/foo_sc68/pref_sc68.cpp)
   ----------------------------------------------------------------------- */

static const GUID guid_sc68_pref_page =
  { 0xa8b3c4d5, 0xe6f7, 0x4802, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe2 } };

static const GUID guid_cfg_spr =
  { 0xa8b3c4d5, 0xe6f7, 0x4803, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe3 } };
static const GUID guid_cfg_deftime =
  { 0xa8b3c4d5, 0xe6f7, 0x4804, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe4 } };
static const GUID guid_cfg_asid =
  { 0xa8b3c4d5, 0xe6f7, 0x4805, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe5 } };
static const GUID guid_cfg_engine =
  { 0xa8b3c4d5, 0xe6f7, 0x4806, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe6 } };
static const GUID guid_cfg_filter =
  { 0xa8b3c4d5, 0xe6f7, 0x4807, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe7 } };
static const GUID guid_cfg_volmodel =
  { 0xa8b3c4d5, 0xe6f7, 0x4808, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe8 } };
static const GUID guid_cfg_blend =
  { 0xa8b3c4d5, 0xe6f7, 0x4809, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xe9 } };
static const GUID guid_cfg_amiga_filter =
  { 0xa8b3c4d5, 0xe6f7, 0x480a, { 0x92, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xea } };

enum {
  default_sampling_rate = 48000,
  default_time          = 180,
  default_asid          = 0,    /* off     */
  default_engine        = 0,    /* blep    */
  default_filter        = 0,    /* 2-poles */
  default_volmodel      = 0,    /* atari   */
  default_blend         = 128,  /* center  */
  default_amiga_filter  = 0,    /* off     */
};

enum { SPR_MIN = 4000, SPR_MAX = 96000 };

static const int   spr_values[] = { 11025, 22050, 44100, 48000, 96000 };
static const char *spr_labels[] = { "11 kHz", "22 kHz", "44.1 kHz", "48 kHz", "96 kHz" };
static const int   spr_count    = sizeof(spr_values) / sizeof(*spr_values);

/* Popup index 0 is "Custom", presets follow. */
static int spr_to_popup_index(int spr) {
  for (int i = 0; i < spr_count; i++)
    if (spr_values[i] == spr)
      return i + 1;
  return 0;
}

static cfg_int cfg_spr         (guid_cfg_spr,          default_sampling_rate);
static cfg_int cfg_deftime     (guid_cfg_deftime,       default_time);
static cfg_int cfg_asid        (guid_cfg_asid,          default_asid);
static cfg_int cfg_engine      (guid_cfg_engine,        default_engine);
static cfg_int cfg_filter      (guid_cfg_filter,        default_filter);
static cfg_int cfg_volmodel    (guid_cfg_volmodel,      default_volmodel);
static cfg_int cfg_blend       (guid_cfg_blend,         default_blend);
static cfg_int cfg_amiga_filter(guid_cfg_amiga_filter,  default_amiga_filter);

/* -----------------------------------------------------------------------
   Apply preferences to sc68 library and global variables.
   Called from on_init (startup) and after every UI change (see below).
   ----------------------------------------------------------------------- */

void apply_sc68_preferences()
{
  g_sampling_rate = (int) cfg_spr;
  g_ym_asid       = (int) cfg_asid;
  g_ym_engine     = (int) cfg_engine;
  g_ym_filter     = (int) cfg_filter;

  sc68_cntl(0, SC68_SET_OPT_INT, "sampling-rate", (int) cfg_spr);
  sc68_cntl(0, SC68_SET_OPT_INT, "default-time",  (int) cfg_deftime);
  sc68_cntl(0, SC68_SET_ASID,    (int) cfg_asid);
  sc68_cntl(0, SC68_SET_OPT_INT, "ym-engine",     (int) cfg_engine);
  sc68_cntl(0, SC68_SET_OPT_INT, "ym-filter",     (int) cfg_filter);
  sc68_cntl(0, SC68_SET_OPT_INT, "ym-volmodel",   (int) cfg_volmodel);
  sc68_cntl(0, SC68_SET_OPT_INT, "amiga-blend",   (int) cfg_blend);
  sc68_cntl(0, SC68_SET_OPT_INT, "amiga-filter",  (int) cfg_amiga_filter);

  /* SC68_SET_OPT_INT only updates the live option68 store; libsc68's
   * "default-time" fallback track length (api68.c: calc_track_len) is
   * read from a separate process-wide snapshot that SC68_SET_OPT_INT
   * never touches, so it would otherwise stay stuck at whatever it was
   * when sc68_init() first ran. SC68_CONFIG_SAVE + SC68_CONFIG_LOAD
   * forces that snapshot to refresh from the option68 store we just set. */
  sc68_cntl(0, SC68_CONFIG_SAVE);
  sc68_cntl(0, SC68_CONFIG_LOAD);
}

/* -----------------------------------------------------------------------
   Preferences view (built in code, no .xib). Every control applies its
   change immediately -- there is no separate Apply/Reset step on mac,
   matching the pattern used by the SDK's own foo_sample Mac preferences.
   ----------------------------------------------------------------------- */

@interface SC68PreferencesViewController : NSViewController
@end

@implementation SC68PreferencesViewController {
  NSPopUpButton *_sprPopup;
  NSTextField   *_sprCustomField;
  NSTextField   *_defTimeField;
  NSPopUpButton *_asidPopup;
  NSPopUpButton *_enginePopup;
  NSPopUpButton *_filterPopup;
  NSPopUpButton *_volmodelPopup;
  NSSlider      *_blendSlider;
  NSButton      *_amigaFilterCheck;
}

- (instancetype)init {
  return [super initWithNibName:nil bundle:nil];
}

- (NSPopUpButton *)popupFromOption:(const char *)key {
  NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  option68_t *opt = option68_get(key, opt68_ALWAYS);
  if (opt && opt->type == opt68_ENU) {
    const char **names = (const char **) opt->set;
    for (unsigned i = 0; i < opt->sets; i++) {
      const char *name = names[i] ? names[i] : "<unknown>";
      [popup addItemWithTitle:[NSString stringWithUTF8String:name]];
    }
  }
  return popup;
}

- (NSView *)rowWithLabel:(NSString *)text control:(NSView *)control {
  NSTextField *label = [NSTextField labelWithString:text];
  label.alignment = NSTextAlignmentRight;
  [label setContentHuggingPriority:NSLayoutPriorityDefaultHigh
                     forOrientation:NSLayoutConstraintOrientationHorizontal];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  [label.widthAnchor constraintGreaterThanOrEqualToConstant:130].active = YES;

  NSStackView *row = [NSStackView stackViewWithViews:@[ label, control ]];
  row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  row.alignment = NSLayoutAttributeCenterY;
  row.spacing = 8;
  return row;
}

- (void)loadView {
  NSPopUpButton *spr = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  [spr addItemWithTitle:@"Custom…"];
  for (int i = 0; i < spr_count; i++)
    [spr addItemWithTitle:[NSString stringWithUTF8String:spr_labels[i]]];
  spr.target = self;
  spr.action = @selector(onSPR:);
  _sprPopup = spr;

  NSTextField *sprCustom = [NSTextField textFieldWithString:@""];
  sprCustom.target = self;
  sprCustom.action = @selector(onSPRCustom:);
  [sprCustom.widthAnchor constraintEqualToConstant:70].active = YES;
  _sprCustomField = sprCustom;

  NSStackView *sprControls = [NSStackView stackViewWithViews:@[ spr, sprCustom ]];
  sprControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  sprControls.spacing = 6;

  NSTextField *defTime = [NSTextField textFieldWithString:@""];
  defTime.target = self;
  defTime.action = @selector(onDefTime:);
  [defTime.widthAnchor constraintEqualToConstant:70].active = YES;
  _defTimeField = defTime;

  NSPopUpButton *asid = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  for (NSString *s in @[ @"Off", @"On", @"Force" ])
    [asid addItemWithTitle:s];
  asid.target = self;
  asid.action = @selector(onASID:);
  _asidPopup = asid;

  NSPopUpButton *engine = [self popupFromOption:"ym-engine"];
  engine.target = self;
  engine.action = @selector(onEngine:);
  _enginePopup = engine;

  NSPopUpButton *filter = [self popupFromOption:"ym-filter"];
  filter.target = self;
  filter.action = @selector(onFilter:);
  _filterPopup = filter;

  NSPopUpButton *volmodel = [self popupFromOption:"ym-volmodel"];
  volmodel.target = self;
  volmodel.action = @selector(onVolmodel:);
  _volmodelPopup = volmodel;

  NSSlider *blend = [NSSlider sliderWithValue:default_blend
                                      minValue:0
                                      maxValue:255
                                        target:self
                                        action:@selector(onBlend:)];
  _blendSlider = blend;

  NSButton *amiga = [NSButton checkboxWithTitle:@"Enable Amiga low-pass filter"
                                          target:self
                                          action:@selector(onAmigaFilter:)];
  _amigaFilterCheck = amiga;

  NSStackView *stack = [NSStackView stackViewWithViews:@[
    [self rowWithLabel:@"Sampling rate:"      control:sprControls],
    [self rowWithLabel:@"Default length (s):" control:defTime],
    [self rowWithLabel:@"aSIDifier:"          control:asid],
    [self rowWithLabel:@"YM engine:"          control:engine],
    [self rowWithLabel:@"YM filter:"          control:filter],
    [self rowWithLabel:@"Volume model:"       control:volmodel],
    [self rowWithLabel:@"L/R blend:"          control:blend],
    amiga,
  ]];
  stack.orientation = NSUserInterfaceLayoutOrientationVertical;
  stack.alignment = NSLayoutAttributeLeading;
  stack.spacing = 10;
  stack.edgeInsets = NSEdgeInsetsMake(16, 16, 16, 16);

  // Host resizes our returned view to fill the whole preferences pane.
  // A stack view used directly as that view ends up anchored to the
  // *bottom* of the enlarged frame instead of the top, so wrap it in a
  // plain container and pin the stack to the top-leading corner only.
  NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 480, 320)];
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  [container addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.topAnchor constraintEqualToAnchor:container.topAnchor],
    [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
    [stack.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor],
  ]];

  self.view = container;
  [self loadSettings];
}

- (void)loadSettings {
  int spr = (int) cfg_spr;
  [_sprPopup selectItemAtIndex:spr_to_popup_index(spr)];
  _sprCustomField.stringValue = [NSString stringWithFormat:@"%d", spr];
  _sprCustomField.enabled = (spr_to_popup_index(spr) == 0);

  _defTimeField.integerValue = (int) cfg_deftime;

  [_asidPopup selectItemAtIndex:(int) cfg_asid];
  [_enginePopup selectItemAtIndex:(int) cfg_engine];
  [_filterPopup selectItemAtIndex:(int) cfg_filter];
  [_volmodelPopup selectItemAtIndex:(int) cfg_volmodel];
  _blendSlider.integerValue = (int) cfg_blend;
  _amigaFilterCheck.state = cfg_amiga_filter ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)onSPR:(id)sender {
  NSInteger idx = _sprPopup.indexOfSelectedItem;
  _sprCustomField.enabled = (idx == 0);
  cfg_spr = (idx == 0) ? (int) _sprCustomField.integerValue : spr_values[idx - 1];
  apply_sc68_preferences();
}

- (void)onSPRCustom:(id)sender {
  if (_sprPopup.indexOfSelectedItem != 0)
    return;
  int v = (int) _sprCustomField.integerValue;
  if (v < SPR_MIN) v = SPR_MIN;
  if (v > SPR_MAX) v = SPR_MAX;
  _sprCustomField.integerValue = v;
  cfg_spr = v;
  apply_sc68_preferences();
}

- (void)onDefTime:(id)sender {
  int v = (int) _defTimeField.integerValue;
  if (v < 0) v = 0;
  if (v > 86399) v = 86399;
  _defTimeField.integerValue = v;
  cfg_deftime = v;
  apply_sc68_preferences();
}

- (void)onASID:(id)sender {
  cfg_asid = (int) _asidPopup.indexOfSelectedItem;
  apply_sc68_preferences();
}

- (void)onEngine:(id)sender {
  cfg_engine = (int) _enginePopup.indexOfSelectedItem;
  apply_sc68_preferences();
}

- (void)onFilter:(id)sender {
  cfg_filter = (int) _filterPopup.indexOfSelectedItem;
  apply_sc68_preferences();
}

- (void)onVolmodel:(id)sender {
  cfg_volmodel = (int) _volmodelPopup.indexOfSelectedItem;
  apply_sc68_preferences();
}

- (void)onBlend:(id)sender {
  cfg_blend = (int) _blendSlider.integerValue;
  apply_sc68_preferences();
}

- (void)onAmigaFilter:(id)sender {
  cfg_amiga_filter = (_amigaFilterCheck.state == NSControlStateValueOn) ? 1 : 0;
  apply_sc68_preferences();
}

@end

/* -----------------------------------------------------------------------
   Preferences page factory (registered with foobar2000)
   ----------------------------------------------------------------------- */

class sc68_pref_page_mac : public preferences_page {
public:
  service_ptr instantiate() override {
    return fb2k::wrapNSObject([SC68PreferencesViewController new]);
  }
  const char * get_name() override { return "SC68"; }
  GUID get_guid() override { return guid_sc68_pref_page; }
  GUID get_parent_guid() override { return preferences_page::guid_input; }
};

static preferences_page_factory_t<sc68_pref_page_mac> g_sc68_pref_factory;
