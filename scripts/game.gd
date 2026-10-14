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
const MAX_BOARD_COUNT := 1
const MATCH_TARGET := 25
const MIN_SHOT_SPEED := 320.0
const MAX_SHOT_SPEED := 1425.0
const DUBOO_MIN_SHOT_SPEED := 250.0
const DUBOO_MAX_SHOT_SPEED := 1080.0
# Desktop stats dock width is independent of labels, scores, and window changes.
const DESKTOP_STATS_WIDTH := 244.0
# The opponent's portrait and biography live in a drawer INSIDE the left dock.
# Only a slim handle remains at the bottom of the stats panel when closed.
const RIVAL_DRAWER_HANDLE_HEIGHT := 42.0

# Roster order matches the eight PNG portraits supplied with the project.
# Shot preferences are small bonuses applied AFTER real collision prediction.
# Each rival keeps Casual / Standard / Expert precision and planning budgets.
const RIVALS := [
	{"name": "DIEGO SOLIS", "alias": "KICKFLIP", "type": "THE SKATEBOARDER",
	 "bio": "A backstreet skater who sees angles where others see walls. Loves bold rebounds and quick recoveries.",
	 "bias": {"bank": 23.0, "combo": 11.0, "touch": -6.0, "safety": -11.0}, "quota": [-3, 2, 1, 0], "position": 0.75, "multi": 1.05},
	{"name": "VIKTOR MARKOVIC", "alias": "VELVET KNUCKLES", "type": "THE GANGSTER",
	 "bio": "Never shows his hand. Favors safe finishes, controlled power, and leaving you with the harder shot.",
	 "bias": {"touch": 17.0, "direct": 9.0, "safety": 15.0, "bank": -9.0}, "quota": [1, -1, -1, 1], "position": 1.55, "multi": 0.9},
	{"name": "AIKO SATO", "alias": "FEEDBACK", "type": "THE ROCKER",
	 "bio": "Plays every round like a live set. Thrives on lively breaks, chain reactions, and loud combinations.",
	 "bias": {"combo": 23.0, "clear": 10.0, "direct": 5.0, "safety": -9.0}, "quota": [-2, 0, 3, -1], "position": 0.65, "multi": 1.5},
	{"name": "ROWAN VALE", "alias": "STATIC", "type": "THE PUNK",
	 "bio": "Hates the obvious route. Will try a wild cushion line when a safer shot is staring them in the face.",
	 "bias": {"bank": 28.0, "combo": 18.0, "clear": 12.0, "direct": -9.0}, "quota": [-3, 3, 1, -1], "position": 0.6, "multi": 1.1},
	{"name": "NIA OKAFOR", "alias": "SPRINT", "type": "THE ATHLETE",
	 "bio": "Disciplined and relentless. Favors clean lanes, repeatable precision, and fast, decisive finishes.",
	 "bias": {"direct": 21.0, "touch": 17.0, "combo": -4.0, "safety": -9.0}, "quota": [3, -1, -1, -1], "position": 1.05, "multi": 1.0},
	{"name": "LEILA RAHMAN", "alias": "VELOUR", "type": "THE MODEL",
	 "bio": "Unhurried and immaculate. Prefers a delicate touch and tidy board control over risky theatrics.",
	 "bias": {"touch": 26.0, "direct": 11.0, "safety": 8.0, "bank": -10.0}, "quota": [2, -1, -1, 0], "position": 1.3, "multi": 0.85},
	{"name": "MALIK BAPTISTE", "alias": "VERSE", "type": "THE RAPPER",
	 "bio": "Finds rhythm in every collision. Builds momentum through combinations and is always chasing the double.",
	 "bias": {"combo": 27.0, "bank": 11.0, "direct": 2.0, "safety": -8.0}, "quota": [-2, 0, 3, -1], "position": 0.8, "multi": 1.65},
	{"name": "HANA PARK", "alias": "GHOSTWIRE", "type": "THE HACKER",
	 "bio": "Reads the board like a system. Values quiet positioning, blocked lanes, and the precise shot nobody expected.",
	 "bias": {"safety": 24.0, "clear": 12.0, "touch": 12.0, "bank": 5.0}, "quota": [-2, 0, 0, 2], "position": 1.85, "multi": 1.0}
]
# Nine one-liners per opponent, in the same order as RIVALS. Triggered only
# after an unfouled CPU shot pockets one or more of its own pieces.
const RIVAL_POCKET_QUOTES := [
	["Clean landing. No wobble.", "Saw that gap from the start.", "That one had a nice line.", "Just rode the cushion.", "Sometimes the bank is the road.", "That pocket was calling.", "No brakes on that one.", "Little angle, big payoff.", "Roll with it."],
	["Business as usual.", "I prefer certainty.", "Nothing personal. Just the board.", "A quiet move pays more.", "You left that door open.", "I collect what's available.", "The table keeps its own books.", "I never rush a sure thing.", "Consider that settled."],
	["That one hit the chorus.", "Turn it up.", "Perfect timing, ugly noise.", "Caught the beat just right.", "Hear that? That's momentum.", "One take. No rehearsal.", "The board is my amplifier.", "That was a clean riff.", "Keep the tempo."],
	["Rules are fine. Angles aren't.", "Did that bother you?", "Straight shots are overrated.", "Chaos has a nice sound.", "That cushion deserved it.", "Nothing neat about that.", "Try predicting the next one.", "Ugly shot. Beautiful result.", "Good luck with the leftovers."],
	["Stay focused.", "That's repetition paying off.", "One point at a time.", "Good form. Clean finish.", "Trust the fundamentals.", "No wasted motion.", "Keep the pressure on.", "Eyes on the next one.", "I trained for that angle."],
	["A clean line never fails.", "Presentation matters.", "Precision is always in style.", "That was effortless.", "Less force. More finesse.", "Such a pleasing finish.", "Make every touch count.", "No need to make a scene.", "Perfectly placed."],
	["That's another bar.", "Caught the pocket on beat.", "Two moves ahead of the rhythm.", "Let the chain reaction speak.", "That's a clean drop.", "The board knows my name.", "A little bounce, a lot of flow.", "I don't waste a good setup.", "Run that back."],
	["Target acquired.", "That route was optimal.", "Clean execution.", "The board gave away its weakness.", "Predictable trajectory.", "I found a better path.", "Your defense has an opening.", "Just a simple calculation.", "No glitches this time."]
]
const RIVAL_QUOTE_PEEK_HEIGHT := 167.0
const RIVAL_QUOTE_DISPLAY_TIME := 4.6

const RIVAL_PORTRAITS := [
	preload("res://portraits/rival_01_skateboarder.png"),
	preload("res://portraits/rival_02_gangster.png"),
	preload("res://portraits/rival_03_rocker.png"),
	preload("res://portraits/rival_04_punk.png"),
	preload("res://portraits/rival_05_athlete.png"),
	preload("res://portraits/rival_06_model.png"),
	preload("res://portraits/rival_07_rapper.png"),
	preload("res://portraits/rival_08_hacker.png")
]

var duboo_mode := false
var mode_bar: HBoxContainer
var classic_button: Button
var duboo_button: Button
var desktop_classic_button: Button
var desktop_duboo_button: Button
var style_heading: Label
var style_selector: HBoxContainer
var rules_body: Label
var desktop_rules_scroll: ScrollContainer
var mobile_rules_content: VBoxContainer
var mobile_rules_mode: Label
var mobile_rules_titles: Array[Label] = []
var mobile_rules_descriptions: Array[Label] = []
var mobile_rules_cards: Array[PanelContainer] = []
var rules_title_label: Label
var board: CarromBoard
var discs: Array = []
var auto_battle := false
var auto_battle_button: Button
var auto_advance_time := -1.0
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
var rival_index := 0  # Selected opponent in normal play, BLACK in auto battle.
var auto_rival_index := 0  # Different rival controlling WHITE in spectator mode.
var white_score_heading: Label
var black_score_heading: Label
var rival_card_heading: Label
var auto_rival_card: PanelContainer
var auto_rival_portrait: TextureRect
var auto_rival_name: Label
var auto_rival_bio: Label
var rival_results: Dictionary = {}  # classic_0 -> [player wins, CPU wins, draws]
var rival_match_recorded := false
var rival_portrait: TextureRect
var rival_name: Label
var rival_alias: Label
var rival_type: Label
var rival_bio: Label
var rival_record: Label
var rival_prev_button: Button
var rival_next_button: Button
var rival_drawer: Panel
var rival_drawer_handle: Button
var rival_drawer_scroll: ScrollContainer
var rival_drawer_chevron: Line2D
var rival_drawer_open := false
var rival_drawer_tween: Tween
var rival_quote_box: PanelContainer
var rival_quote_heading: Label
var rival_quote_text: Label
var rival_quote_peek := false
var rival_quote_time := 0.0
var rival_last_quote: Dictionary = {}
var mobile_rival_name: Label
var mobile_rival_bio: Label
var mobile_rival_prev: Button
var mobile_rival_next: Button
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
var mobile_score_cards: Array[PanelContainer] = []
var mobile_header_subtitle: Label
var mobile_turn_accent: ColorRect
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
var mobile_menu_content: VBoxContainer
var mobile_modal_scale := 1.0
# A web phone can report a provisional viewport on the initial draw.
# Reflow after containers and CSS/viewport dimensions have settled.
var mobile_reflow_pending := false
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
# Mobile shot controls use two independent gestures: aim on the board,
# then draw the right-side power grip LEFT and release. The power gesture
# cannot steer the ball or run off the bottom edge of a phone.
var mobile_pull_handle: PanelContainer
var mobile_pull_finger := -1
var mobile_pull_mouse := false
var mobile_pull_origin := Vector2.ZERO
var mobile_pull_length := 0.0
var mobile_pull_idle := 0.0
var mobile_locked_shot_direction := Vector2.UP
var mobile_ignore_synthetic_mouse := 0.0
const MOBILE_PULL_THRESHOLD := 8.0
const MOBILE_PULL_MAX := 190.0

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
	get_viewport().size_changed.connect(_schedule_mobile_reflow)
	_schedule_mobile_reflow()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()
		_schedule_mobile_reflow()
		queue_redraw()

func _schedule_mobile_reflow() -> void:
	if mobile_reflow_pending or not is_inside_tree():
		return
	mobile_reflow_pending = true
	_finish_mobile_reflow()

func _finish_mobile_reflow() -> void:
	# Godot's minimum-size propagation and mobile-browser viewport setup can
	# each happen *after* _ready / NOTIFICATION_RESIZED. Wait for both frames.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_layout()
	await get_tree().process_frame
	if is_inside_tree():
		if portrait_touch:
			_mobile_fit_dialogs()
		mobile_reflow_pending = false

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
	# Leave the bottom drawer tab clear of scrolling match information.
	margin.add_theme_constant_override("margin_bottom", 58 if stats_panel == null else 22)
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
	var heading_label := _label(meta, heading, 11, accent)
	heading_label.clip_text = true
	var coins := _label(meta, "0 / 9 pocketed", 11, MUTED)
	var score := _label(row, "0", 29, TEXT)
	score.size_flags_horizontal = Control.SIZE_SHRINK_END
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return [score, coins, heading_label]

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
	match_info = _label(stats, "QUICK MATCH / ONE BOARD", 14, TEXT, true)
	match_info.custom_minimum_size.y = 38
	var scoreboard := VBoxContainer.new()
	scoreboard.add_theme_constant_override("separation", 8)
	stats.add_child(scoreboard)
	var white_card := _stat_row(scoreboard, "YOU / WHITE", MINT)
	main_score_white = white_card[0]
	coins_white = white_card[1]
	white_score_heading = white_card[2]
	var black_card := _stat_row(scoreboard, "CPU / BLACK", GOLD)
	main_score_black = black_card[0]
	coins_black = black_card[1]
	black_score_heading = black_card[2]
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
	# The opponent profile is independent of the scrolling stats content.
	# Its collapsed handle stays visible; opening it never changes dock width.
	_build_rival_drawer()

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
	_label(info, "SPECTATOR", 11, MINT)
	auto_battle_button = _make_button(info, "AUTO BATTLE  OFF")
	auto_battle_button.pressed.connect(_toggle_auto_battle)
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

