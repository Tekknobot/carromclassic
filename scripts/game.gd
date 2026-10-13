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
# Unified trim: bright enough to define controls without distracting from play.
const EDGE := Color("#55786b")
const EDGE_SOFT := Color("#3b6055")
const PANEL_LIFT := Color("#24443c")
const MOBILE_DIFFICULTY_ARROW := preload("res://assets/difficulty_arrow_mobile.png")
const DESKTOP_DIFFICULTY_ARROW := preload("res://assets/difficulty_arrow_desktop.png")
const MOBILE_MENU_BUTTON := preload("res://scripts/mobile_menu_icon.gd")
const MAX_BOARD_COUNT := 8
const MATCH_TARGET := 25
const MIN_SHOT_SPEED := 320.0
const MAX_SHOT_SPEED := 1425.0
const DUBOO_MIN_SHOT_SPEED := 250.0
const DUBOO_MAX_SHOT_SPEED := 1080.0
# Desktop stats dock width is independent of labels, scores, and window changes.
const DESKTOP_STATS_WIDTH := 244.0

var duboo_mode := false
var mode_bar: HBoxContainer
var classic_button: Button
var duboo_button: Button
var desktop_classic_button: Button
var desktop_duboo_button: Button
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
# Per-turn incremental physics search. Each difficulty gets its own budget.
var cpu_plan_candidates: Array[Dictionary] = []
var cpu_plan_ranked: Array[Dictionary] = []
var cpu_plan_cursor := 0
var cpu_plan_active := false
var cpu_plan_base_value := 0.0
var winner := -1
var board_finished_message := ""
var status_title := "YOUR BREAK"
var status_text := "Move over the bottom baseline and click to place your striker."
var side_panel: Panel
var stats_panel: Panel
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
var rules_close_button: Button
var rules_footer_button: Button
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
# Mobile-only, top-right hamburger and an uncluttered settings sheet.
var mobile_menu_button: Button
var mobile_menu_scrim: ColorRect
var mobile_menu_panel: PanelContainer
var mobile_menu_open := false
var mobile_menu_style_name: Label
var mobile_menu_style_count: Label
var mobile_menu_prev: Button
var mobile_menu_next_style: Button
var mobile_menu_difficulties: Array[Button] = []
var mobile_menu_rules: Button
var mobile_menu_restart: Button
var mobile_menu_next_board: Button
var mobile_mobile_scale := 1.0
var mobile_board_finger := -1
var mobile_board_mouse_down := false
var mobile_drag_baseline := false
var mobile_aim_target := Vector2(340.0, 340.0)
# The phone uses a captured drag gesture, not a timed hold. Pull backward on
# the pad to choose direction and power; lift the SAME finger to shoot.
var mobile_pull_finger := -1
var mobile_pull_mouse := false
var mobile_pull_origin := Vector2.ZERO
var mobile_pull_length := 0.0
var mobile_pull_idle := 0.0
var mobile_locked_shot_direction := Vector2.UP
var mobile_ignore_synthetic_mouse := 0.0
const MOBILE_PULL_THRESHOLD := 16.0
const MOBILE_PULL_MAX := 155.0

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
	get_window().focus_exited.connect(_cancel_mobile_charge)
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

func _apply_button_skin(b: Button, highlight: bool = false) -> void:
	var normal_bg := MINT if highlight else PANEL_ALT
	var normal_edge := Color("#a3eee0") if highlight else EDGE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var bg: Color = normal_bg
		var edge: Color = normal_edge
		if state == "hover":
			bg = Color("#9be9d5") if highlight else Color("#2c5046")
			edge = Color("#c9fff0") if highlight else Color("#79af9e")
		elif state == "pressed":
			bg = Color("#5cc2ab") if highlight else Color("#15302a")
		elif state == "disabled":
			bg = Color("#34534b")
			edge = EDGE_SOFT
		var skin := _style(bg, edge, 11)
		skin.content_margin_left = 13.0
		skin.content_margin_right = 13.0
		skin.content_margin_top = 9.0
		skin.content_margin_bottom = 9.0
		b.add_theme_stylebox_override(state, skin)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := INK if highlight else TEXT
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", Color("#c5d8ce"))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _mobile_button_skin(b: Button, highlight: bool, u: float) -> void:
	_apply_button_skin(b, highlight)
	# Touch control padding is deliberately more generous than desktop.
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := b.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		skin.set_corner_radius_all(maxi(10, int(round(12.0 * u))))
		skin.content_margin_left = 12.0 * u
		skin.content_margin_right = 12.0 * u
		skin.content_margin_top = 8.0 * u
		skin.content_margin_bottom = 8.0 * u
		b.add_theme_stylebox_override(state, skin)

func _make_button(parent: Node, title: String, highlight: bool = false) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 44.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 15)
	_apply_button_skin(b, highlight)
	parent.add_child(b)
	return b

# Style the closed OptionButton AND its actual PopupMenu: the popup is a
# separate window and does not automatically inherit the button's typography.
func _style_cpu_option(opt: OptionButton, portrait: bool, u: float = 1.0, popup_width: int = 0) -> void:
	var type_size := maxi(16, int(round((17.0 if portrait else 15.0) * u)))
	opt.add_theme_font_size_override("font_size", type_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		opt.add_theme_color_override(state, TEXT)
	for state in ["normal", "hover", "pressed"]:
		var fill: Color = PANEL_ALT
		var trim: Color = EDGE
		if state == "hover":
			fill = Color("#305349")
			trim = Color("#7cbaaa")
		elif state == "pressed":
			fill = Color("#19362f")
			trim = MINT
		var skin := _style(fill, trim, 11)
		skin.content_margin_left = 15.0 * u
		skin.content_margin_right = 9.0 * u
		skin.content_margin_top = 9.0 * u
		skin.content_margin_bottom = 9.0 * u
		opt.add_theme_stylebox_override(state, skin)
	opt.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# An oversized custom chevron replaces the almost invisible default arrow.
	opt.add_theme_icon_override("arrow", MOBILE_DIFFICULTY_ARROW if portrait else DESKTOP_DIFFICULTY_ARROW)
	opt.add_theme_constant_override("arrow_margin", maxi(8, int(round(9.0 * u))))
	opt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var menu := opt.get_popup()
	menu.add_theme_font_size_override("font_size", type_size)
	menu.add_theme_color_override("font_color", TEXT)
	menu.add_theme_color_override("font_hover_color", INK)
	menu.add_theme_color_override("font_disabled_color", MUTED)
	menu.add_theme_stylebox_override("panel", _style(Color("#1c3832"), Color("#668e80"), 10))
	menu.add_theme_stylebox_override("hover", _style(MINT, Color("#a8efdc"), 6))
	menu.add_theme_constant_override("v_separation", maxi(9, int(round((22.0 if portrait else 12.0) * u))))
	menu.add_theme_constant_override("h_separation", maxi(10, int(round(16.0 * u))))
	menu.add_theme_constant_override("item_start_padding", maxi(11, int(round(15.0 * u))))
	menu.add_theme_constant_override("item_end_padding", maxi(11, int(round(15.0 * u))))
	if popup_width > 0:
		menu.min_size = Vector2i(popup_width, 0)

func _sidebar_panel() -> VBoxContainer:
	# Panel (not PanelContainer) has no content-driven minimum width.
	# Its exact width is assigned only by _layout(), so even arbitrarily long
	# CPU status text can NEVER widen it or push over the board.
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _style(PANEL, EDGE_SOFT, 14))
	panel.clip_contents = true
	add_child(panel)
	# An anchored content region follows the panel's bounds but cannot resize
	# the panel. This also preserves scrolling on short browser windows.
	var margin := MarginContainer.new()
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	var scroll := ScrollContainer.new()
	# Keep any unexpectedly long strings inside the clipped dock rather than
	# allowing the ScrollContainer's child minimum width to alter its parent.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 11)
	scroll.add_child(content)
	# The owner references are established here so the content builder
	# can use the same factory for both independent docks.
	if stats_panel == null:
		stats_panel = panel
	else:
		side_panel = panel
	return content

func _sidebar_rule(parent: Node) -> void:
	var rule := HSeparator.new()
	rule.add_theme_color_override("color", EDGE_SOFT)
	parent.add_child(rule)

func _stat_row(parent: Node, heading: String, accent: Color) -> Array[Label]:
	# A compact horizontal score row remains legible in a narrow left dock.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(PANEL_ALT, EDGE_SOFT, 11))
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	card.add_child(row)
	var meta := VBoxContainer.new()
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_theme_constant_override("separation", 3)
	row.add_child(meta)
	_label(meta, heading, 11, accent)
	var coins := _label(meta, "0 / 9 pocketed", 11, MUTED)
	var score := _label(row, "0", 29, TEXT)
	score.size_flags_horizontal = Control.SIZE_SHRINK_END
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return [score, coins]

