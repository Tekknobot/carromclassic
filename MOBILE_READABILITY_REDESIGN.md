CARROM - MOBILE READABILITY REDESIGN

The mobile UI has its own HUD, settings sheet and short Rules cards.
Desktop side panels and the full desktop rules remain unchanged.

Changes:
- Removed the four expanding spacer controls responsible for the enormous
  empty menu gaps and invisible items below the fold.
- Settings and Rules now size against the same portrait density as the board
  UI (previous modal maximum was 1.22 versus board UI up to 2.5).
- Settings stays vertically centered and compact with visible Board Design,
  Difficulty, Rival, Rules, Restart, and conditional Next Board.
- Menu buttons and labels use minimum legible sizes on narrow phones.
- Rules use six concise, mode-aware sections with larger readable typography.
- Mobile score/status panels and prompts have been refined.
- Gameplay, physics, input behavior, desktop controls are unchanged.

Both portrait sheets contain no scroll container. Extremely short or atypical
portrait viewports are constrained by the viewport's available height.