func _build_rival_drawer() -> void:
	# This is a *child* of stats_panel, not a sibling in the board layout.
	# It slides vertically within exactly the existing 244px dock bounds.
	rival_drawer = Panel.new()
	rival_drawer.name = "RivalDrawer"
	rival_drawer.clip_contents = true
	rival_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	var drawer_skin := _style(Color("#1b3731"), EDGE, 12)
	drawer_skin.content_margin_left = 0.0
	drawer_skin.content_margin_right = 0.0
	drawer_skin.content_margin_top = 0.0
	drawer_skin.content_margin_bottom = 0.0
	rival_drawer.add_theme_stylebox_override("panel", drawer_skin)
	stats_panel.add_child(rival_drawer)

	rival_drawer_handle = Button.new()
	rival_drawer_handle.name = "RivalDrawerHandle"
	rival_drawer_handle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	rival_drawer_handle.clip_text = true
	rival_drawer_handle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	rival_drawer_handle.focus_mode = Control.FOCUS_NONE
	rival_drawer_handle.add_theme_font_size_override("font_size", 11)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := Color("#295047") if state == "hover" else Color("#26483f")
		var edge := MINT if state == "hover" else EDGE
		var head_style := _style(fill, edge, 8)
		head_style.content_margin_left = 12.0
		head_style.content_margin_right = 36.0
		head_style.content_margin_top = 3.0
		head_style.content_margin_bottom = 3.0
		rival_drawer_handle.add_theme_stylebox_override(state, head_style)
	rival_drawer_handle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	rival_drawer_handle.add_theme_color_override("font_color", MINT)
	rival_drawer_handle.add_theme_color_override("font_hover_color", TEXT)
	rival_drawer_handle.add_theme_color_override("font_pressed_color", TEXT)
	rival_drawer_handle.pressed.connect(_toggle_rival_drawer)
	rival_drawer.add_child(rival_drawer_handle)

	# Draw the chevron ourselves: no dependency on special font characters.
	rival_drawer_chevron = Line2D.new()
	rival_drawer_chevron.points = PackedVector2Array([
		Vector2(-10.0, 4.0), Vector2(0.0, -4.0), Vector2(10.0, 4.0)
	])
	rival_drawer_chevron.width = 2.4
	rival_drawer_chevron.default_color = MINT
	rival_drawer_chevron.antialiased = true
	rival_drawer_handle.add_child(rival_drawer_chevron)

	rival_drawer_scroll = ScrollContainer.new()
	rival_drawer_scroll.name = "RivalDrawerContent"
	rival_drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rival_drawer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rival_drawer_scroll.clip_contents = true
	rival_drawer.add_child(rival_drawer_scroll)
	var content := VBoxContainer.new()
	content.name = "RivalProfile"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	rival_drawer_scroll.add_child(content)
	# An event-driven speech panel inside the existing drawer, never on the board.
	rival_quote_box = PanelContainer.new()
	rival_quote_box.add_theme_stylebox_override("panel", _style(Color("#28483f"), EDGE_SOFT, 10))
	content.add_child(rival_quote_box)
	var speech := VBoxContainer.new()
	speech.add_theme_constant_override("separation", 3)
	rival_quote_box.add_child(speech)
	rival_quote_heading = _label(speech, "", 10, GOLD, true)
	rival_quote_text = _label(speech, "", 12, TEXT, true)
	rival_quote_text.custom_minimum_size.y = 48.0
	rival_quote_box.hide()
	_build_auto_rival_card(content)
	_build_rival_card(content)
	_refresh_rival_drawer_handle()

func _refresh_rival_drawer_handle() -> void:
	if rival_drawer_handle == null:
		return
	if rival_drawer_open:
		rival_drawer_handle.text = "BACK TO MATCH"
	else:
		rival_drawer_handle.text = "RIVALS  /  MATCHUP" if auto_battle else "RIVAL  /  " + str(RIVALS[rival_index]["alias"])
	if rival_drawer_chevron != null:
		rival_drawer_chevron.rotation = PI if rival_drawer_open else 0.0

func _rival_drawer_target_y() -> float:
	if rival_drawer_open:
		return 0.0
	var height := stats_panel.size.y
	if rival_quote_peek:
		return maxf(0.0, height - minf(RIVAL_QUOTE_PEEK_HEIGHT, height * 0.75))
	return maxf(0.0, height - RIVAL_DRAWER_HANDLE_HEIGHT)

func _animate_rival_drawer() -> void:
	if rival_drawer == null or portrait_touch:
		return
	if rival_drawer_tween != null and rival_drawer_tween.is_running():
		rival_drawer_tween.kill()
	rival_drawer_tween = create_tween()
	rival_drawer_tween.set_trans(Tween.TRANS_CUBIC)
	rival_drawer_tween.set_ease(Tween.EASE_OUT)
	rival_drawer_tween.tween_property(rival_drawer, "position:y", _rival_drawer_target_y(), 0.27)

func _show_rival_pocket_quote(actor: int) -> void:
	if rival_quote_box == null:
		return
	var actor_index := _rival_for_player(actor)
	var lines: Array = RIVAL_POCKET_QUOTES[actor_index]
	var previous := int(rival_last_quote.get(actor_index, -1))
	var pick := randi_range(0, lines.size() - 1 if previous < 0 else lines.size() - 2)
	if previous >= 0 and pick >= previous:
		pick += 1
	rival_last_quote[actor_index] = pick
	rival_quote_heading.text = str(RIVALS[actor_index]["alias"]) + "  /  POCKETED"
	rival_quote_text.text = str(lines[pick])
	rival_quote_box.show()
	rival_drawer_scroll.scroll_vertical = 0
	if not rival_drawer_open and not portrait_touch:
		rival_quote_peek = true
		rival_quote_time = RIVAL_QUOTE_DISPLAY_TIME
		_animate_rival_drawer()

func _layout_rival_drawer() -> void:
	if rival_drawer == null or stats_panel == null:
		return
	# Resizing is authoritative: no old tween can leave the drawer partly out.
	if rival_drawer_tween != null and rival_drawer_tween.is_running():
		rival_drawer_tween.kill()
	var width := stats_panel.size.x
	var height := stats_panel.size.y
	rival_drawer.size = Vector2(width, height)
	rival_drawer.position = Vector2(0.0, _rival_drawer_target_y())
	rival_drawer_handle.position = Vector2(7.0, 4.0)
	rival_drawer_handle.size = Vector2(maxf(0.0, width - 14.0), RIVAL_DRAWER_HANDLE_HEIGHT - 8.0)
	rival_drawer_chevron.position = Vector2(rival_drawer_handle.size.x - 23.0, rival_drawer_handle.size.y * 0.5)
	rival_drawer_scroll.position = Vector2(12.0, RIVAL_DRAWER_HANDLE_HEIGHT + 6.0)
	rival_drawer_scroll.size = Vector2(maxf(0.0, width - 24.0), maxf(0.0, height - RIVAL_DRAWER_HANDLE_HEIGHT - 20.0))

func _toggle_rival_drawer() -> void:
	if portrait_touch or rival_drawer == null:
		return
	rival_drawer_open = not rival_drawer_open
	rival_quote_peek = false
	rival_quote_time = 0.0
	_animate_rival_drawer()
	_refresh_rival_drawer_handle()
	if rival_drawer_open:
		rival_drawer_scroll.scroll_vertical = 0
	if sound_click != null:
		sound_click.play()

func _build_auto_rival_card(parent: VBoxContainer) -> void:
	# The second rival uses the same roster portraits and shot personalities.
	# This compact challenger card appears only for spectator matches.
	auto_rival_card = PanelContainer.new()
	auto_rival_card.add_theme_stylebox_override("panel", _style(PANEL_ALT, EDGE_SOFT, 10))
	parent.add_child(auto_rival_card)
	var lineup := HBoxContainer.new()
	lineup.add_theme_constant_override("separation", 10)
	auto_rival_card.add_child(lineup)
	auto_rival_portrait = TextureRect.new()
	auto_rival_portrait.custom_minimum_size = Vector2(75.0, 96.0)
	auto_rival_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	auto_rival_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	auto_rival_portrait.clip_contents = true
	lineup.add_child(auto_rival_portrait)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 4)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lineup.add_child(details)
	_label(details, "WHITE / CHALLENGER", 10, MINT, true)
	auto_rival_name = _label(details, "", 13, TEXT, true)
	auto_rival_bio = _label(details, "", 10, MUTED, true)
	auto_rival_card.hide()