func _build_ui() -> void:
	# Portrait keeps its familiar header and own mobile menu. These two
	# new docks are only displayed on landscape / desktop viewports.
	title_label = _label(self, "CARROM", 29, TEXT)
	mode_bar = HBoxContainer.new()
	mode_bar.add_theme_constant_override("separation", 8)
	add_child(mode_bar)
	classic_button = _make_button(mode_bar, "CLASSIC")
	duboo_button = _make_button(mode_bar, "DUBOO")
	classic_button.pressed.connect(func() -> void: _set_mode(false))
	duboo_button.pressed.connect(func() -> void: _set_mode(true))

	# LEFT: Read-only live match information and feedback. No appearance
	# or game-mode actions compete visually with the current score.
	var stats := _sidebar_panel()
	_label(stats, "GAME STATS", 12, MINT)
	_sidebar_rule(stats)
	_label(stats, "THE MATCH", 11, MUTED)
	match_info = _label(stats, "BOARD 1 OF 8  /  FIRST TO 25", 14, TEXT, true)
	match_info.custom_minimum_size.y = 38
	var scoreboard := VBoxContainer.new()
	scoreboard.add_theme_constant_override("separation", 8)
	stats.add_child(scoreboard)
	var white_card := _stat_row(scoreboard, "YOU / WHITE", MINT)
	main_score_white = white_card[0]
	coins_white = white_card[1]
	var black_card := _stat_row(scoreboard, "CPU / BLACK", GOLD)
	main_score_black = black_card[0]
	coins_black = black_card[1]
	var queens := PanelContainer.new()
	queens.add_theme_stylebox_override("panel", _style(PANEL_ALT, EDGE_SOFT, 11))
	stats.add_child(queens)
	var queen_row := HBoxContainer.new()
	queen_row.add_theme_constant_override("separation", 3)
	queens.add_child(queen_row)
	var queen_dot := Label.new()
	queen_dot.text = "Q"
	queen_dot.add_theme_font_size_override("font_size", 20)
	queen_dot.add_theme_color_override("font_color", Color("#e45f62"))
	queen_row.add_child(queen_dot)
	queen_text = _label(queen_row, "QUEEN / ON THE BOARD", 11, TEXT, true)
	queen_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sidebar_rule(stats)
	_label(stats, "CURRENT TURN", 11, MUTED)
	var turn_card := PanelContainer.new()
	turn_card.add_theme_stylebox_override("panel", _style(Color("#25483f"), EDGE, 11))
	stats.add_child(turn_card)
	var turn_stack := VBoxContainer.new()
	turn_stack.add_theme_constant_override("separation", 6)
	turn_card.add_child(turn_stack)
	turn_head = _label(turn_stack, "YOUR BREAK", 17, MINT, true)
	turn_head.clip_text = true
	turn_desc = _label(turn_stack, "Click the bottom baseline to place.", 12, TEXT, true)
	turn_desc.custom_minimum_size.y = 56
	var power_box := VBoxContainer.new()
	power_box.add_theme_constant_override("separation", 6)
	stats.add_child(power_box)
	power_label = _label(power_box, "SHOT POWER", 11, MUTED, true)
	power_meter = ProgressBar.new()
	power_meter.show_percentage = false
	power_meter.min_value = 0
	power_meter.max_value = 100
	power_meter.custom_minimum_size.y = 10
	power_meter.add_theme_stylebox_override("background", _style(Color("#0e2623"), Color.TRANSPARENT, 6))
	power_meter.add_theme_stylebox_override("fill", _style(MINT, Color.TRANSPARENT, 6))
	power_box.add_child(power_meter)
	next_button = _make_button(stats, "NEXT BOARD", true)
	next_button.pressed.connect(_next_board)
	next_button.visible = false

	# RIGHT: Identity, game mode and all adjustable information/actions.
	var info := _sidebar_panel()
	var identity := VBoxContainer.new()
	identity.add_theme_constant_override("separation", 3)
	info.add_child(identity)
	var desktop_title := _label(identity, "CARROM", 27, TEXT)
	desktop_title.custom_minimum_size.y = 36
	board_caption = _label(identity, "STYLE 01 / 08  /  CLASSIC TOURNAMENT", 11, MUTED, true)
	board_caption.custom_minimum_size.y = 31
	_sidebar_rule(info)
	_label(info, "GAME MODE", 11, MINT)
	var desktop_modes := HBoxContainer.new()
	desktop_modes.add_theme_constant_override("separation", 8)
	info.add_child(desktop_modes)
	desktop_classic_button = _make_button(desktop_modes, "CLASSIC")
	desktop_duboo_button = _make_button(desktop_modes, "DUBOO")
	desktop_classic_button.pressed.connect(func() -> void: _set_mode(false))
	desktop_duboo_button.pressed.connect(func() -> void: _set_mode(true))
	_sidebar_rule(info)
	style_heading = _label(info, "BOARD APPEARANCE", 11, MINT)
	# The style name has its own full-width row: long theme names are
	# readable even if the browser is resized to a compact landscape size.
	board_style_label = _label(info, "01 / 08  CLASSIC TOURNAMENT", 13, TEXT, true)
	board_style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_style_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board_style_label.custom_minimum_size.y = 39
	style_selector = HBoxContainer.new()
	style_selector.add_theme_constant_override("separation", 8)
	info.add_child(style_selector)
	board_style_prev = _make_button(style_selector, "PREV")
	board_style_prev.pressed.connect(func() -> void: _cycle_board_style(-1))
	board_style_next = _make_button(style_selector, "NEXT", true)
	board_style_next.pressed.connect(func() -> void: _cycle_board_style(1))
	_sidebar_rule(info)
	_label(info, "CPU DIFFICULTY", 11, MINT)
	cpu_selector = OptionButton.new()
	cpu_selector.custom_minimum_size.y = 40
	cpu_selector.add_item("Casual", 0)
	cpu_selector.add_item("Standard", 1)
	cpu_selector.add_item("Expert", 2)
	cpu_selector.select(1)
	_style_cpu_option(cpu_selector, false)
	cpu_selector.item_selected.connect(func(idx: int) -> void:
		cpu_skill = idx
		_mobile_refresh_menu()
	)
	info.add_child(cpu_selector)
	_sidebar_rule(info)
	_label(info, "GAME INFO", 11, MINT)
	tip_label = _label(info, "MOUSE: PLACE / AIM / HOLD TO POWER / RELEASE", 11, MUTED, true)
	var bottom_buttons := HBoxContainer.new()
	bottom_buttons.add_theme_constant_override("separation", 8)
	info.add_child(bottom_buttons)
	var rules_button := _make_button(bottom_buttons, "RULES")
	rules_button.pressed.connect(_open_rules)
	restart_button = _make_button(bottom_buttons, "NEW MATCH")
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
	var skin := _style(Color("#1d3b35"), EDGE, 11)
	skin.content_margin_left = 16.0
	skin.content_margin_right = 16.0
	skin.content_margin_top = 7.0
	skin.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", skin)
	panel.visible = false
	add_child(panel)
	return panel

