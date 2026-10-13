# CPU refinement - Classic Carrom and Duboo

This patch changes `scripts/game.gd` only; the shared collision solver,
shot power constraints, opponent rules, interface, assets and controls remain unchanged.

## What the old CPU did

- Calculated ghost contact points to send a black piece toward a pocket.
- Tested launch positions across its baseline and rejected some obstructed lines.
- Chose the highest geometry score with difficulty-dependent random error.
- Fell back to hitting the nearest reachable black piece.
- Did not forecast the consequences of a shot, deliberately plan cushion banks,
  or evaluate multi-piece positional outcomes.

## New shot planner

1. Generate direct-pocket opportunities with both touch and firmer shots.
2. Generate one-rail bank opportunities by reflecting the intended contact
   point across a cushion, if the approach and rebound paths are open.
3. Generate aligned two-piece combination attempts (including black helpers).
4. Include simpler clearing/safety attempts when clean pockets are unavailable.
5. Reserve a diverse per-target shortlist for each shot category.
6. On copies of the current board, test shortlisted attempts using the same
   `CarromPhysics.advance` routine as live gameplay.
7. Score real predicted pockets, multi-pockets, striker fouls, opponent pockets,
   queen coverage, game-ending rules and resulting board positioning.
8. Apply skill-dependent mechanical variance before physically taking the shot.

## Three difficulty tiers (unchanged UI)

- Casual: evaluates at most 12 intentions; more imperfect aim and occasionally
  chooses a lower-rated attempt. Can surprise, but remains beatable.
- Standard: evaluates at most 24 intentions; better aim and more bank and
  combination awareness.
- Expert: evaluates at most 39 intentions; highly precise aim, broadest search,
  and prioritizes stronger physical outcomes and defensive positioning.

The search is processed incrementally in `_process`, avoiding a single long
synchronous planning pass. Complex arrangements can make Expert think longer.

No outcomes are scripted, and the CPU never changes the physical state of
live pieces as part of planning. The search predicts with fixed substeps; actual
outcomes may vary slightly with game frame timing, just as intended.

## Playtesting checklist

- All three difficulty settings in Classic and Duboo.
- Opening CPU break after an alternate board starts.
- Direct pockets, clustered boards and crowded CPU baselines.
- CPU covering the queen and avoiding an uncaptured final-piece finish.
- CPU planning after multiple consecutive successful pockets.
- Restart and switch modes during a CPU turn.
- Test desktop web performance, especially Expert on Duboo.

Godot runtime test could not be performed in the authoring environment.