func _build_rival_card(parent: VBoxContainer) -> void:
	# Fixed-width opponent card with vertically stacked identity.
	rival_card_heading = _label(parent, "CLUB OPPONENT", 11, MINT)

	var card := PanelContainer.new()
	var skin := _style(PANEL_ALT, EDGE_SOFT, 10)
	skin.content_margin_left = 8.0
	skin.content_margin_right = 8.0
	skin.content_margin_top = 9.0
	skin.content_margin_bottom = 9.0
	card.add_theme_stylebox_override("panel", skin)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(column)

	# Portrait - full card width, above all identity text.
	rival_portrait = TextureRect.new()
	rival_portrait.custom_minimum_size = Vector2(0.0, 180.0)
	rival_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rival_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rival_portrait.clip_contents = true
	rival_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(rival_portrait)

	# Identity - stacked vertically below portrait.
	var text_column := VBoxContainer.new()
	text_column.add_theme_constant_override("separation", 2)
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(text_column)

	rival_type = _label(
		text_column, "THE SKATEBOARDER", 10, MUTED, true
	)

	rival_name = _label(
		text_column, "DIEGO SOLIS", 13, TEXT, true
	)

	rival_alias = _label(
		text_column, "KICKFLIP", 11, GOLD, true
	)

	# Biography.
	rival_bio = _label(column, "", 11, MUTED, true)

	# Head-to-head record.
	rival_record = _label(column, "", 10, MINT, true)

	# Opponent navigation.
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	column.add_child(nav)

	rival_prev_button = _make_button(nav, "PREV")
	rival_next_button = _make_button(nav, "NEXT")

	for button in [rival_prev_button, rival_next_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 29.0
		button.add_theme_font_size_override("font_size", 11)

		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			style.content_margin_top = 3.0
			style.content_margin_bottom = 3.0
			style.content_margin_left = 6.0
			style.content_margin_right = 6.0
			button.add_theme_stylebox_override(state, style)

	rival_prev_button.pressed.connect(
		func() -> void: _set_rival(rival_index - 1)
	)
	rival_next_button.pressed.connect(
		func() -> void: _set_rival(rival_index + 1)
	)

	_refresh_rival_card()

func _rival_for_player(side: int) -> int:
	# The existing black rival remains selected by PREV/NEXT.
	# Auto battle assigns WHITE a separate identity and planning profile.
	return auto_rival_index if auto_battle and side == 0 else rival_index

func _rival_alias_for_player(side: int) -> String:
	return str(RIVALS[_rival_for_player(side)]["alias"])

func _choose_auto_rival() -> void:
	# Never allow a rival to play against itself. Re-roll once per new match.
	var opponent := randi_range(0, RIVALS.size() - 2)
	if opponent >= rival_index:
		opponent += 1
	auto_rival_index = opponent

func _rival_key() -> String:
	return "%s_%d" % ["duboo" if duboo_mode else "classic", rival_index]

func _refresh_rival_card() -> void:
	if rival_portrait == null:
		return
	var profile: Dictionary = RIVALS[rival_index]
	rival_portrait.texture = RIVAL_PORTRAITS[rival_index]
	rival_name.text = str(profile["name"])
	rival_alias.text = str(profile["alias"])
	rival_type.text = str(profile["type"])
	rival_bio.text = str(profile["bio"])
	_refresh_rival_drawer_handle()
	var results: Array = rival_results.get(_rival_key(), [0, 0, 0])
	rival_record.text = "VS YOU  %d W  /  %d L  /  %d D" % [int(results[1]), int(results[0]), int(results[2])]
	if auto_battle:
		rival_record.text = "SPECTATOR / NO RECORD KEPT"
	if rival_card_heading != null:
		rival_card_heading.text = "BLACK / RIVAL" if auto_battle else "CLUB OPPONENT"
	if auto_rival_card != null:
		auto_rival_card.visible = auto_battle
		if auto_battle:
			var challenger: Dictionary = RIVALS[auto_rival_index]
			auto_rival_portrait.texture = RIVAL_PORTRAITS[auto_rival_index]
			auto_rival_name.text = str(challenger["alias"])
			auto_rival_bio.text = str(challenger["name"])
	if mobile_rival_name != null:
		_mobile_refresh_menu()

func _set_rival(next_index: int) -> void:
	var new_index := posmod(next_index, RIVALS.size())
	if new_index == rival_index:
		return
	rival_quote_peek = false
	rival_quote_time = 0.0
	if rival_quote_box != null:
		rival_quote_box.hide()
	rival_index = new_index
	var config := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	config.set_value("rivals", "selected", rival_index)
	config.save(SETTINGS_PATH)
	_refresh_rival_card()
	# Avoid swapping a CPU's identity midway through its active match.
	_new_match()
	if sound_click != null:
		sound_click.play()

func _record_rival_match(result: int) -> void:
	# result 0 = human win; 1 = rival win; 2 = draw.
	if rival_match_recorded:
		return
	rival_match_recorded = true
	var key := _rival_key()
	var counts: Array = rival_results.get(key, [0, 0, 0]).duplicate()
	counts[clampi(result, 0, 2)] = int(counts[clampi(result, 0, 2)]) + 1
	rival_results[key] = counts
	var config := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	config.set_value("rivals", key + "_win", int(counts[0]))
	config.set_value("rivals", key + "_loss", int(counts[1]))
	config.set_value("rivals", key + "_draw", int(counts[2]))
	config.set_value("rivals", "selected", rival_index)
	config.save(SETTINGS_PATH)
	_refresh_rival_card()

func _mobile_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := _label(parent, value, font_size, color, false)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	return label

func _mobile_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var skin := _style(Color("#1c3933"), Color("#48685e"), 13)
	skin.content_margin_left = 13.0
	skin.content_margin_right = 13.0
	skin.content_margin_top = 8.0
	skin.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", skin)
	panel.visible = false
	add_child(panel)
	return panel

func _mobile_score_tile(parent: HBoxContainer, accent: Color) -> VBoxContainer:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.size_flags_stretch_ratio = 1.0
	var skin := _style(Color("#1d3a34"), Color("#41665a"), 14)
	skin.content_margin_left = 6.0
	skin.content_margin_right = 6.0
	skin.content_margin_top = 7.0
	skin.content_margin_bottom = 7.0
	skin.border_width_top = 2
	skin.border_color = accent.darkened(0.3)
	tile.add_theme_stylebox_override("panel", skin)
	parent.add_child(tile)
	mobile_score_cards.append(tile)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 2)
	tile.add_child(stack)
	return stack

func _mobile_game_tab_skin(b: Button, selected: bool, u: float) -> void:
	# Independent segmented-tab treatment, intentionally not imposed on the
	# hamburger menu, gamepad or desktop buttons.
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := MINT if selected else Color("#1c3731")
		if state == "pressed":
			fill = Color("#66cbb3") if selected else Color("#294b41")
		elif state == "hover" and not selected:
			fill = Color("#28483e")
		var skin := _style(fill, Color("#8ae0cc") if selected else Color("#45685d"), maxi(11, int(round(13.0 * u))))
		skin.content_margin_left = 8.0 * u
		skin.content_margin_right = 8.0 * u
		skin.content_margin_top = 4.0 * u
		skin.content_margin_bottom = 4.0 * u
		b.add_theme_stylebox_override(state, skin)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := INK if selected else TEXT
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(state, ink)

func _build_mobile_ui() -> void:
	# Phone UI has its own hierarchy; no desktop sidebar is scaled onto a phone.
	mobile_match_label = _mobile_label(self, "BOARD 1 / 8", 16, GOLD)
	mobile_match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mobile_match_label.visible = false
	# The game screen is NOT a scaled desktop dock. Compact modular cards,
	# deliberately different from the settings sheet, keep the board dominant.
	mobile_header_subtitle = _mobile_label(self, "A TABLETOP CLASSIC", 10, MUTED)
	mobile_header_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mobile_header_subtitle.visible = false

	# Three balanced tiles make both scores immediately readable. They sit on
	# their own transparent surface rather than inside another large box.
	mobile_score_panel = _mobile_panel()
	mobile_score_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 6)
	mobile_score_panel.add_child(scores)
	var you_stack := _mobile_score_tile(scores, MINT)
	mobile_score_headings.append(_mobile_label(you_stack, "YOU / WHITE", 12, MINT))
	mobile_you = _mobile_label(you_stack, "0 PTS / 0", 19, TEXT)
	var queen_stack := _mobile_score_tile(scores, Color("#e88683"))
	mobile_score_headings.append(_mobile_label(queen_stack, "QUEEN", 12, Color("#e88683")))
	mobile_queen = _mobile_label(queen_stack, "ON BOARD", 12, TEXT)
	var cpu_stack := _mobile_score_tile(scores, GOLD)
	mobile_score_headings.append(_mobile_label(cpu_stack, "CPU / BLACK", 12, GOLD))
	mobile_cpu = _mobile_label(cpu_stack, "0 PTS / 0", 19, TEXT)

	# Low-profile feedback. The colour rail communicates whose turn it is,
	# leaving one quiet strip with an explicit action hint.
	mobile_status_panel = _mobile_panel()
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 9)
	mobile_status_panel.add_child(status_row)
	mobile_turn_accent = ColorRect.new()
	mobile_turn_accent.color = MINT
	mobile_turn_accent.custom_minimum_size.x = 3.0
	mobile_turn_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(mobile_turn_accent)
	var status_stack := VBoxContainer.new()
	status_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	status_stack.add_theme_constant_override("separation", 2)
	status_row.add_child(status_stack)
	mobile_status_title = _mobile_label(status_stack, "YOUR BREAK", 15, MINT)
	mobile_status_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mobile_status_hint = _mobile_label(status_stack, "SLIDE STRIKER ON BASELINE", 12, TEXT)
	mobile_status_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Independent touch shot control. Aim with a gesture on the board;
	# drag the grip horizontally within this dock to choose strength.
	mobile_power_panel = _mobile_panel()
	var power_column := VBoxContainer.new()
	power_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_column.alignment = BoxContainer.ALIGNMENT_CENTER
	power_column.add_theme_constant_override("separation", 5)
	mobile_power_panel.add_child(power_column)
	var power_stack := VBoxContainer.new()
	power_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_stack.add_theme_constant_override("separation", 5)
	power_column.add_child(power_stack)
	mobile_power_label = _mobile_label(power_stack, "PULL THE GRIP LEFT", 14, MUTED)
	mobile_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mobile_power_meter = ProgressBar.new()
	mobile_power_meter.min_value = 0.0
	mobile_power_meter.max_value = 100.0
	mobile_power_meter.show_percentage = false
	mobile_power_meter.custom_minimum_size.y = 9.0
	mobile_power_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_power_meter.add_theme_stylebox_override("background", _style(Color("#102522"), Color.TRANSPARENT, 7))
	mobile_power_meter.add_theme_stylebox_override("fill", _style(MINT, Color.TRANSPARENT, 7))
	power_stack.add_child(mobile_power_meter)
	mobile_fire = _make_button(power_column, "SLIDE LEFT", false)
	mobile_fire.custom_minimum_size = Vector2(0.0, 55.0)
	mobile_fire.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_fire.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Global input captures pull/release even outside the decorative control.
	mobile_fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_fire.add_theme_stylebox_override("disabled", _style(Color("#31584e"), EDGE_SOFT, 14))
	mobile_fire.add_theme_color_override("font_disabled_color", TEXT)
	# An obvious physical grip, not a tiny invisible gesture hotspot.
	mobile_pull_handle = PanelContainer.new()
	mobile_pull_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grip_skin := _style(MINT, Color("#a6f2d7"), 12)
	grip_skin.content_margin_left = 6.0
	grip_skin.content_margin_right = 6.0
	mobile_pull_handle.add_theme_stylebox_override("panel", grip_skin)
	mobile_fire.add_child(mobile_pull_handle)
	var grip_text := _mobile_label(mobile_pull_handle, "PULL", 13, INK)
	grip_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grip_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_fire.resized.connect(_mobile_position_pull_grip)

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
	mobile_menu_scrim.color = Color(0.01, 0.06, 0.05, 0.83)
	mobile_menu_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_menu_scrim.visible = false
	mobile_menu_scrim.gui_input.connect(_mobile_menu_outside_input)
	add_child(mobile_menu_scrim)

	mobile_menu_panel = PanelContainer.new()
	var menu_skin := _style(Color("#1b3832"), Color("#719889"), 19)
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
	# Portrait-only settings sheet: every item is in one readable, non-scrolling
	# column. Blank space is reserved around the entire composition, NEVER
	# inserted between its controls.
	mobile_menu_content = VBoxContainer.new()
	mobile_menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_menu_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mobile_menu_content.add_theme_constant_override("separation", 8)
	mobile_menu_panel.add_child(mobile_menu_content)
	var menu_content := mobile_menu_content

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
	design_panel.name = "MenuDesignPanel"
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

	var rival_divider := HSeparator.new()
	rival_divider.name = "MenuRivalDivider"
	rival_divider.add_theme_color_override("color", EDGE_SOFT)
	menu_content.add_child(rival_divider)
	_label(menu_content, "YOUR RIVAL", 12, MINT)
	var mobile_rival_row := HBoxContainer.new()
	mobile_rival_row.name = "MenuRivalChoices"
	mobile_rival_row.add_theme_constant_override("separation", 7)
	menu_content.add_child(mobile_rival_row)
	mobile_rival_prev = _make_button(mobile_rival_row, "PREV")
	mobile_rival_prev.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mobile_rival_prev.pressed.connect(func() -> void: _set_rival(rival_index - 1))
	mobile_rival_name = _label(mobile_rival_row, "DIEGO SOLIS", 14, TEXT, true)
	mobile_rival_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mobile_rival_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mobile_rival_next = _make_button(mobile_rival_row, "NEXT")
	mobile_rival_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	mobile_rival_next.pressed.connect(func() -> void: _set_rival(rival_index + 1))
	mobile_rival_bio = _label(menu_content, "", 12, MUTED, true)

	var actions_divider := HSeparator.new()
	actions_divider.name = "MenuActionsDivider"
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
	var footnote := _mobile_label(menu_content, "NEW RIVAL STARTS A FRESH MATCH", 11, MUTED)
	footnote.name = "MenuFootnote"
	footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# No expanding spacer nodes: they formerly pushed the rival, Rules and
	# Restart controls entirely below the screen on high-density phones.
	menu_content.alignment = BoxContainer.ALIGNMENT_CENTER
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
	# Opening a previously hidden Container changes its measured minimum.
	# Always fit from the real portrait viewport, including the very first tap.
	_layout()
	_schedule_mobile_reflow()
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
		_mobile_button_skin(mobile_menu_difficulties[i], i == cpu_skill, mobile_modal_scale)
	if mobile_rival_name != null:
		var selected: Dictionary = RIVALS[rival_index]
		mobile_rival_name.text = str(selected["name"]) + "\n" + str(selected["alias"])
		mobile_rival_bio.text = ("BLACK RIVAL / WHITE FACES %s" % _rival_alias_for_player(0)) if auto_battle else str(selected["bio"])
	if mobile_menu_restart != null:
		mobile_menu_restart.text = "NEW BOARD" if duboo_mode else "RESTART"
	if mobile_menu_next_board != null:
		mobile_menu_next_board.visible = phase == "board_over" and not duboo_mode
	# Rival text and the NEXT BOARD action can change the dialog's minimum.
	if mobile_menu_open and portrait_touch:
		call_deferred("_mobile_fit_dialogs")


