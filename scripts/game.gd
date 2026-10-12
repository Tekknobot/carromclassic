extends Control

# Carrom: a self-contained, mouse-first, top-down board game.
# Traditional colors and central rules; rare compound-foul adjudication is
# intentionally simplified as documented in README.md.
const PHYSICS := preload("res://scripts/carrom_physics.gd")
const BOARD_SCENE := preload("res://scripts/carrom_board.gd")
const BG := Color("#102320")
const PANEL := Color("#19322e")
const PANEL_ALT := Color("#213c36")
const TEXT := Color("#f7f0d9")
const MUTED := Color("#a7bbb1")
const MINT := Color("#7bdac2")
const GOLD := Color("#e8bf7e")
const INK := Color("#0b211e")
const MAX_BOARD_COUNT := 8
const MATCH_TARGET := 25
const MIN_SHOT_SPEED := 320.0
const MAX_SHOT_SPEED := 1425.0

var board: CarromBoard
var discs: Array = []
var player_turn := 0
var phase := "placement"
var board_number := 1
var totals: Array[int] = [0, 0]
var outstanding_dues: Array[int] = [0, 0]
var queen_owner := -1
var pending_queen := -1
var last_shot_pockets: Array[int] = []
var own_count_before := 0
var shot_duration := 0.0
var charge_time := 0.0
var charge_power := 0.25
var aim_direction := Vector2.UP
var cpu_time := 0.0
var cpu_queued_shot: Dictionary = {}
var cpu_skill := 1
var winner := -1
var board_finished_message := ""
var status_title := "YOUR BREAK"
var status_text := "Move over the bottom baseline and click to place your striker."
var side_panel: PanelContainer
var main_score_white: Label
var main_score_black: Label
var coins_white: Label
var coins_black: Label
var turn_head: Label
var turn_desc: Label
var queen_text: Label
var power_label: Label
var power_meter: ProgressBar
var match_info: Label
var rules_overlay: PanelContainer
var next_button: Button
var restart_button: Button
var cpu_selector: OptionButton
var sound_shoot: AudioStreamPlayer
var sound_pocket: AudioStreamPlayer
var sound_click: AudioStreamPlayer
var title_label: Label
var board_caption: Label
var tip_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	board = BOARD_SCENE.new()
	add_child(board)
	_build_ui()
	_build_audio()
	_new_match()
	_layout()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()
		queue_redraw()

func _draw() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), BG, true)
	for n in range(int(sz.y / 30.0) + 2):
		var yy: float = float(n) * 30.0
		draw_line(Vector2(0, yy), Vector2(sz.x, yy), Color(1, 1, 1, 0.018), 1.0)
	for n in range(int(sz.x / 30.0) + 2):
		var xx: float = float(n) * 30.0
		draw_line(Vector2(xx, 0), Vector2(xx, sz.y), Color(1, 1, 1, 0.018), 1.0)

func _build_audio() -> void:
	sound_shoot = AudioStreamPlayer.new()
	sound_shoot.stream = load("res://audio/strike.wav")
	sound_shoot.volume_db = -8.0
	add_child(sound_shoot)
	sound_pocket = AudioStreamPlayer.new()
	sound_pocket.stream = load("res://audio/pocket.wav")
	sound_pocket.volume_db = -6.0
	add_child(sound_pocket)
	sound_click = AudioStreamPlayer.new()
	sound_click.stream = load("res://audio/tick.wav")
	sound_click.volume_db = -13.0
	add_child(sound_click)

func _style(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 12) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(1 if border.a > 0.0 else 0)
	st.set_corner_radius_all(radius)
	st.content_margin_left = 15.0
	st.content_margin_right = 15.0
	st.content_margin_top = 12.0
	st.content_margin_bottom = 12.0
	return st

func _label(parent: Node, value: String, font_size: int, color: Color, wrap_text: bool = false) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func _gap(parent: Node, pixels: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = pixels
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)

