extends Control
## The list of achievements, with progress towards each one.

signal closed

const Achievements := preload("res://scripts/achievements.gd")

const DONE := Color("7fd67f")
const DIM := Color(1, 1, 1, 0.55)

var game
var _list: VBoxContainer
var _count: Label


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
	var title := _label("TROPHIES", 28)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_count = _label("", 20, Color("ffd23f"))
	header.add_child(_count)

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