func _mobile_sync() -> void:
	if mobile_score_panel == null:
		return
	mobile_you.text = "%d / 9" % _pocketed_count("white") if duboo_mode else "%d PTS / %d" % [totals[0], _pocketed_count("white")]
	mobile_cpu.text = "%d / 9" % _pocketed_count("black") if duboo_mode else "%d PTS / %d" % [totals[1], _pocketed_count("black")]
	if mobile_score_headings.size() >= 3:
		mobile_score_headings[0].text = "WHITE\n%s" % _rival_alias_for_player(0) if auto_battle else "YOU / WHITE"
		mobile_score_headings[2].text = "BLACK\n%s" % _rival_alias_for_player(1) if auto_battle else "CPU / BLACK"
	if pending_queen >= 0:
		mobile_queen.text = ("WHITE COVER" if pending_queen == 0 else "BLACK COVER") if auto_battle else ("COVER IT" if pending_queen == 0 else "CPU COVER")
	elif queen_owner >= 0:
		mobile_queen.text = ("WHITE HAS IT" if queen_owner == 0 else "BLACK HAS IT") if auto_battle else ("YOURS" if queen_owner == 0 else "CPU HAS IT")
	else:
		mobile_queen.text = "ON BOARD"
	mobile_status_title.text = status_title
	if phase == "placement":
		mobile_status_hint.text = "SLIDE STRIKER ON BASELINE"
	elif phase == "aim":
		mobile_status_hint.text = "AIM ON BOARD  /  PULL LEFT"
	elif phase == "charging":
		mobile_status_hint.text = "RELEASE GRIP TO SHOOT"
	elif phase == "moving":
		mobile_status_hint.text = "WAIT FOR PIECES TO STOP"
	elif phase in ["cpu_aim", "cpu_think", "cpu_search"]:
		mobile_status_hint.text = "RIVAL PLAYING" if auto_battle else "OPPONENT PLAYING"
	elif phase == "board_over":
		mobile_status_hint.text = "OPEN MENU TO CONTINUE"
	else:
		mobile_status_hint.text = "MATCH IN PROGRESS"
	mobile_power_label.text = "POWER  %d%%" % int(round(charge_power * 100.0)) if phase == "charging" else "PULL THE GRIP LEFT"
	mobile_power_meter.value = charge_power * 100.0 if phase == "charging" else 0.0
	mobile_fire.disabled = phase not in ["aim", "charging"] or player_turn != 0 or rules_overlay.visible
	_mobile_position_pull_grip()
	mobile_match_label.text = "DUBOO  /  01" if duboo_mode else "BOARD  %02d / %02d" % [board_number, MAX_BOARD_COUNT]
	mobile_header_subtitle.text = "SLATE TABLE EDITION" if duboo_mode else "A TABLETOP CLASSIC"
	mobile_turn_accent.color = MINT if player_turn == 0 else GOLD
	mobile_status_title.add_theme_color_override("font_color", MINT if player_turn == 0 else GOLD)
	_mobile_refresh_menu()

func _mobile_position_pull_grip() -> void:
	if mobile_pull_handle == null or mobile_fire == null:
		return
	var u := mobile_mobile_scale
	var handle_w := minf(mobile_fire.size.x * 0.30, 72.0 * u)
	var handle_h := maxf(28.0, mobile_fire.size.y - 8.0 * u)
	mobile_pull_handle.size = Vector2(handle_w, handle_h)
	var slide := minf(mobile_pull_length, maxf(0.0, mobile_fire.size.x - handle_w - 8.0 * u))
	mobile_pull_handle.position = Vector2(maxf(4.0 * u, mobile_fire.size.x - handle_w - 4.0 * u - slide), (mobile_fire.size.y - handle_h) * 0.5)
	(mobile_pull_handle.get_child(0) as Label).add_theme_font_size_override("font_size", maxi(11, int(round(13.0 * u))))
	var grip_skin := _style(GOLD if mobile_pull_finger >= 0 or mobile_pull_mouse else MINT, Color("#a6f2d7"), maxi(9, int(12.0 * u)))
	grip_skin.content_margin_left = 3.0 * u
	grip_skin.content_margin_right = 3.0 * u
	mobile_pull_handle.add_theme_stylebox_override("panel", grip_skin)

