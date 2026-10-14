# Android performance patch

The procedural board artwork is now cached in a separate CanvasItem. Disc, aim and placement updates redraw only the dynamic layer. Static board commands regenerate when switching between board styles or Carrom/Duboo modes. No viewport, layout, physics, touch-control, or rules changes.

Retains your existing 30 FPS project setting. Test the APK on the SM-T510. This patch may reduce CPU draw-command overhead; it does not guarantee a fixed FPS if GPU fill-rate or physics is the bottleneck.