func _make_button(parent: Node, title: String, highlight: bool = false) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 42.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", INK if highlight else TEXT)
	b.add_theme_color_override("font_hover_color", INK if highlight else TEXT)
	b.add_theme_color_override("font_pressed_color", INK if highlight else TEXT)
	b.add_theme_stylebox_override("normal", _style(MINT if highlight else PANEL_ALT, Color.TRANSPARENT, 9))
	b.add_theme_stylebox_override("hover", _style(Color("#9aebd8") if highlight else Color("#38594d"), Color.TRANSPARENT, 9))
	b.add_theme_stylebox_override("pressed", _style(Color("#58bba4") if highlight else Color("#102722"), Color.TRANSPARENT, 9))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(b)
	return b

func _build_ui() -> void:
	title_label = _label(self, "CARROM", 29, TEXT)
	board_caption = _label(self, "CLASSIC BOARD  /  SINGLE PLAYER", 12, MUTED)
	tip_label = _label(self, "MOUSE   PLACE  /  AIM  /  HOLD TO POWER  /  RELEASE", 12, MUTED, true)
	side_panel = PanelContainer.new()
	side_panel.add_theme_stylebox_override("panel", _style(PANEL, Color("#3c5b51"), 16))
	add_child(side_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 11)
	side_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_label(content, "THE MATCH", 11, MINT)
	match_info = _label(content, "BOARD 1 OF 8   |   FIRST TO 25", 14, TEXT)
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 10)
	content.add_child(scores)
	var white_card := _score_card(scores, "YOU   /   WHITE", _cream_color())
	main_score_white = white_card[0]
	coins_white = white_card[1]
	var black_card := _score_card(scores, "CPU   /   BLACK", GOLD)
	main_score_black = black_card[0]
	coins_black = black_card[1]
	var queens := PanelContainer.new()
	queens.add_theme_stylebox_override("panel", _style(PANEL_ALT))
	content.add_child(queens)
	var queen_row := HBoxContainer.new()
	queens.add_child(queen_row)
	var queen_dot := Label.new()
	queen_dot.text = "●"
	queen_dot.add_theme_font_size_override("font_size", 22)
	queen_dot.add_theme_color_override("font_color", Color("#e45f62"))
	queen_row.add_child(queen_dot)
	queen_text = _label(queen_row, "  QUEEN  /  ON THE BOARD", 13, TEXT)
	var turn_card := PanelContainer.new()
	turn_card.add_theme_stylebox_override("panel", _style(Color("#25483f"), Color("#3e6759")))
	content.add_child(turn_card)
	var turn_stack := VBoxContainer.new()
	turn_stack.add_theme_constant_override("separation", 6)
	turn_card.add_child(turn_stack)
	turn_head = _label(turn_stack, "YOUR BREAK", 18, MINT)
	turn_desc = _label(turn_stack, "Click the bottom baseline to place.", 14, TEXT, true)
	turn_desc.custom_minimum_size.y = 60
	var power_box := VBoxContainer.new()
	power_box.add_theme_constant_override("separation", 5)
	content.add_child(power_box)
	power_label = _label(power_box, "SHOT POWER   0%", 12, MUTED)
	power_meter = ProgressBar.new()
	power_meter.show_percentage = false
	power_meter.min_value = 0
	power_meter.max_value = 100
	power_meter.custom_minimum_size.y = 11
	power_meter.add_theme_stylebox_override("background", _style(Color("#0e2623"), Color.TRANSPARENT, 6))
	power_meter.add_theme_stylebox_override("fill", _style(MINT, Color.TRANSPARENT, 6))
	power_box.add_child(power_meter)
	next_button = _make_button(content, "NEXT BOARD", true)
	next_button.pressed.connect(_next_board)
	next_button.visible = false
	var divider := HSeparator.new()
	divider.add_theme_color_override("color", Color("#537167"))
	content.add_child(divider)
	_label(content, "CPU OPPONENT", 11, MINT)
	cpu_selector = OptionButton.new()
	cpu_selector.custom_minimum_size.y = 38
	cpu_selector.add_item("Casual", 0)
	cpu_selector.add_item("Standard", 1)
	cpu_selector.add_item("Expert", 2)
	cpu_selector.select(1)
	cpu_selector.add_theme_font_size_override("font_size", 14)
	cpu_selector.add_theme_color_override("font_color", TEXT)
	cpu_selector.add_theme_stylebox_override("normal", _style(PANEL_ALT, Color("#46665a"), 9))
	cpu_selector.add_theme_stylebox_override("hover", _style(Color("#345a4e"), Color.TRANSPARENT, 9))
	cpu_selector.item_selected.connect(func(idx: int) -> void: cpu_skill = idx)
	content.add_child(cpu_selector)
	_label(content, "HOW TO PLAY", 11, MINT)
	_label(content, "1  Click the glowing baseline to place.\n2  Point the cursor to aim.\n3  Hold left mouse to charge. Release to shoot.\n4  Pocket WHITE. CPU plays BLACK.", 13, TEXT, true)
	var bottom_buttons := HBoxContainer.new()
	bottom_buttons.add_theme_constant_override("separation", 10)
	content.add_child(bottom_buttons)
	var rules_button := _make_button(bottom_buttons, "RULES", false)
	rules_button.pressed.connect(_open_rules)
	restart_button = _make_button(bottom_buttons, "NEW MATCH", false)
	restart_button.pressed.connect(_new_match)
	_build_rules_overlay()

