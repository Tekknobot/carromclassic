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
const DUBOO_MIN_SHOT_SPEED := 250.0
const DUBOO_MAX_SHOT_SPEED := 1080.0

var duboo_mode := false
var mode_bar: HBoxContainer
var classic_button: Button
var duboo_button: Button
var style_heading: Label
var style_selector: HBoxContainer
var rules_body: Label
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
var sound_pocket_alt: AudioStreamPlayer
var sound_click: AudioStreamPlayer
var sound_impact: AudioStreamPlayer
var sound_rail: AudioStreamPlayer
var impact_cooldown := 0.0
var rail_cooldown := 0.0
var title_label: Label
var board_caption: Label
var board_style_index: int = 0
var duboo_style_index: int = 0
var board_style_label: Label
var board_style_prev: Button
var board_style_next: Button
const SETTINGS_PATH := "user://carrom_board_settings.cfg"
var tip_label: Label

# A separate, portrait-only control surface. Desktop input/layout is unchanged.
var portrait_touch := false
var mobile_score_panel: PanelContainer
var mobile_match_label: Label
var mobile_score_headings: Array[Label] = []
var mobile_you: Label
var mobile_cpu: Label
var mobile_queen: Label
var mobile_status_panel: PanelContainer
var mobile_status_title: Label
var mobile_status_hint: Label
var mobile_power_panel: PanelContainer
var mobile_power_label: Label
var mobile_power_meter: ProgressBar
var mobile_fire: Button
var mobile_style_bar: HBoxContainer
var mobile_style_prev: Button
var mobile_style_next: Button
var mobile_style_name: Label
var mobile_mobile_scale := 1.0
var mobile_action_bar: HBoxContainer
var mobile_cpu_select: OptionButton
var mobile_rules: Button
var mobile_restart: Button
var mobile_next: Button
var mobile_board_finger := -1
var mobile_charge_finger := -1
var mobile_board_mouse_down := false
var mobile_mouse_charge := false
var mobile_drag_baseline := false
var mobile_aim_target := Vector2(340.0, 340.0)
var mobile_ignore_synthetic_mouse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_board_style()
	board = BOARD_SCENE.new()
	add_child(board)
	board.set_style(board_style_index)
	board.set_duboo_style(duboo_style_index)
	_build_ui()
	_build_mobile_ui()
	_refresh_mode_ui()
	_build_audio()
	_refresh_board_style_ui()
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
	# Both modes share the same event system, but each has its own materials.
	sound_shoot = AudioStreamPlayer.new()
	add_child(sound_shoot)
	sound_pocket = AudioStreamPlayer.new()
	add_child(sound_pocket)
	# Two voices let rapid multi-pockets be heard rather than silently dropped.
	sound_pocket_alt = AudioStreamPlayer.new()
	add_child(sound_pocket_alt)
	sound_click = AudioStreamPlayer.new()
	sound_click.stream = load("res://audio/tick.wav")
	sound_click.volume_db = -13.0
	add_child(sound_click)
	sound_impact = AudioStreamPlayer.new()
	add_child(sound_impact)
	sound_rail = AudioStreamPlayer.new()
	add_child(sound_rail)
	_refresh_mode_audio()

func _refresh_mode_audio() -> void:
	if sound_shoot == null or sound_pocket == null or sound_impact == null:
		return
	# Classic retains its familiar strike/drop; new wooden impacts fill the gaps.
	sound_shoot.stream = load("res://audio/duboo_strike.wav") if duboo_mode else load("res://audio/strike.wav")
	sound_pocket.stream = load("res://audio/duboo_pocket.wav") if duboo_mode else load("res://audio/pocket.wav")
	sound_pocket_alt.stream = sound_pocket.stream
	sound_impact.stream = load("res://audio/duboo_collision.wav") if duboo_mode else load("res://audio/classic_collision.wav")
	sound_rail.stream = load("res://audio/duboo_rail.wav") if duboo_mode else load("res://audio/classic_rail.wav")
	sound_shoot.volume_db = -8.5 if duboo_mode else -8.0
	sound_pocket.volume_db = -7.5 if duboo_mode else -6.0
	sound_pocket_alt.volume_db = sound_pocket.volume_db - 1.5
	sound_shoot.pitch_scale = 1.0
	sound_pocket.pitch_scale = 1.0
	sound_pocket_alt.pitch_scale = 1.0
	sound_impact.stop()
	sound_rail.stop()
	sound_pocket_alt.stop()
	impact_cooldown = 0.0
	rail_cooldown = 0.0