func _mobile_fire_visual(held: bool) -> void:
	if mobile_fire == null:
		return
	if portrait_touch:
		_mobile_button_skin(mobile_fire, false, mobile_mobile_scale)
	else:
		_apply_button_skin(mobile_fire, false)
	var u := mobile_mobile_scale
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := mobile_fire.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		skin.bg_color = Color("#1a4038") if state != "disabled" else Color("#203932")
		skin.border_color = GOLD if held else EDGE_SOFT
		skin.set_corner_radius_all(maxi(10, int(round(13.0 * u))))
		skin.content_margin_top = 3.0 * u
		skin.content_margin_bottom = 3.0 * u
		mobile_fire.add_theme_stylebox_override(state, skin)
	mobile_fire.add_theme_color_override("font_color", TEXT)
	_mobile_position_pull_grip()

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
		mobile_fire.text = "SLIDE LEFT"
	_mobile_position_pull_grip()

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
	# Desktop retains its detailed scrollable reference. Portrait has a
	# separately typeset, concise six-section guide that never scrolls.
	rules_overlay = PanelContainer.new()
	rules_overlay.visible = false
	rules_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_skin := _style(Color("#193630"), Color("#719889"), 19)
	panel_skin.content_margin_left = 14.0
	panel_skin.content_margin_right = 14.0
	panel_skin.content_margin_top = 14.0
	panel_skin.content_margin_bottom = 14.0
	rules_overlay.add_theme_stylebox_override("panel", panel_skin)
	add_child(rules_overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	rules_overlay.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	rules_title_label = _label(header, "CARROM  /  RULES", 21, MINT)
	rules_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rules_close_button = _make_button(header, "CLOSE", true)
	rules_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	rules_close_button.custom_minimum_size = Vector2(94, 46)
	rules_close_button.pressed.connect(_close_rules)
	var separator := HSeparator.new()
	separator.add_theme_color_override("color", EDGE_SOFT)
	column.add_child(separator)

	desktop_rules_scroll = ScrollContainer.new()
	desktop_rules_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desktop_rules_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desktop_rules_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(desktop_rules_scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	desktop_rules_scroll.add_child(details)
	rules_body = _label(details,
		"OBJECTIVE\nYou are WHITE. Pocket all nine white pieces, with the red Queen legally covered, to win the board. The CPU plays BLACK.\n\nTURNS\nWhite breaks. You keep shooting whenever you pocket at least one of your own pieces; otherwise the turn passes. Opponent pieces remain pocketed if you sink them.\n\nTHE QUEEN\nYou must pocket one of your own pieces before you can claim the Queen. Pocket the Queen and one of your own pieces in the same shot, or pocket your own piece on your very next shot to cover it. An uncovered Queen returns to the center. If you capture the Queen together with your very first piece, a further cover is required.\n\nSTRIKER FOUL\nPocketing the striker costs one of your previously pocketed pieces (or incurs one owed piece if none is available), and ends your turn.\n\nSCORING\nThe board winner scores one point for each opponent piece left on the board. The Queen adds three points if secured by the winner, or one when their pre-board match score is at least 22. First to 25 points or the leader after eight boards wins.\n\nThis is a playable standard-rules adaptation: specialist referee calls and uncommon compound fouls are simplified.",
		14, TEXT, true)

	mobile_rules_content = VBoxContainer.new()
	mobile_rules_content.visible = false
	mobile_rules_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_rules_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mobile_rules_content.add_theme_constant_override("separation", 7)
	column.add_child(mobile_rules_content)
	mobile_rules_mode = _label(mobile_rules_content, "CLASSIC  /  QUICK GUIDE", 11, GOLD)
	for i in range(6):
		var section := PanelContainer.new()
		section.size_flags_vertical = Control.SIZE_FILL
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var skin := _style(PANEL_ALT, Color("#446b60"), 12)
		skin.content_margin_left = 9.0
		skin.content_margin_right = 9.0
		skin.content_margin_top = 6.0
		skin.content_margin_bottom = 6.0
		section.add_theme_stylebox_override("panel", skin)
		mobile_rules_content.add_child(section)
		mobile_rules_cards.append(section)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		section.add_child(row)
		var number := _label(row, "%02d" % (i + 1), 12, GOLD)
		number.custom_minimum_size.x = 22.0
		number.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		copy.add_theme_constant_override("separation", 2)
		row.add_child(copy)
		mobile_rules_titles.append(_label(copy, "", 12, MINT))
		mobile_rules_descriptions.append(_label(copy, "", 12, TEXT, true))

	rules_footer_button = _make_button(column, "RETURN TO GAME", true)
	rules_footer_button.custom_minimum_size.y = 50.0
	rules_footer_button.pressed.connect(_close_rules)
	_mobile_refresh_rules()

func _mobile_refresh_rules() -> void:
	if mobile_rules_content == null:
		return
	var touch := "Slide striker on baseline. Tap or drag board to aim. Pull grip LEFT for power, then release."
	var sections: Array = []
	if duboo_mode:
		mobile_rules_mode.text = "DUBOO  /  SINGLE BOARD"
		sections = [
			["OBJECTIVE", "Pocket your nine pieces and secure the red Queen. The CPU plays black."],
			["TAKING TURNS", "Pocket your colour to play again. Otherwise the CPU takes over."],
			["THE QUEEN", "Pocket one of yours first. Cover the Queen on the same shot or your next shot, or it returns."],
			["THE RING", "The large ring cannot enter a pocket, so ring-pocket fouls do not occur. Physics are approximate."],
			["WINNING", "Complete one board to win. Select NEW BOARD for another match."],
			["TOUCH CONTROLS", touch]
		]
	else:
		mobile_rules_mode.text = "CLASSIC  /  SINGLE BOARD"
		sections = [
			["OBJECTIVE", "Pocket all nine white pieces and secure the Queen. The CPU plays black."],
			["TAKING TURNS", "White breaks. Pocket your colour to play again; otherwise turns switch."],
			["THE QUEEN", "Pocket one of yours first. Cover the Queen now or on your next shot, or it returns. Your first piece alone cannot cover it."],
			["STRIKER FOUL", "Pocketing the striker ends your turn and returns one piece, or creates a debt."],
			["SCORING", "Earn 1 point per opponent piece left. The Queen adds 3, or 1 at 22+ match points. One-board match."],
			["TOUCH CONTROLS", touch]
		]
	# The guide intentionally becomes shorter *before* the dialog fills a
	# phone's available height, rather than relying on a scroll view.
	var compact := portrait_touch and (size.x < 410.0 or size.y < 900.0)
	if compact:
		if duboo_mode:
			sections = [
				["OBJECTIVE & TURNS", "Pocket nine of your colour and secure the Queen. Pocket yours to play again."],
				["THE QUEEN", "Take one of yours first. Cover the Queen on the same or next shot, or it returns."],
				["RING & WIN", "The ring cannot be pocketed. Win one board; NEW BOARD starts another."],
				["TOUCH CONTROLS", touch]
			]
		else:
			sections = [
				["OBJECTIVE & TURNS", "Pocket nine white pieces. White breaks; pocket yours to play again."],
				["THE QUEEN", "Take one of yours first. Cover the Queen now or next shot, or it returns. Your first piece needs a later cover."],
				["FOUL & SCORE", "Striker pocket ends your turn and costs a piece. Score pieces left; Queen adds 3 (1 at 22+)."],
				["TOUCH CONTROLS", touch]
			]
	if portrait_touch and (size.y < 555.0 or size.x < 305.0):
		if duboo_mode:
			sections = [
				["PLAY", "Pocket your nine pieces and the Queen. Pot yours to take another shot."],
				["QUEEN & RING", "Take a piece first; cover the Queen now or next. The ring cannot be pocketed."],
				["CONTROLS", "Slide striker on baseline. Aim on the board. Pull grip LEFT and release to shoot."]
			]
		else:
			sections = [
				["PLAY", "Pocket nine white pieces. Pot yours to play again; cover the Queen now or next."],
				["FOUL & SCORE", "A pocketed striker costs a piece and ends your turn. Count remaining CPU pieces; Queen adds points."],
				["CONTROLS", "Slide striker on baseline. Aim on the board. Pull grip LEFT and release to shoot."]
			]
	for i in range(mobile_rules_cards.size()):
		mobile_rules_cards[i].visible = i < sections.size()
		if i < sections.size():
			mobile_rules_titles[i].text = str(sections[i][0])
			mobile_rules_descriptions[i].text = str(sections[i][1])

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
			_mobile_game_tab_skin(b, selected, mobile_mobile_scale)
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
	_mobile_refresh_rules()
	_refresh_board_style_ui()
	_refresh_rival_card()
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
	var tall_screen := sz.y > sz.x * 1.06
	# Android phones and tablets need touch controls even when rotated.
	# Desktop landscape retains the original mouse UI.
	var should_touch := tall_screen or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	if should_touch != portrait_touch:
		_mobile_close_menu()
		_cancel_mobile_charge()
		mobile_board_finger = -1
		mobile_board_mouse_down = false
		portrait_touch = should_touch
		if portrait_touch and phase == "placement" and player_turn == 0:
			phase = "aim"
			board.show_aim = true
			board.side = 0
	if desktop_rules_scroll != null:
		desktop_rules_scroll.visible = not portrait_touch
		mobile_rules_content.visible = portrait_touch
		rules_footer_button.visible = not portrait_touch
	if portrait_touch:
		if tall_screen:
			_layout_portrait(sz)
		else:
			_layout_touch_landscape(sz)
		return
	for mobile_node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_match_label, mobile_menu_button, mobile_header_subtitle]:
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
	_layout_rival_drawer()
	side_panel.position = Vector2(sz.x - info_w - gutter, gutter)
	side_panel.size = Vector2(info_w, maxf(170.0, sz.y - 2.0 * gutter))
	cpu_selector.get_popup().min_size = Vector2i(maxi(176, int(info_w - 44.0)), 0)
	var dialog_size := Vector2(minf(640.0, sz.x - 65.0), minf(740.0, sz.y - 42.0))
	rules_overlay.position = (sz - dialog_size) * 0.5
	rules_overlay.size = dialog_size

func _layout_touch_landscape(sz: Vector2) -> void:
	# Tablet landscape: board on the left, actual touch controls to the right.
	# Unlike the desktop sidebar, the shot grip remains available to fingers.
	title_label.show()
	mobile_header_subtitle.show()
	mode_bar.show()
	stats_panel.hide()
	side_panel.hide()
	board_caption.hide()
	tip_label.hide()
	for node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_match_label, mobile_menu_button]:
		node.show()
	var u := clampf(minf(sz.y / 580.0, sz.x / 950.0), 0.53, 1.3)
	mobile_mobile_scale = u
	var gutter := 11.0 * u
	var board_width := minf(sz.y - 2.0 * gutter, sz.x * 0.60)
	var board_scale := board_width / 766.0
	board.scale = Vector2.ONE * board_scale
	var board_y := (sz.y - board_width) * 0.5
	board.position = Vector2(gutter + 43.0 * board_scale, board_y + 43.0 * board_scale)
	var right_x := gutter + board_width + 14.0 * u
	var right_w := maxf(100.0, sz.x - right_x - gutter)
	var y := gutter
	var header_h := 42.0 * u
	title_label.position = Vector2(right_x, y - 3.0 * u)
	title_label.size = Vector2(right_w * 0.43, 29.0 * u)
	title_label.add_theme_font_size_override("font_size", maxi(16, int(round(25.0 * u))))
	mobile_header_subtitle.position = Vector2(right_x, y + 25.0 * u)
	mobile_header_subtitle.size = Vector2(right_w * 0.44, 14.0 * u)
	mobile_header_subtitle.add_theme_font_size_override("font_size", maxi(9, int(round(10.0 * u))))
	mobile_menu_button.position = Vector2(right_x + right_w - 43.0 * u, y)
	mobile_menu_button.size = Vector2(43.0 * u, 43.0 * u)
	_mobile_button_skin(mobile_menu_button, false, u)
	mobile_match_label.position = Vector2(right_x + right_w * 0.46, y)
	mobile_match_label.size = Vector2(right_w * 0.54 - 49.0 * u, header_h)
	mobile_match_label.add_theme_font_size_override("font_size", maxi(10, int(round(12.5 * u))))
	y += header_h + 9.0 * u
	mode_bar.position = Vector2(right_x, y)
	mode_bar.size = Vector2(right_w, 41.0 * u)
	mode_bar.add_theme_constant_override("separation", maxi(4, int(round(7.0 * u))))
	for mode_button in [classic_button, duboo_button]:
		mode_button.custom_minimum_size.y = 41.0 * u
		mode_button.add_theme_font_size_override("font_size", maxi(13, int(round(17.0 * u))))
	_mobile_game_tab_skin(classic_button, not duboo_mode, u)
	_mobile_game_tab_skin(duboo_button, duboo_mode, u)
	y += 48.0 * u
	mobile_score_panel.position = Vector2(right_x, y)
	mobile_score_panel.size = Vector2(right_w, 63.0 * u)
	(mobile_score_panel.get_child(0) as HBoxContainer).add_theme_constant_override("separation", maxi(3, int(round(6.0 * u))))
	for tile in mobile_score_cards:
		var skin := tile.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		skin.content_margin_left = 4.0 * u
		skin.content_margin_right = 4.0 * u
		skin.content_margin_top = 5.0 * u
		skin.content_margin_bottom = 5.0 * u
		tile.add_theme_stylebox_override("panel", skin)
	for heading in mobile_score_headings:
		heading.add_theme_font_size_override("font_size", maxi(10, int(round(12.0 * u))))
	mobile_you.add_theme_font_size_override("font_size", maxi(14, int(round(18.0 * u))))
	mobile_cpu.add_theme_font_size_override("font_size", maxi(14, int(round(18.0 * u))))
	mobile_queen.add_theme_font_size_override("font_size", maxi(10, int(round(12.0 * u))))
	y += 69.0 * u
	mobile_status_panel.position = Vector2(right_x, y)
	mobile_status_panel.size = Vector2(right_w, 46.0 * u)
	var turn_skin := mobile_status_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	turn_skin.content_margin_left = 8.0 * u
	turn_skin.content_margin_right = 7.0 * u
	turn_skin.content_margin_top = 4.0 * u
	turn_skin.content_margin_bottom = 4.0 * u
	mobile_status_panel.add_theme_stylebox_override("panel", turn_skin)
	mobile_status_title.add_theme_font_size_override("font_size", maxi(12, int(round(15.0 * u))))
	mobile_status_hint.add_theme_font_size_override("font_size", maxi(10, int(round(12.0 * u))))
	# Reserve the bottom of the right lane for the swipe grip.
	var dock_h := 104.0 * u
	mobile_power_panel.position = Vector2(right_x, sz.y - gutter - dock_h)
	mobile_power_panel.size = Vector2(right_w, dock_h)
	var power_skin := mobile_power_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	power_skin.content_margin_left = 12.0 * u
	power_skin.content_margin_right = 12.0 * u
	power_skin.content_margin_top = 6.0 * u
	power_skin.content_margin_bottom = 6.0 * u
	mobile_power_panel.add_theme_stylebox_override("panel", power_skin)
	mobile_power_label.add_theme_font_size_override("font_size", maxi(11, int(round(13.0 * u))))
	mobile_power_meter.custom_minimum_size.y = 9.0 * u
	mobile_fire.custom_minimum_size = Vector2(0.0, 55.0 * u)
	mobile_fire.size = Vector2(right_w - 24.0 * u, 55.0 * u)
	mobile_fire.add_theme_font_size_override("font_size", maxi(13, int(round(16.0 * u))))
	_mobile_fire_visual(phase == "charging")
	mobile_menu_scrim.position = Vector2.ZERO
	mobile_menu_scrim.size = sz
	mobile_modal_scale = clampf(minf(sz.x / 650.0, sz.y / 760.0), 0.55, 1.4)
	_mobile_menu_layout(mobile_modal_scale)
	_mobile_rules_layout(mobile_modal_scale)
	_mobile_fit_dialogs()
	_mobile_sync()