func _cream_color() -> Color:
	return Color("#f8eacc")

func _score_card(parent: Node, heading: String, accent: Color) -> Array[Label]:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style(PANEL_ALT))
	parent.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	_label(v, heading, 11, accent)
	var score := _label(v, "0", 35, TEXT)
	var sub := _label(v, "0 / 9 pocketed", 12, MUTED)
	return [score, sub]

func _build_rules_overlay() -> void:
	rules_overlay = PanelContainer.new()
	rules_overlay.visible = false
	rules_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	rules_overlay.add_theme_stylebox_override("panel", _style(Color("#19332f"), Color("#74ae97"), 16))
	add_child(rules_overlay)
	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_right", 12)
	inner.add_theme_constant_override("margin_top", 12)
	inner.add_theme_constant_override("margin_bottom", 12)
	rules_overlay.add_child(inner)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	scroll.add_child(v)
	_label(v, "CARROM  /  QUICK RULES", 23, MINT)
	_label(v,
		"OBJECTIVE\nYou are WHITE. Pocket all nine white pieces, with the red Queen legally covered, to win the board. The CPU plays BLACK.\n\nTURNS\nWhite breaks. You keep shooting whenever you pocket at least one of your own pieces; otherwise the turn passes. Opponent pieces remain pocketed if you sink them.\n\nTHE QUEEN\nYou must pocket one of your own pieces before you can claim the Queen. Pocket the Queen and one of your own pieces in the same shot, or pocket your own piece on your very next shot to cover it. An uncovered Queen returns to the center. If you capture the Queen together with your very first piece, a further cover is required.\n\nSTRIKER FOUL\nPocketing the striker costs one of your previously pocketed pieces (or incurs one owed piece if none is available), and ends your turn.\n\nSCORING\nThe board winner scores one point for each opponent piece left on the board. The Queen adds three points if secured by the winner, or one when their pre-board match score is at least 22. First to 25 points or the leader after eight boards wins.\n\nThis is a playable standard-rules adaptation: specialist referee calls and uncommon compound fouls are simplified.",
		14, TEXT, true)
	var close := _make_button(v, "RETURN TO BOARD", true)
	close.pressed.connect(func() -> void: rules_overlay.visible = false)

func _layout() -> void:
	if board == null or side_panel == null:
		return
	var sz := size
	var side_w := clampf(sz.x * 0.315, 358.0, 468.0)
	var side_x := sz.x - side_w - 24.0
	var board_w := side_x - 30.0
	var scale_value := clampf(minf((board_w - 56.0) / 766.0, (sz.y - 134.0) / 766.0), 0.48, 1.22)
	board.scale = Vector2.ONE * scale_value
	board.position = Vector2(board_w * 0.5 - 340.0 * scale_value, sz.y * 0.51 - 340.0 * scale_value)
	side_panel.position = Vector2(side_x, 22.0)
	side_panel.size = Vector2(side_w, sz.y - 44.0)
	title_label.position = Vector2(32.0, 11.0)
	title_label.size = Vector2(board_w - 50, 42)
	board_caption.position = Vector2(34.0, 53.0)
	board_caption.size = Vector2(board_w - 50, 20)
	tip_label.position = Vector2(35.0, sz.y - 41.0)
	tip_label.size = Vector2(board_w - 50, 30)
	var dialog_size := Vector2(minf(640, sz.x - 80), minf(790, sz.y - 50))
	rules_overlay.position = (sz - dialog_size) * 0.5
	rules_overlay.size = dialog_size