func _play_impact_sfx(feedback: Array, delta: float) -> void:
	# Strongest collision and rebound per short window. This avoids a wall
	# of noise when many counters bump into one another during a break.
	impact_cooldown = maxf(0.0, impact_cooldown - delta)
	rail_cooldown = maxf(0.0, rail_cooldown - delta)
	var strongest_hit := 0.0
	var strongest_rail := 0.0
	for event in feedback:
		if event.get("type", "") == "collision":
			strongest_hit = maxf(strongest_hit, float(event.get("speed", 0.0)))
		elif event.get("type", "") == "rail":
			strongest_rail = maxf(strongest_rail, float(event.get("speed", 0.0)))
	var hit_threshold := 65.0 if duboo_mode else 55.0
	var rail_threshold := 110.0 if duboo_mode else 95.0
	if strongest_hit > hit_threshold and impact_cooldown <= 0.0:
		var strength := clampf(strongest_hit / (650.0 if duboo_mode else 850.0), 0.0, 1.0)
		sound_impact.volume_db = lerpf(-18.0, -9.5, strength) if duboo_mode else lerpf(-20.0, -11.0, strength)
		sound_impact.pitch_scale = randf_range(0.94, 1.08) if duboo_mode else randf_range(0.97, 1.06)
		sound_impact.play()
		impact_cooldown = 0.082 if duboo_mode else 0.095
	if strongest_rail > rail_threshold and rail_cooldown <= 0.0:
		var strength := clampf(strongest_rail / (720.0 if duboo_mode else 880.0), 0.0, 1.0)
		sound_rail.volume_db = lerpf(-19.0, -11.0, strength) if duboo_mode else lerpf(-22.0, -12.0, strength)
		sound_rail.pitch_scale = randf_range(0.95, 1.07) if duboo_mode else randf_range(0.97, 1.05)
		sound_rail.play()
		rail_cooldown = 0.115 if duboo_mode else 0.13

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
	mode_bar = HBoxContainer.new()
	mode_bar.add_theme_constant_override("separation", 8)
	add_child(mode_bar)
	classic_button = _make_button(mode_bar, "CLASSIC")
	duboo_button = _make_button(mode_bar, "DUBOO")
	classic_button.pressed.connect(func() -> void: _set_mode(false))
	duboo_button.pressed.connect(func() -> void: _set_mode(true))
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
	# A dedicated cosmetic selector: usable during every phase of the match.
	# "NEXT" wraps from theme 8 back to the untouched original theme 1.
	style_heading = _label(content, "BOARD APPEARANCE", 11, MINT)
	var board_style_row := HBoxContainer.new()
	style_selector = board_style_row
	board_style_row.add_theme_constant_override("separation", 7)
	content.add_child(board_style_row)
	board_style_prev = _make_button(board_style_row, "PREV")
	board_style_prev.custom_minimum_size.x = 58
	board_style_prev.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	board_style_prev.pressed.connect(func() -> void: _cycle_board_style(-1))
	board_style_label = _label(board_style_row, "01 / 08   CLASSIC TOURNAMENT", 12, TEXT, true)
	board_style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_style_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board_style_label.custom_minimum_size.y = 45
	board_style_next = _make_button(board_style_row, "NEXT", true)
	board_style_next.custom_minimum_size.x = 58
	board_style_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	board_style_next.pressed.connect(func() -> void: _cycle_board_style(1))
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
	queen_dot.text = "Q"
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
	cpu_selector.item_selected.connect(func(idx: int) -> void:
		cpu_skill = idx
		if mobile_cpu_select != null:
			mobile_cpu_select.select(idx)
	)
	content.add_child(cpu_selector)
	# One concise controls reminder belongs below the board, not in the sidebar.
	var bottom_buttons := HBoxContainer.new()
	bottom_buttons.add_theme_constant_override("separation", 10)
	content.add_child(bottom_buttons)
	var rules_button := _make_button(bottom_buttons, "RULES", false)
	rules_button.pressed.connect(_open_rules)
	restart_button = _make_button(bottom_buttons, "NEW MATCH", false)
	restart_button.pressed.connect(_new_match)
	_build_rules_overlay()

func _mobile_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := _label(parent, value, font_size, color, false)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	return label

func _mobile_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var skin := _style(Color("#1d3b35"), Color("#426f60"), 11)
	skin.content_margin_left = 9.0
	skin.content_margin_right = 9.0
	skin.content_margin_top = 5.0
	skin.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override("panel", skin)
	panel.visible = false
	add_child(panel)
	return panel

func _build_mobile_ui() -> void:
	# Phone UI has its own hierarchy; no desktop sidebar is scaled onto a phone.
	mobile_match_label = _mobile_label(self, "BOARD 1 / 8", 16, GOLD)
	mobile_match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mobile_match_label.visible = false
	# Flat, separate regions: mode, score, board, status, charge, theme, actions.
	# No mobile input widgets ever sit on top of the physical board.
	mobile_score_panel = _mobile_panel()
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 3)
	mobile_score_panel.add_child(scores)
	var you_stack := VBoxContainer.new()
	you_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores.add_child(you_stack)
	mobile_score_headings.append(_mobile_label(you_stack, "YOU / WHITE", 13, MINT))
	mobile_you = _mobile_label(you_stack, "0 / 9", 18, TEXT)
	var queen_stack := VBoxContainer.new()
	queen_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores.add_child(queen_stack)
	mobile_score_headings.append(_mobile_label(queen_stack, "QUEEN", 13, Color("#f28b8b")))
	mobile_queen = _mobile_label(queen_stack, "ON BOARD", 11, TEXT)
	var cpu_stack := VBoxContainer.new()
	cpu_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores.add_child(cpu_stack)
	mobile_score_headings.append(_mobile_label(cpu_stack, "CPU / BLACK", 13, GOLD))
	mobile_cpu = _mobile_label(cpu_stack, "0 / 9", 18, TEXT)

	mobile_status_panel = _mobile_panel()
	var status_stack := VBoxContainer.new()
	status_stack.add_theme_constant_override("separation", 0)
	mobile_status_panel.add_child(status_stack)
	mobile_status_title = _mobile_label(status_stack, "YOUR BREAK", 12, MINT)
	mobile_status_hint = _mobile_label(status_stack, "SLIDE THE STRIKER ON THE BASELINE", 10, TEXT)

	mobile_power_panel = _mobile_panel()
	var power_row := HBoxContainer.new()
	power_row.add_theme_constant_override("separation", 11)
	mobile_power_panel.add_child(power_row)
	var power_stack := VBoxContainer.new()
	power_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_stack.add_theme_constant_override("separation", 7)
	power_row.add_child(power_stack)
	mobile_power_label = _mobile_label(power_stack, "POWER  0%", 15, TEXT)
	mobile_power_meter = ProgressBar.new()
	mobile_power_meter.min_value = 0.0
	mobile_power_meter.max_value = 100.0
	mobile_power_meter.show_percentage = false
	mobile_power_meter.custom_minimum_size.y = 11.0
	mobile_power_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_power_meter.add_theme_stylebox_override("background", _style(Color("#102522"), Color.TRANSPARENT, 5))
	mobile_power_meter.add_theme_stylebox_override("fill", _style(MINT, Color.TRANSPARENT, 5))
	power_stack.add_child(mobile_power_meter)
	mobile_fire = _make_button(power_row, "HOLD TO SHOOT", true)
	mobile_fire.custom_minimum_size = Vector2(145, 66)
	mobile_fire.size_flags_horizontal = Control.SIZE_SHRINK_END
	# Hit testing happens in _input: touch release outside this rectangle
	# must still release the shot, and the other finger may aim concurrently.
	mobile_fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The unavailable state must remain readable while a player places the striker.
	mobile_fire.add_theme_stylebox_override("disabled", _style(Color("#34594e"), Color("#638b7b"), 9))
	mobile_fire.add_theme_color_override("font_disabled_color", Color("#dcebe4"))

	mobile_style_bar = HBoxContainer.new()
	mobile_style_bar.add_theme_constant_override("separation", 5)
	mobile_style_bar.visible = false
	add_child(mobile_style_bar)
	mobile_style_prev = _make_button(mobile_style_bar, "PREV")
	mobile_style_prev.custom_minimum_size.x = 61
	mobile_style_prev.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mobile_style_prev.pressed.connect(func() -> void: _cycle_board_style(-1))
	mobile_style_name = _mobile_label(mobile_style_bar, "CLASSIC TOURNAMENT", 11, MINT)
	mobile_style_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_style_next = _make_button(mobile_style_bar, "NEXT")
	mobile_style_next.custom_minimum_size.x = 61
	mobile_style_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	mobile_style_next.pressed.connect(func() -> void: _cycle_board_style(1))

	mobile_action_bar = HBoxContainer.new()
	mobile_action_bar.add_theme_constant_override("separation", 5)
	mobile_action_bar.visible = false
	add_child(mobile_action_bar)
	mobile_cpu_select = OptionButton.new()
	mobile_cpu_select.add_item("CASUAL", 0)
	mobile_cpu_select.add_item("STANDARD", 1)
	mobile_cpu_select.add_item("EXPERT", 2)
	mobile_cpu_select.select(cpu_skill)
	mobile_cpu_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_cpu_select.add_theme_font_size_override("font_size", 16)
	mobile_cpu_select.add_theme_color_override("font_color", TEXT)
	mobile_cpu_select.add_theme_stylebox_override("normal", _style(PANEL_ALT, Color("#46665a"), 8))
	mobile_cpu_select.item_selected.connect(func(index: int) -> void:
		cpu_skill = index
		cpu_selector.select(index)
	)
	mobile_action_bar.add_child(mobile_cpu_select)
	mobile_rules = _make_button(mobile_action_bar, "RULES")
	mobile_rules.pressed.connect(_open_rules)
	mobile_restart = _make_button(mobile_action_bar, "RESTART")
	mobile_restart.pressed.connect(_new_match)
	mobile_next = _make_button(mobile_action_bar, "NEXT BOARD", true)
	mobile_next.pressed.connect(_next_board)
	mobile_next.visible = false

