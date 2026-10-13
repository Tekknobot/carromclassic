extends Button

# Three true vector strokes: consistent at every mobile resolution.
# No special characters or third-party icon fonts.
func _draw() -> void:
	var scale_factor: float = minf(size.x, size.y) / 48.0
	var length: float = 22.0 * scale_factor
	var separation: float = 6.2 * scale_factor
	var thickness: float = maxf(2.0, 2.4 * scale_factor)
	for i in range(3):
		var yy: float = size.y * 0.5 + float(i - 1) * separation
		draw_line(Vector2(size.x * 0.5 - length * 0.5, yy), Vector2(size.x * 0.5 + length * 0.5, yy), Color("#f7f0d9"), thickness, true)
