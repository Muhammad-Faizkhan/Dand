# Design system

Tokens are transcribed from the Figma file and centralised — screens reference these
rather than hard-coding values.

## Colour — `core/constants/app_colors.dart`

| Token | Value | Use |
|---|---|---|
| `background` | `#0A0406` | Page base, behind the texture |
| `surface` | `#161618` | Cards, fields, list rows |
| `surfaceAlt` / `surfaceLight` | `#1F1F23` / `#232326` | Raised controls |
| `navBar` | `#09090B` | Bottom navigation |
| `navBorder` / `navIndicator` / `navLabel` | `#161617` / `#A2141A` / `#5F5F60` | Bottom-bar hairline, active indicator, inactive label |
| `sheet` | `#161617` | Bottom sheets |
| `drawer` | `#420411` | Side menu |
| `red` → `redDark` | `#F13A3F` → `#A91318` | Primary gradient |
| `redSolid` | `#E4232B` | Solid accents, FAB, badges |
| `redTint` | `#21060B` | Tinted promo cards |
| `textPrimary` / `textSecondary` / `textTertiary` | `#FFFFFF` / `#9A9AA3` / `#6B6B70` | Type |
| `green` | `#1BB76C` | Sale / live / success |
| `blue`, `planBlue` | `#2847C0`, `#3D5FE8` | Buy flow, order status |
| `teal` | `#3FA9A0` | Rarity badges |
| `amber`, `planGold` | `#F5B301`, `#E8B923` | Pending status, Gold tier |
| `border` / `borderStrong` | white 8% / 14% | Hairlines |

Gradients: `redGradient` (top-left → bottom-right), `redGradientH`, `blueGradient`,
`navAddGradient` (top-right `#9F1319` → bottom-left `#DC2128`, the docked "+").

## Type — `core/constants/app_text_styles.dart`

Inter, bundled at weights 400 / 500 / 600 / 700 / 800.

| Style | Size | Weight |
|---|---|---|
| `display` | 27.2 | 800 |
| `h1` | 24 | 800 |
| `h2` | 19.2 | 700 |
| `h3` | 16 | 700 |
| `h4` | 13.6 | 700 |
| `h5` | 12 | 600 |
| `body` / `bodyDim` | 12 | 400 |
| `bodySm` / `bodySmDim` | 10.8 | 400 |
| `caption` | 9.6 | 400 |
| `button` | 13.2 | 700 |
| `label` | 10.4 | 400 |

Screens override `fontSize` per frame where the design calls for it; page titles sit at
20.5, auth headings at 26–28.

## Components — `lib/widgets/`

| Widget | Purpose |
|---|---|
| `AppBackground` / `AppScaffold` | Grunge texture background + transparent chrome |
| `PrimaryButton` | Gradient CTA with glow; `gradient`/`glowColor` swap it to the blue buy-flow variant |
| `SecondaryButton` | Flat dark button with hairline border |
| `CircleIconButton` | Round translucent icon button |
| `AppTextField` / `DropdownField` | Labelled dark input and select; `obscure` fields get an eye toggle automatically |
| `AppBottomNav` / `ShellBottomNav` | Four glyph tabs, active indicator, docked red "+"; the shell variant returns to `/main` |
| `SideMenu` | Maroon drawer |
| `StatusBadge`, `SectionHeader`, `AppCard`, `InitialsAvatar`, `PageHeader` | Common furniture |
| `ChipGridCard` | White-topped listing tile for every grid |
| `AuthIconBadge`, `StepProgress`, `OtpInput` / `OtpBoxes` | Auth-flow pieces; `OtpInput` owns the code, `OtpBoxes` just draws it |
| `BluePlanProgress`, `PaymentMethodTile`, `AddPaymentMethodTile`, `SummaryCard` | Payment pieces |
| `SuccessView` | Ring + title + detail rows + button stack, shared by all confirmation frames |
| `ScanFrame` | Red camera viewfinder graphic |
| `ImageSourceSheet` | Camera / gallery / remove picker sheet |
| `AssetIcon` | Design-exported glyph with a Material fallback while the file is missing |
| `SettingsHeader`, `ToggleGroup`, `ToggleRow` | Settings furniture |
| `CreditCardVisual` | Red gradient card artwork |
| `SegmentedTabs` | Pill tab selector |