func _layout_portrait(sz: Vector2) -> void:
	# Phone game view: one visual hierarchy -- identity, segmented modes,
	# three match tiles, compact status, generous board, compact shot dock.
	# The settings and Rules sheets continue to have separate implementations.
	title_label.visible = true
	mobile_header_subtitle.visible = true
	mode_bar.visible = true
	side_panel.visible = false
	stats_panel.visible = false
	board_caption.visible = false
	tip_label.visible = false
	for node in [mobile_score_panel, mobile_status_panel, mobile_power_panel, mobile_match_label, mobile_menu_button]:
		node.show()

	var u := clampf(sz.x / 430.0, 0.72, 2.5)
	mobile_mobile_scale = u
	var gutter := 10.0 * u
	var safe_top := 14.0 * u
	var safe_bottom := 12.0 * u
	var header_h := 43.0 * u
	var mode_h := 43.0 * u
	var scores_h := 66.0 * u
	var status_h := 43.0 * u
	var power_h := 106.0 * u
	var gap_header := 7.0 * u
	var gap_modes := 8.0 * u
	var gap_score := 5.0 * u
	var gap_board := 9.0 * u
	var gap_dock := 10.0 * u
	var total_fixed := safe_top + safe_bottom + header_h + mode_h + scores_h + status_h + power_h + gap_header + gap_modes + gap_score + gap_board + gap_dock
	var max_board_width := maxf(0.0, sz.x - 2.0 * gutter)
	var board_width := minf(max_board_width, maxf(0.0, sz.y - total_fixed))
	var spare := maxf(0.0, sz.y - total_fixed - board_width)
	# Only taller aspect ratios receive extra space. Do not let spacers
	# reduce the board or introduce the enormous gaps seen in the old menu.
	var rhythm_add := minf(spare / 8.0, 13.0 * u)
	var y := safe_top + maxf(0.0, spare - rhythm_add * 4.0) * 0.42

	# Masthead: large single-word identity, understated subtitle and a
	# framed menu trigger. No desktop assets or text get resized here.
	title_label.position = Vector2(gutter + 1.0 * u, y - 3.0 * u)
	title_label.size = Vector2(sz.x * 0.46, 29.0 * u)
	title_label.add_theme_font_size_override("font_size", maxi(22, int(round(27.0 * u))))
	mobile_header_subtitle.position = Vector2(gutter + 2.0 * u, y + 28.0 * u)
	mobile_header_subtitle.size = Vector2(sz.x * 0.47, 14.0 * u)
	mobile_header_subtitle.add_theme_font_size_override("font_size", maxi(10, int(round(10.0 * u))))
	mobile_menu_button.position = Vector2(sz.x - gutter - 43.0 * u, y)
	mobile_menu_button.size = Vector2(43.0 * u, 43.0 * u)
	_mobile_button_skin(mobile_menu_button, false, u)
	mobile_match_label.position = Vector2(sz.x * 0.49, y)
	mobile_match_label.size = Vector2(sz.x * 0.51 - gutter - 49.0 * u, header_h)
	mobile_match_label.add_theme_font_size_override("font_size", maxi(12, int(round(12.5 * u))))
	y += header_h + gap_header + rhythm_add

	# Segmented mode selector. 43 logical px on the standard phone; the
	# selected tab is obvious but intentionally less dominant than the board.
	mode_bar.position = Vector2(gutter, y)
	mode_bar.size = Vector2(sz.x - 2.0 * gutter, mode_h)
	mode_bar.add_theme_constant_override("separation", maxi(6, int(round(7.0 * u))))
	classic_button.custom_minimum_size.y = mode_h
	duboo_button.custom_minimum_size.y = mode_h
	classic_button.add_theme_font_size_override("font_size", maxi(16, int(round(17.0 * u))))
	duboo_button.add_theme_font_size_override("font_size", maxi(16, int(round(17.0 * u))))
	_mobile_game_tab_skin(classic_button, not duboo_mode, u)
	_mobile_game_tab_skin(duboo_button, duboo_mode, u)
	y += mode_h + gap_modes + rhythm_add

	# No nested slab: the three scoreboard tiles have equal-width lanes,
	# individual borders and ample type-size at 360px through 1200px.
	mobile_score_panel.position = Vector2(gutter, y)
	mobile_score_panel.size = Vector2(sz.x - 2.0 * gutter, scores_h)
	var score_row := mobile_score_panel.get_child(0) as HBoxContainer
	score_row.add_theme_constant_override("separation", maxi(5, int(round(6.0 * u))))
	for tile in mobile_score_cards:
		var skin := tile.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		skin.content_margin_left = 5.0 * u
		skin.content_margin_right = 5.0 * u
		skin.content_margin_top = 6.0 * u
		skin.content_margin_bottom = 6.0 * u
		skin.set_corner_radius_all(maxi(10, int(round(13.0 * u))))
		skin.border_width_top = maxi(2, int(round(2.0 * u)))
		tile.add_theme_stylebox_override("panel", skin)
		(tile.get_child(0) as VBoxContainer).add_theme_constant_override("separation", maxi(2, int(round(3.0 * u))))
	for heading in mobile_score_headings:
		heading.add_theme_font_size_override("font_size", maxi(12, int(round(11.8 * u))))
	mobile_you.add_theme_font_size_override("font_size", maxi(16, int(round(18.5 * u))))
	mobile_cpu.add_theme_font_size_override("font_size", maxi(16, int(round(18.5 * u))))
	mobile_queen.add_theme_font_size_override("font_size", maxi(12, int(round(12.4 * u))))
	y += scores_h + gap_score

	# Turn info is deliberately smaller than the board. Accent rail changes
	# from mint to gold when the opponent takes control.
	mobile_status_panel.position = Vector2(gutter, y)
	mobile_status_panel.size = Vector2(sz.x - 2.0 * gutter, status_h)
	var turn_skin := mobile_status_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	turn_skin.bg_color = Color("#19352f")
	turn_skin.border_color = Color("#385c51")
	turn_skin.content_margin_left = 11.0 * u
	turn_skin.content_margin_right = 9.0 * u
	turn_skin.content_margin_top = 4.0 * u
	turn_skin.content_margin_bottom = 4.0 * u
	turn_skin.set_corner_radius_all(maxi(10, int(round(12.0 * u))))
	mobile_status_panel.add_theme_stylebox_override("panel", turn_skin)
	var turn_row := mobile_status_panel.get_child(0) as HBoxContainer
	turn_row.add_theme_constant_override("separation", maxi(8, int(round(10.0 * u))))
	mobile_turn_accent.custom_minimum_size.x = 3.0 * u
	mobile_status_title.add_theme_font_size_override("font_size", maxi(15, int(round(15.0 * u))))
	mobile_status_hint.add_theme_font_size_override("font_size", maxi(12, int(round(11.5 * u))))
	(mobile_status_title.get_parent() as VBoxContainer).add_theme_constant_override("separation", maxi(1, int(round(2.0 * u))))
	y += status_h + gap_board + rhythm_add

	var board_scale := board_width / 766.0
	var board_left := (sz.x - board_width) * 0.5
	board.scale = Vector2.ONE * board_scale
	board.position = Vector2(board_left + 43.0 * board_scale, y + 43.0 * board_scale)
	y += board_width + gap_dock + rhythm_add

	# Short, deliberate shot dock, instead of the old 142px-tall slab. Bar
	# stays immediately ABOVE a large central pull pad, preserving input rect.
	mobile_power_panel.position = Vector2(gutter, y)
	mobile_power_panel.size = Vector2(sz.x - 2.0 * gutter, power_h)
	var power_skin := mobile_power_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	power_skin.bg_color = Color("#1b3932")
	power_skin.border_color = Color("#456b60")
	power_skin.set_corner_radius_all(maxi(12, int(round(15.0 * u))))
	power_skin.content_margin_left = 13.0 * u
	power_skin.content_margin_right = 13.0 * u
	power_skin.content_margin_top = 6.0 * u
	power_skin.content_margin_bottom = 6.0 * u
	mobile_power_panel.add_theme_stylebox_override("panel", power_skin)
	var power_column := mobile_power_panel.get_child(0) as VBoxContainer
	power_column.add_theme_constant_override("separation", maxi(3, int(round(5.0 * u))))
	var power_stack := power_column.get_child(0) as VBoxContainer
	power_stack.add_theme_constant_override("separation", maxi(3, int(round(5.0 * u))))
	mobile_power_label.add_theme_font_size_override("font_size", maxi(13, int(round(13.2 * u))))
	mobile_power_meter.custom_minimum_size.y = 9.0 * u
	mobile_fire.custom_minimum_size = Vector2(0.0, 55.0 * u)
	mobile_fire.add_theme_font_size_override("font_size", maxi(17, int(round(18.0 * u))))
	_mobile_fire_visual(phase == "charging")
	# Dock is a full-width horizontal rail. Keep the touch grip visibly on it.
	mobile_fire.size = Vector2(mobile_power_panel.size.x - 26.0 * u, 55.0 * u)
	_mobile_position_pull_grip()

	# Prepare fonts and content first. Dialog geometry comes from the actual
	# minimum size *after* typography, buttons and visibility have changed.
	mobile_menu_scrim.position = Vector2.ZERO
	mobile_menu_scrim.size = sz
	var modal_u := clampf(minf(sz.x / 430.0, sz.y / 760.0), 0.76, 2.5)
	mobile_modal_scale = modal_u
	_mobile_menu_layout(modal_u)
	_mobile_rules_layout(modal_u)
	_mobile_fit_dialogs()
	_mobile_sync()

func _mobile_fit_dialogs() -> void:
	if not portrait_touch or mobile_menu_panel == null or rules_overlay == null:
		return
	var sz := size
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	# Physical canvas bounds, not the old fixed 505/708 logical-pixel caps.
	# Both panels fit independently, even at initial load or after an on-screen
	# browser toolbar changes the viewport. No ScrollContainer is introduced.
	var u := mobile_modal_scale
	var edge_x := maxf(8.0, 11.0 * u)
	var edge_y := maxf(8.0, 10.0 * u)
	var safe := Rect2(Vector2(edge_x, edge_y), sz - Vector2(edge_x * 2.0, edge_y * 2.0))
	if safe.size.x < 1.0 or safe.size.y < 1.0:
		return
	_mobile_fit_panel(mobile_menu_panel, safe, 505.0 * u)
	_mobile_fit_panel(rules_overlay, safe, 708.0 * u)

func _mobile_fit_panel(panel: PanelContainer, safe: Rect2, ideal_h: float) -> void:
	# Crucial: Godot enforces minimum sizes from child Labels and Buttons.
	# Measuring those sizes AFTER applying fonts fixes the one-time giant menu
	# that only corrected itself when a desktop window was nudged.
	panel.pivot_offset = Vector2.ZERO
	panel.scale = Vector2.ONE
	var content_min := panel.get_combined_minimum_size()
	var logical_w := maxf(safe.size.x, content_min.x)
	var logical_h := maxf(content_min.y + 2.0, minf(ideal_h, safe.size.y))
	# The last-resort uniform fit handles even 320x568 (or shorter browser
	# viewports) without clipping controls or creating a scrollbar.
	var fit := minf(1.0, minf(safe.size.x / logical_w, safe.size.y / logical_h))
	panel.size = Vector2(logical_w, logical_h)
	panel.scale = Vector2.ONE * fit
	var drawn := Vector2(logical_w, logical_h) * fit
	panel.position = safe.position + (safe.size - drawn) * 0.5

