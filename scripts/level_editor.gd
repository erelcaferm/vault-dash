extends Control
## The level editor: paint tiles on a 13 x 18 grid, set the time limit,
## test it, and share it as a code. A level can only be shared once its
## maker has beaten it since the last change, so every shared level is
## known to be possible in the time given.

const LevelCode := preload("res://scripts/level_code.gd")
const LevelGrid := preload("res://scripts/level_grid.gd")
const Solver := preload("res://scripts/solver.gd")
const Skins := preload("res://scripts/skins.gd")

const CELL := 24
const GOLD := Color("ffd23f")
const DIM := Color(1, 1, 1, 0.6)
const BAD := Color("ff6b5b")
const GOOD := Color("7fd67f")
const FLOOR := Color("1d2030")
const WALL := Color("4a5068")
const EDGE := Color("7a82a3")
## Tiles in the palette, as [tile, name].
const TOOLS := [
	["#", "Wall"], [".", "Floor"], ["c", "Coin"], ["^", "Spikes"],
	["x", "Cracked wall"], ["f", "Fake floor"], ["S", "Start"], ["G", "Exit"],
]
## The search gives up past this many positions; huge open levels are
## still allowed, they just can't be checked before testing.
const SOLVER_LIMIT := 20000

var game
var level := {}
var index := -1                  # place in game.custom_levels, -1 if not saved yet
var tool := "#"
var tested := false              # beaten since the last change
var changed := false
var _canvas: Control
var _name_edit: LineEdit
var _time_label: Label
var _status: Label
var _tool_buttons := {}
var _pending_clear := false
var _painting := false


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
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	column.add_child(top)
	_button(top, "Back", _back, false)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Level name"
	_name_edit.max_length = LevelCode.MAX_NAME
	_name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	_name_edit.add_theme_font_size_override("font_size", 16)
	_name_edit.text_changed.connect(func(t):
		level.name = t
		changed = true)
	top.add_child(_name_edit)

	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 6)
	column.add_child(time_row)
	_button(time_row, "-", func(): _change_time(-LevelCode.TIME_STEP), false).custom_minimum_size.x = 40
	_time_label = _label("", 16)
	_time_label.custom_minimum_size.x = 86
	time_row.add_child(_time_label)
	_button(time_row, "+", func(): _change_time(LevelCode.TIME_STEP), false).custom_minimum_size.x = 40
	_status = _label("", 13, DIM)
	_status.size_flags_horizontal = SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_row.add_child(_status)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(LevelCode.WIDTH * CELL, LevelCode.HEIGHT * CELL)
	_canvas.size_flags_horizontal = SIZE_SHRINK_CENTER
	_canvas.mouse_filter = MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_grid)
	_canvas.gui_input.connect(_on_grid_input)
	column.add_child(_canvas)

	var palette := HBoxContainer.new()
	palette.add_theme_constant_override("separation", 3)
	palette.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(palette)
	for t in TOOLS:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(40, 40)
		b.tooltip_text = t[1]
		var tile: String = t[0]
		b.draw.connect(func(): _draw_tile(b, Rect2(Vector2(8, 8), b.size - Vector2(16, 16)), tile))
		b.pressed.connect(func(): _pick_tool(tile))
		palette.add_child(b)
		_tool_buttons[tile] = b

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	bottom.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(bottom)
	_button(bottom, "CLEAR", _clear, true)
	_button(bottom, "TEST", _test, true)
	_button(bottom, "SHARE", _share, true)
	visible = false


## Opens `lv` for editing. `at` is its place in the player's list, or -1.
func open(lv: Dictionary, at: int) -> void:
	level = lv.duplicate(true)
	index = at
	tested = false
	changed = at < 0
	_pending_clear = false
	_name_edit.text = level.name
	_pick_tool("#")
	open_again()


## Comes back to the level being edited, after testing it.
func open_again() -> void:
	visible = true
	_refresh()


## Called when the level is beaten in a test run.
func mark_tested() -> void:
	tested = true
	_save()


func _refresh() -> void:
	_time_label.text = tr("Time %s") % game._clock(level.time)
	var problem := LevelCode.problem(level)
	if problem != "":
		_status.text = tr(problem)
		_status.add_theme_color_override("font_color", BAD)
	elif tested:
		_status.text = tr("Beaten! Ready to share")
		_status.add_theme_color_override("font_color", GOOD)
	else:
		_status.text = tr(_tool_name(tool))
		_status.add_theme_color_override("font_color", DIM)
	_canvas.queue_redraw()


func _tool_name(t: String) -> String:
	for entry in TOOLS:
		if entry[0] == t:
			return entry[1]
	return ""


func _pick_tool(t: String) -> void:
	tool = t
	for key in _tool_buttons:
		_tool_buttons[key].set_pressed_no_signal(key == t)
	_refresh()


func _change_time(amount: int) -> void:
	level.time = clampi(level.time + amount, LevelCode.MIN_TIME, LevelCode.MAX_TIME)
	_edited()


func _edited() -> void:
	changed = true
	tested = false
	_pending_clear = false
	_refresh()


