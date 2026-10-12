# CARROM | Classic Board

A playable single-player, mouse-first, bird's-eye 2D carrom project for **Godot 4.6.2**. Built from the uploaded starter project, which contained no gameplay scenes or scripts. The board and coins are rendered procedurally in GDScript; no missing textures, paid assets or external plugins.

## Run

1. Extract `carrom/` from the ZIP.
2. Open Godot **4.6.2** and choose **Import**, then select `carrom/project.godot`.
3. Run the main scene (`F6` with `scenes/main.tscn` open) or the project (`F5`).
4. The game begins immediately, with white at the bottom and black at the top.

## Mouse controls

- Hover over the highlighted **bottom baseline** to preview striker placement.
- **Left-click the baseline** to lock the striker position. Click the baseline again to reposition.
- **Move the mouse** to point in the desired shot direction.
- **Hold left mouse anywhere on the board** to charge, then **release** to strike.
- **Right-click while charging** to cancel.
- All match controls, difficulty selection and the rules panel are accessible via mouse.

## Gameplay

- Nine **white** carrommen (player), nine **black** carrommen (CPU), one **red Queen**; larger patterned striker.
- White breaks first. On later boards, the breaking side alternates.
- Sink your own color to continue shooting. Sink only an opponent coin or miss and your turn passes.
- Claiming the red Queen requires you to have pocketed one of your own pieces, and the Queen must be **covered** either with an own piece in the same shot or with an own piece on the next stroke. If you take the Queen with your first own piece, one further own piece is needed to cover. Failed attempts return Queen to the center.
- Pocketing the striker costs one own piece or creates an outstanding due, then passes the turn (a simplified rule for consistent solo gameplay).
- Win a board by pocketing all nine of your pieces after a Queen has been secured. Pocketing the last of your color before the Queen is secured forfeits the board.
- Winner gains 1 point for each opposing piece remaining, plus Queen bonus (3 points, or 1 if the winner entered the board with 22+ points). A match ends at 25 points or after 8 boards.
- CPU difficulty: **Casual / Standard / Expert**. CPU evaluates pocket paths, legal contact points, baseline start positions, obstructions, distance and angle, then introduces difficulty-dependent shot inaccuracy.

### Rules scope

The traditional equipment, colors, basic flow, Queen covering, turns, striker dues and end-of-board scoring are modeled after international rules. **This is not a tournament-referee simulator**: advanced compound fouls, board-overboard pieces, striker/piece coincidence adjudications, time limits, player seating, tournament service rules, umpire coin-placement discretion, and a few rare Queen/outstanding-due subtleties are simplified. The in-game Rules panel describes what this game actually implements.

Official reference: https://www.indiancarrom.co.in/laws-of-carrom/

## Project files

- `scenes/main.tscn` — startup Control scene
- `scripts/game.gd` — UI, input, turn rules, score, CPU shot planning
- `scripts/carrom_board.gd` — wood board, lines, pockets, pieces, aiming illustration
- `scripts/carrom_physics.gd` — deterministic 2D circle solver, friction, banks, pocket capture
- `audio/*.wav` — generated, original game sounds
- `BOARD_PREVIEW.png` — manually generated illustration of the default board style (not a runtime screenshot)

## Useful tuning constants

- `carrom_physics.gd`: `FRICTION`, `RAIL_BOUNCE`, `COIN_BOUNCE`, `POCKET_RADIUS`
- `game.gd`: `MIN_SHOT_SPEED`, `MAX_SHOT_SPEED`, `MATCH_TARGET`, `MAX_BOARD_COUNT`
- `carrom_board.gd`: `MAPLE`, `WOOD_LIGHT`, `WOOD_DARK`, `INK`, `RED`
- `_choose_cpu_shot()` in `game.gd`: CPU evaluation weights and skill spread.

## Technical notes

Uses one drawn board and an in-memory disc state. The board collision solver advances twice per physics frame and requires no RigidBody2D nodes. Desktop-first UI scales the board and provides a scrollable right-hand panel; the project uses GL Compatibility so it can run on modest hardware. Sound effects are original, procedurally synthesized files.

**Validation note:** The project archive and initial positions were checked structurally, but Godot 4.6.2 was unavailable in the build environment for a launch test. If the editor reports a parse error, copy the exact error and script line number for a targeted fix.
