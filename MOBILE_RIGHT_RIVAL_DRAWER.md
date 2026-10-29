# CARROM CLASSIC — Right Rival Drawer (Mobile UI patch)

Based on the user-supplied Archive(20261029-095045).zip.

## Implemented

- Preserved the top-right hamburger button and original match-settings overlay, including board design, CPU difficulty, restart, rules, sound and Auto Battle.
- Removed the opponent portrait and dynamic rival nickname from the scoreboard. The right-hand score tile now reads **CPU / RIVAL**, with the original `0 / 9` score below it, matching the other tiles.
- A compact **RIVAL >** button on the right of the in-game turn/status strip opens an overlaid profile drawer sliding in from the RIGHT side of the mobile viewport.
- The game-menu **VIEW RIVAL PROFILE >** item also opens the same drawer. Rival selection and long descriptive text have been moved out of the settings menu.
- The drawer has a square, aspect-preserving 160×160 base-size portrait; full name, alias, personality, biography, win/loss/draw record, per-mode Club completion, and Previous/Next Rival selectors.
- Tapping outside the drawer, pressing CLOSE, or pressing Escape dismisses it with a slide-out animation. The board remains visible behind a translucent scrim but doesn't accept gameplay touches while the drawer is open.
- Changing a rival through Previous/Next preserves the original behavior: it starts a fresh match and saves the selected rival. The drawer remains open so players can browse the roster.
- Win/loss result portrait has been made square to match the original artwork proportions.
- No changes to the CPU search, board rules, game physics, progression save format, exported app identity, or Android settings.

## QA checklist (device verification required)

1. On an Android phone in portrait, verify the right score tile reads **CPU / RIVAL** and no portrait appears in it.
2. Tap **RIVAL >** in the status row, verify the drawer slides in from the right; close via CLOSE and outside tap.
3. Inspect all eight original 640×640 portraits and test Previous/Next selectors while Club record is updating correctly.
4. Open the hamburger and confirm the settings screen stays accessible; tap **VIEW RIVAL PROFILE >** to open the drawer.
5. Check touch shooting and the pull grip after closing the drawer. Drawer overlay should intercept taps while open.
6. Test narrow screens, portrait tablets, touch-landscape tablets and match results, including resuming after app switching.
7. Test Classic/Duboo switching, saved rival selection, and Auto Battle record labeling.

## Validation notes

The archive was structurally checked and repackaged. The Godot executable is not installed in this environment, so this is not a Godot compile-tested or device-tested build. Keep a backup of the last working project until device QA passes.

## Mobile readability refinement

- Enlarged the right-side profile to roughly 90% of phone viewport width, instead of the previous narrow fixed cap. Landscape touch layouts use a narrower drawer.
- Increased portrait to a 222-unit square before responsive scaling; aspect preserved.
- Scaled profile title, name, alias, biography, record, and controls to match the rest of the mobile UI.
- Added responsive outer margins, card padding, and section spacing.
- Kept the Close control at the top and Previous/Next rival buttons at the bottom; only profile content scrolls.
- The hamburger remains separate and now closes reliably when opening the rival drawer from the settings menu.
- No rules, physics, scoring, opponent data, persistence, or app identity changes.

Verify the drawer on both a narrow phone and a tall Android phone, including device rotation and the eight different rival bios. This source patch cannot substitute for a Godot runtime/device test.