func _new_match() -> void:
	board_number = 1
	totals = [0, 0]
	outstanding_dues = [0, 0]
	queen_owner = -1
	pending_queen = -1
	winner = -1
	_begin_board()

func _begin_board() -> void:
	discs.clear()
	queen_owner = -1
	pending_queen = -1
	outstanding_dues = [0, 0]
	winner = -1
	last_shot_pockets.clear()
	var index := 0
	_add_disc("queen", Vector2(340, 340), index)
	index += 1
	# Six inner + twelve outer carrommen; 9 white and 9 black.
	for ring in range(2):
		var count := 6 if ring == 0 else 12
		var radius := 29.0 if ring == 0 else 57.0
		for k in range(count):
			var angle := -PI / 2.0 + float(k) * TAU / float(count)
			var kind := "white" if k % 2 == 0 else "black"
			_add_disc(kind, Vector2(340, 340) + Vector2.from_angle(angle) * radius, index)
			index += 1
	_add_disc("striker", Vector2(340, 573.5), 100)
	player_turn = 0 if board_number % 2 == 1 else 1
	phase = "placement" if player_turn == 0 else "cpu_think"
	board.discs = discs
	board.side = player_turn
	board.display_striker = true
	board.active_x = 340.0
	board.show_aim = false
	board.charging = false
	board.show_cpu_target = false
	charge_time = 0.0
	cpu_time = 0.75
	if player_turn == 0:
		_set_status("YOUR BREAK" if board_number == 1 else "YOUR TURN", "Move onto the bottom baseline and click to place your striker.")
	else:
		_set_status("CPU BREAK", "The computer is looking for its opening shot.")
	_refresh_ui()
	board.queue_redraw()

func _add_disc(kind: String, at: Vector2, id_number: int) -> void:
	discs.append({"id": id_number, "kind": kind, "pos": at, "vel": Vector2.ZERO, "radius": PHYSICS.radius_for(kind), "mass": PHYSICS.coin_mass(kind), "pocketed": false})

func _get_striker() -> Dictionary:
	return discs[discs.size() - 1]

func _get_disc(id_number: int) -> Dictionary:
	for d in discs:
		if d["id"] == id_number:
			return d
	return {}

func _pocketed_count(kind: String) -> int:
	var count := 0
	for disc in discs:
		if disc["kind"] == kind and disc["pocketed"]:
			count += 1
	return count

func _kind_for(player: int) -> String:
	return "white" if player == 0 else "black"

func _set_status(title: String, message: String) -> void:
	status_title = title
	status_text = message
	if turn_head != null:
		turn_head.text = title
		turn_head.add_theme_color_override("font_color", MINT if player_turn == 0 else GOLD)
		turn_desc.text = message

func _refresh_ui() -> void:
	main_score_white.text = str(totals[0])
	main_score_black.text = str(totals[1])
	coins_white.text = "%d / 9 pocketed" % _pocketed_count("white")
	coins_black.text = "%d / 9 pocketed" % _pocketed_count("black")
	match_info.text = "BOARD %d OF %d    |    FIRST TO %d" % [board_number, MAX_BOARD_COUNT, MATCH_TARGET]
	if pending_queen != -1:
		queen_text.text = "  QUEEN  /  %s MUST COVER" % ("YOU" if pending_queen == 0 else "CPU")
	elif queen_owner != -1:
		queen_text.text = "  QUEEN  /  COVERED BY %s" % ("YOU" if queen_owner == 0 else "CPU")
	else:
		queen_text.text = "  QUEEN  /  ON THE BOARD"
	next_button.visible = phase == "board_over"
	power_label.text = "SHOT POWER   %d%%" % int(round(charge_power * 100.0)) if phase == "charging" else "SHOT POWER   HOLD MOUSE TO CHARGE"
	power_meter.value = charge_power * 100.0 if phase == "charging" else 0.0
	turn_head.text = status_title
	turn_desc.text = status_text

func _screen_to_board() -> Vector2:
	return board.to_local(get_global_mouse_position())