func _build_mobile_ui() -> void:
	# Phone UI has its own hierarchy; no desktop sidebar is scaled onto a phone.
	mobile_match_label = _mobile_label(self, "BOARD 1 / 8", 16, GOLD)
	mobile_match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mobile_match_label.visible = false
	# Flat, separate regions: mode, score, board, status, pull pad, theme, actions.
	# No mobile input widgets ever sit on top of the physical board.
	mobile_score_panel = _mobile_panel()
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 7)
	mobile_score_panel.add_child(scores)
	var you_stack := VBoxContainer.new()
	you_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	you_stack.add_theme_constant_override("separation", 4)
	scores.add_child(you_stack)
	mobile_score_headings.append(_mobile_label(you_stack, "YOU / WHITE", 13, MINT))
	mobile_you = _mobile_label(you_stack, "0 / 9", 18, TEXT)
	var queen_stack := VBoxContainer.new()
	queen_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queen_stack.add_theme_constant_override("separation", 4)
	scores.add_child(queen_stack)
	mobile_score_headings.append(_mobile_label(queen_stack, "QUEEN", 13, Color("#f28b8b")))
	mobile_queen = _mobile_label(queen_stack, "ON BOARD", 11, TEXT)
	var cpu_stack := VBoxContainer.new()
	cpu_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cpu_stack.add_theme_constant_override("separation", 4)
	scores.add_child(cpu_stack)
	mobile_score_headings.append(_mobile_label(cpu_stack, "CPU / BLACK", 13, GOLD))
	mobile_cpu = _mobile_label(cpu_stack, "0 / 9", 18, TEXT)

	mobile_status_panel = _mobile_panel()
	var status_stack := VBoxContainer.new()
	status_stack.add_theme_constant_override("separation", 4)
	mobile_status_panel.add_child(status_stack)
	mobile_status_title = _mobile_label(status_stack, "YOUR BREAK", 12, MINT)
	mobile_status_hint = _mobile_label(status_stack, "SLIDE THE STRIKER ON THE BASELINE", 10, TEXT)

	mobile_power_panel = _mobile_panel()
	# Vertical shot dock: the power label and full-width meter are above a
	# compact, centered pull pad. The pad is NOT stretched across the screen.
	var power_column := VBoxContainer.new()
	power_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_column.add_theme_constant_override("separation", 7)
	mobile_power_panel.add_child(power_column)
	var power_stack := VBoxContainer.new()
	power_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_stack.add_theme_constant_override("separation", 6)
	power_column.add_child(power_stack)
	mobile_power_label = _mobile_label(power_stack, "PULL BACK TO SHOOT", 15, TEXT)
	mobile_power_meter = ProgressBar.new()
	mobile_power_meter.min_value = 0.0
	mobile_power_meter.max_value = 100.0
	mobile_power_meter.show_percentage = false
	mobile_power_meter.custom_minimum_size.y = 11.0
	mobile_power_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_power_meter.add_theme_stylebox_override("background", _style(Color("#102522"), Color.TRANSPARENT, 5))
	mobile_power_meter.add_theme_stylebox_override("fill", _style(MINT, Color.TRANSPARENT, 5))
	power_stack.add_child(mobile_power_meter)
	mobile_fire = _make_button(power_column, "PULL BACK", true)
	mobile_fire.custom_minimum_size = Vector2(155, 74)
	mobile_fire.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mobile_fire.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# The single pull gesture is captured globally, even when the finger
	# moves beyond this visual pad. The pad itself is display-only.
	mobile_fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The unavailable state must remain readable while a player places the striker.
	mobile_fire.add_theme_stylebox_override("disabled", _style(Color("#34594e"), EDGE, 9))
	mobile_fire.add_theme_color_override("font_disabled_color", Color("#dcebe4"))

	# The menu trigger is the only additional button in the phone header.
	# Drawn in code so no unsupported font glyphs or texture import are needed.
	mobile_menu_button = MOBILE_MENU_BUTTON.new()
	mobile_menu_button.tooltip_text = "Open game menu"
	mobile_menu_button.visible = false
	mobile_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_menu_button.pressed.connect(_mobile_toggle_menu)
	add_child(mobile_menu_button)

	# An outside tap dismisses the menu. Scrim and sheet intercept all input,
	# while the existing gesture-owned pull pad stays completely separate.
	mobile_menu_scrim = ColorRect.new()
	mobile_menu_scrim.color = Color(0.02, 0.08, 0.07, 0.78)
	mobile_menu_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_menu_scrim.visible = false
	mobile_menu_scrim.gui_input.connect(_mobile_menu_outside_input)
	add_child(mobile_menu_scrim)

	mobile_menu_panel = PanelContainer.new()
	var menu_skin := _style(Color("#1b3731"), Color("#719889"), 18)
	menu_skin.content_margin_left = 19.0
	menu_skin.content_margin_right = 19.0
	menu_skin.content_margin_top = 20.0
	menu_skin.content_margin_bottom = 20.0
	menu_skin.shadow_color = Color(0, 0, 0, 0.38)
	menu_skin.shadow_size = 20
	menu_skin.shadow_offset = Vector2(0, 8)
	mobile_menu_panel.add_theme_stylebox_override("panel", menu_skin)
	mobile_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_menu_panel.visible = false
	add_child(mobile_menu_panel)
	var menu_scroll := ScrollContainer.new()
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	mobile_menu_panel.add_child(menu_scroll)
	var menu_content := VBoxContainer.new()
	menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content.add_theme_constant_override("separation", 12)
	menu_scroll.add_child(menu_content)

	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 10)
	menu_content.add_child(heading_row)
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_text.add_theme_constant_override("separation", 2)
	heading_row.add_child(heading_text)
	var menu_title := _label(heading_text, "GAME MENU", 23, TEXT)
	menu_title.name = "MenuTitle"
	var menu_subtitle := _label(heading_text, "MATCH SETTINGS", 11, MINT)
	menu_subtitle.name = "MenuSubtitle"
	var close := _make_button(heading_row, "CLOSE")
	close.name = "MenuClose"
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(81, 43)
	close.pressed.connect(_mobile_close_menu)

	var divider := HSeparator.new()
	divider.add_theme_color_override("color", EDGE_SOFT)
	menu_content.add_child(divider)

	var design_heading := _label(menu_content, "BOARD DESIGN", 12, MINT)
	design_heading.name = "MenuDesignTitle"
	var design_panel := PanelContainer.new()
	var design_skin := _style(Color("#24463e"), EDGE_SOFT, 12)
	design_skin.content_margin_left = 7.0
	design_skin.content_margin_right = 7.0
	design_skin.content_margin_top = 7.0
	design_skin.content_margin_bottom = 7.0
	design_panel.add_theme_stylebox_override("panel", design_skin)
	menu_content.add_child(design_panel)
	var design_row := HBoxContainer.new()
	design_row.add_theme_constant_override("separation", 6)
	design_panel.add_child(design_row)
	mobile_menu_prev = _make_button(design_row, "PREV")
	mobile_menu_prev.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mobile_menu_prev.custom_minimum_size = Vector2(65, 49)
	mobile_menu_prev.pressed.connect(func() -> void: _cycle_board_style(-1))
	var style_text := VBoxContainer.new()
	style_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_text.add_theme_constant_override("separation", 2)
	design_row.add_child(style_text)
	mobile_menu_style_count = _mobile_label(style_text, "01 / 08", 12, MUTED)
	mobile_menu_style_name = _mobile_label(style_text, "CLASSIC TOURNAMENT", 15, TEXT)
	mobile_menu_next_style = _make_button(design_row, "NEXT")
	mobile_menu_next_style.size_flags_horizontal = Control.SIZE_SHRINK_END
	mobile_menu_next_style.custom_minimum_size = Vector2(65, 49)
	mobile_menu_next_style.pressed.connect(func() -> void: _cycle_board_style(1))

	var difficulty_heading := _label(menu_content, "CPU DIFFICULTY", 12, MINT)
	difficulty_heading.name = "MenuDifficultyTitle"
	var difficulty_choices := HBoxContainer.new()
	difficulty_choices.name = "MenuDifficultyChoices"
	difficulty_choices.add_theme_constant_override("separation", 7)
	menu_content.add_child(difficulty_choices)
	for i in range(3):
		var b := _make_button(difficulty_choices, ["CASUAL", "STANDARD", "EXPERT"][i])
		b.custom_minimum_size.y = 48
		b.pressed.connect(_mobile_set_difficulty.bind(i))
		mobile_menu_difficulties.append(b)

	var actions_divider := HSeparator.new()
	actions_divider.add_theme_color_override("color", EDGE_SOFT)
	menu_content.add_child(actions_divider)
	var actions := HBoxContainer.new()
	actions.name = "MenuActions"
	actions.add_theme_constant_override("separation", 9)
	menu_content.add_child(actions)
	mobile_menu_rules = _make_button(actions, "RULES")
	mobile_menu_rules.pressed.connect(_open_rules)
	mobile_menu_restart = _make_button(actions, "RESTART")
	mobile_menu_restart.pressed.connect(func() -> void:
		_mobile_close_menu()
		_new_match()
	)
	mobile_menu_next_board = _make_button(menu_content, "NEXT BOARD", true)
	mobile_menu_next_board.visible = false
	mobile_menu_next_board.pressed.connect(func() -> void:
		_mobile_close_menu()
		_next_board()
	)
	var footnote := _mobile_label(menu_content, "CHANGES APPLY IMMEDIATELY", 11, MUTED)
	footnote.name = "MenuFootnote"
	_mobile_refresh_menu()

func _mobile_menu_outside_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_mobile_close_menu()
		get_viewport().set_input_as_handled()

func _mobile_toggle_menu() -> void:
	if mobile_menu_open:
		_mobile_close_menu()
	else:
		_mobile_open_menu()

func _mobile_open_menu() -> void:
	if not portrait_touch or mobile_menu_open or rules_overlay.visible:
		return
	_cancel_mobile_charge()
	mobile_board_finger = -1
	mobile_board_mouse_down = false
	mobile_menu_open = true
	_mobile_refresh_menu()
	mobile_menu_scrim.show()
	mobile_menu_panel.show()
	mobile_menu_scrim.move_to_front()
	mobile_menu_panel.move_to_front()
	if sound_click != null:
		sound_click.play()

func _mobile_close_menu() -> void:
	if not mobile_menu_open:
		return
	mobile_menu_open = false
	mobile_menu_panel.hide()
	mobile_menu_scrim.hide()
	if sound_click != null:
		sound_click.play()

func _mobile_set_difficulty(index: int) -> void:
	cpu_skill = index
	cpu_selector.select(index)
	_mobile_refresh_menu()
	if sound_click != null:
		sound_click.play()

func _mobile_refresh_menu() -> void:
	if mobile_menu_style_name == null:
		return
	var names: Array = CarromBoard.DUBOO_STYLE_NAMES if duboo_mode else CarromBoard.STYLE_NAMES
	var index := duboo_style_index if duboo_mode else board_style_index
	mobile_menu_style_name.text = str(names[index])
	mobile_menu_style_count.text = "%02d / %02d" % [index + 1, names.size()]
	for i in range(mobile_menu_difficulties.size()):
		_mobile_button_skin(mobile_menu_difficulties[i], i == cpu_skill, mobile_mobile_scale)
	if mobile_menu_restart != null:
		mobile_menu_restart.text = "NEW BOARD" if duboo_mode else "RESTART"
	if mobile_menu_next_board != null:
		mobile_menu_next_board.visible = phase == "board_over" and not duboo_mode


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
		mobile_status_hint.text = "MOVE STRIKER ON THE LOWER BASELINE"
	elif phase == "aim":
		mobile_status_hint.text = "PULL BACK, THEN RELEASE"
	elif phase == "charging":
		mobile_status_hint.text = "RELEASE TO SHOOT"
	elif phase == "moving":
		mobile_status_hint.text = "WAIT FOR PIECES TO STOP"
	elif phase in ["cpu_aim", "cpu_think", "cpu_search"]:
		mobile_status_hint.text = "OPPONENT PLAYING"
	elif phase == "board_over":
		mobile_status_hint.text = "OPEN MENU TO CONTINUE"
	else:
		mobile_status_hint.text = "MATCH IN PROGRESS"
	mobile_power_label.text = "POWER  %d%%" % int(round(charge_power * 100.0)) if phase == "charging" else "PULL BACK TO SHOOT"
	mobile_power_meter.value = charge_power * 100.0 if phase == "charging" else 0.0
	mobile_fire.disabled = phase not in ["aim", "charging"] or player_turn != 0 or rules_overlay.visible
	mobile_match_label.text = "DUBOO / ONE BOARD" if duboo_mode else "BOARD %d / 8" % board_number
	_mobile_refresh_menu()

