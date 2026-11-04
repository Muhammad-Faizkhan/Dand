# Docs index — what to trust first

Last updated 15 September 2026.

Anything in `docs/archive/` is superseded and kept only as a record. Read it
for history, not for how the app works today.

## Start here

| Doc | What it answers |
|---|---|
| [`RESPONSIVE.md`](RESPONSIVE.md) | How sizing works. **Read before touching any layout** — every widget sizes in design units, and the tablet/landscape behaviour is not obvious. |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Project structure, controllers, routing. |
| [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) | Colours, typography, shared widgets. |
| [`SCREENS.md`](SCREENS.md) | The screen inventory and what each one is for. |

## Current state — 15 September 2026

* `flutter analyze` clean; **`flutter test` 150/150 green.**
* The app is responsive: phones unchanged, tablets at ~1.25-1.30x with
  multi-column grids, both orientations handled.
* Goldens were regenerated on Flutter **3.41.2**. They had been failing since
  the toolchain moved off 3.32.0 and are now the live guard on phone
  rendering — `test/screens_golden_test.dart` renders through the production
  `ResponsiveScreenUtil`, so a regression in the scale curve fails them.
* Data is still mock (`lib/core/utils/app_data.dart`). **No backend.**

## Session logs

Newest first. The most recent doubles as the current state of play.

| Date | |
|---|---|
| [`SESSION-2026-09-15.md`](SESSION-2026-09-15.md) | Responsive/tablet support; goldens regenerated |
| [`../archive/SESSION-2026-09-09.md`](../archive/SESSION-2026-09-09.md) | Camera, onboarding Skip, chip artwork rebuild, avatar, logout confirm |
| [`../archive/SESSION-2026-09-03.md`](../archive/SESSION-2026-09-03.md) | Earlier build-out |

## Known issues

Carried in the latest session log; the ones most likely to bite:

1. **No version control.** There is no `.git` — nothing is recoverable. See
   `CLAUDE.md`.
2. **Release signs with the debug key** (`android/app/build.gradle.kts`).
3. **Chip artwork** is repaired screen grabs — 11 distinct chips across 26
   filenames, several misnamed. Needs real photography.
4. **Throwaway `TextEditingController`s** in `payment_screens.dart`,
   `item_form_screen.dart`, `edit_profile_screen.dart`.