func _mobile_sync() -> void:
	if mobile_score_panel == null:
		return
	mobile_you.text = "%d / 9" % _pocketed_count("white") if duboo_mode else "%d PTS / %d" % [totals[0], _pocketed_count("white")]
	mobile_cpu.text = "%d / 9" % _pocketed_count("black") if duboo_mode else "%d PTS / %d" % [totals[1], _pocketed_count("black")]
	if pending_queen >= 0:
		mobile_queen.text = "COVER IT" if pending_queen == 0 else "CPU COVER"
	elif queen_owner >= 0:
		mobile_queen.text = "YOURS" if queen_owner == 0 else "CPU HAS IT"
	else:
		mobile_queen.text = "ON BOARD"
	mobile_status_title.text = status_title
	if phase == "placement":
		mobile_status_hint.text = "DRAG THE BASELINE TO PLACE"
	elif phase == "aim":
		mobile_status_hint.text = "DRAG TO AIM  -  HOLD SHOOT"
	elif phase == "charging":
		mobile_status_hint.text = "RELEASE TO SHOOT"
	elif phase == "moving":
		mobile_status_hint.text = "WAIT FOR PIECES TO STOP"
	elif phase in ["cpu_aim", "cpu_think"]:
		mobile_status_hint.text = "OPPONENT PLAYING"
	else:
		mobile_status_hint.text = "CONTINUE USING BUTTONS BELOW"
	mobile_power_label.text = "POWER  %d%%" % int(round(charge_power * 100.0)) if phase == "charging" else "SHOT POWER"
	mobile_power_meter.value = charge_power * 100.0 if phase == "charging" else 0.0
	mobile_fire.disabled = phase not in ["aim", "charging"] or player_turn != 0 or rules_overlay.visible
	mobile_next.visible = phase == "board_over"
	mobile_restart.visible = phase != "board_over"
	mobile_restart.text = "NEW GAME" if duboo_mode else "RESTART"
	mobile_style_name.text = CarromBoard.DUBOO_STYLE_NAMES[duboo_style_index] if duboo_mode else CarromBoard.STYLE_NAMES[board_style_index]
	mobile_match_label.text = "DUBOO / ONE BOARD" if duboo_mode else "BOARD %d / 8" % board_number
	if mobile_cpu_select.selected != cpu_skill:
		mobile_cpu_select.select(cpu_skill)

func _mobile_fire_visual(held: bool) -> void:
	if mobile_fire == null:
		return
	mobile_fire.add_theme_stylebox_override("normal", _style(GOLD if held else MINT, Color.TRANSPARENT, 9))
	mobile_fire.add_theme_color_override("font_color", INK)

func _cancel_mobile_charge() -> void:
	mobile_charge_finger = -1
	mobile_mouse_charge = false
	if phase == "charging" and player_turn == 0:
		phase = "aim"
		board.charging = false
	_mobile_fire_visual(false)

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
	rules_body = _label(v,
		"OBJECTIVE\nYou are WHITE. Pocket all nine white pieces, with the red Queen legally covered, to win the board. The CPU plays BLACK.\n\nTURNS\nWhite breaks. You keep shooting whenever you pocket at least one of your own pieces; otherwise the turn passes. Opponent pieces remain pocketed if you sink them.\n\nTHE QUEEN\nYou must pocket one of your own pieces before you can claim the Queen. Pocket the Queen and one of your own pieces in the same shot, or pocket your own piece on your very next shot to cover it. An uncovered Queen returns to the center. If you capture the Queen together with your very first piece, a further cover is required.\n\nSTRIKER FOUL\nPocketing the striker costs one of your previously pocketed pieces (or incurs one owed piece if none is available), and ends your turn.\n\nSCORING\nThe board winner scores one point for each opponent piece left on the board. The Queen adds three points if secured by the winner, or one when their pre-board match score is at least 22. First to 25 points or the leader after eight boards wins.\n\nThis is a playable standard-rules adaptation: specialist referee calls and uncommon compound fouls are simplified.",
		14, TEXT, true)
	var close := _make_button(v, "RETURN TO BOARD", true)
	close.pressed.connect(func() -> void: rules_overlay.visible = false)

