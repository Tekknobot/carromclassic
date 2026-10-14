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
# Uniform width for all painted board marks, trims, rings, and veins.
const BOARD_LINE_WIDTH := 1.0

# Style 0 retains the original hand-drawn tournament board design.
# The seven additional designs are cosmetic; geometry and physics never change.
const STYLE_NAMES := [
	"CLASSIC TOURNAMENT", "DARK ROSEWOOD", "IVORY & WALNUT", "MODERN MINIMAL",
	"VINTAGE HERITAGE", "BLACK & GOLD", "COASTAL TEAK", "ARCADE NEON"
]
const STYLE_PALETTES := [
	{},
	{"outer": "#241212", "rim": "#693329", "trim": "#cfac70", "inner": "#442019", "lip": "#572b23", "surface": "#68392f", "ink": "#e9c88d", "mark": "#adbd9d", "detail": "#b98958", "pocket": "#100d11", "pocket_ring": "#bd9165", "grain": "#230f11"},
	{"outer": "#38251d", "rim": "#69442b", "trim": "#b58a55", "inner": "#54351f", "lip": "#dcc392", "surface": "#f3e6c8", "ink": "#713a2e", "mark": "#a94f43", "detail": "#ae8958", "pocket": "#19191b", "pocket_ring": "#825b40", "grain": "#8b6b48"},
	{"outer": "#232c34", "rim": "#46535b", "trim": "#a9b6b7", "inner": "#283740", "lip": "#b6c5c3", "surface": "#d9ded6", "ink": "#475861", "mark": "#b26d55", "detail": "#849a9b", "pocket": "#141b23", "pocket_ring": "#52676b", "grain": "#52676b"},
	{"outer": "#4a251a", "rim": "#915b32", "trim": "#d6a969", "inner": "#66321e", "lip": "#bd854c", "surface": "#d5aa69", "ink": "#6e2d25", "mark": "#9f3d2b", "detail": "#744627", "pocket": "#24150f", "pocket_ring": "#a75d36", "grain": "#76411d"},
	{"outer": "#090c10", "rim": "#272628", "trim": "#b49554", "inner": "#12171a", "lip": "#55503b", "surface": "#20252a", "ink": "#c9ae71", "mark": "#f6db9a", "detail": "#82704c", "pocket": "#06090c", "pocket_ring": "#d1b776", "grain": "#778084"},
	{"outer": "#394335", "rim": "#725338", "trim": "#c0a270", "inner": "#6f5a3c", "lip": "#d6bb8e", "surface": "#dabc89", "ink": "#336a66", "mark": "#a35140", "detail": "#6a9b90", "pocket": "#172b29", "pocket_ring": "#4c7870", "grain": "#8b6135"},
	{"outer": "#080e22", "rim": "#25234b", "trim": "#a852bb", "inner": "#10142e", "lip": "#152c40", "surface": "#131e36", "ink": "#73e3e8", "mark": "#f674ba", "detail": "#697cd7", "pocket": "#050b1b", "pocket_ring": "#70d7e4", "grain": "#36618c"}
]


# Duboo table collection. All eight share EXACTLY the same pocket and physics
# geometry; only the carved stone, border, and inlay change.
const DUBOO_STYLE_NAMES := [
	"CLUB SLATE", "WHITE CARRARA", "BLACK BASALT", "EMERALD MARBLE",
	"BLUE GRANITE", "SAND TRAVERTINE", "ROSE ONYX", "SMOKED TERRAZZO"
]
const DUBOO_STYLE_PALETTES := [
	{"outer":"#191719", "rim":"#704e3d", "trim":"#bc9169", "inner":"#27322c", "bevel":"#526a60", "surface":"#314b47", "vein":"#bdd5c9", "inlay":"#d8e3da", "accent":"#b79572", "pocket":"#091413", "pocket_rim":"#817667", "glint":"#b9d8ca"},
	{"outer":"#312c2a", "rim":"#755943", "trim":"#c4a47e", "inner":"#d5cfc2", "bevel":"#e4decf", "surface":"#e8e2d6", "vein":"#88867f", "inlay":"#5a7770", "accent":"#997d5b", "pocket":"#181b1b", "pocket_rim":"#c2b4a1", "glint":"#ffffff"},
	{"outer":"#101314", "rim":"#313638", "trim":"#8c8170", "inner":"#171c20", "bevel":"#343a3d", "surface":"#20282b", "vein":"#7c9091", "inlay":"#c1b69e", "accent":"#a39275", "pocket":"#070b0e", "pocket_rim":"#736e64", "glint":"#ced6d0"},
	{"outer":"#102622", "rim":"#305c4d", "trim":"#c7a46e", "inner":"#214337", "bevel":"#396d5a", "surface":"#1b5145", "vein":"#8cc3a3", "inlay":"#e9d8b1", "accent":"#d1b478", "pocket":"#091b18", "pocket_rim":"#9a9879", "glint":"#b9e6c8"},
	{"outer":"#171e2c", "rim":"#364962", "trim":"#9aadc4", "inner":"#263b52", "bevel":"#415c74", "surface":"#304b67", "vein":"#a4c5d8", "inlay":"#e0e8e4", "accent":"#c0ad8d", "pocket":"#0d1926", "pocket_rim":"#799ab0", "glint":"#bbd9e7"},
	{"outer":"#3b3024", "rim":"#7e6247", "trim":"#ba936d", "inner":"#baa17d", "bevel":"#d3bc98", "surface":"#d1bb95", "vein":"#79644b", "inlay":"#63533b", "accent":"#876a49", "pocket":"#262015", "pocket_rim":"#9e8260", "glint":"#fff0d0"},
	{"outer":"#2b1621", "rim":"#694050", "trim":"#d1a79d", "inner":"#6b3d4b", "bevel":"#935c6b", "surface":"#794555", "vein":"#e7b9b1", "inlay":"#f4dec8", "accent":"#d5a5a0", "pocket":"#210f19", "pocket_rim":"#b88686", "glint":"#f6cdd3"},
	{"outer":"#171919", "rim":"#393c3a", "trim":"#bdaf97", "inner":"#444745", "bevel":"#676861", "surface":"#4e5350", "vein":"#e7d7bd", "inlay":"#f2e2c8", "accent":"#dfbd8f", "pocket":"#111716", "pocket_rim":"#a4a39a", "glint":"#ffffff"},
]

