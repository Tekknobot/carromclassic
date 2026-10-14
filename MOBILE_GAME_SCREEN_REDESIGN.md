# Mobile game screen redesign

The portrait game surface was rebuilt to visually match the mobile hamburger menu and Rules sheet while keeping desktop layout and gameplay unchanged.

- Independent game-only scoreboard with three visually distinct score tiles (You, Queen, CPU).
- Compact left-aligned turn strip with mint/gold ownership indicator.
- Dedicated two-line mobile masthead, compact board-count indicator and segmented Classic/Duboo tabs.
- Shorter shooting dock: full-width charge meter above a large central pull pad, preserving the existing touch gesture hitbox, drag and release logic.
- Responsive sizing allocates portrait height to the board *before* adding decorative breathing room. Settings and Rules overlay sizes are unchanged.
- Desktop stats and controls remain on their original layout.

## Quick manual checks

1. Open on a 9:16 portrait device and verify the complete shot dock and board are visible without a page scrollbar.
2. Slide the striker, drag the PULL BACK pad, then release; confirm the shot fires, including a 100% charge.
3. Switch Classic/Duboo, open and close the hamburger menu, and open Rules; labels and hitboxes should remain legible.
4. Rotate to desktop/landscape; desktop docks should remain unchanged.