func _mobile_menu_layout(u: float) -> void:
	# Important: no scrolling and no expand-fill spacer. Use a clear vertical
	# hierarchy of one title, three setting groups and two large actions.
	var content := mobile_menu_content
	# Optional decoration yields to real touch controls on short phones.
	var short_screen := size.y < 680.0
	var ultra_short := size.y < 575.0
	(content.get_node("MenuFootnote") as Label).visible = not short_screen
	mobile_rival_bio.visible = not ultra_short
	(content.get_node("MenuRivalDivider") as HSeparator).visible = not ultra_short
	(content.get_node("MenuActionsDivider") as HSeparator).visible = not ultra_short
	var menu_skin := mobile_menu_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	menu_skin.content_margin_left = 13.0 * u
	menu_skin.content_margin_right = 13.0 * u
	menu_skin.content_margin_top = (10.0 if short_screen else 14.0) * u
	menu_skin.content_margin_bottom = (10.0 if short_screen else 14.0) * u
	mobile_menu_panel.add_theme_stylebox_override("panel", menu_skin)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", maxi(3, int(round((5.0 if short_screen else 7.0) * u))))
	var header := content.get_child(0) as HBoxContainer
	var heading_stack := header.get_child(0) as VBoxContainer
	heading_stack.add_theme_constant_override("separation", maxi(1, int(round(2.0 * u))))
	var header_title := heading_stack.get_child(0) as Label
	var header_subtitle := heading_stack.get_child(1) as Label
	header_subtitle.visible = not ultra_short
	header_title.add_theme_font_size_override("font_size", maxi(23, int(round(23.0 * u))))
	header_subtitle.add_theme_font_size_override("font_size", maxi(13, int(round(11.5 * u))))
	var close := header.get_child(1) as Button
	close.custom_minimum_size = Vector2(71.0 * u, maxf(42.0, 42.0 * u))
	close.add_theme_font_size_override("font_size", maxi(14, int(round(13.0 * u))))
	_mobile_button_skin(close, false, u)

	for name in ["MenuDesignTitle", "MenuDifficultyTitle"]:
		var heading := content.get_node(name) as Label
		heading.add_theme_font_size_override("font_size", maxi(15, int(round(13.0 * u))))
	for item in content.get_children():
		if item is Label and item.name != "MenuFootnote" and item.name != "MenuDesignTitle" and item.name != "MenuDifficultyTitle":
			(item as Label).add_theme_font_size_override("font_size", maxi(15, int(round(13.0 * u))))

	var design_panel := content.get_node("MenuDesignPanel") as PanelContainer
	var panel_skin := design_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_skin.content_margin_top = 6.0 * u
	panel_skin.content_margin_bottom = 6.0 * u
	panel_skin.content_margin_left = 6.0 * u
	panel_skin.content_margin_right = 6.0 * u
	design_panel.add_theme_stylebox_override("panel", panel_skin)
	var design_row := design_panel.get_child(0) as HBoxContainer
	design_row.add_theme_constant_override("separation", maxi(4, int(round(6.0 * u))))
	for b in [mobile_menu_prev, mobile_menu_next_style]:
		b.custom_minimum_size = Vector2(54.0 * u, maxf(43.0, 43.0 * u))
		b.add_theme_font_size_override("font_size", maxi(14, int(round(13.0 * u))))
		_mobile_button_skin(b, false, u)
	mobile_menu_style_count.add_theme_font_size_override("font_size", maxi(13, int(round(12.5 * u))))
	mobile_menu_style_name.add_theme_font_size_override("font_size", maxi(15, int(round(15.0 * u))))

	var difficulty_row := content.get_node("MenuDifficultyChoices") as HBoxContainer
	difficulty_row.add_theme_constant_override("separation", maxi(4, int(round(6.0 * u))))
	for b in mobile_menu_difficulties:
		b.custom_minimum_size.y = maxf(46.0, 45.0 * u)
		b.add_theme_font_size_override("font_size", maxi(13, int(round(13.0 * u))))

	var rival_row := content.get_node("MenuRivalChoices") as HBoxContainer
	rival_row.add_theme_constant_override("separation", maxi(5, int(round(7.0 * u))))
	for b in [mobile_rival_prev, mobile_rival_next]:
		b.custom_minimum_size = Vector2(54.0 * u, maxf(44.0, 44.0 * u))
		b.add_theme_font_size_override("font_size", maxi(14, int(round(13.0 * u))))
		_mobile_button_skin(b, false, u)
	mobile_rival_name.add_theme_font_size_override("font_size", maxi(15, int(round(14.0 * u))))
	mobile_rival_bio.add_theme_font_size_override("font_size", maxi(14, int(round(12.5 * u))))
	# A short two-line description is part of the settings composition, not
	# an expanding text area that shoves actions out of view.
	mobile_rival_bio.max_lines_visible = 2

	var actions := content.get_node("MenuActions") as HBoxContainer
	actions.add_theme_constant_override("separation", maxi(7, int(round(9.0 * u))))
	for b in [mobile_menu_rules, mobile_menu_restart, mobile_menu_next_board]:
		b.custom_minimum_size.y = maxf(47.0, 47.0 * u)
		b.add_theme_font_size_override("font_size", maxi(16, int(round(15.0 * u))))
		_mobile_button_skin(b, b == mobile_menu_next_board, u)
	var footer := content.get_node("MenuFootnote") as Label
	footer.add_theme_font_size_override("font_size", maxi(12, int(round(11.0 * u))))
	_mobile_refresh_menu()

func _mobile_rules_layout(u: float) -> void:
	if mobile_rules_content == null:
		return
	_mobile_refresh_rules()
	var rules_skin := rules_overlay.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	rules_skin.content_margin_left = 11.0 * u
	rules_skin.content_margin_right = 11.0 * u
	rules_skin.content_margin_top = 10.0 * u
	rules_skin.content_margin_bottom = 10.0 * u
	rules_overlay.add_theme_stylebox_override("panel", rules_skin)
	var column := rules_overlay.get_child(0) as VBoxContainer
	column.add_theme_constant_override("separation", maxi(4, int(round(8.0 * u))))
	var header := column.get_child(0) as HBoxContainer
	header.add_theme_constant_override("separation", maxi(5, int(round(8.0 * u))))
	rules_title_label.add_theme_font_size_override("font_size", maxi(20, int(round(22.0 * u))))
	rules_close_button.custom_minimum_size = Vector2(68.0 * u, maxf(43.0, 43.0 * u))
	rules_close_button.add_theme_font_size_override("font_size", maxi(14, int(round(13.0 * u))))
	_mobile_button_skin(rules_close_button, true, u)
	mobile_rules_content.add_theme_constant_override("separation", maxi(4, int(round(7.0 * u))))
	mobile_rules_mode.add_theme_font_size_override("font_size", maxi(14, int(round(13.0 * u))))
	for i in range(mobile_rules_cards.size()):
		var card := mobile_rules_cards[i]
		var skin := card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		skin.content_margin_left = 10.0 * u
		skin.content_margin_right = 10.0 * u
		skin.content_margin_top = 7.0 * u
		skin.content_margin_bottom = 7.0 * u
		card.add_theme_stylebox_override("panel", skin)
		var row := card.get_child(0) as HBoxContainer
		row.add_theme_constant_override("separation", maxi(5, int(round(9.0 * u))))
		var number := row.get_child(0) as Label
		number.custom_minimum_size.x = 24.0 * u
		number.add_theme_font_size_override("font_size", maxi(14, int(round(13.0 * u))))
		var copy := row.get_child(1) as VBoxContainer
		copy.add_theme_constant_override("separation", maxi(1, int(round(2.0 * u))))
		mobile_rules_titles[i].add_theme_font_size_override("font_size", maxi(15, int(round(14.0 * u))))
		mobile_rules_descriptions[i].add_theme_font_size_override("font_size", maxi(15, int(round(14.0 * u))))

func _load_board_style() -> void:
	rival_index = randi_range(0, RIVALS.size() - 1)
	var config := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH) and config.load(SETTINGS_PATH) == OK:
		board_style_index = clampi(int(config.get_value("appearance", "board_style", 0)), 0, CarromBoard.STYLE_NAMES.size() - 1)
		duboo_style_index = clampi(int(config.get_value("appearance", "duboo_table_style", 0)), 0, CarromBoard.DUBOO_STYLE_NAMES.size() - 1)
		for game in ["classic", "duboo"]:
			for idx in range(RIVALS.size()):
				var key := "%s_%d" % [game, idx]
				rival_results[key] = [int(config.get_value("rivals", key + "_win", 0)), int(config.get_value("rivals", key + "_loss", 0)), int(config.get_value("rivals", key + "_draw", 0))]

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

func _toggle_auto_battle() -> void:
	auto_battle = not auto_battle
	auto_advance_time = -1.0
	auto_battle_button.text = "AUTO BATTLE  ON" if auto_battle else "AUTO BATTLE  OFF"
	_new_match()
	if sound_click != null:
		sound_click.play()

func _auto_begin_turn() -> void:
	phase = "cpu_think"
	board.side = player_turn
	board.display_striker = true
	board.show_aim = false
	board.show_cpu_target = false
	_place_striker(player_turn, 340.0)
	cpu_time = 1.5
	_set_status("%s / %s" % [_rival_alias_for_player(player_turn), "WHITE" if player_turn == 0 else "BLACK"], "Rival is studying the board.")
	_refresh_ui()
	board.queue_redraw()

# Rotate the board and swap colors only inside the existing black-side CPU
# planner. Its search remains identical for both sides and live discs are never
# changed; white-side results are rotated back before execution.
func _auto_mirror_state() -> Array:
	var mirrored: Array = discs.duplicate(true)
	for disc in mirrored:
		disc["pos"] = Vector2(680.0, 680.0) - (disc["pos"] as Vector2)
		disc["vel"] = -(disc["vel"] as Vector2)
		if disc["kind"] == "white":
			disc["kind"] = "black"
		elif disc["kind"] == "black":
			disc["kind"] = "white"
	return mirrored

func _auto_mirror_owner(owner: int) -> int:
	return 1 - owner if owner >= 0 else -1

func _auto_cpu_search_start() -> void:
	if not auto_battle or player_turn == 1:
		_cpu_start_search()
		return
	var original := discs
	var original_pending := pending_queen
	var original_queen := queen_owner
	discs = _auto_mirror_state()
	# The planner is black-oriented. Its mirrored WHITE turn must also mirror
	# Queen ownership so legal cover and score predictions stay correct.
	pending_queen = _auto_mirror_owner(original_pending)
	queen_owner = _auto_mirror_owner(original_queen)
	_cpu_start_search()
	discs = original
	pending_queen = original_pending
	queen_owner = original_queen

func _auto_cpu_search_frame() -> void:
	if not auto_battle or player_turn == 1:
		_cpu_search_frame()
		return
	var original := discs
	var original_pending := pending_queen
	var original_queen := queen_owner
	discs = _auto_mirror_state()
	pending_queen = _auto_mirror_owner(original_pending)
	queen_owner = _auto_mirror_owner(original_queen)
	_cpu_search_frame()
	discs = original
	pending_queen = original_pending
	queen_owner = original_queen
	if phase == "cpu_aim":
		_place_striker(0, float(cpu_queued_shot["x"]))