func _set_mode(use_duboo: bool) -> void:
	if duboo_mode == use_duboo:
		return
	_cancel_mobile_charge()
	mobile_board_finger = -1
	duboo_mode = use_duboo
	board.duboo_mode = duboo_mode
	_refresh_mode_ui()
	_refresh_mode_audio()
	_new_match()
	if sound_click != null:
		sound_click.play()

func _refresh_mode_ui() -> void:
	if board == null or classic_button == null:
		return
	board.duboo_mode = duboo_mode
	for b in [classic_button, duboo_button]:
		var selected = (b == duboo_button) if duboo_mode else (b == classic_button)
		b.add_theme_stylebox_override("normal", _style(MINT if selected else PANEL_ALT, Color.TRANSPARENT, 9))
		b.add_theme_color_override("font_color", INK if selected else TEXT)
		b.add_theme_color_override("font_hover_color", INK if selected else TEXT)
		b.add_theme_color_override("font_pressed_color", INK if selected else TEXT)
	# Reuse the original appearance selector for both modes. No extra controls.
	style_heading.visible = true
	style_heading.text = "DUBOO TABLE" if duboo_mode else "BOARD APPEARANCE"
	style_selector.visible = true
	restart_button.text = "NEW BOARD" if duboo_mode else "NEW MATCH"
	if rules_body != null:
		if duboo_mode:
			rules_body.text = "DUBOO - KARACHI-INSPIRED\nPlay a single board on a large slate/marble-style table with smaller counters, compact markings, and an oversize open-centred acrylic ring. The ring is much larger than the pocket and cannot fall into it. The physics are gameplay approximations.\n\nPLAY\nClick the bottom baseline to position the ring. Aim, hold left mouse to charge, then release. The controls are identical to Classic.\n\nOBJECTIVE\nPocket all nine of your colour and legally secure the Queen. Pocket your colour to shoot again. CPU plays black.\n\nQUEEN AND FOULS\nQueen and cover rules follow this game's existing adaptation. A ring-pocket foul is impossible because the ring cannot fit a hole.\n\nMATCH\nA single completed board determines the winner. Select NEW BOARD to restart."
		else:
			rules_body.text = "OBJECTIVE\nYou are WHITE. Pocket all nine white pieces, with the red Queen legally covered, to win the board. The CPU plays BLACK.\n\nTURNS\nYou keep shooting whenever you pocket your color; otherwise the turn passes.\n\nTHE QUEEN\nYou must first pocket a piece of your color. Pocket the Queen and another piece in the same shot or cover it on your next shot. If not covered, she returns to the center.\n\nSTRIKER FOUL\nPocketing the striker costs one of your pocketed pieces, or creates an owed piece, and ends the turn.\n\nSCORING\nFirst to 25 points or the leader after eight boards wins. Uncommon compound fouls are simplified."
	if portrait_touch:
		rules_body.text += "\n\nPORTRAIT TOUCH CONTROLS\nDrag the striker along the lower baseline to place it. Drag anywhere on the board to aim. Hold the SHOOT button to build power, then lift your finger to strike. You can use a second finger to adjust aim while charging."
	_refresh_board_style_ui()
	_mobile_sync()
	board.queue_redraw()

func _shot_speed_min() -> float:
	return DUBOO_MIN_SHOT_SPEED if duboo_mode else MIN_SHOT_SPEED

func _shot_speed_max() -> float:
	return DUBOO_MAX_SHOT_SPEED if duboo_mode else MAX_SHOT_SPEED

func _layout() -> void:
	if board == null or side_panel == null:
		return
	var sz := size
	var should_portrait := sz.y > sz.x * 1.06
	if should_portrait != portrait_touch:
		_cancel_mobile_charge()
		mobile_board_finger = -1
		mobile_board_mouse_down = false
		portrait_touch = should_portrait
	if portrait_touch:
		_layout_portrait(sz)
		return
	for mobile_node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_style_bar, mobile_action_bar, mobile_match_label]:
		mobile_node.visible = false
	classic_button.add_theme_font_size_override("font_size", 14)
	duboo_button.add_theme_font_size_override("font_size", 14)
	side_panel.visible = true
	board_caption.visible = true
	tip_label.visible = true
	var side_w := minf(clampf(sz.x * 0.315, 332.0, 452.0), maxf(280.0, sz.x * 0.42))
	var side_x := sz.x - side_w - 20.0
	var board_w := maxf(260.0, side_x - 18.0)
	# Layout includes the FULL 766 px wooden/marble frame (-43 to 723),
	# never just the 680 px playing field. Keep a real top and bottom gutter.
	var top_guard := 145.0
	var bottom_guard := sz.y - 50.0
	var allowed_h := maxf(220.0, bottom_guard - top_guard)
	var allowed_w := maxf(230.0, board_w - 28.0)
	var scale_value := maxf(0.25, minf(1.15, minf(allowed_w / 766.0, allowed_h / 766.0)))
	board.scale = Vector2.ONE * scale_value
	var board_top := top_guard + (allowed_h - 766.0 * scale_value) * 0.5
	var board_left := (board_w - 766.0 * scale_value) * 0.5
	board.position = Vector2(board_left + 43.0 * scale_value, board_top + 43.0 * scale_value)
	side_panel.position = Vector2(side_x, 18.0)
	side_panel.size = Vector2(side_w, maxf(170.0, sz.y - 36.0))
	title_label.add_theme_font_size_override("font_size", 29)
	title_label.position = Vector2(26.0, 9.0)
	title_label.size = Vector2(board_w - 46.0, 40.0)
	board_caption.position = Vector2(27.0, 48.0)
	board_caption.size = Vector2(board_w - 45.0, 20.0)
	mode_bar.position = Vector2(27.0, 84.0)
	mode_bar.size = Vector2(minf(335.0, board_w - 46.0), 43.0)
	classic_button.custom_minimum_size = Vector2(0, 41)
	duboo_button.custom_minimum_size = Vector2(0, 41)
	tip_label.position = Vector2(27.0, sz.y - 35.0)
	tip_label.size = Vector2(board_w - 45.0, 29.0)
	var dialog_size := Vector2(minf(640.0, sz.x - 65.0), minf(740.0, sz.y - 42.0))
	rules_overlay.position = (sz - dialog_size) * 0.5
	rules_overlay.size = dialog_size

