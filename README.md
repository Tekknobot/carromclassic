# CARROM | Classic + Duboo

Godot 4.6 project. Open `project.godot` and run `scenes/main.tscn`.

## Modes

- **Classic**: The original eight-board / first-to-25 Carrom match, eight board skins, CPU difficulty levels, original rules and physics.
- **Duboo**: Karachi-inspired slate/marble-table interpretation with a noticeably more spacious layout, smaller playing pieces and a much larger, hollow acrylic ring shooter. One board decides the winner. Nine white, nine black and the Queen remain, with Classic's adapted Queen-cover rules; the ring is too large to fit in a pocket, so ring-pocket fouls don't occur. This is a regional-inspired game mode, not a claim to reproduce a universal Duboo rulebook.

Changing modes restarts the current match. The board style selector is hidden while playing Duboo and restored when returning to Classic.

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

- Dark green-grey veined marble/slate, wooden border, small white inlaid center diagram and baseline markings.
- Narrow, smaller corner pocket mouths and a compact central rack.
- Oversized translucent magenta acrylic ring with the **table visible through its open middle**. The ring is approximately 3.3 times the diameter of a Duboo coin.
- Classic retains the original wooden boards and familiar small solid striker.

## Layout

The full 766px outer frame is reserved separately from the top mode selector and bottom control reminder. The right sidebar contains match status, player/CPU pieces, Queen state, charge bar, CPU difficulty and rules/new-board controls. The sidebar uses vertical scrolling on short windows; no controls overlay the table.

## Notes

- Duboo uses a ring-aware collision solver for the striker, not a solid-circle approximation.
- Duboo is regionally varied. The single-board objective and Classic-compatible Queen/foul rules are explicit game-design choices, not claims about all Pakistani club rules.
- Physics effects and rendering should be play-tested in the Godot editor / web export, especially CPU accuracy and the feel of long glides.