# --- Painting ----------------------------------------------------------------

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_painting = event.pressed
		if event.pressed:
			paint(_cell_at(event.position))
	elif event is InputEventMouseMotion and _painting:
		paint(_cell_at(event.position))


func _cell_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


## Puts the current tool's tile at `c`. There's only one start, so placing
## it moves it.
func paint(c: Vector2i) -> void:
	if c.x < 0 or c.y < 0 or c.x >= LevelCode.WIDTH or c.y >= LevelCode.HEIGHT:
		return
	var rows: Array = level.rows
	if rows[c.y][c.x] == tool:
		return
	if tool == "S":
		for y in rows.size():
			rows[y] = (rows[y] as String).replace("S", ".")
	var row: String = rows[c.y]
	rows[c.y] = row.substr(0, c.x) + tool + row.substr(c.x + 1)
	_edited()


func _clear() -> void:
	if not _pending_clear:
		_pending_clear = true
		_status.text = tr("Tap CLEAR again to empty the level")
		_status.add_theme_color_override("font_color", BAD)
		return
	var fresh := LevelCode.blank(level.name)
	fresh.time = level.time
	level = fresh
	_edited()


# --- Test, share and leave ---------------------------------------------------

func _test() -> void:
	var problem := LevelCode.problem(level)
	if problem != "":
		game._toast(tr(problem))
		return
	if solve() == 0:
		_status.text = tr("No way to reach an exit yet")
		_status.add_theme_color_override("font_color", BAD)
		return
	_save()
	game.start_level(level.duplicate(true), "test")


func _share() -> void:
	var problem := LevelCode.problem(level)
	if problem != "":
		game._toast(tr(problem))
		return
	if not tested:
		_status.text = tr("Beat your level with TEST before sharing it")
		_status.add_theme_color_override("font_color", BAD)
		return
	_save()
	visible = false
	game.levels_screen.open()
	game.levels_screen._show_code_panel(true, game.custom_levels[index])


func _back() -> void:
	if changed:
		_save()
	visible = false
	game.levels_screen.open()


func _save() -> void:
	index = game.save_custom_level(level, index)
	changed = false


## The fewest moves that reach an exit, 0 if there's no way, or -1 if the
## level is too open to check.
func solve() -> int:
	var grid := LevelGrid.new()
	grid.load_rows(level.rows)
	var solver := Solver.new(grid)
	solver.max_states = SOLVER_LIMIT
	solver.run()
	if not solver.solution.is_empty():
		return solver.solution.size()
	return -1 if solver.gave_up else 0


# --- Drawing -----------------------------------------------------------------

func _draw_grid() -> void:
	for y in LevelCode.HEIGHT:
		for x in LevelCode.WIDTH:
			_draw_tile(_canvas, Rect2(x * CELL, y * CELL, CELL, CELL), level.rows[y][x])
	var line := Color(1, 1, 1, 0.05)
	for x in LevelCode.WIDTH + 1:
		_canvas.draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, LevelCode.HEIGHT * CELL), line)
	for y in LevelCode.HEIGHT + 1:
		_canvas.draw_line(Vector2(0, y * CELL), Vector2(LevelCode.WIDTH * CELL, y * CELL), line)


func _draw_tile(canvas: CanvasItem, r: Rect2, t: String) -> void:
	var mid := r.get_center()
	var s := r.size.x
	canvas.draw_rect(r, FLOOR)
	match t:
		"#":
			canvas.draw_rect(r, WALL)
			canvas.draw_rect(Rect2(r.position, Vector2(s, s * 0.15)), EDGE)
		"c":
			canvas.draw_circle(mid, s * 0.24, GOLD)
		"^":
			var w := (s - 4) / 3.0
			for i in 3:
				var bx := r.position.x + 2 + i * w
				canvas.draw_colored_polygon(PackedVector2Array([
					Vector2(bx, r.end.y - 2), Vector2(bx + w * 0.5, r.position.y + s * 0.25), Vector2(bx + w, r.end.y - 2),
				]), Color("e84855"))
		"x":
			Skins.draw_cracked(canvas, r, game._wall_skin())
		"f":
			canvas.draw_rect(r.grow(-2), Color(0, 0, 0, 0.35))
			canvas.draw_line(r.position + Vector2(s * 0.25, s * 0.3), mid, Color(1, 1, 1, 0.3), 1.5)
			canvas.draw_line(mid, r.end - Vector2(s * 0.3, s * 0.2), Color(1, 1, 1, 0.3), 1.5)
		"S":
			Skins.draw_hero(canvas, mid, Vector2(s, s) * 0.75, game._hero_skin().color)
		"G":
			canvas.draw_circle(mid, s * 0.42, Color(GOLD, 0.35))
			canvas.draw_circle(mid, s * 0.3, GOLD)
			canvas.draw_circle(mid, s * 0.13, Color.WHITE)


# --- Helpers ---------------------------------------------------------------

func _button(parent: Node, text: String, action: Callable, big: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 44 if big else 40
	if big:
		b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18 if big else 16)
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