func _mobile_fire_visual(held: bool) -> void:
	if mobile_fire == null:
		return
	if portrait_touch:
		_mobile_button_skin(mobile_fire, true, mobile_mobile_scale)
	else:
		_apply_button_skin(mobile_fire, true)
	if held:
		var skin := _style(GOLD, Color("#fff2cf"), 11)
		skin.content_margin_left = 12.0
		skin.content_margin_right = 12.0
		mobile_fire.add_theme_stylebox_override("normal", skin)
	mobile_fire.add_theme_color_override("font_color", INK)

func _cancel_mobile_charge() -> void:
	mobile_pull_finger = -1
	mobile_pull_mouse = false
	mobile_pull_length = 0.0
	mobile_pull_idle = 0.0
	if phase == "charging" and player_turn == 0:
		phase = "aim"
		charge_power = 0.0
		board.charging = false
		board.aim_power = 0.0
	_mobile_fire_visual(false)
	if mobile_fire != null:
		mobile_fire.text = "PULL BACK"

func _cream_color() -> Color:
	return Color("#f8eacc")

func _score_card(parent: Node, heading: String, accent: Color) -> Array[Label]:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style(PANEL_ALT, EDGE_SOFT, 11))
	parent.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	_label(v, heading, 11, accent)
	var score := _label(v, "0", 34, TEXT)
	var sub := _label(v, "0 / 9 pocketed", 12, MUTED)
	return [score, sub]

func _build_rules_overlay() -> void:
	# A fixed header and footer keep dismiss actions visible while the long
	# instructions scroll independently; important on narrow touch screens.
	rules_overlay = PanelContainer.new()
	rules_overlay.visible = false
	rules_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_skin := _style(Color("#19332f"), MINT, 14)
	panel_skin.content_margin_left = 13.0
	panel_skin.content_margin_right = 13.0
	panel_skin.content_margin_top = 13.0
	panel_skin.content_margin_bottom = 13.0
	rules_overlay.add_theme_stylebox_override("panel", panel_skin)
	add_child(rules_overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	rules_overlay.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var title := _label(header, "CARROM  /  RULES", 22, MINT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rules_close_button = _make_button(header, "CLOSE", true)
	rules_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	rules_close_button.custom_minimum_size = Vector2(104, 48)
	rules_close_button.pressed.connect(_close_rules)
	var separator := HSeparator.new()
	column.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	scroll.add_child(v)
	rules_body = _label(v,
		"OBJECTIVE\nYou are WHITE. Pocket all nine white pieces, with the red Queen legally covered, to win the board. The CPU plays BLACK.\n\nTURNS\nWhite breaks. You keep shooting whenever you pocket at least one of your own pieces; otherwise the turn passes. Opponent pieces remain pocketed if you sink them.\n\nTHE QUEEN\nYou must pocket one of your own pieces before you can claim the Queen. Pocket the Queen and one of your own pieces in the same shot, or pocket your own piece on your very next shot to cover it. An uncovered Queen returns to the center. If you capture the Queen together with your very first piece, a further cover is required.\n\nSTRIKER FOUL\nPocketing the striker costs one of your previously pocketed pieces (or incurs one owed piece if none is available), and ends your turn.\n\nSCORING\nThe board winner scores one point for each opponent piece left on the board. The Queen adds three points if secured by the winner, or one when their pre-board match score is at least 22. First to 25 points or the leader after eight boards wins.\n\nThis is a playable standard-rules adaptation: specialist referee calls and uncommon compound fouls are simplified.",
		14, TEXT, true)
	rules_footer_button = _make_button(column, "RETURN TO GAME", true)
	rules_footer_button.custom_minimum_size.y = 50.0
	rules_footer_button.pressed.connect(_close_rules)

func _close_rules() -> void:
	if rules_overlay == null or not rules_overlay.visible:
		return
	rules_overlay.hide()
	_cancel_mobile_charge()
	_mobile_sync()
	if sound_click != null:
		sound_click.play()

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
	# Both layouts share the same game mode, despite using separate controls.
	for b in [classic_button, duboo_button, desktop_classic_button, desktop_duboo_button]:
		var selected = (b == duboo_button or b == desktop_duboo_button) if duboo_mode else (b == classic_button or b == desktop_classic_button)
		if portrait_touch and (b == classic_button or b == duboo_button):
			_mobile_button_skin(b, selected, mobile_mobile_scale)
		else:
			_apply_button_skin(b, selected)
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
		rules_body.text += "\n\nPORTRAIT TOUCH CONTROLS\nDrag the striker along the lower baseline to place it. Touch PULL BACK below the board. Drag backward to set shot angle and strength: down means shoot up, and sideways changes the angle. Release to fire. A very short pull cancels the shot. No timer and no need to hold."
	_refresh_board_style_ui()
	_mobile_sync()
	board.queue_redraw()

func _shot_speed_min() -> float:
	return DUBOO_MIN_SHOT_SPEED if duboo_mode else MIN_SHOT_SPEED

func _shot_speed_max() -> float:
	return DUBOO_MAX_SHOT_SPEED if duboo_mode else MAX_SHOT_SPEED

func _layout() -> void:
	if board == null or side_panel == null or stats_panel == null:
		return
	var sz := size
	var should_portrait := sz.y > sz.x * 1.06
	if should_portrait != portrait_touch:
		_mobile_close_menu()
		_cancel_mobile_charge()
		mobile_board_finger = -1
		mobile_board_mouse_down = false
		portrait_touch = should_portrait
	if portrait_touch:
		_layout_portrait(sz)
		return
	for mobile_node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_match_label, mobile_menu_button]:
		mobile_node.visible = false
	mobile_menu_scrim.hide()
	mobile_menu_panel.hide()
	title_label.visible = false
	mode_bar.visible = false
	stats_panel.visible = true
	side_panel.visible = true
	board_caption.visible = true
	tip_label.visible = true
	_style_cpu_option(cpu_selector, false)
	# The left dock is ALWAYS 244 px in landscape, regardless of text and
	# score updates. Both panels own separate, non-overlapping lanes.
	var gutter := clampf(minf(sz.x, sz.y) * 0.018, 10.0, 21.0)
	var between := clampf(sz.x * 0.012, 10.0, 22.0)
	var stats_w := DESKTOP_STATS_WIDTH
	var info_w := clampf(sz.x * 0.19, 198.0, 310.0)
	# Never impose an artificial minimum board size; it caused earlier panel
	# overlap when there wasn't actually enough center space to draw it.
	var center_space := maxf(0.0, sz.x - 2.0 * gutter - 2.0 * between - stats_w - info_w)
	var board_diameter := minf(center_space, maxf(0.0, sz.y - 2.0 * gutter))
	var scale_value := minf(1.6, board_diameter / 766.0)
	var drawn_size := 766.0 * scale_value
	var board_lane_x := gutter + stats_w + between
	var board_left := board_lane_x + (center_space - drawn_size) * 0.5
	var board_top := (sz.y - drawn_size) * 0.5
	board.scale = Vector2.ONE * scale_value
	board.position = Vector2(board_left + 43.0 * scale_value, board_top + 43.0 * scale_value)
	stats_panel.position = Vector2(gutter, gutter)
	stats_panel.size = Vector2(stats_w, maxf(170.0, sz.y - 2.0 * gutter))
	side_panel.position = Vector2(sz.x - info_w - gutter, gutter)
	side_panel.size = Vector2(info_w, maxf(170.0, sz.y - 2.0 * gutter))
	cpu_selector.get_popup().min_size = Vector2i(maxi(176, int(info_w - 44.0)), 0)
	var dialog_size := Vector2(minf(640.0, sz.x - 65.0), minf(740.0, sz.y - 42.0))
	rules_overlay.position = (sz - dialog_size) * 0.5
	rules_overlay.size = dialog_size

func _layout_portrait(sz: Vector2) -> void:
	# The board and score are always visible; ALL secondary controls live in
	# the hamburger menu. Only the power display and pull pad sit below the board.
	title_label.visible = true
	mode_bar.visible = true
	side_panel.visible = false
	stats_panel.visible = false
	board_caption.visible = false
	tip_label.visible = false
	for node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_match_label, mobile_menu_button]:
		node.show()

	var u := clampf(sz.x / 430.0, 0.72, 2.5)
	mobile_mobile_scale = u
	var gutter := 12.0 * u
	var safe_top := 25.0 * u
	var safe_bottom := 18.0 * u
	var header_h := 48.0 * u
	var mode_h := 47.0 * u
	var scores_h := 67.0 * u
	var status_h := 61.0 * u
	# Enough vertical room for a stacked meter and the original-size shot pad.
	var power_h := 142.0 * u
	var gap := 10.0 * u
	var max_board_width := sz.x - gutter * 2.0
	var fixed_h := safe_top + header_h + mode_h + scores_h + status_h + power_h + safe_bottom + 4.0 * gap
	# Short portrait devices can still fit a legible board; taller ones keep
	# the board edge-to-edge and distribute the remaining vertical breathing room.
	var board_width := minf(max_board_width, maxf(210.0 * u, sz.y - fixed_h))
	var spare := maxf(0.0, sz.y - fixed_h - board_width)
	var rhythm := gap + minf(spare / 4.0, 27.0 * u)
	var leftover := maxf(0.0, spare - (rhythm - gap) * 4.0)
	# The pull pad keeps its familiar footprint; distribute surplus space as
	# breathing room rather than enlarging the button or its touch hitbox.
	var dock_extra := minf(leftover * 0.38, 30.0 * u)
	power_h += dock_extra
	var extra_top := maxf(0.0, leftover - dock_extra) * 0.40
	var y := safe_top + extra_top

	# Compact game identity / match indicator / 48px hamburger trigger.
	title_label.position = Vector2(gutter + 2.0 * u, y)
	title_label.size = Vector2(sz.x * 0.42, header_h)
	title_label.add_theme_font_size_override("font_size", maxi(21, int(round(28.0 * u))))
	mobile_menu_button.position = Vector2(sz.x - gutter - header_h, y)
	mobile_menu_button.size = Vector2(header_h, header_h)
	_mobile_button_skin(mobile_menu_button, false, u)
	mobile_match_label.position = Vector2(sz.x * 0.45, y)
	mobile_match_label.size = Vector2(sz.x * 0.55 - gutter - header_h - 5.0 * u, header_h)
	mobile_match_label.add_theme_font_size_override("font_size", maxi(12, int(round(14.5 * u))))
	y += header_h + rhythm

	mode_bar.position = Vector2(gutter, y)
	mode_bar.size = Vector2(sz.x - gutter * 2.0, mode_h)
	mode_bar.add_theme_constant_override("separation", maxi(8, int(round(9.0 * u))))
	classic_button.custom_minimum_size.y = mode_h
	duboo_button.custom_minimum_size.y = mode_h
	classic_button.add_theme_font_size_override("font_size", maxi(16, int(round(19.0 * u))))
	duboo_button.add_theme_font_size_override("font_size", maxi(16, int(round(19.0 * u))))
	_mobile_button_skin(classic_button, not duboo_mode, u)
	_mobile_button_skin(duboo_button, duboo_mode, u)
	y += mode_h + rhythm

	mobile_score_panel.position = Vector2(gutter, y)
	mobile_score_panel.size = Vector2(sz.x - gutter * 2.0, scores_h)
	for heading in mobile_score_headings:
		heading.add_theme_font_size_override("font_size", maxi(12, int(round(14.5 * u))))
	mobile_you.add_theme_font_size_override("font_size", maxi(18, int(round(22.0 * u))))
	mobile_cpu.add_theme_font_size_override("font_size", maxi(18, int(round(22.0 * u))))
	mobile_queen.add_theme_font_size_override("font_size", maxi(12, int(round(16.0 * u))))
	y += scores_h + 6.0 * u

	# Game status belongs ABOVE the table, not among the bottom controls.
	mobile_status_panel.position = Vector2(gutter, y)
	mobile_status_panel.size = Vector2(sz.x - gutter * 2.0, status_h)
	mobile_status_title.add_theme_font_size_override("font_size", maxi(15, int(round(18.0 * u))))
	mobile_status_hint.add_theme_font_size_override("font_size", maxi(11, int(round(13.8 * u))))
	y += status_h + 7.0 * u

	var scale_value := board_width / 766.0
	var board_left := (sz.x - board_width) * 0.5
	board.scale = Vector2.ONE * scale_value
	board.position = Vector2(board_left + 43.0 * scale_value, y + 43.0 * scale_value)
	y += board_width + rhythm

	# One quiet control dock. No rules, difficulty, theme, or restart buttons.
	mobile_power_panel.position = Vector2(gutter, y)
	mobile_power_panel.size = Vector2(sz.x - gutter * 2.0, power_h)
	# Scale the internal gaps along with the portrait layout so even narrow
	# phones fit the bar above the touch target without clipping either.
	var power_skin := mobile_power_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	power_skin.content_margin_left = 16.0 * u
	power_skin.content_margin_right = 16.0 * u
	power_skin.content_margin_top = 7.0 * u
	power_skin.content_margin_bottom = 7.0 * u
	mobile_power_panel.add_theme_stylebox_override("panel", power_skin)
	var power_column := mobile_power_panel.get_child(0) as VBoxContainer
	power_column.add_theme_constant_override("separation", maxi(4, int(round(7.0 * u))))
	var power_stack := power_column.get_child(0) as VBoxContainer
	power_stack.add_theme_constant_override("separation", maxi(3, int(round(6.0 * u))))
	mobile_power_label.add_theme_font_size_override("font_size", maxi(15, int(round(18.0 * u))))
	mobile_power_meter.custom_minimum_size.y = 13.0 * u
	mobile_fire.custom_minimum_size = Vector2(155.0 * u, 74.0 * u)
	mobile_fire.add_theme_font_size_override("font_size", maxi(16, int(round(18.0 * u))))
	_mobile_fire_visual(phase == "charging")

	# Modal occupies the upper screen with its own internally scrolling body.
	mobile_menu_scrim.position = Vector2.ZERO
	mobile_menu_scrim.size = sz
	var menu_w := sz.x - 2.0 * gutter
	var menu_h := minf(398.0 * u, sz.y - safe_top - safe_bottom - 12.0 * u)
	mobile_menu_panel.position = Vector2(gutter, safe_top + header_h + 12.0 * u)
	mobile_menu_panel.size = Vector2(menu_w, minf(menu_h, sz.y - mobile_menu_panel.position.y - safe_bottom))
	var menu_skin := mobile_menu_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	menu_skin.content_margin_left = 17.0 * u
	menu_skin.content_margin_right = 17.0 * u
	menu_skin.content_margin_top = 17.0 * u
	menu_skin.content_margin_bottom = 17.0 * u
	mobile_menu_panel.add_theme_stylebox_override("panel", menu_skin)
	_mobile_menu_layout(u)

	var dialog_size := Vector2(sz.x - gutter * 2.0, minf(sz.y - safe_top - safe_bottom, 740.0 * u))
	rules_overlay.position = Vector2((sz.x - dialog_size.x) * 0.5, safe_top)
	rules_overlay.size = dialog_size
	rules_body.add_theme_font_size_override("font_size", maxi(16, int(round(17.0 * u))))
	rules_close_button.custom_minimum_size = Vector2(94.0 * u, 48.0 * u)
	rules_close_button.add_theme_font_size_override("font_size", maxi(15, int(round(17.0 * u))))
	rules_footer_button.custom_minimum_size.y = 52.0 * u
	rules_footer_button.add_theme_font_size_override("font_size", maxi(16, int(round(18.0 * u))))
	_mobile_button_skin(rules_close_button, true, u)
	_mobile_button_skin(rules_footer_button, true, u)
	if rules_body != null and not rules_body.text.contains("PORTRAIT TOUCH CONTROLS"):
		rules_body.text += "\n\nPORTRAIT TOUCH CONTROLS\nMove the striker by dragging on the lower baseline. Then touch PULL BACK below the board, drag backward to set both direction and power, and lift your finger to shoot. A short drag cancels. There is no timed charging or automatic firing."
	_mobile_sync()