func _layout_portrait(sz: Vector2) -> void:
	# Use screen WIDTH first: portrait phones deserve a full-width board.
	# UI dimensions and fonts share a density factor so the browser cannot
	# shrink 10px labels into unreadable text on high-resolution displays.
	side_panel.visible = false
	board_caption.visible = false
	tip_label.visible = false
	for mobile_node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_style_bar, mobile_action_bar, mobile_match_label]:
		mobile_node.visible = true
	var u := clampf(minf(sz.x / 430.0, sz.y / 780.0), 0.72, 2.5)
	mobile_mobile_scale = u
	var gutter := 7.0 * u
	# Clear the camera cutout, rounded phone corners, and the browser top edge.
	var safe_top := 28.0 * u
	var title_h := 29.0 * u
	var mode_h := 48.0 * u
	var scores_h := 64.0 * u
	var status_h := 52.0 * u
	var power_h := 78.0 * u
	var theme_h := 50.0 * u
	var actions_h := 54.0 * u
	var lower_gap := 6.0 * u
	var min_bottom := 12.0 * u
	# Unambiguous top-to-bottom order, each element within its own rectangle.
	var y := safe_top
	title_label.position = Vector2(gutter + 2.0 * u, y)
	title_label.size = Vector2(sz.x * 0.48, title_h)
	title_label.add_theme_font_size_override("font_size", maxi(22, int(round(29.0 * u))))
	mobile_match_label.position = Vector2(sz.x * 0.53, y + 1.0 * u)
	mobile_match_label.size = Vector2(sz.x * 0.45 - gutter, title_h)
	mobile_match_label.add_theme_font_size_override("font_size", maxi(12, int(round(16.0 * u))))
	y += title_h + 4.0 * u
	mode_bar.position = Vector2(gutter, y)
	mode_bar.size = Vector2(sz.x - gutter * 2.0, mode_h)
	classic_button.custom_minimum_size.y = mode_h
	duboo_button.custom_minimum_size.y = mode_h
	classic_button.add_theme_font_size_override("font_size", maxi(17, int(round(19.0 * u))))
	duboo_button.add_theme_font_size_override("font_size", maxi(17, int(round(19.0 * u))))
	y += mode_h + lower_gap
	mobile_score_panel.position = Vector2(gutter, y)
	mobile_score_panel.size = Vector2(sz.x - gutter * 2.0, scores_h)
	for heading in mobile_score_headings:
		heading.add_theme_font_size_override("font_size", maxi(13, int(round(15.0 * u))))
	mobile_you.add_theme_font_size_override("font_size", maxi(20, int(round(25.0 * u))))
	mobile_cpu.add_theme_font_size_override("font_size", maxi(20, int(round(25.0 * u))))
	mobile_queen.add_theme_font_size_override("font_size", maxi(14, int(round(17.0 * u))))
	y += scores_h + lower_gap
	# Keep the wooden/marble frame inside its own board rectangle.
	# Only reduce board width on unusually short screens where controls would
	# otherwise fall below the viewport; never shrink it to reserve empty space.
	var controls_after := status_h + power_h + theme_h + actions_h + lower_gap * 4.0 + min_bottom
	var board_width := minf(sz.x - 2.0 * gutter, sz.y - y - controls_after)
	board_width = maxf(200.0 * u, board_width)
	var scale_value := board_width / 766.0
	var board_left := (sz.x - board_width) * 0.5
	board.scale = Vector2.ONE * scale_value
	board.position = Vector2(board_left + 43.0 * scale_value, y + 43.0 * scale_value)
	y += board_width + lower_gap
	mobile_status_panel.position = Vector2(gutter, y)
	mobile_status_panel.size = Vector2(sz.x - gutter * 2.0, status_h)
	mobile_status_title.add_theme_font_size_override("font_size", maxi(16, int(round(19.0 * u))))
	mobile_status_hint.add_theme_font_size_override("font_size", maxi(13, int(round(16.0 * u))))
	y += status_h + lower_gap
	mobile_power_panel.position = Vector2(gutter, y)
	mobile_power_panel.size = Vector2(sz.x - gutter * 2.0, power_h)
	mobile_power_label.add_theme_font_size_override("font_size", maxi(17, int(round(19.0 * u))))
	mobile_power_meter.custom_minimum_size.y = 14.0 * u
	mobile_fire.custom_minimum_size = Vector2(157.0 * u, power_h - 10.0 * u)
	mobile_fire.add_theme_font_size_override("font_size", maxi(17, int(round(19.0 * u))))
	y += power_h + lower_gap
	mobile_style_bar.position = Vector2(gutter, y)
	mobile_style_bar.size = Vector2(sz.x - gutter * 2.0, theme_h)
	mobile_style_prev.custom_minimum_size = Vector2(72.0 * u, theme_h)
	mobile_style_next.custom_minimum_size = Vector2(72.0 * u, theme_h)
	mobile_style_prev.add_theme_font_size_override("font_size", maxi(15, int(round(17.0 * u))))
	mobile_style_next.add_theme_font_size_override("font_size", maxi(15, int(round(17.0 * u))))
	mobile_style_name.add_theme_font_size_override("font_size", maxi(14, int(round(16.0 * u))))
	y += theme_h + lower_gap
	mobile_action_bar.position = Vector2(gutter, y)
	mobile_action_bar.size = Vector2(sz.x - gutter * 2.0, actions_h)
	mobile_cpu_select.custom_minimum_size = Vector2(125.0 * u, actions_h)
	mobile_cpu_select.add_theme_font_size_override("font_size", maxi(14, int(round(16.0 * u))))
	for b in [mobile_rules, mobile_restart, mobile_next]:
		b.custom_minimum_size.y = actions_h
		b.add_theme_font_size_override("font_size", maxi(14, int(round(16.0 * u))))
	# Readable modal typography on touch as well.
	var dialog_size := Vector2(sz.x - gutter * 2.0, minf(sz.y - safe_top - min_bottom, 740.0 * u))
	rules_overlay.position = Vector2((sz.x - dialog_size.x) * 0.5, safe_top)
	rules_overlay.size = dialog_size
	rules_body.add_theme_font_size_override("font_size", maxi(16, int(round(18.0 * u))))
	if rules_body != null and not rules_body.text.contains("PORTRAIT TOUCH CONTROLS"):
		rules_body.text += "\n\nPORTRAIT TOUCH CONTROLS\nDrag along the lower baseline to place the striker. Drag elsewhere on the board to aim. Hold SHOOT to charge and release to fire. You can aim with another finger while charging."
	_mobile_sync()