var style_index: int = 0
var duboo_style_index: int = 0

func set_duboo_style(value: int) -> void:
	duboo_style_index = posmod(value, DUBOO_STYLE_NAMES.size())
	queue_redraw()

func set_style(value: int) -> void:
	style_index = posmod(value, STYLE_NAMES.size())
	queue_redraw()

func get_style_name() -> String:
	return STYLE_NAMES[style_index]

func _skin_color(key: String) -> Color:
	return Color(str(STYLE_PALETTES[style_index][key]))

func _ink() -> Color:
	return INK if style_index == 0 else _skin_color("ink")

func _red() -> Color:
	return RED if style_index == 0 else _skin_color("mark")

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
var duboo_mode := false

func _ready() -> void:
	_static_art = Node2D.new()
	_static_art.set_script(load("res://scripts/carrom_board_static.gd"))
	_static_art.z_index = 0
	_static_art.show_behind_parent = true
	add_child(_static_art)
	_sync_static_art()
	queue_redraw()

# Static artwork lives in a separate CanvasItem and is rebuilt only on style changes.
var _static_art: Node2D
var _static_style := -1
var _static_duboo_style := -1
var _static_mode := false

func _sync_static_art() -> void:
	if not is_instance_valid(_static_art):
		return
	if _static_style == style_index and _static_duboo_style == duboo_style_index and _static_mode == duboo_mode:
		return
	_static_style = style_index
	_static_duboo_style = duboo_style_index
	_static_mode = duboo_mode
	_static_art.style_index = style_index
	_static_art.duboo_style_index = duboo_style_index
	_static_art.duboo_mode = duboo_mode
	_static_art.queue_redraw()

func _draw() -> void:
	_sync_static_art()
	# Active placement guide remains dynamic, so the static board never redraws on shots.
	if display_striker:
		var baseline_y := base_y(side, duboo_mode)
		var ac: Color = GLOW if side == 0 else Color("#e3b87d")
		if duboo_mode:
			ac = Color(str(DUBOO_STYLE_PALETTES[duboo_style_index]["inlay"])) if side == 0 else Color(str(DUBOO_STYLE_PALETTES[duboo_style_index]["accent"]))
		elif style_index == 7:
			ac = Color("#68e9ed") if side == 0 else Color("#f4ad7b")
		var zone_left := 112.0 if duboo_mode else 132.0
		var zone_right := 568.0 if duboo_mode else 548.0
		draw_line(Vector2(zone_left, baseline_y), Vector2(zone_right, baseline_y), Color(ac, 0.21), BOARD_LINE_WIDTH, true)
		draw_line(Vector2(zone_left, baseline_y), Vector2(zone_right, baseline_y), Color(ac, 0.80), BOARD_LINE_WIDTH, true)
		for end_x in [zone_left, zone_right]:
			draw_circle(Vector2(end_x, baseline_y), 3.0, ac, true, -1.0, true)
	_draw_discs()
	_draw_aim()