func _mobile_menu_layout(u: float) -> void:
	# Independently scaled typography and tap targets; avoids narrow popups.
	var scroll := mobile_menu_panel.get_child(0) as ScrollContainer
	var content := scroll.get_child(0) as VBoxContainer
	content.add_theme_constant_override("separation", maxi(8, int(round(11.0 * u))))
	for node in content.get_children():
		if node is Label:
			var label := node as Label
			label.add_theme_font_size_override("font_size", maxi(12, int(round(12.0 * u))))
	var header := content.get_child(0) as HBoxContainer
	var heading_stack := header.get_child(0) as VBoxContainer
	var header_title := heading_stack.get_child(0) as Label
	var header_subtitle := heading_stack.get_child(1) as Label
	header_title.add_theme_font_size_override("font_size", maxi(21, int(round(23.0 * u))))
	header_subtitle.add_theme_font_size_override("font_size", maxi(11, int(round(12.0 * u))))
	var close := header.get_child(1) as Button
	close.custom_minimum_size = Vector2(81.0 * u, 42.0 * u)
	close.add_theme_font_size_override("font_size", maxi(13, int(round(14.0 * u))))
	_mobile_button_skin(close, false, u)
	var design_panel := content.get_child(3) as PanelContainer
	var row := design_panel.get_child(0) as HBoxContainer
	for b in [mobile_menu_prev, mobile_menu_next_style]:
		b.custom_minimum_size = Vector2(64.0 * u, 50.0 * u)
		b.add_theme_font_size_override("font_size", maxi(12, int(round(13.5 * u))))
		_mobile_button_skin(b, false, u)
	mobile_menu_style_count.add_theme_font_size_override("font_size", maxi(12, int(round(13.0 * u))))
	mobile_menu_style_name.add_theme_font_size_override("font_size", maxi(12, int(round(15.0 * u))))
	row.add_theme_constant_override("separation", maxi(4, int(round(6.0 * u))))
	var difficulty_row := content.get_node("MenuDifficultyChoices") as HBoxContainer
	difficulty_row.add_theme_constant_override("separation", maxi(5, int(round(7.0 * u))))
	for b in mobile_menu_difficulties:
		b.custom_minimum_size.y = 48.0 * u
		b.add_theme_font_size_override("font_size", maxi(12, int(round(13.5 * u))))
	var actions := content.get_node("MenuActions") as HBoxContainer
	actions.add_theme_constant_override("separation", maxi(7, int(round(9.0 * u))))
	for b in [mobile_menu_rules, mobile_menu_restart, mobile_menu_next_board]:
		b.custom_minimum_size.y = 49.0 * u
		b.add_theme_font_size_override("font_size", maxi(13, int(round(15.0 * u))))
		_mobile_button_skin(b, b == mobile_menu_next_board, u)
	var footer := content.get_node("MenuFootnote") as Label
	footer.add_theme_font_size_override("font_size", maxi(10, int(round(11.0 * u))))
	_mobile_refresh_menu()

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
	_mobile_refresh_menu()
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
	cpu_plan_active = false
	cpu_plan_candidates.clear()
	cpu_plan_ranked.clear()
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
	if portrait_touch:
		aim_direction = Vector2.UP
		board.aim_direction = aim_direction
		mobile_locked_shot_direction = aim_direction
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
	# Mobile aiming is a separate gesture completed BEFORE charging.
	if player_turn != 0 or phase not in ["placement", "aim"]:
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
	# Do not allow a second finger, a drag, or UI touch to turn the shot
	# while a pull gesture is active. Only the captured finger steers.
	if player_turn != 0 or phase not in ["placement", "aim"]:
		return
	var local := _mobile_board_point(screen_point)
	if mobile_drag_baseline:
		if _place_striker(0, local.x):
			if phase == "placement":
				phase = "aim"
				board.show_aim = true
				board.side = 0
				mobile_aim_target = _get_striker()["pos"] + Vector2.UP * 220.0
				aim_direction = Vector2.UP
				board.aim_direction = aim_direction
				sound_click.play()
				_set_status("AIM YOUR SHOT", "Pull back on the shot pad to aim and release to fire.")
			else:
				# Sliding along the baseline should not rotate a previously aimed
				# shot merely because the striker's world position has changed.
				mobile_aim_target = _get_striker()["pos"] + aim_direction.normalized() * 220.0
		else:
			_set_status("BASELINE BLOCKED", "Try another point on the lower baseline.")
	else:
		mobile_aim_target = local
		var diff: Vector2 = mobile_aim_target - _get_striker()["pos"]
		if diff.length_squared() > 18.0 * 18.0:
			aim_direction = diff.normalized()
			board.aim_direction = aim_direction
			board.queue_redraw()

