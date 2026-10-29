# CARROM CLASSIC — Godot 4.6 project

Classic Carrom and Duboo, eight rival personalities, three CPU difficulty levels, board styles, spectator Auto Battle, an illustrated match-results screen, and a persistent eight-rival Club goal for each mode.

## Rival Club and game endings

Each board is a complete match. On victory or defeat, the game shows the opponent portrait, personal win/loss/draw record, and progress toward defeating all eight rivals in the selected mode. No opponents are locked. Use **Rematch** or **Next Rival** to continue. Mobile shows your current rival portrait in the score tile and game menu. See `RIVAL_CLUB_UPDATE.md` for behaviour and testing notes.

## Open and test

1. Unzip this entire folder. **Keep** `project.godot`, `scripts`, `scenes`, `audio`, `assets`, `portraits`, `store_assets` and `export_presets.cfg` together.
2. Open `project.godot` using Godot **4.6**. Let assets import on first open.
3. Run the main scene and test the modes and controls on desktop, then Android.
4. Read `RELEASE_READINESS.md` for the implemented changes and required on-device verification.
5. Install Android export templates and choose **Project → Install Android Build Template** before the Gradle/AAB export.
6. Supply your own release keystore through Godot's Android export settings; never commit/upload it to source control.
7. Export **without debug** as `CARROM_CLASSIC_1.0.0.aab` and upload to an internal testing track first.

This ZIP contains a **patched source project**, **not** a compiled, tested, signed Android release. For Google Play, store listing screenshots must come from a real build of this game, not mockups.


## Mobile rival drawer refresh (October 29, 2026)
The in-game score now uses `CPU / RIVAL` without a portrait. The hamburger menu remains; the rival profile and selection have moved to an animated right-side drawer accessible via `RIVAL >` in the live status strip or `VIEW RIVAL PROFILE >` in settings. See `MOBILE_RIGHT_RIVAL_DRAWER.md` for details and QA.