func _draw_duboo_board() -> void:
	# All Duboo designs use the same 680px playable square and the same compact
	# pocket sizes, rack, baselines, and oversize hollow ring.
	var p: Dictionary = DUBOO_STYLE_PALETTES[duboo_style_index]
	var outer := Color(str(p["outer"]))
	var rim := Color(str(p["rim"]))
	var trim := Color(str(p["trim"]))
	var inner := Color(str(p["inner"]))
	var bevel := Color(str(p["bevel"]))
	var surface := Color(str(p["surface"]))
	var vein := Color(str(p["vein"]))
	var inlay := Color(str(p["inlay"]))
	var accent := Color(str(p["accent"]))
	var pocket_color := Color(str(p["pocket"]))
	var pocket_rim := Color(str(p["pocket_rim"]))
	var glint := Color(str(p["glint"]))
	# Preserve original Duboo frame dimensions exactly, keeping the UI gutters.
	draw_rect(Rect2(-43, -43, 766, 766), outer)
	draw_rect(Rect2(-39, -39, 758, 758), rim)
	draw_rect(Rect2(-34, -34, 748, 748), trim)
	draw_rect(Rect2(-28, -28, 736, 736), inner)
	draw_rect(Rect2(-19, -19, 718, 718), bevel)
	draw_rect(Rect2(-9, -9, 698, 698), inner)
	draw_rect(Rect2(0, 0, S, S), surface)
	# Each material has its own restrained, deterministic surface pattern.
	# No textures to import, no shaders, and no per-frame random flicker.
	match duboo_style_index:
		0: # Fine green slate veins and long soft polishing passes.
			for k in range(85):
				var y := float((k * 179 + 49) % 672) + 3.0
				var x := float((k * 107 + 63) % 475) - 60.0
				var points := PackedVector2Array()
				for n in range(8):
					var t := float(n) / 7.0
					points.append(Vector2(clampf(x + (135.0 + float(k % 5) * 48.0) * t, 1.0, S - 1.0), clampf(y + 9.0 * sin(6.0 * t + float(k)), 1.0, S - 1.0)))
				draw_polyline(points, Color(vein, 0.025 if k % 4 else 0.065), BOARD_LINE_WIDTH, true)
			for k in range(7):
				var y := 24.0 + float(k) * 94.0
				draw_line(Vector2(14, y), Vector2(665, y + 9.0), Color(glint, 0.025), BOARD_LINE_WIDTH, true)
		1: # Carrara: broad diagonal, branching grey veins.
			for k in range(25):
				var x := -140.0 + float(k) * 46.0
				var line := PackedVector2Array()
				for n in range(14):
					var t := float(n) / 13.0
					line.append(Vector2(clampf(x + 410.0 * t + 8.0 * sin(t * 9.0 + float(k)), 1.0, S - 1.0), 680.0 * t))
				draw_polyline(line, Color(vein, 0.05 if k % 3 else 0.16), BOARD_LINE_WIDTH, true)
			for k in range(12):
				var a := Vector2(float((k * 153 + 41) % 680), float((k * 187 + 97) % 680))
				draw_line(a, Vector2(clampf(a.x + 55.0, 1.0, S - 1.0), clampf(a.y - 32.0, 1.0, S - 1.0)), Color(vein, 0.11), BOARD_LINE_WIDTH, true)
		2: # Basalt: dark mineral flecks and occasional tiny fractures.
			for k in range(340):
				var pt := Vector2(float((k * 173 + 13) % 666) + 7.0, float((k * 251 + 37) % 666) + 7.0)
				draw_circle(pt, 0.45 + float(k % 4) * 0.35, Color(glint, 0.06 if k % 5 else 0.17))
			for k in range(11):
				var a := Vector2(float((k * 111 + 63) % 500) + 30.0, float((k * 163 + 23) % 600) + 20.0)
				draw_line(a, Vector2(clampf(a.x + 28.0, 1.0, S - 1.0), clampf(a.y + 45.0, 1.0, S - 1.0)), Color(vein, 0.07), BOARD_LINE_WIDTH, true)
		3: # Serpentine: sinuous quartz strands in deep green.
			for k in range(35):
				var strand := PackedVector2Array()
				for n in range(25):
					var t := float(n) / 24.0
					strand.append(Vector2(t * S, clampf(28.0 + float(k) * 19.0 + 15.0 * sin(t * 11.0 + float(k) * 0.65), 1.0, S - 1.0)))
				draw_polyline(strand, Color(vein, 0.035 if k % 4 else 0.16), BOARD_LINE_WIDTH, true)
		4: # Blue granite: a densely mineralised, polished surface.
			for k in range(460):
				var pt := Vector2(float((k * 127 + 21) % 668) + 6.0, float((k * 239 + 29) % 668) + 6.0)
				draw_circle(pt, 0.5 + float(k % 4) * 0.32, Color(vein if k % 3 != 0 else glint, 0.08 if k % 7 != 0 else 0.24))
			for k in range(9):
				var y := float(k) * 79.0 + 13.0
				draw_line(Vector2(14, y), Vector2(666, y + 18.0), Color(glint, 0.027), BOARD_LINE_WIDTH, true)
		5: # Travertine: sedimentary horizontal layers and small pores.
			for k in range(62):
				var y := 8.0 + float(k) * 11.0
				draw_line(Vector2(5, y), Vector2(S - 5.0, y + 2.0 * sin(float(k))), Color(vein, 0.05 if k % 5 else 0.18), BOARD_LINE_WIDTH, true)
			for k in range(150):
				var pt := Vector2(float((k * 241 + 61) % 656) + 12, float((k * 97 + 13) % 652) + 14)
				draw_circle(pt, 0.55 + float(k % 3) * 0.6, Color(vein, 0.09), true)
		6: # Rose onyx: long layered curves with pale translucent veins.
			for k in range(40):
				var strand := PackedVector2Array()
				for n in range(25):
					var t := float(n) / 24.0
					strand.append(Vector2(t * S, clampf(18.0 + float(k) * 17.0 + 21.0 * sin(t * 8.0 + float(k) * 0.34), 1.0, S - 1.0)))
				draw_polyline(strand, Color(vein, 0.035 if k % 5 else 0.20), BOARD_LINE_WIDTH, true)
		7: # Terrazzo: polished stone aggregate chips with no busy grain.
			for k in range(190):
				var x := float((k * 167 + 47) % 652) + 14.0
				var y := float((k * 283 + 89) % 652) + 14.0
				var r := 1.5 + float(k % 5) * 0.7
				var points := PackedVector2Array([Vector2(x - r, y - r * 0.4), Vector2(x + r * 0.7, y - r), Vector2(x + r, y + r * 0.45), Vector2(x - r * 0.45, y + r)])
				draw_colored_polygon(points, Color(vein if k % 3 != 0 else glint, 0.14 if k % 4 != 0 else 0.25))
	# Inlaid rings and baselines are consistent across designs and easy to read.
	var c := Vector2(S * 0.5, S * 0.5)
	draw_arc(c, 51.0, 0, TAU, 100, Color(inlay, 0.70), BOARD_LINE_WIDTH, true)
	draw_arc(c, 9.0, 0, TAU, 36, Color(inlay, 0.72), BOARD_LINE_WIDTH, true)
	draw_line(c + Vector2(-62, 0), c + Vector2(62, 0), Color(inlay, 0.32), BOARD_LINE_WIDTH, true)
	draw_line(c + Vector2(0, -62), c + Vector2(0, 62), Color(inlay, 0.32), BOARD_LINE_WIDTH, true)
	if duboo_style_index == 3 or duboo_style_index == 6:
		draw_arc(c, 59.0, 0, TAU, 100, Color(accent, 0.36), BOARD_LINE_WIDTH, true)
	for face in range(4):
		var y1 := 612.0
		var y2 := 628.0
		var x1 := 108.0
		var x2 := 572.0
		draw_line(_rotate_board(Vector2(x1, y1), face), _rotate_board(Vector2(x2, y1), face), Color(inlay, 0.75), BOARD_LINE_WIDTH, true)
		draw_line(_rotate_board(Vector2(x1, y2), face), _rotate_board(Vector2(x2, y2), face), Color(inlay, 0.75), BOARD_LINE_WIDTH, true)
		for endpoint in [x1, x2]:
			var ep := _rotate_board(Vector2(endpoint, 620.0), face)
			draw_arc(ep, 8.3, 0, TAU, 36, Color(inlay, 0.76), BOARD_LINE_WIDTH, true)
	for pocket in CarromPhysics.POCKETS:
		draw_circle(pocket, 21.0, pocket_rim)
		draw_circle(pocket, 18.0, inner)
		draw_circle(pocket, CarromPhysics.DUBOO_POCKET_RADIUS + 0.2, pocket_color)
		draw_arc(pocket, 20.0, 0.18, PI * 1.4, 44, Color(accent, 0.68), BOARD_LINE_WIDTH, true)

