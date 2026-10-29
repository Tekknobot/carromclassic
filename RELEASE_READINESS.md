# CARROM CLASSIC — 1.0 release-readiness patch

Source: supplied archive `Archive(20261029-083259).zip` (29 October 2026). All original gameplay, rivals, sound effects, board variations, mode artwork and game scripts are retained. The macOS `__MACOSX` metadata was excluded from the replacement ZIP.

## Implemented

- Renamed prominent game/rules headings to CARROM CLASSIC.
- Replaced pizza startup splash reference and launcher icon with CARROM-branded resources; Play icon, adaptive icon and feature graphic supplied in `store_assets/`.
- Updated Android preset for Gradle/AAB, target SDK API 36, app identity `com.zillatronics.carromclassic`, version name 1.0.0/code 1, ARM64 and launcher visibility. **Export templates, Android SDK and signing key are NOT included.**
- Changed capped rendering to 60 FPS with explicit 60 Hz physics tick. Physics already runs fixed-step independently of rendering; visual frame rate must still be profiled on devices.
- Fixed rival selection restore; CPU difficulty and SFX on/off now persist.
- Added all-SFX toggle to desktop and mobile menus; Auto Battle now accessible from the mobile menu. Both start from the existing mechanics, with no new game modes.
- Converted desktop and mobile live score tiles to pocketed pieces out of nine, consistently with the shipped one-board Classic/Duboo matches; corrected obsolete eight-board/25-point UI copy. End-of-board win/loss still uses existing Carrom rules logic.
- First-run three-step *touch* tutorial (place, aim, shoot), dismissible and shown only once per installation after completion/skip.
- Restores **stable turn-boundary** match snapshots after closing/backgrounding. If the app exits during a moving shot, the most recently saved stable turn is restored; partial moving shots are deliberately not serialized.
- CPU predictions now use the live physics tick rate and live substep counts; this improves step alignment but may increase CPU computation, especially in Duboo Expert. Device benchmarking is essential.
- No extra account, login, ads, analytics, internet permission or monetization SDK has been introduced.

## Must test in Godot before shipping (not executed in this patch environment)

1. Start new Classic and Duboo games; play a full match each against Casual, Standard and Expert CPU.
2. Queen pocketed before any own piece, first piece + Queen on same shot, Queen with cover same shot, Queen with cover on next shot, failed cover, Queen on final shot, and wrong-color final piece.
3. Striker pocketed with/without own pocketed pieces, with pending Queen, and repeated dues; ensure turn changes/respots work.
4. Restart, switch modes, select rival, change board, enable/disable SFX, use mobile Auto Battle; quit and relaunch each time.
5. Force-close during player aiming, CPU thinking, active shot, and match-finished screen; verify stable restoration and no duplicate win/loss record.
6. Repeated mobile pull gestures, taps, cancelled drags, rotation attempts, notch/safe-area and small Android viewport; confirm menu extras and tutorial are visible and actionable.
7. Benchmark CPU think times on S22 and Galaxy Tab A SM-T510, especially Duboo Expert; reduce search work if necessary before paid release.
8. Export and install real signed APK for local testing, then a signed AAB for Play internal testing; verify Android 16/16-KB page-size compliance from generated binary and Play checks.
9. Generate 4–6 genuine in-game phone screenshots at Play Console target dimensions; confirm splash, icon, app label and package ID.
10. Check privacy/data-safety declarations with the **actual final AAB** (including engine/runtime components), and publish a real privacy-policy URL.

## Known scope / nonclaims

- No running Godot executable or Android device test was available during patching. These code/config changes are *not* proof of a crash-free, Play-compliant binary.
- The game's uncommon compound foul rules remain the project's existing simplified adaptation; no formal referee-level rule rewrite or multiplayer was added.
- Full crash-resume **in the middle of** an active shot is not implemented. It resumes from the last safe turn boundary.
- No release key or Play Console upload is provided. You must select your keystore and verify final Android export and target SDK.
- `store_assets/feature_graphic_1024x500.png` is artwork, not a screenshot. Capture actual game footage/screens yourself.

## Suggested release sequence

1. Open project in Godot 4.6; address any editor diagnostics and inspect restored/new match flow.
2. Device gameplay/regression pass; tune CPU search if necessary.
3. Confirm Android templates, signing, min/target SDK and AAB build compliance.
4. Capture real screenshots and create store listing; check data safety, privacy and content rating.
5. Upload internal test AAB; publish paid 1.0 after validation.

## Rival Club / Result Screen addendum

The current patch includes a modal end-of-match screen with rival portrait, win/loss/draw record, and automatic club progression (one win against each of eight rivals in Classic and separately in Duboo). The mobile HUD and mobile menu now show rival portraits. Pressing NEXT RIVAL after a completed game prefers an undefeated rival. Club progress is derived from existing stored win records, with no new data migration needed. Auto Battle is still excluded.

**Do not publish before testing** the new results screen on real Android devices, especially button taps, menu sizing, portrait crops, match restart, and result snapshot restoration. Automated source-structure checks and ZIP integrity verification are not equivalent to running Godot or a device.
