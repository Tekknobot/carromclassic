extends Node2D
class_name CarromBoard

const S: float = CarromPhysics.SURFACE
const MAPLE := Color("#e6c68d")
const WOOD_LIGHT := Color("#f0d7a6")
const WOOD_DARK := Color("#7b4b2c")
const INK := Color("#6e3026")
const RED := Color("#9b292d")
const CREAM := Color("#fff6dc")
const GLOW := Color("#80d9c2")

var discs: Array = []
var side: int = 0
var display_striker := false
var active_x: float = S / 2.0
var show_aim := false
var aim_direction := Vector2.UP
var aim_power: float = 0.38
var charging := false
var cpu_target := Vector2.ZERO
var show_cpu_target := false

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Cast-shadow, solid wood frame, inner inset and warm playing veneer.
	draw_rect(Rect2(-43, -34, 775, 774), Color(0.0, 0.0, 0.0, 0.28), true)
	draw_rect(Rect2(-43, -43, 766, 766), Color("#3f291e"), true)
	draw_rect(Rect2(-37, -37, 754, 754), Color("#ac7444"), true)
	draw_rect(Rect2(-29, -29, 738, 738), Color("#c8955c"), true)
	draw_rect(Rect2(-21, -21, 722, 722), Color("#704328"), true)
	draw_rect(Rect2(-12, -12, 704, 704), MAPLE, true)
	draw_rect(Rect2(0, 0, S, S), WOOD_LIGHT, true)
	# Quiet grain. Deterministic painted lines, no external textures required.
	for i in range(62):
		var gy := float((i * 47 + 13) % 663) + 8.0
		var tone := Color(0.63, 0.34, 0.15, 0.035 if i % 3 else 0.055)
		draw_line(Vector2(9, gy), Vector2(S - 9, gy + sin(float(i) * 2.1) * 1.8), tone, 1.0, true)
	for k in range(4):
		var tone := Color("#ffe3b5") if k % 2 == 0 else Color("#87542f")
		draw_rect(Rect2(-36 + float(k) * 4, -36 + float(k) * 4, 752 - float(k) * 8, 752 - float(k) * 8), tone, false, 1.0)
	# Four black pocket mouths with inner leather-like rings.
	for pocket in CarromPhysics.POCKETS:
		draw_circle(pocket, 28.5, Color("#7a482b"), true, -1, true)
		draw_circle(pocket, 24.8, Color("#342720"), true, -1, true)
		draw_circle(pocket, 22.0, Color("#131b1a"), true, -1, true)
		draw_circle(pocket + Vector2(-3.0, -3.0), 18.4, Color(0, 0, 0, 0.22), true, -1, true)
	# Tournament-style center design and inward corner arrows.
	var c: Vector2 = Vector2(S * 0.5, S * 0.5)
	draw_arc(c, 218.0, 0, TAU, 160, INK, 2.25, true)
	draw_arc(c, 14.65, 0, TAU, 48, INK, 2.6, true)
	draw_circle(c, 7.0, RED, true, -1, true)
	for q in range(4):
		var angle := PI / 4.0 + float(q) * PI / 2.0
		var unit := Vector2.from_angle(angle)
		var right := unit.orthogonal()
		var near_pt := c + unit * 239.0
		var far_pt := c + unit * 285.0
		draw_line(near_pt, far_pt, INK, 2.4, true)
		var head := PackedVector2Array([near_pt - unit * 2.0, near_pt + unit * 14.0 + right * 7.0, near_pt + unit * 14.0 - right * 7.0])
		draw_colored_polygon(head, RED)
	for face in range(4):
		_draw_baseline(face)
	# Small engraved corner patterns complete the board without visual clutter.
	for ix in [81.0, S - 81.0]:
		for iy in [81.0, S - 81.0]:
			draw_arc(Vector2(ix, iy), 10.5, 0.0, TAU, 32, Color("#9c503d"), 1.2, true)
	# Subtle highlight of active player's placement zone.
	if display_striker:
		var baseline_y := base_y(side)
		var ac := GLOW if side == 0 else Color("#e3b87d")
		draw_line(Vector2(132, baseline_y), Vector2(548, baseline_y), Color(ac, 0.34), 5.0, true)
		draw_line(Vector2(132, baseline_y), Vector2(548, baseline_y), Color(ac, 0.92), 1.6, true)
		for end_x in [132.0, 548.0]:
			draw_circle(Vector2(end_x, baseline_y), 3.0, ac, true, -1.0, true)
	_draw_discs()
	_draw_aim()