func _valid_baseline_click(point: Vector2) -> bool:
	return point.x >= 106.0 and point.x <= 574.0 and absf(point.y - CarromBoard.base_y(0)) < 40.0

func _place_striker(player: int, desired_x: float) -> bool:
	var striker := _get_striker()
	var y := CarromBoard.base_y(player)
	var x := clampf(desired_x, 125.0, 555.0)
	var candidates: Array[float] = [x]
	for i in range(1, 53):
		candidates.append(clampf(x + float(i) * 7.5, 125.0, 555.0))
		candidates.append(clampf(x - float(i) * 7.5, 125.0, 555.0))
	for test_x in candidates:
		var sample := Vector2(test_x, y)
		if _can_place_striker(sample):
			striker["pos"] = sample
			striker["vel"] = Vector2.ZERO
			striker["pocketed"] = false
			board.active_x = test_x
			board.queue_redraw()
			return true
	return false

func _can_place_striker(point: Vector2) -> bool:
	for other in discs:
		if other["kind"] == "striker" or other["pocketed"]:
			continue
		if point.distance_squared_to(other["pos"]) < pow(PHYSICS.STRIKER_RADIUS + other["radius"] + 2.5, 2):
			return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if rules_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			rules_overlay.visible = false
		return
	if player_turn != 0 or phase not in ["placement", "aim", "charging"]:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := _screen_to_board()
		if event.pressed:
			if _valid_baseline_click(mouse) and phase != "charging":
				if _place_striker(0, mouse.x):
					phase = "aim"
					board.show_aim = true
					board.side = 0
					_set_status("AIM YOUR SHOT", "Point anywhere on the board. Hold LEFT MOUSE to charge, then release to shoot. Click the baseline again to reposition.")
					sound_click.play()
					_refresh_ui()
				else:
					_set_status("BASELINE BLOCKED", "Try another spot on the glowing baseline.")
			elif phase == "aim" and Rect2(0, 0, 680, 680).has_point(mouse):
				phase = "charging"
				charge_time = 0.0
				charge_power = 0.2
				board.charging = true
				_refresh_ui()
		else:
			if phase == "charging":
				_shoot(aim_direction, charge_power)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if phase == "charging":
			phase = "aim"
			board.charging = false
			_set_status("AIM YOUR SHOT", "Hold left mouse to charge. Right click cancels a charging shot.")
			_refresh_ui()

func _process(delta: float) -> void:
	if rules_overlay != null and rules_overlay.visible:
		return
	if phase == "aim" or phase == "charging":
		var mouse := _screen_to_board()
		var diff: Vector2 = mouse - _get_striker()["pos"]
		if diff.length() > 22.0:
			aim_direction = diff.normalized()
			board.aim_direction = aim_direction
		if phase == "charging":
			charge_time = minf(charge_time + delta, 1.5)
			charge_power = 0.20 + 0.80 * charge_time / 1.5
			power_label.text = "SHOT POWER   %d%%" % int(round(charge_power * 100.0))
			power_meter.value = charge_power * 100.0
			board.charging = true
		board.aim_power = charge_power
		board.queue_redraw()
	elif phase == "placement":
		var mouse := _screen_to_board()
		if _valid_baseline_click(mouse):
			_place_striker(0, mouse.x)
	elif phase == "cpu_think":
		cpu_time -= delta
		if cpu_time <= 0.0:
			cpu_queued_shot = _choose_cpu_shot()
			_place_striker(1, cpu_queued_shot["x"])
			board.aim_direction = cpu_queued_shot["dir"]
			board.aim_power = inverse_lerp(MIN_SHOT_SPEED, MAX_SHOT_SPEED, cpu_queued_shot["speed"])
			board.show_aim = true
			board.show_cpu_target = true
			board.cpu_target = cpu_queued_shot["target"]
			board.queue_redraw()
			phase = "cpu_aim"
			cpu_time = 0.65
			_set_status("CPU AIMING", "The computer has selected a shot.")
			_refresh_ui()
	elif phase == "cpu_aim":
		cpu_time -= delta
		if cpu_time <= 0.0:
			_shoot(cpu_queued_shot["dir"], inverse_lerp(MIN_SHOT_SPEED, MAX_SHOT_SPEED, cpu_queued_shot["speed"]))