func _new_match() -> void:
	rival_quote_peek = false
	rival_quote_time = 0.0
	if rival_quote_box != null:
		rival_quote_box.hide()
	if rival_drawer != null and not rival_drawer_open:
		_animate_rival_drawer()
	_cancel_mobile_charge()
	mobile_board_finger = -1
	board_number = 1
	totals = [0, 0]
	outstanding_dues = [0, 0]
	queen_owner = -1
	pending_queen = -1
	winner = -1
	rival_match_recorded = false
	if auto_battle:
		_choose_auto_rival()
	_refresh_rival_card()
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
	phase = ("aim" if portrait_touch else "placement") if player_turn == 0 else "cpu_think"
	board.discs = discs
	board.side = player_turn
	board.display_striker = true
	board.active_x = 340.0
	board.show_aim = portrait_touch and player_turn == 0
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
		_set_status("YOUR BREAK" if board_number == 1 else "YOUR TURN", "Slide the striker on the baseline, tap the board to aim, pull the grip left to shoot.")
	else:
		_set_status("CPU BREAK", "%s is studying the opening." % str(RIVALS[rival_index]["alias"]))
	if auto_battle:
		_auto_begin_turn()
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
	if duboo_mode:
		match_info.text = "DUBOO / RIVAL VS RIVAL" if auto_battle else "DUBOO / ONE BOARD"
	elif MAX_BOARD_COUNT == 1:
		match_info.text = "RIVAL VS RIVAL / ONE BOARD" if auto_battle else "QUICK MATCH / ONE BOARD"
	else:
		match_info.text = "BOARD %d OF %d / FIRST TO %d" % [
			board_number, MAX_BOARD_COUNT, MATCH_TARGET
		]
	white_score_heading.text = ("%s / WHITE" % _rival_alias_for_player(0)) if auto_battle else "YOU / WHITE"
	black_score_heading.text = ("%s / BLACK" % _rival_alias_for_player(1)) if auto_battle else "CPU / BLACK"
	if pending_queen != -1:
		queen_text.text = "  QUEEN  /  %s MUST COVER" % (("WHITE" if pending_queen == 0 else "BLACK") if auto_battle else ("YOU" if pending_queen == 0 else "CPU"))
	elif queen_owner != -1:
		queen_text.text = "  QUEEN  /  COVERED BY %s" % (("WHITE" if queen_owner == 0 else "BLACK") if auto_battle else ("YOU" if queen_owner == 0 else "CPU"))
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
				_set_status("AIM YOUR SHOT", "Touch the board to aim, then pull the grip LEFT and release.")
			else:
				# Sliding along the baseline should not rotate a previously aimed
				# shot merely because the striker's world position has changed.
				mobile_aim_target = _get_striker()["pos"] + aim_direction.normalized() * 220.0
		else:
			_set_status("BASELINE BLOCKED", "Try another point on the lower baseline.")
	else:
		# A drag that goes off the board cannot turn into an out-of-range aim.
		mobile_aim_target = Vector2(clampf(local.x, 25.0, 655.0), clampf(local.y, 25.0, 655.0))
		var diff: Vector2 = mobile_aim_target - _get_striker()["pos"]
		if diff.length_squared() > 18.0 * 18.0:
			aim_direction = diff.normalized()
			board.aim_direction = aim_direction
			board.queue_redraw()

func _mobile_touch_on_grip(position: Vector2) -> bool:
	if mobile_fire == null or not mobile_fire.get_global_rect().has_point(position):
		return false
	# The knob lives at the right end, leaving space on the LEFT for the pull.
	# A generous 45% hit target accommodates a thumb on a small phone.
	return position.x >= mobile_fire.global_position.x + mobile_fire.size.x * 0.55

func _mobile_start_pull(position: Vector2) -> void:
	if player_turn != 0 or phase != "aim" or rules_overlay.visible:
		return
	mobile_pull_origin = position
	mobile_pull_length = 0.0
	mobile_pull_idle = 0.0
	mobile_locked_shot_direction = aim_direction.normalized() if aim_direction.length_squared() > 0.5 else Vector2.UP
	charge_power = 0.0
	phase = "charging"
	board.charging = false
	board.aim_power = 0.0
	mobile_fire.text = "RELEASE"
	_mobile_sync()
	_mobile_fire_visual(true)

func _mobile_update_pull(position: Vector2) -> void:
	if phase != "charging" or player_turn != 0:
		return
	# Only horizontal LEFT displacement sets power. Vertical jitter never
	# changes power or aim, and no pointer needs to leave the phone screen.
	var u := maxf(0.7, mobile_mobile_scale)
	var dead_zone := MOBILE_PULL_THRESHOLD * u
	var max_slide := minf(MOBILE_PULL_MAX * u, mobile_fire.size.x * 0.55)
	mobile_pull_length = clampf(mobile_pull_origin.x - position.x, 0.0, max_slide)
	mobile_pull_idle = 0.0
	if mobile_pull_length >= dead_zone:
		charge_power = lerpf(0.20, 1.0, clampf((mobile_pull_length - dead_zone) / maxf(1.0, max_slide - dead_zone), 0.0, 1.0))
	else:
		charge_power = 0.0
	# Never change locked direction here, even if the finger slides diagonally.
	board.aim_direction = mobile_locked_shot_direction
	board.aim_power = charge_power
	mobile_power_label.text = "POWER  %d%%" % int(round(charge_power * 100.0)) if charge_power > 0.0 else "PULL THE GRIP LEFT"
	mobile_power_meter.value = charge_power * 100.0
	_mobile_position_pull_grip()
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
			_set_status("AIM YOUR SHOT", "Aim on the board. Pull the grip LEFT to shoot.")
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
			if _mobile_touch_on_grip(event.position) and mobile_board_finger < 0 and player_turn == 0 and phase == "aim":
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
				if _mobile_touch_on_grip(event.position) and not mobile_board_mouse_down and player_turn == 0 and phase == "aim":
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
	if auto_battle or player_turn != 0 or phase not in ["placement", "aim", "charging"]:
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
	if rival_quote_time > 0.0:
		rival_quote_time = maxf(0.0, rival_quote_time - delta)
		if rival_quote_time <= 0.0 and rival_quote_peek:
			rival_quote_peek = false
			_animate_rival_drawer()
	# Browser/webview touchcancel is not always delivered. A dead pull must
	# cancel itself, never fire a shot or strand the player in charging.
	if portrait_touch and phase == "charging":
		mobile_pull_idle += delta
		if mobile_pull_idle > 5.0:
			_cancel_mobile_charge()
			_set_status("AIM YOUR SHOT", "Shot reset. Pull the grip LEFT and release to shoot.")
			_refresh_ui()
			return
	if rules_overlay != null and rules_overlay.visible:
		return
	if auto_battle and phase == "board_over":
		if auto_advance_time < 0.0:
			auto_advance_time = 1.5
		auto_advance_time -= delta
		if auto_advance_time <= 0.0:
			auto_advance_time = -1.0
			_next_board()
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
			_auto_cpu_search_start()
			phase = "cpu_search"
			_set_status("%s IS THINKING" % _rival_alias_for_player(player_turn) if auto_battle else "CPU STUDYING BOARD", "The rival is planning a shot." if auto_battle else "The computer is considering its options.")
	elif phase == "cpu_search":
		if cpu_plan_active:
			_auto_cpu_search_frame()
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
	_set_status("PIECES IN MOTION", "%s took the shot. Watch the pieces settle." % _rival_alias_for_player(player_turn) if auto_battle else "Watch the shot settle. Pocket your color to keep the turn.")
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
		notices.append("Striker pocketed: foul. Turn ends." if auto_battle else "Striker pocketed: foul. Your turn ends.")
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
	# Only legitimate CPU progress earns a line. One line per scoring shot,
	# including double pockets, with no interruptions over the board.
	if (actor == 1 or auto_battle) and actor_has_scored and not striker_in_shot:
		_show_rival_pocket_quote(actor)
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
	if auto_battle:
		_auto_begin_turn()
	elif player_turn == 0:
		phase = "aim" if portrait_touch else "placement"
		mobile_board_finger = -1
		board.display_striker = true
		board.side = 0
		_place_striker(0, 340.0)
		board.show_aim = portrait_touch
		if portrait_touch:
			aim_direction = Vector2.UP
			board.aim_direction = aim_direction
			mobile_aim_target = _get_striker()["pos"] + Vector2.UP * 220.0
		_set_status("YOUR TURN  /  WHITE", result + " Aim on the board, then pull left to shoot.")
	else:
		phase = "cpu_think"
		board.display_striker = true
		board.side = 1
		_place_striker(1, 340.0)
		cpu_time = 0.85
		_set_status("CPU TURN  /  BLACK", result + " %s is choosing a shot." % str(RIVALS[rival_index]["alias"]))
	_refresh_ui()
	board.queue_redraw()

func _end_board(board_winner: int, reason: String) -> void:
	winner = board_winner
	if duboo_mode:
		phase = "match_over"
		if not auto_battle:
			_record_rival_match(board_winner)
		board.display_striker = false
		board.show_aim = false
		_set_status("%s WINS DUBOO!" % _rival_alias_for_player(board_winner) if auto_battle else ("YOU WIN DUBOO!" if board_winner == 0 else "CPU WINS DUBOO"), reason + "  Select NEW BOARD to play again.")
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
	var board_winner_text := ("%s WINS THE BOARD!" % _rival_alias_for_player(board_winner)) if auto_battle else ("YOU WIN THE BOARD!" if board_winner == 0 else "CPU WINS THE BOARD")
	board_finished_message = "%s  +%d POINTS  |  %s" % [board_winner_text, gain, reason]
	var match_over := totals[board_winner] >= MATCH_TARGET or board_number >= MAX_BOARD_COUNT
	if match_over:
		phase = "match_over"
		var match_winner := 0 if totals[0] > totals[1] else 1
		if not auto_battle:
			_record_rival_match(2 if totals[0] == totals[1] else match_winner)
		if totals[0] == totals[1]:
			_set_status("RIVALS TIED" if auto_battle else "MATCH TIED", "Match ends level. Select NEW MATCH to play again." if auto_battle else "Eight boards completed with equal points. Select NEW MATCH to play again.")
		else:
			_set_status("%s WINS!" % _rival_alias_for_player(match_winner) if auto_battle else ("YOU WIN THE MATCH!" if match_winner == 0 else "CPU WINS THE MATCH"), board_finished_message + "  Select NEW MATCH to play again.")
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
	_mobile_refresh_rules()
	rules_overlay.show()
	rules_overlay.move_to_front()
	if portrait_touch:
		_layout()
		_schedule_mobile_reflow()
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
	var limits: Array = (quotas[clampi(cpu_skill, 0, 2)] as Array).duplicate()
	var quota_change: Array = RIVALS[_rival_for_player(player_turn)]["quota"]
	for i in range(4):
		limits[i] = maxi(0, int(limits[i]) + int(quota_change[i]))
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
	var personality: Dictionary = RIVALS[_rival_for_player(player_turn)]
	if own >= 2:
		score += 42.0 * float(own - 1) * float(personality["multi"])
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
	score += clampf((after_value - cpu_plan_base_value) * 0.55 * float(personality["position"]), -55.0, 55.0)
	if own == 0:
		score -= 22.0  # Losing your turn has a tactical cost.
	if own == 0 and other == 0 and not queen:
		score -= 8.0  # Discourage pointless hard breaks once spread out.
	# Prefer reliable, short execution when simulated outcomes tie.
	score += float(candidate["seed"]) * 0.038
	# Preference matters on comparable outcomes; pocket count, Queen rules,
	# and fouls still dominate. No artificial successes or physics changes.
	var biases: Dictionary = personality["bias"]
	score += float(biases.get(str(candidate.get("style", "direct")), 0.0))
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
	if auto_battle and player_turn == 0:
		cpu_queued_shot["x"] = 680.0 - float(cpu_queued_shot["x"])
		cpu_queued_shot["dir"] = -(cpu_queued_shot["dir"] as Vector2)
		cpu_queued_shot["target"] = Vector2(680.0, 680.0) - (cpu_queued_shot["target"] as Vector2)
	_place_striker(player_turn if auto_battle else 1, float(cpu_queued_shot["x"]))
	board.side = player_turn if auto_battle else 1
	board.aim_direction = cpu_queued_shot["dir"]
	board.aim_power = inverse_lerp(_shot_speed_min(), _shot_speed_max(), cpu_queued_shot["speed"])
	board.show_aim = true
	board.show_cpu_target = true
	board.cpu_target = cpu_queued_shot["target"]
	board.queue_redraw()
	phase = "cpu_aim"
	cpu_time = 0.60
	_set_status("%s AIMING" % _rival_alias_for_player(player_turn) if auto_battle else "CPU AIMING", "%s is lining up a shot." % _rival_alias_for_player(player_turn))
	_refresh_ui()