func _mobile_start_pull(position: Vector2) -> void:
	if player_turn != 0 or phase != "aim" or rules_overlay.visible:
		return
	# Starting a drag never fires anything. It only captures the control finger.
	mobile_pull_origin = position
	mobile_pull_length = 0.0
	mobile_pull_idle = 0.0
	mobile_locked_shot_direction = aim_direction.normalized() if aim_direction.length_squared() > 0.5 else Vector2.UP
	charge_power = 0.0
	phase = "charging"
	board.charging = false
	board.aim_power = 0.0
	_mobile_fire_visual(true)
	mobile_fire.text = "PULL BACK"
	_mobile_sync()

func _mobile_update_pull(position: Vector2) -> void:
	if phase != "charging" or player_turn != 0:
		return
	# As with a slingshot, dragging downward sends the striker upward.
	# Screen coordinates are already in the same global coordinate system.
	var pull: Vector2 = mobile_pull_origin - position
	mobile_pull_length = pull.length()
	mobile_pull_idle = 0.0
	var scale_factor := maxf(0.7, mobile_mobile_scale)
	var dead_zone := MOBILE_PULL_THRESHOLD * scale_factor
	if mobile_pull_length >= dead_zone:
		mobile_locked_shot_direction = pull.normalized()
		aim_direction = mobile_locked_shot_direction
		board.aim_direction = aim_direction
		var power_fraction := clampf((mobile_pull_length - dead_zone) / ((MOBILE_PULL_MAX - MOBILE_PULL_THRESHOLD) * scale_factor), 0.0, 1.0)
		charge_power = lerpf(0.20, 1.0, power_fraction)
	else:
		charge_power = 0.0
	board.aim_power = charge_power
	mobile_fire.text = "RELEASE  %d%%" % int(round(charge_power * 100.0)) if charge_power > 0.0 else "PULL BACK"
	mobile_power_label.text = "POWER  %d%%" % int(round(charge_power * 100.0)) if charge_power > 0.0 else "PULL BACK TO SHOOT"
	mobile_power_meter.value = charge_power * 100.0
	board.queue_redraw()

func _mobile_end_pull() -> void:
	if phase == "charging" and player_turn == 0 and not rules_overlay.visible:
		var should_shoot := mobile_pull_length >= MOBILE_PULL_THRESHOLD * maxf(0.7, mobile_mobile_scale)
		var shot_direction := mobile_locked_shot_direction
		var shot_power := charge_power
		_cancel_mobile_charge()
		if should_shoot:
			_shoot(shot_direction, shot_power)
		else:
			_set_status("AIM YOUR SHOT", "Pull back on the shot pad, then release to shoot.")
			_refresh_ui()
	else:
		_cancel_mobile_charge()

func _mobile_handle_touch(event: InputEventScreenTouch) -> void:
	mobile_ignore_synthetic_mouse = 0.75
	if event.pressed:
		if rules_overlay.visible:
			return
		# One finger owns one gesture. A new press can also recover if the
		# browser failed to deliver the previous finger's release.
		if mobile_fire.get_global_rect().has_point(event.position):
			if player_turn == 0 and phase in ["aim", "charging"]:
				if phase == "charging":
					_cancel_mobile_charge()
				mobile_pull_finger = event.index
				_mobile_start_pull(event.position)
			get_viewport().set_input_as_handled()
			return
		if phase == "charging":
			get_viewport().set_input_as_handled()
			return
		if mobile_board_finger < 0 and _mobile_start_board_drag(event.position):
			mobile_board_finger = event.index
			get_viewport().set_input_as_handled()
	else:
		if event.index == mobile_pull_finger:
			mobile_pull_finger = -1
			_mobile_end_pull()
			get_viewport().set_input_as_handled()
		elif event.index == mobile_board_finger:
			mobile_board_finger = -1
			get_viewport().set_input_as_handled()

func _mobile_handle_mouse(event: InputEvent) -> void:
	# Allow mouse testing in the browser, while ignoring touch-generated mouse
	# events to prevent duplicate shots or stray aim changes.
	if mobile_ignore_synthetic_mouse > 0.0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if rules_overlay.visible:
				return
			if mobile_fire.get_global_rect().has_point(event.position):
				if player_turn == 0 and phase in ["aim", "charging"]:
					if phase == "charging":
						_cancel_mobile_charge()
					mobile_pull_mouse = true
					_mobile_start_pull(event.position)
				get_viewport().set_input_as_handled()
			elif phase != "charging" and _mobile_start_board_drag(event.position):
				mobile_board_mouse_down = true
				get_viewport().set_input_as_handled()
		else:
			if mobile_pull_mouse:
				mobile_pull_mouse = false
				_mobile_end_pull()
				get_viewport().set_input_as_handled()
			elif mobile_board_mouse_down:
				mobile_board_mouse_down = false
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if mobile_pull_mouse:
			_mobile_update_pull(event.position)
			get_viewport().set_input_as_handled()
		elif mobile_board_mouse_down:
			_mobile_update_board_drag(event.position)
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if rules_overlay != null and rules_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_rules()
			get_viewport().set_input_as_handled()
		return
	if mobile_menu_open:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_mobile_close_menu()
			get_viewport().set_input_as_handled()
		return
	if not portrait_touch:
		return
	if event is InputEventScreenTouch:
		_mobile_handle_touch(event)
	elif event is InputEventScreenDrag:
		mobile_ignore_synthetic_mouse = 0.75
		if event.index == mobile_pull_finger:
			_mobile_update_pull(event.position)
			get_viewport().set_input_as_handled()
		elif phase == "charging":
			get_viewport().set_input_as_handled()
		elif event.index == mobile_board_finger:
			_mobile_update_board_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		_mobile_handle_mouse(event)

func _unhandled_input(event: InputEvent) -> void:
	if portrait_touch:
		return
	if rules_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_rules()
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
	# Browser/webview touchcancel is not always delivered. A dead pull must
	# cancel itself, never fire a shot or strand the player in charging.
	if portrait_touch and phase == "charging":
		mobile_pull_idle += delta
		if mobile_pull_idle > 5.0:
			_cancel_mobile_charge()
			_set_status("AIM YOUR SHOT", "Shot reset. Pull back and release to shoot.")
			_refresh_ui()
			return
	if rules_overlay != null and rules_overlay.visible:
		return
	if phase == "aim" or phase == "charging":
		if portrait_touch and phase == "charging":
			# Only the captured pull gesture can adjust mobile aim and power.
			# No timers and no automatic fire at 100 percent.
			aim_direction = mobile_locked_shot_direction
			board.aim_direction = aim_direction
		else:
			var mouse := mobile_aim_target if portrait_touch else _screen_to_board()
			var diff: Vector2 = mouse - _get_striker()["pos"]
			if diff.length() > 22.0:
				aim_direction = diff.normalized()
				board.aim_direction = aim_direction
		if phase == "charging" and not portrait_touch:
			charge_time = minf(charge_time + delta, 1.5)
			charge_power = 0.20 + 0.80 * charge_time / 1.5
			power_label.text = "SHOT POWER   %d%%" % int(round(charge_power * 100.0))
			power_meter.value = charge_power * 100.0
			board.charging = true
		board.aim_power = charge_power
		board.queue_redraw()
	elif phase == "placement" and not portrait_touch:
		var mouse := _screen_to_board()
		if _valid_baseline_click(mouse):
			_place_striker(0, mouse.x)
	elif phase == "cpu_think":
		cpu_time -= delta
		if cpu_time <= 0.0:
			_cpu_start_search()
			phase = "cpu_search"
			_set_status("CPU STUDYING BOARD", "The computer is considering its options.")
	elif phase == "cpu_search":
		if cpu_plan_active:
			_cpu_search_frame()
	elif phase == "cpu_aim":
		cpu_time -= delta
		if cpu_time <= 0.0:
			_shoot(cpu_queued_shot["dir"], inverse_lerp(_shot_speed_min(), _shot_speed_max(), cpu_queued_shot["speed"]))