func _draw_classic_board() -> void:
	# Cast-shadow, solid wood frame, inner inset and warm playing veneer.
	#draw_rect(Rect2(-43, -34, 775, 774), Color(0.0, 0.0, 0.0, 0.28), true)
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
		draw_line(Vector2(9, gy), Vector2(S - 9, gy + sin(float(i) * 2.1) * 1.8), tone, BOARD_LINE_WIDTH, true)
	for k in range(4):
		var tone := Color("#ffe3b5") if k % 2 == 0 else Color("#87542f")
		draw_rect(Rect2(-36 + float(k) * 4, -36 + float(k) * 4, 752 - float(k) * 8, 752 - float(k) * 8), tone, false, BOARD_LINE_WIDTH)
	# Four black pocket mouths with inner leather-like rings.
	for pocket in CarromPhysics.POCKETS:
		draw_circle(pocket, 28.5, Color("#7a482b"), true, -1, true)
		draw_circle(pocket, 24.8, Color("#342720"), true, -1, true)
		draw_circle(pocket, 22.0, Color("#131b1a"), true, -1, true)
		draw_circle(pocket + Vector2(-3.0, -3.0), 18.4, Color(0, 0, 0, 0.22), true, -1, true)
	# Tournament-style center design and inward corner arrows.
	var c: Vector2 = Vector2(S * 0.5, S * 0.5)
	draw_arc(c, 218.0, 0, TAU, 160, INK, BOARD_LINE_WIDTH, true)
	draw_arc(c, 14.65, 0, TAU, 48, INK, BOARD_LINE_WIDTH, true)
	draw_circle(c, 7.0, RED, true, -1, true)
	for q in range(4):
		var angle := PI / 4.0 + float(q) * PI / 2.0
		var unit := Vector2.from_angle(angle)
		var right := unit.orthogonal()
		var near_pt := c + unit * 239.0
		var far_pt := c + unit * 285.0
		draw_line(near_pt, far_pt, INK, BOARD_LINE_WIDTH, true)
		var head := PackedVector2Array([near_pt - unit * 2.0, near_pt + unit * 14.0 + right * 7.0, near_pt + unit * 14.0 - right * 7.0])
		draw_colored_polygon(head, RED)
	for face in range(4):
		_draw_baseline(face)
	# Small engraved corner patterns complete the board without visual clutter.
	for ix in [81.0, S - 81.0]:
		for iy in [81.0, S - 81.0]:
			draw_arc(Vector2(ix, iy), 10.5, 0.0, TAU, 32, Color("#9c503d"), BOARD_LINE_WIDTH, true)

