# CARROM CLASSIC — Rival Club + Match Results

This patch adds visible match endings and a lightweight progression goal while retaining all original Classic, Duboo, CPU personality, and spectator gameplay.

## How matches end

- Each match consists of one board. White (player) and Black (CPU) each have nine pieces; Queen coverage rules remain unchanged.
- The game ends when the board's winner is decided. A finished match displays a modal results screen, including the selected opponent's portrait, victory/defeat text, and your updated W/L/D record.
- **Rematch** starts another board against the same rival, and **Next Rival** moves to the next unbeaten opponent in that mode when available (otherwise the next portrait/CPU profile). **View Finished Board** closes the presentation without starting another match.
- A completed result is persisted in the existing match snapshot so reopening the app can show the result again. Changing modes or starting a new match dismisses it.
- Spectator Auto Battle displays the **winning CPU's portrait** and an appropriate outcome but does **not** change personal records or club progress.

## Progression — no grind or locks

- In each mode, the goal is to defeat **all eight distinct CPU rivals at least once**.
- Club progress is displayed as `CLASSIC CLUB 3/8` and `DUBOO CLUB 2/8` depending on the mode.
- A first win over a new opponent announces `NEW RIVAL DEFEATED!`; defeating all eight announces `CLUB COMPLETE!`.
- **Every rival remains available from the beginning**, and a loss never resets progress.
- Progress is **calculated from the previous per-rival win records**, rather than maintaining an additional save file. Existing players' records automatically count toward the club.
- Club records are counted separately between Classic and Duboo and persist between sessions through `user://carrom_board_settings.cfg`.
- Difficulty is a player-selectable setting, **not** a progression gate. A win on any CPU difficulty marks that rival defeated. There is no separate expert trophy.

## Mobile UI

- The currently selected CPU opponent's existing portrait appears in the black rival scoreboard tile, without creating an extra row or shrinking the board.
- The opponent selection area in the mobile game menu also displays the portrait and your club status / W-L-D record.
- For compact phone widths, nicknames in the score tile display their first word when necessary; the menu and results always show the full identity.

## Please test in Godot and on real Android devices

1. New match: Rival portrait in the mobile black score tile and correct portrait in the menu; change rivals and modes; check 320 px and 360 px widths.
2. Win on Classic: result overlay, correct opponent portrait, 1 win saved, club 1/8, first-clear announcement; repeat win does not increase club count.
3. Lose Classic and Duboo: rival portrait, defeat copy and incremented loss counter; the club count does not decrease.
4. Beat a different rival: club advances to 2/8; switching to Duboo shows a separate count.
5. Reopen the game with a completed match: result overlay reappears without recording the same match twice.
6. Rematch button: same rival, clean board, existing records remain. Next Rival: next unbeaten rival (or next when all cleared), fresh board.
7. View Finished Board: overlay hides; the board remains finished and does not accept shot input.
8. Auto Battle: winner's portrait is shown, spectator copy only, **no** win/loss/club changes; Watch Again / New Matchup work.
9. Test menu sizing, result sizing and back navigation on Samsung S22 and Galaxy Tab A, including rotating while a modal is open where possible.

**Validation scope:** Source changes were reviewed and ZIP integrity tested, but Godot 4.6 and Android hardware were not available in this environment. This is a source patch, not a verified signed AAB.