func _shoot(direction: Vector2, power: float) -> void:
	if direction.length_squared() < 0.5:
		return
	phase = "moving"
	var striker := _get_striker()
	striker["vel"] = direction.normalized() * lerpf(MIN_SHOT_SPEED, MAX_SHOT_SPEED, clampf(power, 0.0, 1.0))
	striker["pocketed"] = false
	own_count_before = _pocketed_count(_kind_for(player_turn))
	shot_duration = 0.0
	last_shot_pockets.clear()
	board.display_striker = false
	board.show_aim = false
	board.show_cpu_target = false
	board.charging = false
	sound_shoot.play()
	_set_status("PIECES IN MOTION", "Watch the shot settle. Pocket your color to keep the turn.")
	_refresh_ui()
	board.queue_redraw()

func _physics_process(delta: float) -> void:
	if rules_overlay != null and rules_overlay.visible:
		return
	if phase != "moving":
		return
	shot_duration += delta
	for _substep in range(2):
		var fallen: Array[int] = PHYSICS.advance(discs, delta * 0.5)
		for piece_id in fallen:
			last_shot_pockets.append(piece_id)
			if not sound_pocket.playing:
				sound_pocket.play()
	board.queue_redraw()
	if (shot_duration > 0.35 and PHYSICS.is_still(discs)) or shot_duration >= 12.0:
		for d in discs:
			d["vel"] = Vector2.ZERO
		_resolve_shot()

func _respot_disc(disc: Dictionary) -> void:
	disc["pocketed"] = true
	var position: Vector2 = PHYSICS.find_open_position(discs, Vector2(340, 340), disc["radius"], disc["id"])
	disc["pos"] = position
	disc["vel"] = Vector2.ZERO
	disc["pocketed"] = false

func _respot_queen() -> void:
	for disc in discs:
		if disc["kind"] == "queen":
			_respot_disc(disc)
			break
	pending_queen = -1

func _apply_striker_due(player: int) -> String:
	var color := _kind_for(player)
	for disc in discs:
		if disc["kind"] == color and disc["pocketed"]:
			_respot_disc(disc)
			return "One %s piece was returned as a striker due." % color
	outstanding_dues[player] += 1
	return "Striker due: one future %s piece must be returned." % color

func _collect_outstanding_due(player: int) -> String:
	if outstanding_dues[player] <= 0:
		return ""
	for disc in discs:
		if disc["kind"] == _kind_for(player) and disc["pocketed"]:
			_respot_disc(disc)
			outstanding_dues[player] -= 1
			return "An outstanding striker due returned one of your pieces."
	return ""