func _draw_alternate_board() -> void:
	var outer := _skin_color("outer")
	var rim := _skin_color("rim")
	var trim := _skin_color("trim")
	var inner := _skin_color("inner")
	var lip := _skin_color("lip")
	var surface := _skin_color("surface")
	var ink := _ink()
	var mark := _red()
	var detail := _skin_color("detail")
	var grain := _skin_color("grain")
	# Constant outer dimensions and playable surface across every theme.
	#draw_rect(Rect2(-43, -34, 775, 774), Color(0, 0, 0, 0.33), true)
	draw_rect(Rect2(-43, -43, 766, 766), outer, true)
	draw_rect(Rect2(-37, -37, 754, 754), rim, true)
	draw_rect(Rect2(-29, -29, 738, 738), trim, true)
	draw_rect(Rect2(-25, -25, 730, 730), inner, true)
	draw_rect(Rect2(-19, -19, 718, 718), lip, true)
	draw_rect(Rect2(-12, -12, 704, 704), rim, true)
	draw_rect(Rect2(0, 0, S, S), surface, true)
	# Frames receive distinct inlays without increasing their collision bounds.
	for j in range(3):
		var inset := float(j) * 3.0
		var edge := Color(trim, 0.83 if j == 0 else 0.38)
		draw_rect(Rect2(-33 + inset, -33 + inset, 746 - inset * 2.0, 746 - inset * 2.0), edge, false, BOARD_LINE_WIDTH)
	# Material details are subtle so every disc remains clearly legible.
	match style_index:
		1: # Polished rosewood, continuous lateral grain and brass joinery.
			for i in range(86):
				var y := float((i * 41 + 17) % 676) + 2.0
				var bend := sin(float(i) * 1.91) * 3.7
				draw_line(Vector2(5, y), Vector2(S - 5.0, y + bend), Color(grain, 0.11 if i % 4 == 0 else 0.052), BOARD_LINE_WIDTH)
			for corner_x in [-24.0, S + 24.0]:
				for corner_y in [-24.0, S + 24.0]:
					draw_circle(Vector2(corner_x, corner_y), 3.5, trim)
					draw_circle(Vector2(corner_x - 0.8, corner_y - 0.8), 1.1, Color("#f6d8a1"))
		2: # Porcelain-like ivory face and walnut frame.
			for i in range(41):
				var x := float(i * 19 + 5)
				draw_line(Vector2(x, 4), Vector2(x - 8, S - 4), Color(grain, 0.025), BOARD_LINE_WIDTH)
			for t in range(4):
				draw_rect(Rect2(16 + float(t) * 4.0, 16 + float(t) * 4.0, 648 - float(t) * 8.0, 648 - float(t) * 8.0), Color(detail, 0.14 if t == 0 else 0.045), false, BOARD_LINE_WIDTH)
		3: # Contemporary matte face, almost no grain.
			for k in range(4):
				var y := 45.0 + float(k) * 196.0
				draw_line(Vector2(50, y), Vector2(S - 50, y), Color(grain, 0.035), BOARD_LINE_WIDTH)
			for k in range(4):
				var x := 45.0 + float(k) * 196.0
				draw_line(Vector2(x, 50), Vector2(x, S - 50), Color(grain, 0.035), BOARD_LINE_WIDTH)
		4: # Amber patina and small hand-carved marks.
			for i in range(93):
				var y := float((i * 43 + 21) % 672) + 4.0
				draw_line(Vector2(7, y), Vector2(S - 8, y + sin(float(i)) * 2.8), Color(grain, 0.045 if i % 3 else 0.09), BOARD_LINE_WIDTH)
			for x in [43.0, 637.0]:
				for y in [43.0, 637.0]:
					draw_arc(Vector2(x, y), 15.0, 0.0, TAU, 48, Color(detail, 0.45), BOARD_LINE_WIDTH, true)
					draw_arc(Vector2(x, y), 9.0, 0.0, TAU, 40, Color(mark, 0.35), BOARD_LINE_WIDTH, true)
		5: # Jet-black enamel with hairline metallic machining.
			for i in range(48):
				var y := float(i) * 14.0 + 10.0
				draw_line(Vector2(10, y), Vector2(S - 10, y), Color(grain, 0.027), BOARD_LINE_WIDTH)
			for x in [42.0, 638.0]:
				for y in [42.0, 638.0]:
					_draw_diamond(Vector2(x, y), 11.0, Color(trim, 0.57))
		6: # Sun-warmed teak: plank seams and turquoise accents.
			for i in range(1, 8):
				var x := float(i) * 85.0
				draw_line(Vector2(x, 5.0), Vector2(x, S - 5.0), Color(grain, 0.095), BOARD_LINE_WIDTH)
			for i in range(68):
				var y := float((i * 29 + 7) % 673) + 4.0
				draw_line(Vector2(8, y), Vector2(S - 8, y + sin(float(i) * 1.4)), Color(grain, 0.045), BOARD_LINE_WIDTH)
		7: # Sleek arcade board with fine luminous grid lines.
			for i in range(1, 17):
				var x := float(i) * 40.0
				draw_line(Vector2(x, 4), Vector2(x, S - 4), Color(ink, 0.055), BOARD_LINE_WIDTH)
				draw_line(Vector2(4, x), Vector2(S - 4, x), Color(ink, 0.055), BOARD_LINE_WIDTH)
			for k in range(4):
				var at := Vector2(40.0 if k % 2 == 0 else 640.0, 40.0 if k < 2 else 640.0)
				draw_arc(at, 31.0, 0, TAU, 60, Color(mark, 0.25), BOARD_LINE_WIDTH, true)
	# All boards retain the official-style center ring and four baseline layouts.
	var c := Vector2(S * 0.5, S * 0.5)
	if style_index == 7:
		draw_arc(c, 218.0, 0.0, TAU, 160, Color(ink, 0.17), BOARD_LINE_WIDTH, true)
		draw_arc(c, 218.0, 0.0, TAU, 160, Color(ink, 0.28), BOARD_LINE_WIDTH, true)
	draw_arc(c, 218.0, 0, TAU, 160, ink, BOARD_LINE_WIDTH, true)
	draw_arc(c, 14.65, 0, TAU, 48, ink, BOARD_LINE_WIDTH, true)
	draw_circle(c, 7.0, mark)
	if style_index == 1:
		draw_arc(c, 209.0, 0, TAU, 160, Color(detail, 0.42), BOARD_LINE_WIDTH, true)
		draw_arc(c, 25.0, 0, TAU, 80, Color(trim, 0.45), BOARD_LINE_WIDTH, true)
	elif style_index == 2:
		draw_arc(c, 207.0, 0, TAU, 160, Color(detail, 0.34), BOARD_LINE_WIDTH, true)
		draw_arc(c, 32.0, 0, TAU, 80, Color(mark, 0.35), BOARD_LINE_WIDTH, true)
	elif style_index == 3:
		draw_line(c + Vector2(-28, 0), c + Vector2(28, 0), Color(ink, 0.25), BOARD_LINE_WIDTH)
		draw_line(c + Vector2(0, -28), c + Vector2(0, 28), Color(ink, 0.25), BOARD_LINE_WIDTH)
	elif style_index == 4:
		for k in range(12):
			var a := float(k) * TAU / 12.0
			var point := c + Vector2.from_angle(a) * 207.0
			draw_circle(point, 2.2, Color(detail, 0.34))
		draw_arc(c, 198.0, 0, TAU, 150, Color(mark, 0.16), BOARD_LINE_WIDTH, true)
	elif style_index == 5:
		draw_arc(c, 224.0, 0, TAU, 160, Color(trim, 0.20), BOARD_LINE_WIDTH, true)
		for k in range(8):
			_draw_diamond(c + Vector2.from_angle(float(k) * TAU / 8.0) * 199.0, 6.5, Color(trim, 0.42))
	elif style_index == 6:
		draw_arc(c, 207.0, 0, TAU, 160, Color(detail, 0.36), BOARD_LINE_WIDTH, true)
		for k in range(12):
			var a := float(k) * TAU / 12.0
			draw_line(c + Vector2.from_angle(a) * 28.0, c + Vector2.from_angle(a) * 36.0, Color(detail, 0.45), BOARD_LINE_WIDTH)
	elif style_index == 7:
		draw_arc(c, 209.0, 0, TAU, 160, Color(mark, 0.46), BOARD_LINE_WIDTH, true)
		draw_arc(c, 28.0, 0, TAU, 80, Color(mark, 0.35), BOARD_LINE_WIDTH, true)
	for q in range(4):
		var angle := PI / 4.0 + float(q) * PI / 2.0
		var unit := Vector2.from_angle(angle)
		var right := unit.orthogonal()
		var near_pt := c + unit * 239.0
		var far_pt := c + unit * 285.0
		draw_line(near_pt, far_pt, ink, BOARD_LINE_WIDTH, true)
		var head := PackedVector2Array([near_pt - unit * 2.0, near_pt + unit * 14.0 + right * 7.0, near_pt + unit * 14.0 - right * 7.0])
		draw_colored_polygon(head, mark)
	for face in range(4):
		_draw_baseline(face)
	for x in [81.0, S - 81.0]:
		for y in [81.0, S - 81.0]:
			var corner := Vector2(x, y)
			if style_index == 3:
				_draw_diamond(corner, 8.0, Color(detail, 0.7))
			elif style_index == 7:
				draw_arc(corner, 11.0, 0, TAU, 44, mark, BOARD_LINE_WIDTH, true)
			else:
				draw_arc(corner, 10.5, 0, TAU, 32, Color(detail, 0.72), BOARD_LINE_WIDTH, true)
	# Physical pockets have exactly the same centers and hole radius as classic.
	for pocket in CarromPhysics.POCKETS:
		draw_circle(pocket, 28.5, _skin_color("pocket_ring"))
		draw_circle(pocket, 24.8, _skin_color("inner"))
		draw_circle(pocket, 22.0, _skin_color("pocket"))
		draw_circle(pocket + Vector2(-3.0, -3.0), 18.4, Color(0, 0, 0, 0.22))
		if style_index == 7:
			draw_arc(pocket, 28.0, 0, TAU, 60, Color(mark, 0.33), BOARD_LINE_WIDTH, true)

