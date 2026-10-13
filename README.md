# CARROM | Classic + Duboo

Godot 4.6 project. Open `project.godot` and run `scenes/main.tscn`.

## Modes

- **Classic**: The original eight-board / first-to-25 Carrom match, eight board skins, CPU difficulty levels, original rules and physics.
- **Duboo**: Karachi-inspired slate/marble-table interpretation with a noticeably more spacious layout, smaller playing pieces and a much larger, hollow acrylic ring shooter. One board decides the winner. Nine white, nine black and the Queen remain, with Classic's adapted Queen-cover rules; the ring is too large to fit in a pocket, so ring-pocket fouls don't occur. This is a regional-inspired game mode, not a claim to reproduce a universal Duboo rulebook.

Changing modes restarts the current match. The existing appearance selector is available in both modes, with **independent saved selections**: eight Classic wooden boards and eight Duboo stone finishes. Switching a table finish during play is cosmetic and does not reset a game.

## Mouse controls — identical in both modes

1. Click the highlighted bottom baseline to place the striker (or reposition it).
2. Point the mouse into the table to aim.
3. Hold left mouse to build power; release to shoot.
4. Right-click cancels a charging shot.

## Duboo table, scale and physics

The logical 680-pixel playing field stays the same size on screen. What changes is the **relative scale of the equipment** and the table markings, informed by Karachi-style Duboo videos and the Carrom Adda browser reference. That reference's default ring is around 2.7 times its playing-piece diameter; this game uses an approximately 3.3x ratio to make the difference unmistakable.

| Logical dimension / behavior | Classic | Duboo |
|---|---:|---:|
| Coin radius | 13.88 px | 8.8 px |
| Queen radius | 14 px | 9 px |
| Striker outer radius | 18.98 px | 29 px |
| Striker inner radius | solid | 19.7 px |
| Pocket radius | 23 px | 15.5 px |
| Start baseline (bottom) | y = 573.5 | y = 620 |
| Outer initial rack radius | 57 px | 37.8 px |
| Coin sliding deceleration | 360 | 112 |
| Ring sliding deceleration | 360 | 137 |
| Coin rail restitution | .78 | .77 |
| Ring rail restitution | .78 | .72 |
| Coin/coin collision restitution | .92 | .91 |
| Ring/coin collision restitution | .92 | .57 |
| Striker mass (coin = 1) | 2.25 | 3.15 |

In Duboo, the shooter's **centre is truly open in the collision model**, not just transparent artwork over a solid physics disc. Exterior collisions use the ring's outer circumference; counters within its aperture are constrained by the inner circumference. The shooter cannot enter a counter-sized pocket. These are game-tuned pixel-scale values, not measured marble material constants.

Duboo shot velocity stays 250–1080, separate from Classic's 320–1425. Player and CPU both use the selected mode's physics and striker size.

## Art direction

- Eight individual Duboo stone finishes: **Club Slate, White Carrara, Black Basalt, Emerald Marble, Blue Granite, Sand Travertine, Rose Onyx, and Smoked Terrazzo**. Every finish uses its own stone coloration, procedural grain/veins/aggregate, trim, pocket rims, and contrasted playing marks.
- Narrow, smaller corner pocket mouths and a compact central rack.
- Oversized ivory-toned hollow ring with the **table visible through its open middle**. The ring is approximately 3.3 times the diameter of a Duboo coin.
- Classic retains the original wooden boards and familiar small solid striker.

## Duboo sound design

Duboo uses four newly synthesized short, dry samples (source WAVs in `audio/`):

- `duboo_strike.wav`: low, hollow acrylic-ring contact against polished stone.
- `duboo_collision.wav`: crisp counter-on-counter/ring collision, pitch and loudness varied by impact.
- `duboo_rail.wav`: softened stone/cushion return, pitch and loudness varied by speed.
- `duboo_pocket.wav`: small edge tick followed by a restrained cavity knock.

Physics collision sounds are rate-limited to avoid noisy, constant retriggering during clustered strikes. Switching back to Classic restores the original strike and pocket WAVs; Classic physics triggers no Duboo collision/rail SFX. These samples are original synthetic sound design, not recordings from a Pakistani club.

## Layout

The full 766px outer frame is reserved separately from the top mode selector and bottom control reminder. The right sidebar contains match status, player/CPU pieces, Queen state, charge bar, CPU difficulty and rules/new-board controls. The sidebar uses vertical scrolling on short windows; no controls overlay the table.

## Notes

- Duboo uses a ring-aware collision solver for the striker, not a solid-circle approximation.
- Duboo is regionally varied. The single-board objective and Classic-compatible Queen/foul rules are explicit game-design choices, not claims about all Pakistani club rules.
- Physics effects and rendering should be play-tested in the Godot editor / web export, especially CPU accuracy and the feel of long glides.


### Mode-specific sound effects
Both Classic and Duboo now play strike, piece collision, rail rebound, and pocket
sounds for either player's turn. Classic uses the original `strike.wav` and
`pocket.wav`, plus lighter `classic_collision.wav` and `classic_rail.wav`. Duboo
uses the four `duboo_*.wav` sounds. Collision and rail playback uses the strongest
impact in a short window, avoiding excessive overlap during clustered shots.
Two pocket voices allow quick double pockets without silencing the second drop.
Sound detection is read-only and does not change any physical simulation.


## Portrait touch controls (Classic and Duboo)

The portrait browser layout uses a **single pull-back-and-release gesture** for
shot direction and power. Drag the striker sideways on the bottom baseline to
place it, then touch the PULL BACK pad under the board. Drag **down** to shoot
**up**, adjust the horizontal direction as you drag, then release. The longer
the drag, the greater the shot power. A tiny drag cancels. The shot fires on
release, not on a timer, and remains safe from touches on neighboring controls.

If a browser fails to deliver the finger-up event, the unfinished pull will
cancel itself after five seconds of inactivity. The Classic and Duboo desktop
mouse controls remain unchanged.

## Portrait mobile layout

The phone UI keeps the nearly full-width board, large touch targets, and
compact match information. The control labeled PULL BACK replaces the old
timed CHARGE button. There is no need to hold, wait for a meter to fill, or
use two fingers. Only the portrait input method changes.
