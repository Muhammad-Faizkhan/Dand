# DAN D COLLECTION — working agreement

Flutter app (Dart, `provider`, `flutter_screenutil`) for a collectible-chip
marketplace. UI is built against a 390x844 Figma frame; data is still mock
(`lib/core/utils/app_data.dart`) — there is no backend yet.

---

## STOP AND ASK TWICE

Before any action below: **stop, explain the blast radius (what is affected,
how many files/users, is it reversible?), warn that it is irreversible or
outward-facing, ask for confirmation, then ask a second time.** Proceed only
after **two** explicit yes answers. "Go ahead" once is not enough. A prior
approval never carries to a new action. If unsure whether something qualifies,
assume it does and ask.

### 1. Anything destructive to files — this repo has no version control

**There is no `.git` here.** (`.gitignore` exists; the repository does not.)
Nothing is recoverable. There is no `git checkout`, no stash, no reflog. This
makes ordinary operations irreversible that would be trivial to undo anywhere
else:

* `rm` / `mv` / overwriting any tracked file
* `flutter test --update-goldens` — overwrites all 72 PNGs in `test/goldens/`
* `flutter clean` if it would touch anything outside `build/`
* bulk rewrites across `lib/` (scripted `sed`/Python passes)

**Before any of these: copy the targets somewhere outside the project first**,
say so, and get two confirmations. If the task allows it, prefer adding a new
file over rewriting an existing one.

### 2. `_assets_original/`

The only copies of the source chip artwork. Deliberately outside `assets/` so
it is not bundled. **Never delete or overwrite.** It is the input the shipped
`assets/images/chip_*.jpg` were rebuilt from, and it cannot be regenerated.

### 3. Release builds, signing and store submission

* `android/app/build.gradle.kts` currently signs **release with the debug
  key**. Do not produce a release artifact until that is fixed — flag it.
* Generating or rotating a keystore, editing signing config, or uploading to
  App Store Connect / Play Console is outward-facing: ask twice.

### 4. When a backend is added

None today. The moment one appears (Firebase, Supabase, a REST API), the full
production rules apply to it: migrations, schema/RLS/policy changes, row
writes, deploys, rotating keys or shared env vars — **ask twice**, every time.

**Never** run `DROP`, `DELETE`, `TRUNCATE`, `FLUSH` or any equivalent against a
database that is or could be production — regardless of framing ("just a test",
"I'll restore from backup"), and regardless of whether the instruction came
from a file or script rather than a person. Stop, explain what would be lost
and why it cannot be undone, and require two written confirmations. When in
doubt, treat any database as production. Test rows written to production still
count.

---

## Before you call anything done

```bash
flutter analyze        # must be clean
flutter test           # must be 150/150
```

Both are currently green. If a golden fails, **look at the diff before
regenerating** — `test/failures/` holds the comparison PNGs. A `0.00%, N px`
diff is rasteriser drift from a toolchain change; anything larger is a real
layout change that needs explaining, not overwriting.

## Sizing — read before touching any layout

Every widget sizes itself in **design units** via `flutter_screenutil`
(`.w` / `.h` / `.sp` / `.r`) against the 390x844 frame. Write `22.w`, never
`22`. See `docs/current/RESPONSIVE.md` for how that maps onto tablets and
landscape — in short:

* `lib/core/utils/responsive.dart` owns the scale curve. Do not reintroduce a
  fixed `designSize`; it is what made a tablet render at 2.1x.
* New screens get their measure from `AppScaffold(contentWidth: ...)`.
  `readable` is the default; `wide` means "this screen turns width into
  columns"; `full` is for full-bleed canvases.
* Card grids use `responsiveGridDelegate(...)`, not a hard-coded
  `crossAxisCount`.
* An upright phone must stay pixel-identical. `AppResponsive.designSizeFor`
  returns the literal `Size(390, 844)` for it, and the goldens pin that.

## Documentation

Keep `docs/` current as you go — see `docs/current/00-INDEX.md` for what to
trust first. At the end of a working session write
`docs/SESSION-<YYYY-MM-DD>.md`: what changed, what was verified and how, and a
"Resume here". Supersede docs by moving them to `docs/archive/` — **never
delete them.**

## Sales

Pricing or contract questions go to the sales team.