func _shoot(direction: Vector2, power: float) -> void:
	if direction.length_squared() < 0.5:
		return
	phase = "moving"
	mobile_pull_finger = -1
	mobile_pull_mouse = false
	mobile_pull_length = 0.0
	mobile_pull_idle = 0.0
	mobile_board_finger = -1
	mobile_board_mouse_down = false
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
	_mobile_close_menu()
	_cancel_mobile_charge()
	rules_overlay.show()
	rules_overlay.move_to_front()
	_mobile_sync()
	sound_click.play()

# CPU shot planning: generate physically feasible intentions, then play short
# sandbox simulations using EXACTLY the player's disc/rail physics. This is
# not a scripted pocket and never moves an opponent's pieces in the live game.
# Search is spread across frames so even Expert remains usable in web builds.
func _cpu_start_search() -> void:
	cpu_plan_candidates.clear()
	cpu_plan_ranked.clear()
	cpu_plan_cursor = 0
	cpu_plan_base_value = _cpu_position_value(discs)
	var direct: Array[Dictionary] = []
	var banks: Array[Dictionary] = []
	var combos: Array[Dictionary] = []
	var safeties: Array[Dictionary] = []
	var own_before := _pocketed_count("black")
	var striker_radius: float = PHYSICS.radius_for("striker", duboo_mode)
	var base_y: float = CarromBoard.base_y(1, duboo_mode)
	var left: float = 111.0 if duboo_mode else 125.0
	var right: float = 569.0 if duboo_mode else 555.0
	var samples: Array[float] = []
	for i in range(11):
		samples.append(lerpf(left, right, float(i) / 10.0))
	# Also aim from x positions directly beneath useful ghost points.
	var targets: Array[Dictionary] = []
	for disc in discs:
		if bool(disc["pocketed"]) or disc["kind"] == "striker":
			continue
		if disc["kind"] == "black" or (disc["kind"] == "queen" and own_before > 0 and pending_queen == -1 and queen_owner == -1):
			targets.append(disc)
	for target_disc in targets:
		var target: Vector2 = target_disc["pos"]
		var target_id: int = int(target_disc["id"])
		var radius: float = float(target_disc["radius"])
		for pocket in PHYSICS.POCKETS:
			var exit: Vector2 = (pocket - target).normalized()
			var ghost: Vector2 = target - exit * (striker_radius + radius + 0.7)
			var open_pocket: bool = _cpu_lane_open(target, pocket, radius * 1.75, target_id)
			var xs: Array[float] = samples.duplicate()
			xs.append(clampf(ghost.x, left, right))
			for x in xs:
				var origin := Vector2(x, base_y)
				if not _can_place_striker(origin):
					continue
				var aim: Vector2 = ghost - origin
				if aim.length_squared() < 1400.0:
					continue
				var direction: Vector2 = aim.normalized()
				var travel: float = origin.distance_to(target)
				if open_pocket and _cpu_lane_open(origin, ghost, striker_radius + 2.0, target_id):
					var quality: float = 95.0 - travel * 0.032 - target.distance_to(pocket) * 0.035
					if target_disc["kind"] == "queen":
						quality -= 11.0
					var speed: float = clampf(360.0 + travel * 0.48 + target.distance_to(pocket) * 0.40, 360.0, 980.0) if duboo_mode else clampf(455.0 + travel * 0.60 + target.distance_to(pocket) * 0.48, 500.0, 1320.0)
					_cpu_add_intention(direct, x, direction, speed, quality, target, "direct")
					_cpu_add_intention(direct, x, direction, speed * 0.77, quality - 2.5, target, "touch")
				# One-rail striker banks: reflect the impact point across the rail.
				# Both segments must be open; prediction decides if the bounce works.
				if not open_pocket:
					continue
				for wall in range(3):
					var wall_coord: float = striker_radius if wall == 0 or wall == 2 else 680.0 - striker_radius
					var mirror: Vector2 = ghost
					if wall == 2:
						mirror.y = 2.0 * wall_coord - ghost.y
					else:
						mirror.x = 2.0 * wall_coord - ghost.x
					var ray: Vector2 = mirror - origin
					var denom: float = ray.y if wall == 2 else ray.x
					if absf(denom) < 0.001:
						continue
					var t: float = (wall_coord - (origin.y if wall == 2 else origin.x)) / denom
					if t < 0.10 or t > 0.90:
						continue
					var bounce: Vector2 = origin + ray * t
					if bounce.x < striker_radius + 30.0 or bounce.x > 680.0 - striker_radius - 30.0 or bounce.y < striker_radius + 30.0 or bounce.y > 680.0 - striker_radius - 30.0:
						# Coordinate ON the target rail is allowed; only test the other axis.
						if (wall == 2 and (bounce.x < 50.0 or bounce.x > 630.0)) or (wall != 2 and (bounce.y < 50.0 or bounce.y > 630.0)):
							continue
					if not _cpu_lane_open(origin, bounce, striker_radius + 1.0, target_id):
						continue
					if not _cpu_lane_open(bounce, ghost, striker_radius + 1.0, target_id):
						continue
					var path_length: float = origin.distance_to(bounce) + bounce.distance_to(target)
					var bank_power: float = clampf(520.0 + path_length * 0.48, 640.0, 1050.0) if duboo_mode else clampf(620.0 + path_length * 0.75, 800.0, 1420.0)
					_cpu_add_intention(banks, x, ray.normalized(), bank_power, 58.0 - path_length * 0.016, target, "bank")
		# Combination intentions: nudge an intervening piece into the target,
		# using a genuine striker -> piece -> target collision chain.
		for helper in discs:
			if bool(helper["pocketed"]) or helper["kind"] == "striker" or int(helper["id"]) == target_id:
				continue
			var hpos: Vector2 = helper["pos"]
			for pocket in PHYSICS.POCKETS:
				var exit: Vector2 = (pocket - target).normalized()
				var connection: Vector2 = target - hpos
				var forward: float = connection.dot(exit)
				var sideways: float = absf(connection.cross(exit))
				if forward < 25.0 or forward > 235.0 or sideways > radius * 2.7:
					continue
				if not _cpu_lane_open(target, pocket, radius * 1.55, target_id):
					continue
				var combo_ghost: Vector2 = hpos - connection.normalized() * (striker_radius + float(helper["radius"]) + 0.5)
				for x in samples:
					var origin := Vector2(x, base_y)
					if not _can_place_striker(origin) or not _cpu_lane_open(origin, combo_ghost, striker_radius + 1.2, int(helper["id"])):
						continue
					var aim: Vector2 = combo_ghost - origin
					if aim.length_squared() < 300.0:
						continue
					var distance: float = aim.length() + connection.length()
					var combo_speed: float = clampf(600.0 + distance * 0.38, 650.0, 1050.0) if duboo_mode else clampf(700.0 + distance * 0.52, 770.0, 1400.0)
					_cpu_add_intention(combos, x, aim.normalized(), combo_speed, 59.0 - sideways * 0.5 - distance * 0.012 + (6.0 if helper["kind"] == "black" else -4.0), target, "combo")
	# Safety / clearing shots are the fallback when direct geometry fails.
	# Their outcomes are still simulated and judged for pocketing/fouls.
	for target_disc in targets:
		if target_disc["kind"] != "black":
			continue
		var target: Vector2 = target_disc["pos"]
		for x in samples:
			var origin := Vector2(x, base_y)
			if not _can_place_striker(origin):
				continue
			var offset: Vector2 = target - origin
			if offset.length_squared() < 1000.0 or not _cpu_lane_open(origin, target, striker_radius + 2.0, int(target_disc["id"])):
				continue
			var direction: Vector2 = offset.normalized()
			var speed: float = clampf(420.0 + offset.length() * 0.34, 450.0, 900.0) if duboo_mode else clampf(550.0 + offset.length() * 0.60, 600.0, 1200.0)
			_cpu_add_intention(safeties, x, direction, speed, 39.0 - offset.length() * 0.022, target, "clear")
			_cpu_add_intention(safeties, x, direction.rotated(0.065), speed * 0.85, 30.0 - offset.length() * 0.02, target, "safety")
			_cpu_add_intention(safeties, x, direction.rotated(-0.065), speed * 0.85, 30.0 - offset.length() * 0.02, target, "safety")
	# Reserve slots for non-direct ideas even when simple pockets are present.
	# Casual, Standard, Expert differ in BOTH search depth and shot precision.
	var quotas: Array = [[7, 1, 1, 3], [12, 4, 3, 5], [19, 7, 6, 7]]
	var limits: Array = quotas[clampi(cpu_skill, 0, 2)]
	_cpu_reserve_candidates(direct, int(limits[0]), 3)
	_cpu_reserve_candidates(banks, int(limits[1]), 2)
	_cpu_reserve_candidates(combos, int(limits[2]), 2)
	_cpu_reserve_candidates(safeties, int(limits[3]), 2)
	# Opening breaks tend to have tightly packed targets and no free lanes.
	# Keep a legal simple break available if the geometry found nothing else.
	if cpu_plan_candidates.is_empty():
		for x in samples:
			var initial := Vector2(x, base_y)
			if _can_place_striker(initial):
				var speed: float = 820.0 if duboo_mode else 1100.0
				cpu_plan_candidates.append({"x": x, "dir": (Vector2(340, 340) - initial).normalized(), "speed": speed, "target": Vector2(340, 340), "seed": 0.0, "style": "break"})
	cpu_plan_candidates.shuffle()
	cpu_plan_active = true

