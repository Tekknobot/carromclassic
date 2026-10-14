# Mobile Touch Shot Control Redesign

Godot 4.6.2 | Classic and Duboo | portrait and landscape touchscreens

## How to play on a phone or tablet

1. Your striker starts ready in the middle of the lower baseline.
2. Drag the striker along the lower baseline to reposition it.
3. Tap or drag on the board to aim. The aim line remains visible when your finger lifts.
4. Touch the mint PULL grip on the right side of the shot dock, then slide LEFT to set power. The power meter fills while you drag.
5. Lift that finger to shoot. The shot uses the direction set on the board, independently of the power gesture.
6. Slide the grip back toward its starting point before release to cancel instead of firing.

No power gesture requires moving your finger outside the screen, or down past the phone edge.
Vertical tremor does not change aim or power. Only the initiating finger may fire the shot.
If the device stops sending touch events, a stalled gesture cancels after five seconds; it never automatically fires.

## Supported layouts

- Portrait touch device: compact phone/tablet view.
- Landscape touch device: left board and right controls.
- Desktop with a mouse: original mouse aiming, hold-to-charge and menus are preserved.

## Test checklist

- Start new match in portrait. Shoot without first tapping baseline.
- Slide striker along baseline and adjust aim elsewhere on board.
- Pull grip left very slightly and release: cancel without shot.
- Pull grip left half way and release: medium-strength shot in same aim direction.
- Pull full travel while moving finger vertically: aim stays the same and power depends only on horizontal travel.
- Drag grip all the way to the left edge of the rail: control never requires traveling outside the display.
- Open and close hamburger menu and Rules before trying to shoot again.
- Play CPU turn and verify new player turn has a centered striker and fresh upward aim.
- Rotate an Android tablet and confirm controls remain available beside the board.

The native Godot 4.6.2 export templates and Android device are required for runtime verification.
