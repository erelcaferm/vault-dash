extends Control
## The daily gift: the first time you open the game each day, a strip of
## seven gifts shows, and you claim the next one. Missing a day never resets
## it; you just pick up where you left off. After day 7 (a chest) it starts
## again at day 1. Saved in main.gd as gift_day and gift_date.

signal claimed(reward: Dictionary)

const GOLD := Color("ffd23f")
const PillStyle := preload("res://scripts/pill_style.gd")

## One entry per day: coins, or a chest.
const GIFTS := [
	{"coins": 25}, {"coins": 50}, {"coins": 75}, {"coins": 100},
	{"coins": 125}, {"coins": 150}, {"chest": true},
]

var game
var _row: HBoxContainer
var _claim: Button


func setup(main_game) -> void:
	game = main_game
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = -120
	panel.offset_bottom = 120
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(_label("DAILY GIFT", 26, GOLD))
	column.add_child(_label("A gift every day you play.", 14, Color(1, 1, 1, 0.7)))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 4)
	column.add_child(_row)
	_claim = Button.new()
	_claim.text = "CLAIM"
	_claim.custom_minimum_size = Vector2(0, 48)
	_claim.add_theme_font_size_override("font_size", 22)
	for key in ["normal", "hover", "pressed"]:
		_claim.add_theme_stylebox_override(key, PillStyle.new(Color(0.85, 0.6, 0.1, 0.9), key == "pressed"))
	_claim.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_claim.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_claim.add_theme_constant_override("outline_size", 4)
	_claim.pressed.connect(_on_claim)
	column.add_child(_claim)
	visible = false


func open() -> void:
	for c in _row.get_children():
		_row.remove_child(c)
		c.queue_free()
	for i in GIFTS.size():
		_row.add_child(_day_card(i))
	visible = true


func _on_claim() -> void:
	visible = false
	claimed.emit(GIFTS[game.gift_day])


func _day_card(i: int) -> Control:
	var today: bool = i == game.gift_day
	var done: bool = i < game.gift_day
	var card := PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 74
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.12 if today else 0.05)
	style.set_corner_radius_all(6)
	if today:
		style.border_color = GOLD
		style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	box.add_child(_label(tr("Day %d") % (i + 1), 11, Color(1, 1, 1, 0.6)))
	var gift: Dictionary = GIFTS[i]
	var what := tr("Chest") if gift.has("chest") else "● %d" % gift.coins
	box.add_child(_label("✓" if done else what, 13 if not done else 18, Color("7fd67f") if done else GOLD))
	return card


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