func _cpu_reserve_candidates(pool: Array[Dictionary], amount: int, per_target: int) -> void:
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["seed"]) > float(b["seed"]))
	var used: Dictionary = {}
	var taken := 0
	# First favor several distinct pieces rather than dozens of near-identical
	# aim lines for the same coin and pocket.
	for candidate in pool:
		if taken >= amount:
			return
		var target_key := str(candidate["target"])
		var count: int = int(used.get(target_key, 0))
		if count >= per_target:
			continue
		used[target_key] = count + 1
		cpu_plan_candidates.append(candidate)
		taken += 1
	# If few pieces remain, spend any unused search slots refining that shot.
	for candidate in pool:
		if taken >= amount:
			return
		if candidate in cpu_plan_candidates:
			continue
		cpu_plan_candidates.append(candidate)
		taken += 1

func _cpu_add_intention(pool: Array[Dictionary], x: float, direction: Vector2, speed: float, merit: float, target: Vector2, style: String) -> void:
	pool.append({"x": x, "dir": direction, "speed": clampf(speed, _shot_speed_min(), _shot_speed_max()), "target": target, "seed": merit, "style": style})

func _cpu_lane_open(a: Vector2, b: Vector2, width: float, excluded_id: int) -> bool:
	var offset: Vector2 = b - a
	var len2: float = offset.length_squared()
	if len2 < 1.0:
		return true
	for piece in discs:
		if piece["pocketed"] or piece["kind"] == "striker" or int(piece["id"]) == excluded_id:
			continue
		var along: float = clampf(((piece["pos"] as Vector2) - a).dot(offset) / len2, 0.0, 1.0)
		var near: Vector2 = a + offset * along
		var needed: float = width + float(piece["radius"]) * 0.75
		if near.distance_squared_to(piece["pos"]) < needed * needed:
			return false
	return true

# Cheap post-shot positional assessment. A move that leaves black pieces near
# open pockets and white ones awkward is preferable to a meaningless smash.
func _cpu_state_lane_open(state: Array, start: Vector2, finish: Vector2, exclude_id: int) -> bool:
	var segment: Vector2 = finish - start
	var length_squared: float = segment.length_squared()
	if length_squared < 1.0:
		return true
	for other in state:
		if bool(other["pocketed"]) or other["kind"] == "striker" or int(other["id"]) == exclude_id:
			continue
		var proj: float = clampf(((other["pos"] as Vector2) - start).dot(segment) / length_squared, 0.0, 1.0)
		var nearest: Vector2 = start + segment * proj
		var clearance: float = float(other["radius"]) + 10.0
		if nearest.distance_squared_to(other["pos"]) < clearance * clearance:
			return false
	return true

func _cpu_position_value(state: Array) -> float:
	var value := 0.0
	for piece in state:
		if piece["pocketed"] or piece["kind"] == "striker" or piece["kind"] == "queen":
			continue
		var nearest := 1000.0
		var clean_lanes := 0
		for hole in PHYSICS.POCKETS:
			nearest = minf(nearest, (piece["pos"] as Vector2).distance_to(hole))
			if _cpu_state_lane_open(state, piece["pos"], hole, int(piece["id"])):
				clean_lanes += 1
		var closeness: float = clampf((320.0 - nearest) / 8.0, -6.0, 24.0)
		# Accessible white pocket lines are a future threat; keeping those
		# lanes obscured creates genuine positional/defensive decisions.
		if piece["kind"] == "black":
			value += closeness + minf(2.0, float(clean_lanes)) * 5.0
		else:
			value -= closeness * 0.65 + minf(2.0, float(clean_lanes)) * 7.0
	return value

func _cpu_predict(candidate: Dictionary) -> float:
	var test: Array = discs.duplicate(true)
	var striker: Dictionary = test[test.size() - 1]
	striker["pos"] = Vector2(float(candidate["x"]), CarromBoard.base_y(1, duboo_mode))
	striker["vel"] = (candidate["dir"] as Vector2) * float(candidate["speed"])
	striker["pocketed"] = false
	var feedback: Array = []
	var dt := 1.0 / 48.0
	var steps: int = 402 if duboo_mode else 250
	var substeps: int = 3 if duboo_mode else 2
	for step in range(steps):
		for _j in range(substeps):
			PHYSICS.advance(test, dt / float(substeps), duboo_mode, feedback)
			feedback.clear()
		if step > 14 and PHYSICS.is_still(test):
			break
	var own := 0
	var other := 0
	var queen := false
	var fouled := false
	for index in range(test.size()):
		if not test[index]["pocketed"] or discs[index]["pocketed"]:
			continue
		match str(test[index]["kind"]):
			"black": own += 1
			"white": other += 1
			"queen": queen = true
			"striker": fouled = true
	var initial_black: int = _pocketed_count("black")
	var score: float = 160.0 * own - 135.0 * other
	if own >= 2:
		score += 42.0 * float(own - 1)  # A genuine multi-pocket is worth pursuing.
	if fouled:
		score -= 390.0
	if queen:
		if initial_black == 0 and own < 2:
			score -= 110.0  # Queen is illegally early and will return.
		elif own > 0:
			score += 115.0  # Queen and cover in one shot.
		else:
			score += 28.0  # Must cover on the next shot.
	if pending_queen == 1:
		score += 135.0 if own > 0 and not fouled else -115.0
	if initial_black + own == 9:
		if queen_owner == 1 or (queen and own > 0) or pending_queen == 1:
			score += 480.0
		else:
			score -= 600.0  # Never deliberately lose by finishing too early.
	var after_value: float = _cpu_position_value(test)
	score += clampf((after_value - cpu_plan_base_value) * 0.55, -38.0, 38.0)
	if own == 0:
		score -= 22.0  # Losing your turn has a tactical cost.
	if own == 0 and other == 0 and not queen:
		score -= 8.0  # Discourage pointless hard breaks once spread out.
	# Prefer reliable, short execution when simulated outcomes tie.
	score += float(candidate["seed"]) * 0.038
	return score

func _cpu_search_frame() -> void:
	# Fixed work-per-frame keeps the HUD responsive and avoids hitching on web.
	var jobs := 1 if cpu_skill == 2 or duboo_mode else 2
	for _j in range(jobs):
		if cpu_plan_cursor >= cpu_plan_candidates.size():
			break
		var attempt: Dictionary = cpu_plan_candidates[cpu_plan_cursor]
		cpu_plan_cursor += 1
		var evaluated: Dictionary = attempt.duplicate()
		evaluated["result"] = _cpu_predict(attempt)
		cpu_plan_ranked.append(evaluated)
	if cpu_plan_cursor < cpu_plan_candidates.size():
		return
	cpu_plan_active = false
	cpu_plan_ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["result"]) > float(b["result"]))
	var selected: Dictionary = {"x": 340.0, "dir": Vector2.DOWN, "speed": 750.0, "target": Vector2(340, 340)}
	if not cpu_plan_ranked.is_empty():
		var index := 0
		if cpu_skill == 0 and cpu_plan_ranked.size() > 3 and randf() < 0.48:
			index = randi_range(1, 3)
		elif cpu_skill == 1 and cpu_plan_ranked.size() > 1 and randf() < 0.17:
			index = 1
		selected = cpu_plan_ranked[index].duplicate()
	# Lower difficulty affects shot execution; Expert is almost mechanically
	# exact, but no tier has a guaranteed outcome after the physical collision.
	var drift: float = [0.055, 0.018, 0.0035][clampi(cpu_skill, 0, 2)]
	selected["dir"] = (selected["dir"] as Vector2).rotated(randf_range(-drift, drift))
	selected["speed"] = clampf(float(selected["speed"]) * randf_range(1.0 - drift * 1.3, 1.0 + drift * 1.3), _shot_speed_min(), _shot_speed_max())
	cpu_queued_shot = selected
	_place_striker(1, float(cpu_queued_shot["x"]))
	board.aim_direction = cpu_queued_shot["dir"]
	board.aim_power = inverse_lerp(_shot_speed_min(), _shot_speed_max(), cpu_queued_shot["speed"])
	board.show_aim = true
	board.show_cpu_target = true
	board.cpu_target = cpu_queued_shot["target"]
	board.queue_redraw()
	phase = "cpu_aim"
	cpu_time = 0.60
	_set_status("CPU AIMING", "The computer has selected a shot.")
	_refresh_ui()