func _draw_baseline(face: int) -> void:
	var a: Vector2 = Vector2(124.0, 559.0)
	var b: Vector2 = Vector2(556.0, 559.0)
	var c: Vector2 = Vector2(124.0, 588.0)
	var d: Vector2 = Vector2(556.0, 588.0)
	_draw_side_line(a, b, face)
	_draw_side_line(c, d, face)
	for x in [124.0, 556.0]:
		var point := _rotate_board(Vector2(x, 573.5), face)
		draw_circle(point, 15.0, RED, true, -1, true)
		draw_arc(point, 15.8, 0, TAU, 40, INK, 1.8, true)
		draw_circle(point, 6.5, Color("#d36a58"), true, -1, true)

func _rotate_board(p: Vector2, quarter_turns: int) -> Vector2:
	var v := p - Vector2(S / 2.0, S / 2.0)
	return Vector2(S / 2.0, S / 2.0) + v.rotated(float(quarter_turns) * PI / 2.0)

func _draw_side_line(a: Vector2, b: Vector2, face: int) -> void:
	draw_line(_rotate_board(a, face), _rotate_board(b, face), INK, 2.0, true)

static func base_y(who: int) -> float:
	return 573.5 if who == 0 else 106.5

func _draw_discs() -> void:
	for disc in discs:
		if disc["pocketed"]:
			continue
		var pos: Vector2 = disc["pos"]
		var rad: float = disc["radius"]
		var kind: String = disc["kind"]
		draw_circle(pos + Vector2(2.0, 3.3), rad + 0.5, Color(0, 0, 0, 0.2), true, -1, true)
		var fill := CREAM
		var outer := Color("#a39b84")
		var ornament := Color("#beb098")
		if kind == "black":
			fill = Color("#30383a")
			outer = Color("#141c1d")
			ornament = Color("#798484")
		elif kind == "queen":
			fill = Color("#c93a3d")
			outer = Color("#7f2028")
			ornament = Color("#f7ac80")
		elif kind == "striker":
			fill = Color("#f9e8c5")
			outer = Color("#3c655f")
			ornament = Color("#28897e")
		draw_circle(pos, rad, outer, true, -1, true)
		draw_circle(pos + Vector2(-0.75, -0.8), rad - 2.0, fill, true, -1, true)
		draw_arc(pos, rad - 4.3, 0.0, TAU, 40, ornament, 1.25, true)
		if kind == "striker":
			draw_arc(pos, rad - 8.6, 0.0, TAU, 40, ornament, 2.0, true)
			draw_circle(pos, 3.9, ornament, true, -1, true)
		elif kind == "queen":
			draw_circle(pos, 3.6, Color("#ffce8e"), true, -1, true)
		else:
			draw_circle(pos, 2.3, ornament, true, -1, true)
			draw_circle(pos + Vector2(-rad * 0.34, -rad * 0.45), 2.4, Color(1, 1, 1, 0.2), true, -1, true)

func _draw_aim() -> void:
	if not show_aim:
		return
	var striker: Dictionary = {}
	for disc in discs:
		if disc["kind"] == "striker" and not disc["pocketed"]:
			striker = disc
			break
	if striker.is_empty():
		return
	var start: Vector2 = striker["pos"]
	var dir: Vector2 = aim_direction.normalized()
	if dir.length_squared() < 0.5:
		return
	var color := Color("#60cbb4") if side == 0 else Color("#edb36c")
	var cast_len: float = 130.0 + aim_power * 245.0
	var end: Vector2 = start + dir * cast_len
	# Dashed aim ray, readable against either light or dark pieces.
	for i in range(int(cast_len / 15.0)):
		var one := start + dir * (27.0 + float(i) * 15.0)
		if one.distance_to(start) > cast_len:
			break
		draw_line(one, one + dir * 8.0, Color(color, 0.86), 2.5, true)
	draw_arc(start, 28.0, 0, TAU, 50, Color(color, 0.5), 1.8, true)
	var tip := end - dir * 5.0
	var wing := dir.orthogonal() * 8.0
	draw_colored_polygon(PackedVector2Array([tip + dir * 15.0, tip - dir * 4.0 + wing, tip - dir * 4.0 - wing]), color)
	if charging:
		draw_arc(start, 28.0, -PI / 2.0, -PI / 2.0 + TAU * aim_power, 60, color, 5.0, true)
	if show_cpu_target:
		draw_arc(cpu_target, 24.0, 0, TAU, 48, Color(color, 0.43), 1.5, true)
