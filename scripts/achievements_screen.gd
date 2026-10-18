extends Control
## The list of achievements, with progress towards each one, and a Stats
## tab of lifetime numbers.

signal closed

const Achievements := preload("res://scripts/achievements.gd")

const DONE := Color("7fd67f")
const DIM := Color(1, 1, 1, 0.55)

var game
var _list: VBoxContainer
var _count: Label
var _title: Label
var _tabs: HBoxContainer
var showing_stats := false

const PillStyle := preload("res://scripts/pill_style.gd")
const Skins := preload("res://scripts/skins.gd")


func setup(main_game) -> void:
	game = main_game
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = _label("TROPHIES", 28)
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(_title)
	_count = _label("", 20, Color("ffd23f"))
	header.add_child(_count)

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 0)
	column.add_child(_tabs)
	for t in [["Trophies", false], ["Stats", true]]:
		var b := Button.new()
		b.text = t[0]
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 40
		b.add_theme_font_size_override("font_size", 16)
		for key in ["normal", "hover", "disabled"]:
			b.add_theme_stylebox_override(key, PillStyle.new(Color(0.24, 0.25, 0.29, 0.62)))
		b.add_theme_stylebox_override("pressed", PillStyle.new(Color(0.85, 0.6, 0.1, 0.8)))
		b.add_theme_stylebox_override("hover_pressed", PillStyle.new(Color(0.85, 0.6, 0.1, 0.8)))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(func():
			showing_stats = t[1]
			open())
		_tabs.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 52
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	visible = true
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for i in _tabs.get_child_count():
		var b: Button = _tabs.get_child(i)
		b.set_pressed_no_signal((i == 1) == showing_stats)
		for key in ["normal", "pressed", "hover_pressed", "disabled"]:
			var face: PillStyle = b.get_theme_stylebox(key)
			face.round_left = i == 0
			face.round_right = i == 1
			face.divider = i == 0
	_title.text = "STATS" if showing_stats else "TROPHIES"
	if showing_stats:
		_show_stats()
		return
	var done := 0
	# Unlocked first, then the ones you're closest to.
	var rows: Array = Achievements.LIST.duplicate()
	rows.sort_custom(func(a, b):
		var ua: bool = game.unlocked.has(a.id)
		var ub: bool = game.unlocked.has(b.id)
		if ua != ub:
			return ua
		return _fraction(a) > _fraction(b))
	for a in rows:
		if game.unlocked.has(a.id):
			done += 1
		_list.add_child(_row(a))
	_count.text = "%d/%d" % [done, Achievements.LIST.size()]


## Lifetime numbers, as [label, value] rows.
func stat_rows() -> Array:
	var owned := 0
	var total := 0
	for kind in ["hero", "hat", "walls", "trail", "lava"]:
		for item in Skins.list(kind):
			total += 1
			if game.owns(item):
				owned += 1
	var seconds: int = game.stat("play_seconds")
	var deaths: int = game.stat("deaths")
	return [
		["Runs played", str(game.stat("runs"))],
		["Time climbing", "%dh %02dm" % [seconds / 3600, (seconds / 60) % 60]],
		["Floors climbed", str(game.stat("floors_climbed"))],
		["Best floor", str(game.best_floor)],
		["Coins collected", str(game.stat("coins_collected"))],
		["Cracked walls broken", str(game.stat("walls_broken"))],
		["Trap floors passed", str(game.stat("trap_floors"))],
		["Power-ups grabbed", str(game.stat("powerups"))],
		["Chests opened", str(game.stat("chests_opened"))],
		["Legendaries found", str(game.stat("legendaries"))],
		["Deaths", str(deaths)],
		["  by lava", str(game.stat("deaths_lava"))],
		["  by spikes", str(game.stat("deaths_spikes"))],
		["  by fake floors", str(game.stat("deaths_fake"))],
		["  by moving blocks", str(game.stat("deaths_mover"))],
		["  by spike traps", str(game.stat("deaths_trap"))],
		["Revives", str(game.stat("revives"))],
		["Daily Climbs played", str(game.stat("daily_days"))],
		["Daily gold medals", str(game.stat("daily_golds"))],
		["Levels cleared", "%d / %d" % [game.levels_cleared.size(), game.Levels.LEVELS.size()]],
		["Level stars", str(game.total_stars())],
		["Missions finished", str(game.stat("missions_done"))],
		["Cosmetics owned", "%d / %d" % [owned, total]],
	]


func _show_stats() -> void:
	_count.text = ""
	for row in stat_rows():
		var line := HBoxContainer.new()
		var name_label := _label(row[0], 16, DIM)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.size_flags_horizontal = SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(_label(row[1], 16, Color.WHITE))
		var gap := Control.new()
		gap.custom_minimum_size.x = 12
		line.add_child(gap)
		_list.add_child(line)


func _fraction(a: Dictionary) -> float:
	return minf(float(game.stat(a.stat)) / a.goal, 1.0)


func _row(a: Dictionary) -> Control:
	var unlocked: bool = game.unlocked.has(a.id)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.07 if unlocked else 0.04)
	style.border_color = DONE if unlocked else Color(1, 1, 1, 0.1)
	style.border_width_left = 4
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var name_label := _label(a.name, 18, DONE if unlocked else Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(name_label)
	top.add_child(_label("Done" if unlocked else Achievements.reward_text(a), 13, DONE if unlocked else Color("ffd23f")))
	var desc := _label(a.desc, 14, DIM, true)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(desc)
	if not unlocked:
		var bar := ProgressBar.new()
		bar.max_value = a.goal
		bar.value = mini(game.stat(a.stat), a.goal)
		bar.show_percentage = false
		bar.custom_minimum_size.y = 8
		box.add_child(bar)
		if a.goal > 1:
			var progress := _label("%d / %d" % [mini(game.stat(a.stat), a.goal), a.goal], 12, DIM)
			progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			box.add_child(progress)
	return panel


func _label(text: String, size: int, color := Color.WHITE, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
