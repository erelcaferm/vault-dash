extends Control
## The LEVELS menu: the handmade levels, then the player's own levels,
## which they can make, edit, share as a code, or add from someone's code.

const Levels := preload("res://scripts/levels.gd")
const LevelCode := preload("res://scripts/level_code.gd")
const Achievements := preload("res://scripts/achievements.gd")

const GOLD := Color("ffd23f")
const DIM := Color(1, 1, 1, 0.55)
const DONE := Color("7fd67f")
const BAD := Color("ff6b5b")

var game
var _grid: GridContainer
var _star_total: Label
var _list: VBoxContainer
var _code_panel: PanelContainer
var _code_title: Label
var _code_edit: LineEdit
var _code_error: Label
var _code_action: Button
var _code_paste: Button
var _sharing := false
var _pending_delete := -1


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
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("LEVELS", 28)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_star_total = _label("", 18, GOLD)
	header.add_child(_star_total)
	column.add_child(_label("Reach the exit before the time runs out.", 13, DIM))
	var build := _button(column, "+ BUILD YOUR OWN LEVEL", func(): game.level_editor.open(LevelCode.blank(), -1), 48)
	build.add_theme_color_override("font_color", GOLD)
	build.add_theme_color_override("font_hover_color", GOLD)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(_grid)

	var heading := _label("YOUR LEVELS", 16, Color(1, 1, 1, 0.6))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(heading)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	column.add_child(actions)
	_button(actions, "ADD CODE", func(): _show_code_panel(false, ""), 44)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_button(column, "Back", func(): visible = false, 52)
	_build_code_panel()
	visible = false


func open() -> void:
	visible = true
	_code_panel.visible = false
	_pending_delete = -1
	_refresh()


func _refresh() -> void:
	_star_total.text = "★ %d/%d" % [game.total_stars(), Levels.LEVELS.size() * Levels.STARS_PER_LEVEL]
	for c in _grid.get_children():
		c.queue_free()
	for i in Levels.LEVELS.size():
		_grid.add_child(_campaign_card(i))
	for c in _list.get_children():
		c.queue_free()
	if game.custom_levels.is_empty():
		var hint := _label("Levels you build or add from a friend's code show here.", 14, DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(hint)
	for i in game.custom_levels.size():
		_list.add_child(_custom_row(i))


func _campaign_card(i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 58)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	var unlocked: bool = game.campaign_unlocked(i)
	var cleared: bool = game.levels_cleared.has(i)
	b.disabled = not unlocked
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	b.add_child(box)
	box.add_child(_label(str(i + 1), 22, Color.WHITE if unlocked else Color(1, 1, 1, 0.3)))
	var sub: Label
	if cleared:
		sub = _label(game.stars_text(i), 14, GOLD)
	elif unlocked:
		var reward: Dictionary = Levels.LEVELS[i].reward
		sub = _label("● %d" % reward.coins if reward.has("coins") else tr("Skin"), 12, GOLD)
	else:
		sub = _label("Locked", 12, Color(1, 1, 1, 0.3))
	game.fit_font(sub, 70, 9)
	box.add_child(sub)
	b.pressed.connect(func(): game.start_campaign_level(i))
	return b


func _custom_row(i: int) -> Control:
	var lv := LevelCode.decode(game.custom_levels[i])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var name := _label(lv.get("name", "") if lv.get("name", "") != "" else tr("Untitled level"), 15)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.size_flags_horizontal = SIZE_EXPAND_FILL
	name.clip_text = true
	row.add_child(name)
	if lv.is_empty():
		row.add_child(_label("Broken level", 13, BAD))
	else:
		row.add_child(_label(game._clock(lv.time), 13, DIM))
		_small(row, "PLAY", func(): game.start_level(lv, "custom"))
		_small(row, "EDIT", func(): game.level_editor.open(lv, i))
		_small(row, "SHARE", func(): _show_code_panel(true, game.custom_levels[i]))
	var del := _small(row, "Sure?" if _pending_delete == i else "✕", func():
		if _pending_delete == i:
			game.delete_custom_level(i)
			_pending_delete = -1
		else:
			_pending_delete = i
		_refresh())
	if _pending_delete == i:
		del.add_theme_color_override("font_color", BAD)
	return row


# --- Share codes -------------------------------------------------------------

func _build_code_panel() -> void:
	_code_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	_code_panel.add_theme_stylebox_override("panel", style)
	_code_panel.set_anchors_preset(PRESET_CENTER)
	_code_panel.offset_left = -160
	_code_panel.offset_right = 160
	_code_panel.offset_top = -120
	_code_panel.offset_bottom = 120
	add_child(_code_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_code_panel.add_child(column)
	_code_title = _label("", 18)
	_code_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_code_title)
	_code_edit = LineEdit.new()
	_code_edit.custom_minimum_size.y = 44
	_code_edit.placeholder_text = "Paste a level code"
	_code_edit.add_theme_font_size_override("font_size", 14)
	column.add_child(_code_edit)
	_code_error = _label("", 13, BAD)
	_code_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_code_error)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	column.add_child(buttons)
	_button(buttons, "Close", func(): _code_panel.visible = false, 44)
	_code_paste = _button(buttons, "Paste", func(): _code_edit.text = DisplayServer.clipboard_get().strip_edges(), 44)
	_code_action = _button(buttons, "", _on_code_action, 44)
	_code_panel.visible = false


func _show_code_panel(sharing: bool, code: String) -> void:
	_sharing = sharing
	_code_error.text = ""
	_code_edit.text = code
	_code_edit.editable = not sharing
	_code_paste.visible = not sharing
	if sharing:
		_code_title.text = tr("Send this code to a friend. They add it with ADD CODE.")
		_code_action.text = tr("Copy")
	else:
		_code_title.text = tr("ADD CODE")
		_code_action.text = tr("Add")
	_code_panel.visible = true


func _on_code_action() -> void:
	if _sharing:
		DisplayServer.clipboard_set(_code_edit.text)
		game._toast(tr("Code copied"))
		game.sfx.play("buy")
		_code_panel.visible = false
		return
	var lv := LevelCode.decode(_code_edit.text)
	if lv.is_empty():
		_code_error.text = tr("That code doesn't work. Check it was copied in full.")
		game.sfx.play("error")
		return
	game.save_custom_level(lv)
	game.sfx.play("reward")
	_code_panel.visible = false
	_refresh()


# --- Helpers ---------------------------------------------------------------

func _button(parent: Node, text: String, action: Callable, height: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = height
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18 if height >= 50 else 16)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _small(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
