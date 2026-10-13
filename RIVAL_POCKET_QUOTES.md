# Rival pocket quotes

Each of the eight rivals has nine short text quotes in `scripts/game.gd`, in `RIVAL_POCKET_QUOTES`.

When an unfouled CPU shot results in at least one newly pocketed black piece, one random line appears in the **existing left-dock rival drawer**. Consecutive lines do not repeat for the same rival. A multi-pocket shot generates only one quote.

The drawer briefly peeks upward (4.6 seconds), then closes automatically. Click its handle to expand the full profile manually; manually opened drawers are never auto-closed by dialogue.

This does not change match rules, CPU planning, accuracy, or the fixed 244px left dock. Mobile retains its existing rival selection menu and has no new overlapping dialogue layer.