## Assets — `assets/images/`

42 files extracted from the design export: `bg_texture.jpg` (seamlessly re-tiled from a
clean region of the splash frame), `logo.png` / `logo_small.png`, `avatar_mike.jpg` /
`avatar_tom.jpg`, the four `nav_*.png` glyphs, ~24 chip photographs, five event posters
and two feedback illustrations. Paths are referenced through `AppAssets`.

The export came out of Figma at 1x, which is a third of what a 3x phone needs, so
everything was resampled to 2x (Lanczos + a light unsharp pass) and the opaque
photographs moved to quality-94 4:4:4 JPEG — 2x resolution for slightly *less* than the
1x PNGs weighed. The `nav_*` glyphs stay PNG and carry a flat `AppColors.navBar`
background rather than transparency, which is how they leave the design export and what
keeps their darkest pixels reading as they do in Figma.

Two icons are still **missing** from the export: the home header's message and
bell glyphs, which are 3D renders in Figma like the `nav_*` set. `AssetIcon`
already points at their final paths — `assets/images/icon_messages.png` and
`icon_notifications.png` — and draws a Material glyph in the meantime. Export
them at 3x (about 72px for the 17.6pt they are drawn at, so 3x of a 24pt
source is comfortable), drop them in, restart, and they take over with no code
change.

**These are still interpolated pixels.** For genuinely retina-sharp artwork the frames
need re-exporting from Figma at 3x; nothing in the code has to change if they land on
the same filenames.

## Bottom navigation

Every figure below is measured off the four Figma frames (390 x 844) and lives in
`widgets/app_bottom_nav.dart`.

| Property | Value |
|---|---|
| Bar | 91 tall, `#09090B`, 1px `#161617` top hairline |
| Bottom gap | 19.8, widened to the device's gesture inset when that is larger |
| Tab centres | x = 60.5 / 131.5 / 258.5 / 329.5 — **not** evenly spaced; the pairs hug the sides to clear the "+" |
| Indicator | 55 x 6 `#A2141A`, flush with the bar's top edge, bottom corners r4, centred on the active tab, 220ms `easeOutCubic` between tabs |
| Glyphs | 23.8 tall (20.8 for the map pin), on a common baseline 45.6 above the bottom of the bar |
| Labels | Inter 400 / 14, cap line 57.6 below the top edge; `#E4232B` active, `#5F5F60` otherwise |
| Docked "+" | 55 dia, `navAddGradient`, top edge 31.5 above the bar |

The tab content and the indicator both derive their x from the same centre
fractions, so the indicator cannot drift off its icon on any screen width.
`test/bottom_nav_golden_test.dart` renders all four states for diffing against
the design and asserts the alignment at four device sizes.

Use `AppBottomNav.heightOf(context)` for the bottom padding of a scrolling
screen — it includes the device's gesture inset, which `barHeight` does not.

## Auth flow notes

* **OTP** — `OtpInput` draws the six design boxes over one long-lived, zero-size
  `TextField`. The boxes are decoration only. An earlier version rebuilt a
  `TextEditingController` inside `build`, which reset the selection on every
  frame and broke backspace and mid-code editing; the controller now lives in
  the widget's state and the caret is pinned after the last digit, so deleting
  always removes the digit the user can see is last. Paste and
  `AutofillHints.oneTimeCode` come for free. Both `/enter-code` and
  `/enter-otp` are the same screen, so the two flows cannot drift apart.
* **Resend** — `EnterCodeScreen` owns a `Timer.periodic` counting 30 seconds
  down. "Resend code" is inert and grey while it runs, turns red when it hits
  zero, and restarts the countdown and clears the entered digits when tapped.
* **Passwords** — `AppTextField.showToggle` defaults to true, so any field
  marked `obscure` gets the eye without the screen asking for it. The card
  form's CVC opts out; there is no room for it in that three-up row.
* **Profile photo** — the create-account avatar opens `ImageSourceSheet`,
  which offers camera, gallery and (once set) remove. `NSCameraUsageDescription`
  / `NSPhotoLibraryUsageDescription` and `android.permission.CAMERA` are already
  declared.