func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0)
	])
	draw_colored_polygon(points, color)

func _draw_baseline(face: int) -> void:
	var a: Vector2 = Vector2(124.0, 559.0)
	var b: Vector2 = Vector2(556.0, 559.0)
	var c: Vector2 = Vector2(124.0, 588.0)
	var d: Vector2 = Vector2(556.0, 588.0)
	_draw_side_line(a, b, face)
	_draw_side_line(c, d, face)
	for x in [124.0, 556.0]:
		var point := _rotate_board(Vector2(x, 573.5), face)
		draw_circle(point, 15.0, _red(), true, -1, true)
		draw_arc(point, 15.8, 0, TAU, 40, _ink(), BOARD_LINE_WIDTH, true)
		draw_circle(point, 6.5, Color("#d36a58") if style_index == 0 else Color(_red(), 0.58), true, -1, true)

func _rotate_board(p: Vector2, quarter_turns: int) -> Vector2:
	var v := p - Vector2(S / 2.0, S / 2.0)
	return Vector2(S / 2.0, S / 2.0) + v.rotated(float(quarter_turns) * PI / 2.0)

func _draw_side_line(a: Vector2, b: Vector2, face: int) -> void:
	draw_line(_rotate_board(a, face), _rotate_board(b, face), _ink(), BOARD_LINE_WIDTH, true)