func _load_board_style() -> void:
	var config := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH) and config.load(SETTINGS_PATH) == OK:
		board_style_index = clampi(int(config.get_value("appearance", "board_style", 0)), 0, CarromBoard.STYLE_NAMES.size() - 1)
		duboo_style_index = clampi(int(config.get_value("appearance", "duboo_table_style", 0)), 0, CarromBoard.DUBOO_STYLE_NAMES.size() - 1)

func _save_board_style() -> void:
	var config := ConfigFile.new()
	# Read first so previously saved settings survive this single-field update.
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	config.set_value("appearance", "board_style", board_style_index)
	config.set_value("appearance", "duboo_table_style", duboo_style_index)
	config.save(SETTINGS_PATH)

func _refresh_board_style_ui() -> void:
	if duboo_mode:
		var name := str(CarromBoard.DUBOO_STYLE_NAMES[duboo_style_index])
		if board_style_label != null:
			board_style_label.text = "%02d / %02d\n%s" % [duboo_style_index + 1, CarromBoard.DUBOO_STYLE_NAMES.size(), name]
		if board_caption != null:
			board_caption.text = "DUBOO  /  %s  /  MARBLE TABLE" % name
	else:
		if board_style_label != null:
			board_style_label.text = "%02d / %02d\n%s" % [board_style_index + 1, CarromBoard.STYLE_NAMES.size(), CarromBoard.STYLE_NAMES[board_style_index]]
		if board_caption != null:
			board_caption.text = "STYLE %02d / 08  /  %s" % [board_style_index + 1, CarromBoard.STYLE_NAMES[board_style_index]]

func _cycle_board_style(step: int) -> void:
	if duboo_mode:
		duboo_style_index = posmod(duboo_style_index + step, CarromBoard.DUBOO_STYLE_NAMES.size())
		board.set_duboo_style(duboo_style_index)
	else:
		board_style_index = posmod(board_style_index + step, CarromBoard.STYLE_NAMES.size())
		board.set_style(board_style_index)
	_refresh_board_style_ui()
	_mobile_sync()
	_save_board_style()
	if sound_click != null:
		sound_click.play()

func _new_match() -> void:
	_cancel_mobile_charge()
	mobile_board_finger = -1
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
		var radius := (19.0 if ring == 0 else 37.8) if duboo_mode else (29.0 if ring == 0 else 57.0)
		for k in range(count):
			var angle := -PI / 2.0 + float(k) * TAU / float(count)
			var kind := "white" if k % 2 == 0 else "black"
			_add_disc(kind, Vector2(340, 340) + Vector2.from_angle(angle) * radius, index)
			index += 1
	_add_disc("striker", Vector2(340, CarromBoard.base_y(0, duboo_mode)), 100)
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
	mobile_aim_target = _get_striker()["pos"] + Vector2.UP * 240.0
	cpu_time = 0.75
	if player_turn == 0:
		_set_status("YOUR BREAK" if board_number == 1 else "YOUR TURN", "Move onto the bottom baseline and click to place your striker.")
	else:
		_set_status("CPU BREAK", "The computer is looking for its opening shot.")
	_refresh_ui()
	board.queue_redraw()

func _add_disc(kind: String, at: Vector2, id_number: int) -> void:
	discs.append({"id": id_number, "kind": kind, "pos": at, "vel": Vector2.ZERO, "radius": PHYSICS.radius_for(kind, duboo_mode), "mass": PHYSICS.coin_mass(kind, duboo_mode), "pocketed": false})

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
	_mobile_sync()

func _refresh_ui() -> void:
	main_score_white.text = str(_pocketed_count("white")) if duboo_mode else str(totals[0])
	main_score_black.text = str(_pocketed_count("black")) if duboo_mode else str(totals[1])
	coins_white.text = "OF 9 POCKETED" if duboo_mode else "%d / 9 pocketed" % _pocketed_count("white")
	coins_black.text = "OF 9 POCKETED" if duboo_mode else "%d / 9 pocketed" % _pocketed_count("black")
	match_info.text = "DUBOO   /   ONE BOARD" if duboo_mode else ("BOARD %d OF %d    |    FIRST TO %d" % [board_number, MAX_BOARD_COUNT, MATCH_TARGET])
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
	_mobile_sync()

func _screen_to_board() -> Vector2:
	return board.to_local(get_global_mouse_position())

func _valid_baseline_click(point: Vector2) -> bool:
	return point.x >= 100.0 and point.x <= 580.0 and absf(point.y - CarromBoard.base_y(0, duboo_mode)) < (32.0 if duboo_mode else 40.0)

func _place_striker(player: int, desired_x: float) -> bool:
	var striker := _get_striker()
	var y := CarromBoard.base_y(player, duboo_mode)
	var x := clampf(desired_x, 111.0 if duboo_mode else 125.0, 569.0 if duboo_mode else 555.0)
	var candidates: Array[float] = [x]
	for i in range(1, 53):
		candidates.append(clampf(x + float(i) * 7.5, 111.0 if duboo_mode else 125.0, 569.0 if duboo_mode else 555.0))
		candidates.append(clampf(x - float(i) * 7.5, 111.0 if duboo_mode else 125.0, 569.0 if duboo_mode else 555.0))
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
		if point.distance_squared_to(other["pos"]) < pow(PHYSICS.radius_for("striker", duboo_mode) + other["radius"] + 2.5, 2):
			return false
	return true