func _resolve_shot() -> void:
	var actor := player_turn
	var own_kind := _kind_for(actor)
	var own_in_shot := 0
	var other_in_shot := 0
	var queen_in_shot := false
	var striker_in_shot := false
	for id in last_shot_pockets:
		var piece := _get_disc(id)
		if piece.is_empty():
			continue
		if piece["kind"] == own_kind:
			own_in_shot += 1
		elif piece["kind"] == "queen":
			queen_in_shot = true
		elif piece["kind"] == "striker":
			striker_in_shot = true
		else:
			other_in_shot += 1
	var notices: Array[String] = []
	var freshly_pending := false
	if striker_in_shot:
		if pending_queen != -1 or queen_in_shot:
			_respot_queen()
		notices.append(_apply_striker_due(actor))
		notices.append("Striker pocketed: foul. Your turn ends.")
	else:
		# The previous shot's Queen must be covered on this immediate shot.
		if pending_queen == actor:
			if own_in_shot > 0:
				queen_owner = actor
				pending_queen = -1
				notices.append("Queen covered!")
			else:
				_respot_queen()
				notices.append("Queen not covered; returned to the center.")
		if queen_in_shot:
			if own_count_before == 0 and own_in_shot == 0:
				_respot_queen()
				notices.append("Pocket one of your pieces before taking the Queen.")
			elif (own_count_before > 0 and own_in_shot > 0) or own_in_shot >= 2:
				queen_owner = actor
				pending_queen = -1
				notices.append("Queen covered in the same shot!")
			else:
				pending_queen = actor
				freshly_pending = true
				notices.append("Queen pocketed. Cover it on your NEXT shot.")
		if outstanding_dues[actor] > 0 and own_in_shot > 0:
			notices.append(_collect_outstanding_due(actor))
	var own_after := _pocketed_count(own_kind)
	var actor_has_scored := own_after > own_count_before
	if own_after >= 9:
		if queen_owner != -1:
			_end_board(actor, "All nine %s pieces pocketed!" % own_kind.to_upper())
		else:
			_end_board(1 - actor, "The last piece fell before the Queen was secured.")
		return
	var opp_kind := _kind_for(1 - actor)
	if _pocketed_count(opp_kind) >= 9:
		_end_board(1 - actor, "The last %s piece was pocketed." % opp_kind.to_upper())
		return
	if not striker_in_shot and (actor_has_scored or freshly_pending):
		player_turn = actor
	else:
		player_turn = 1 - actor
	var result := "  ".join(notices)
	if result.is_empty():
		if actor_has_scored:
			result = "Good pocket. Another shot!"
		elif other_in_shot > 0:
			result = "Opponent piece pocketed. Turn passes."
		else:
			result = "No piece of your color pocketed. Turn passes."
	if player_turn == 0:
		phase = "placement"
		board.display_striker = true
		board.side = 0
		_place_striker(0, 340.0)
		_set_status("YOUR TURN  /  WHITE", result + " Click the bottom baseline to place your striker.")
	else:
		phase = "cpu_think"
		board.display_striker = true
		board.side = 1
		_place_striker(1, 340.0)
		cpu_time = 0.85
		_set_status("CPU TURN  /  BLACK", result + " Computer is choosing its shot.")
	_refresh_ui()
	board.queue_redraw()

func _end_board(board_winner: int, reason: String) -> void:
	winner = board_winner
	var opponent_left := 9 - _pocketed_count(_kind_for(1 - board_winner))
	var gain := maxi(1, opponent_left)
	if queen_owner == board_winner:
		gain += 1 if totals[board_winner] >= 22 else 3
	elif queen_owner == -1:
		# Uncovered Queen / premature finish is a forfeited board.
		gain = maxi(3, gain)
	totals[board_winner] += gain
	phase = "board_over"
	board.display_striker = false
	board.show_aim = false
	board_finished_message = "%s  +%d POINTS  |  %s" % ["YOU WIN THE BOARD!" if board_winner == 0 else "CPU WINS THE BOARD", gain, reason]
	var match_over := totals[board_winner] >= MATCH_TARGET or board_number >= MAX_BOARD_COUNT
	if match_over:
		phase = "match_over"
		var match_winner := 0 if totals[0] > totals[1] else 1
		if totals[0] == totals[1]:
			_set_status("MATCH TIED", "Eight boards completed with equal points. Select NEW MATCH to play again.")
		else:
			_set_status("YOU WIN THE MATCH!" if match_winner == 0 else "CPU WINS THE MATCH", board_finished_message + "  Select NEW MATCH to play again.")
	else:
		_set_status("BOARD COMPLETE", board_finished_message + "  Select NEXT BOARD to continue.")
	_refresh_ui()
	board.queue_redraw()

func _next_board() -> void:
	if phase != "board_over":
		return
	board_number += 1
	_begin_board()
	sound_click.play()

func _open_rules() -> void:
	rules_overlay.visible = true
	rules_overlay.move_to_front()
	sound_click.play()