static func base_y(who: int, duboo: bool = false) -> float:
	if duboo:
		return 620.0 if who == 0 else 60.0
	return 573.5 if who == 0 else 106.5

func _draw_discs() -> void:
	for disc in discs:
		if disc["pocketed"]:
			continue
		var pos: Vector2 = disc["pos"]
		var rad: float = disc["radius"]
		var kind: String = disc["kind"]
		if not (duboo_mode and kind == "striker"):
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
		if duboo_mode:
			if kind == "striker":
				# Traditional ivory Duboo striker with a large hollow centre.
				# Dark outer rim, ivory body and subtle concentric detailing.
				var inner := CarromPhysics.DUBOO_RING_INNER_RADIUS
				var mid := (rad + inner) * 0.5
				var band := rad - inner
				draw_arc(pos + Vector2(1.5, 2.0), mid, 0, TAU, 96, Color(0, 0, 0, 0.25), band + 2.0, true)
				draw_arc(pos, mid, 0, TAU, 96, Color("#514C43"), band + 0.5, true)
				draw_arc(pos, mid, 0, TAU, 96, Color("#F2E6CC"), band - 2.5, true)
				draw_arc(pos, rad - 1.8, 0, TAU, 96, Color("#9A8568"), 1.8, true)
				draw_arc(pos, inner + 1.8, 0, TAU, 96, Color("#B7A184"), 1.6, true)
				draw_arc(pos, mid, -PI * 0.75, -PI * 0.15, 40, Color("#FFFFFF", 0.35), 2.0, true)
				continue
			# Small polished white / dark / red counters against the dark stone.
			if kind == "white":
				fill = Color("#f4e9c9")
				outer = Color("#bbaa8c")
				ornament = Color("#d9d0b8")
			elif kind == "black":
				fill = Color("#222c2b")
				outer = Color("#0d1517")
				ornament = Color("#7b9290")
			else:
				fill = Color("#c4423a")
				outer = Color("#6d2525")
				ornament = Color("#e6a78b")
		# Preserve coin silhouettes on dark or pale Duboo stone finishes.
		if duboo_mode and kind == "black" and duboo_style_index in [0, 2, 3, 4, 6, 7]:
			draw_circle(pos, rad + 1.15, Color(str(DUBOO_STYLE_PALETTES[duboo_style_index]["inlay"]), 0.58), true, -1, true)
		elif duboo_mode and kind == "white" and duboo_style_index in [1, 5]:
			draw_circle(pos, rad + 1.1, Color("#695943", 0.67), true, -1, true)
		# Black carrommen need an extra contrasting silhouette on dark skins.
		if not duboo_mode and style_index in [1, 5, 7] and kind == "black":
			draw_circle(pos, rad + 1.9, Color("#c6b895") if style_index != 7 else Color("#7fdbe7"), true, -1, true)
		draw_circle(pos, rad, outer, true, -1, true)
		draw_circle(pos + Vector2(-0.75, -0.8), rad - 2.0, fill, true, -1, true)
		draw_arc(pos, maxf(2.6, rad - 4.3), 0.0, TAU, 40, ornament, 1.0 if duboo_mode else 1.25, true)
		if kind == "striker":
			draw_arc(pos, rad - 8.6, 0.0, TAU, 40, ornament, 2.0, true)
			draw_circle(pos, 3.9, ornament, true, -1, true)
		elif kind == "queen":
			draw_circle(pos, 2.1 if duboo_mode else 3.6, Color("#ffce8e"), true, -1, true)
		else:
			draw_circle(pos, 1.6 if duboo_mode else 2.3, ornament, true, -1, true)
			draw_circle(pos + Vector2(-rad * 0.34, -rad * 0.45), 1.3 if duboo_mode else 2.4, Color(1, 1, 1, 0.2), true, -1, true)

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
	var color := (Color("#366e64") if side == 0 else Color("#9c724c")) if duboo_mode else ((Color("#79f2f1") if side == 0 else Color("#ffb479")) if style_index == 7 else (Color("#60cbb4") if side == 0 else Color("#edb36c")))
	var cast_len: float = 130.0 + aim_power * 245.0
	var end: Vector2 = start + dir * cast_len
	# Dashed aim ray, readable against either light or dark pieces.
	for i in range(int(cast_len / 15.0)):
		var one := start + dir * ((CarromPhysics.DUBOO_STRIKER_RADIUS + 6.0 if duboo_mode else 27.0) + float(i) * 15.0)
		if one.distance_to(start) > cast_len:
			break
		draw_line(one, one + dir * 8.0, Color(color, 0.86), 2.5, true)
	draw_arc(start, CarromPhysics.DUBOO_STRIKER_RADIUS + 4.0 if duboo_mode else 28.0, 0, TAU, 50, Color(color, 0.5), 1.8, true)
	var tip := end - dir * 5.0
	var wing := dir.orthogonal() * 8.0
	draw_colored_polygon(PackedVector2Array([tip + dir * 15.0, tip - dir * 4.0 + wing, tip - dir * 4.0 - wing]), color)
	if charging:
		draw_arc(start, CarromPhysics.DUBOO_STRIKER_RADIUS + 4.0 if duboo_mode else 28.0, -PI / 2.0, -PI / 2.0 + TAU * aim_power, 60, color, 5.0, true)
	if show_cpu_target:
		draw_arc(cpu_target, 24.0, 0, TAU, 48, Color(color, 0.43), 1.5, true)