func _mobile_board_point(global_point: Vector2) -> Vector2:
	return board.to_local(global_point)

func _mobile_is_baseline(point: Vector2) -> bool:
	return point.x >= 90.0 and point.x <= 590.0 and absf(point.y - CarromBoard.base_y(0, duboo_mode)) < 66.0

func _mobile_is_board(point: Vector2) -> bool:
	return Rect2(-6.0, -6.0, 692.0, 692.0).has_point(point)

func _mobile_start_board_drag(screen_point: Vector2) -> bool:
	if player_turn != 0 or phase not in ["placement", "aim", "charging"]:
		return false
	var local := _mobile_board_point(screen_point)
	if not _mobile_is_board(local):
		return false
	mobile_drag_baseline = _mobile_is_baseline(local) and phase != "charging"
	if phase == "placement" and not mobile_drag_baseline:
		# First place the striker at the visible baseline before aiming.
		return false
	_mobile_update_board_drag(screen_point)
	return true

func _mobile_update_board_drag(screen_point: Vector2) -> void:
	if player_turn != 0 or phase not in ["placement", "aim", "charging"]:
		return
	var local := _mobile_board_point(screen_point)
	if mobile_drag_baseline:
		if _place_striker(0, local.x):
			if phase == "placement":
				phase = "aim"
				board.show_aim = true
				board.side = 0
				mobile_aim_target = _get_striker()["pos"] + Vector2.UP * 220.0
				sound_click.play()
				_set_status("AIM YOUR SHOT", "Drag on the board to aim. Hold SHOOT and release to fire.")
		else:
			_set_status("BASELINE BLOCKED", "Try another point on the lower baseline.")
	else:
		mobile_aim_target = local
		var diff: Vector2 = mobile_aim_target - _get_striker()["pos"]
		if diff.length_squared() > 18.0 * 18.0:
			aim_direction = diff.normalized()
			board.aim_direction = aim_direction
			board.queue_redraw()

func _mobile_start_charge() -> void:
	if player_turn != 0 or phase != "aim" or rules_overlay.visible:
		return
	phase = "charging"
	charge_time = 0.0
	charge_power = 0.20
	board.charging = true
	_mobile_fire_visual(true)
	_mobile_sync()

func _mobile_release_charge() -> void:
	if phase == "charging" and player_turn == 0 and not rules_overlay.visible:
		_mobile_fire_visual(false)
		_shoot(aim_direction, charge_power)
	else:
		_mobile_fire_visual(false)

func _mobile_handle_touch(event: InputEventScreenTouch) -> void:
	mobile_ignore_synthetic_mouse = 0.65
	if event.pressed:
		if rules_overlay.visible:
			return
		if mobile_charge_finger < 0 and mobile_fire.get_global_rect().has_point(event.position):
			if phase == "aim" and player_turn == 0:
				mobile_charge_finger = event.index
				_mobile_start_charge()
				get_viewport().set_input_as_handled()
			return
		if mobile_board_finger < 0 and _mobile_start_board_drag(event.position):
			mobile_board_finger = event.index
			get_viewport().set_input_as_handled()
	else:
		if event.index == mobile_charge_finger:
			mobile_charge_finger = -1
			_mobile_release_charge()
			get_viewport().set_input_as_handled()
		elif event.index == mobile_board_finger:
			mobile_board_finger = -1
			get_viewport().set_input_as_handled()

func _mobile_handle_mouse(event: InputEvent) -> void:
	# Allows portrait testing with a real mouse in an editor/browser, but
	# ignores the synthetic mouse events emitted by a physical touchscreen.
	if mobile_ignore_synthetic_mouse > 0.0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if rules_overlay.visible:
				return
			if mobile_fire.get_global_rect().has_point(event.position):
				if phase == "aim":
					mobile_mouse_charge = true
					_mobile_start_charge()
					get_viewport().set_input_as_handled()
			elif _mobile_start_board_drag(event.position):
				mobile_board_mouse_down = true
				get_viewport().set_input_as_handled()
		else:
			if mobile_mouse_charge:
				mobile_mouse_charge = false
				_mobile_release_charge()
				get_viewport().set_input_as_handled()
			elif mobile_board_mouse_down:
				mobile_board_mouse_down = false
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mobile_board_mouse_down:
		_mobile_update_board_drag(event.position)
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not portrait_touch:
		return
	if event is InputEventScreenTouch:
		_mobile_handle_touch(event)
	elif event is InputEventScreenDrag:
		mobile_ignore_synthetic_mouse = 0.65
		if event.index == mobile_board_finger:
			_mobile_update_board_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		_mobile_handle_mouse(event)

func _unhandled_input(event: InputEvent) -> void:
	if portrait_touch:
		return
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
	mobile_ignore_synthetic_mouse = maxf(0.0, mobile_ignore_synthetic_mouse - delta)
	if rules_overlay != null and rules_overlay.visible:
		return
	if phase == "aim" or phase == "charging":
		var mouse := mobile_aim_target if portrait_touch else _screen_to_board()
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
			if portrait_touch:
				mobile_power_label.text = "POWER  %d%%" % int(round(charge_power * 100.0))
				mobile_power_meter.value = charge_power * 100.0
		board.aim_power = charge_power
		board.queue_redraw()
	elif phase == "placement" and not portrait_touch:
		var mouse := _screen_to_board()
		if _valid_baseline_click(mouse):
			_place_striker(0, mouse.x)
	elif phase == "cpu_think":
		cpu_time -= delta
		if cpu_time <= 0.0:
			cpu_queued_shot = _choose_cpu_shot()
			_place_striker(1, cpu_queued_shot["x"])
			board.aim_direction = cpu_queued_shot["dir"]
			board.aim_power = inverse_lerp(_shot_speed_min(), _shot_speed_max(), cpu_queued_shot["speed"])
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
			_shoot(cpu_queued_shot["dir"], inverse_lerp(_shot_speed_min(), _shot_speed_max(), cpu_queued_shot["speed"]))