# The CPU searches for feasible contact points that send one of its discs
# toward a pocket. It tests baseline positions, collision normals, clear
# approach lines, and target-to-pocket obstruction. This uses the same
# physics and power range as the human (it does not teleport pieces).
func _choose_cpu_shot() -> Dictionary:
	var best_score := -1.0e10
	var best := {"x": 340.0, "dir": Vector2.DOWN, "speed": 1000.0, "target": Vector2(340, 340)}
	var pockets: Array[Vector2] = PHYSICS.POCKETS
	for piece in discs:
		if piece["pocketed"]:
			continue
		if piece["kind"] != "black" and not (piece["kind"] == "queen" and queen_owner == -1 and pending_queen == -1 and _pocketed_count("black") > 0):
			continue
		var target: Vector2 = piece["pos"]
		for pocket in pockets:
			var exit_dir: Vector2 = (pocket - target).normalized()
			var ghost: Vector2 = target - exit_dir * (PHYSICS.STRIKER_RADIUS + piece["radius"] + 0.7)
			var pocket_open := _segment_is_clear(target, pocket, piece["radius"] * 1.9, piece["id"])
			for n in range(16):
				var x := 127.0 + float(n) * 28.3
				var initial := Vector2(x, CarromBoard.base_y(1))
				if not _can_place_striker(initial):
					continue
				var offset := ghost - initial
				if offset.length() < 27.0:
					continue
				var direction: Vector2 = offset.normalized()
				var center_line: Vector2 = target - initial
				var projection := center_line.dot(direction)
				if projection <= 0.0:
					continue
				var closest_sq := center_line.length_squared() - projection * projection
				var contact_radius: float = PHYSICS.STRIKER_RADIUS + piece["radius"]
				if closest_sq > contact_radius * contact_radius:
					continue
				var hit_distance: float = projection - sqrt(maxf(0.0, contact_radius * contact_radius - closest_sq))
				if hit_distance < 10.0:
					continue
				var impact: Vector2 = initial + direction * hit_distance
				var impact_normal: Vector2 = (target - impact).normalized()
				var accuracy: float = impact_normal.dot(exit_dir)
				if accuracy < 0.82:
					continue
				var approach_open := _segment_is_clear(initial, impact, PHYSICS.STRIKER_RADIUS + PHYSICS.COIN_RADIUS + 1.0, piece["id"])
				if not approach_open:
					continue
				var travel: float = initial.distance_to(target) + target.distance_to(pocket)
				var score: float = accuracy * 17.0 + (9.0 if pocket_open else -11.0) - travel * 0.006
				if piece["kind"] == "queen":
					score += 1.0 if _pocketed_count("black") > 1 else -4.5
				# A clean, shorter route is preferable to a long, speculative shot.
				if score > best_score:
					best_score = score
					var speed: float = clampf(450.0 + initial.distance_to(target) * 0.72 + target.distance_to(pocket) * 0.45, 550.0, 1300.0)
					best = {"x": x, "dir": direction, "speed": speed, "target": target}
	# If no direct pocket is available, play a controlled contact/break shot.
	if best_score < -1.0e8:
		var best_fallback := 1.0e8
		for piece in discs:
			if piece["pocketed"] or piece["kind"] != "black":
				continue
			for n in range(12):
				var x := 130.0 + float(n) * 38.0
				var initial := Vector2(x, CarromBoard.base_y(1))
				if not _can_place_striker(initial):
					continue
				var target: Vector2 = piece["pos"]
				var delta: Vector2 = target - initial
				if delta.length_squared() < 10.0:
					continue
				var clear := _segment_is_clear(initial, target - delta.normalized() * 32.0, 28.0, piece["id"])
				var score := delta.length() + (0.0 if clear else 850.0)
				if score < best_fallback:
					best_fallback = score
					best = {"x": x, "dir": delta.normalized(), "speed": 870.0, "target": target}
	# Difficulty affects mechanical precision but not physics or legal pieces.
	var drift: float = [0.085, 0.028, 0.007][cpu_skill]
	var jitter: float = randf_range(-drift, drift)
	best["dir"] = (best["dir"] as Vector2).rotated(jitter)
	best["speed"] = clampf(float(best["speed"]) * randf_range(1.0 - drift * 1.6, 1.0 + drift * 1.6), 420.0, MAX_SHOT_SPEED)
	return best

func _segment_is_clear(a: Vector2, b: Vector2, clearance: float, excluded_id: int) -> bool:
	var segment: Vector2 = b - a
	var length_sq := segment.length_squared()
	if length_sq < 0.01:
		return true
	for disc in discs:
		if disc["pocketed"] or disc["kind"] == "striker" or disc["id"] == excluded_id:
			continue
		var center: Vector2 = disc["pos"]
		var t := clampf((center - a).dot(segment) / length_sq, 0.0, 1.0)
		var nearest: Vector2 = a + segment * t
		if nearest.distance_squared_to(center) < pow(clearance + disc["radius"] * 0.15, 2):
			return false
	return true
