# Responsive sizing

How the app answers a screen it was not drawn for. Added 15 September 2026;
see `docs/current/SESSION-2026-09-15.md` for the change itself.

## The constraint

The design is a **390 x 844** phone frame. Every widget sizes itself against it
through `flutter_screenutil` — roughly 1,800 uses of `.w`, `.h`, `.sp` and
`.r`. ScreenUtil scales those linearly:

    scaleWidth = screenWidth / designSize.width

With a fixed `designSize`, an 820-wide iPad multiplies **every** padding,
glyph, radius and font by 2.10, and a 12.9" by 2.63 — a phone screenshot blown
up, not a tablet layout.

Two files fix that, and all of it is driven from the one design size.

## 1. The scale curve — `lib/core/utils/responsive.dart`

`AppResponsive.uiScale` makes growth stop instead of continuing:

```dart
final raw = screen.shortestSide / 390;
if (raw <= 1.22) return raw;            // phones: the ratio they always had
return 1.22 + (raw - 1.22) * 0.06;      // tablets: a trickle, not a doubling
```

`designSizeFor` feeds ScreenUtil a design size computed back from that scale.
`ResponsiveScreenUtil` (in `main.dart`) re-picks it on every metrics change —
rotation, iPad multitasking, desktop resize.

Three properties this relies on, all pinned by `test/responsive_test.dart`:

| Property | Why |
|---|---|
| Scale comes from the **shortest side** | Identical in both orientations, so rotating re-flows layout without resizing a glyph. |
| The curve is **continuous** (1.2390 at 599dp, 1.2391 at 600dp) | No jump at the tablet threshold. |
| Off the upright-phone path, `scaleWidth == scaleHeight` | The frame is *reproportioned*, not stretched — so `Positioned`-only screens (splash, onboarding) stay correct in landscape with no per-screen work. |

| Device | Naive | Actual | Body text |
|---|---|---|---|
| iPhone 14 (390x844) | 1.000 | **1.000** | 12.0 |
| iPhone SE (375x667) | 0.962 | **0.962** | 11.5 |
| iPhone 14 landscape | 2.164 | **1.000** | 12.0 |
| iPad mini (744x1133) | 1.908 | **1.261** | 15.1 |
| iPad 10.9 (820x1180) | 2.103 | **1.273** | 15.3 |
| iPad Pro 12.9 (1024x1366) | 2.626 | **1.304** | 15.7 |

**An upright phone returns the literal `Size(390, 844)`** — its rendering is
bit-for-bit unchanged, and the goldens pin it.

## 2. Where the freed width goes — `lib/widgets/responsive_layout.dart`

Capping the scale leaves room over. `ContentWidth` decides what each screen
does with it, applied by `AppScaffold` (47 screens) and by `MainShell`
per tab:

| Mode | Width | For |
|---|---|---|
| `readable` (default) | 460 design units | forms, detail, settings, auth, lists of full-width rows |
| `wide` | 780 design units | the seven screens with card grids |
| `full` | unconstrained | map, dealers sheet |

**`wide` means "this screen turns width into columns."** Nothing else gets it.
It was initially given to the list screens and Home too; that just stretched
every row to ~993pt, so they went back to `readable`.

Grids use `responsiveGridDelegate(...)`, which derives the column count from
the content width and preserves each tile's drawn aspect ratio: **2** on a
phone, **3** upright tablet, **4** landscape and 12.9".

`ResponsiveCanvas` hands its child **tight** constraints, not loose ones —
several screens are a `Stack` of nothing but `Positioned` children and would
collapse to zero height under an `Align` or `Center`.

`FillOrScroll` keeps a `Spacer`-based column working when there is room and
scrolls when there is not (landscape).

## Adding a screen

1. Size everything in design units (`22.w`, never `22`).
2. Build on `AppScaffold` and pick a `contentWidth`. `readable` unless the
   screen answers width with columns.
3. Card grid? `responsiveGridDelegate(...)`.
4. Fixed `Column` with a `Spacer`? Wrap it in `FillOrScroll`.
5. Add the route to `test/responsive_test.dart`'s list — it renders every
   route at nine viewports and fails on any layout exception.

## Gotchas

* **Do not reintroduce a fixed `designSize`.** That is the bug.
* `splitScreenMode: true` makes ScreenUtil treat the viewport as at least 700
  tall; `designSizeFor` mirrors that floor so the scale comes out as asked.
* `.sp` resolves through `FontSizeResolvers.width` in this version of
  `flutter_screenutil`, so text follows the **width** scale.
* `test/bottom_nav_golden_test.dart` builds its own `ScreenUtilInit` with
  `splitScreenMode` left at its default, unlike production. It renders only
  phone-portrait sizes, so it agrees today — worth knowing before changing it.

## Not done

* **Two-pane layouts.** A landscape tablet shows one centred column, not a
  list/detail split. A design decision, not a gap in the plumbing —
  `ContentWidth` is where it would hang.
* **OS text scaling on a tablet is untested.** Buttons and fields take fixed
  heights (`56.h`, `53.h`); a large accessibility size plus the tablet scale
  could clip.