func _shoot(direction: Vector2, power: float) -> void:
	if direction.length_squared() < 0.5:
		return
	phase = "moving"
	mobile_charge_finger = -1
	mobile_mouse_charge = false
	_mobile_fire_visual(false)
	var striker := _get_striker()
	striker["vel"] = direction.normalized() * lerpf(_shot_speed_min(), _shot_speed_max(), clampf(power, 0.0, 1.0))
	striker["pocketed"] = false
	own_count_before = _pocketed_count(_kind_for(player_turn))
	shot_duration = 0.0
	last_shot_pockets.clear()
	impact_cooldown = 0.05
	rail_cooldown = 0.04
	board.display_striker = false
	board.show_aim = false
	board.show_cpu_target = false
	board.charging = false
	sound_shoot.pitch_scale = randf_range(0.98, 1.035) if duboo_mode else randf_range(0.98, 1.025)
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
	# Four small substeps stabilize grazing impacts on the faster marble table.
	var substeps := 4 if duboo_mode else 2
	var feedback: Array = []
	for _substep in range(substeps):
		var fallen: Array[int] = PHYSICS.advance(discs, delta / float(substeps), duboo_mode, feedback)
		for piece_id in fallen:
			last_shot_pockets.append(piece_id)
			var pocket_voice: AudioStreamPlayer = sound_pocket if not sound_pocket.playing else sound_pocket_alt
			if not pocket_voice.playing:
				pocket_voice.pitch_scale = randf_range(0.94, 1.04) if duboo_mode else randf_range(0.97, 1.035)
				pocket_voice.play()
	_play_impact_sfx(feedback, delta)
	board.queue_redraw()
	if (shot_duration > 0.35 and PHYSICS.is_still(discs)) or shot_duration >= (18.0 if duboo_mode else 12.0):
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
		mobile_board_finger = -1
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
	if duboo_mode:
		phase = "match_over"
		board.display_striker = false
		board.show_aim = false
		_set_status("YOU WIN DUBOO!" if board_winner == 0 else "CPU WINS DUBOO", reason + "  Select NEW BOARD to play again.")
		_refresh_ui()
		board.queue_redraw()
		return
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
	_cancel_mobile_charge()
	rules_overlay.visible = true
	rules_overlay.move_to_front()
	sound_click.play()

# The CPU searches for feasible contact points that send one of its discs
# toward a pocket. It tests baseline positions, collision normals, clear
# approach lines, and target-to-pocket obstruction. This uses the same
# physics and power range as the human (it does not teleport pieces).
func _choose_cpu_shot() -> Dictionary:
	var best_score := -1.0e10
	var best := {"x": 340.0, "dir": Vector2.DOWN, "speed": 850.0 if duboo_mode else 1000.0, "target": Vector2(340, 340)}
	var pockets: Array[Vector2] = PHYSICS.POCKETS
	for piece in discs:
		if piece["pocketed"]:
			continue
		if piece["kind"] != "black" and not (piece["kind"] == "queen" and queen_owner == -1 and pending_queen == -1 and _pocketed_count("black") > 0):
			continue
		var target: Vector2 = piece["pos"]
		for pocket in pockets:
			var exit_dir: Vector2 = (pocket - target).normalized()
			var ghost: Vector2 = target - exit_dir * (PHYSICS.radius_for("striker", duboo_mode) + piece["radius"] + 0.7)
			var pocket_open := _segment_is_clear(target, pocket, piece["radius"] * 1.9, piece["id"])
			for n in range(16):
				var x := (114.0 + float(n) * 30.0) if duboo_mode else (127.0 + float(n) * 28.3)
				var initial := Vector2(x, CarromBoard.base_y(1, duboo_mode))
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
				var contact_radius: float = PHYSICS.radius_for("striker", duboo_mode) + piece["radius"]
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
				var approach_open := _segment_is_clear(initial, impact, PHYSICS.radius_for("striker", duboo_mode) + PHYSICS.radius_for("white", duboo_mode) + 1.0, piece["id"])
				if not approach_open:
					continue
				var travel: float = initial.distance_to(target) + target.distance_to(pocket)
				var score: float = accuracy * 17.0 + (9.0 if pocket_open else -11.0) - travel * 0.006
				if piece["kind"] == "queen":
					score += 1.0 if _pocketed_count("black") > 1 else -4.5
				# A clean, shorter route is preferable to a long, speculative shot.
				if score > best_score:
					best_score = score
					var speed: float = clampf(350.0 + initial.distance_to(target) * 0.45 + target.distance_to(pocket) * 0.28, 430.0, 990.0) if duboo_mode else clampf(450.0 + initial.distance_to(target) * 0.72 + target.distance_to(pocket) * 0.45, 550.0, 1300.0)
					best = {"x": x, "dir": direction, "speed": speed, "target": target}
	# If no direct pocket is available, play a controlled contact/break shot.
	if best_score < -1.0e8:
		var best_fallback := 1.0e8
		for piece in discs:
			if piece["pocketed"] or piece["kind"] != "black":
				continue
			for n in range(12):
				var x := (112.0 + float(n) * 41.0) if duboo_mode else (130.0 + float(n) * 38.0)
				var initial := Vector2(x, CarromBoard.base_y(1, duboo_mode))
				if not _can_place_striker(initial):
					continue
				var target: Vector2 = piece["pos"]
				var delta: Vector2 = target - initial
				if delta.length_squared() < 10.0:
					continue
				var clear := _segment_is_clear(initial, target - delta.normalized() * 32.0, PHYSICS.radius_for("striker", duboo_mode) + 2.0, piece["id"])
				var score := delta.length() + (0.0 if clear else 850.0)
				if score < best_fallback:
					best_fallback = score
					best = {"x": x, "dir": delta.normalized(), "speed": 690.0 if duboo_mode else 870.0, "target": target}
	# Difficulty affects mechanical precision but not physics or legal pieces.
	var drift: float = [0.085, 0.028, 0.007][cpu_skill]
	var jitter: float = randf_range(-drift, drift)
	best["dir"] = (best["dir"] as Vector2).rotated(jitter)
	best["speed"] = clampf(float(best["speed"]) * randf_range(1.0 - drift * 1.6, 1.0 + drift * 1.6), 330.0 if duboo_mode else 420.0, _shot_speed_max())
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
