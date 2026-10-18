extends Control
## The coin shop: hero colours and cracked-wall skins.
## Coins, owned items and what's equipped live in main.gd, which saves them.

signal closed

const Skins := preload("res://scripts/skins.gd")
const Preview := preload("res://scripts/skin_preview.gd")

const GOLD := Color("ffd23f")
const DIM := Color(1, 1, 1, 0.5)

var game
var tab := "hero"
var pending_buy := ""            # the item waiting for a second tap to confirm
var _coins_label: Label
var _scroll: ScrollContainer
var _grid: GridContainer
var _tab_buttons := {}


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
	var title := _label("SHOP", 28)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_coins_label = _label("", 24, GOLD)
	header.add_child(_coins_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	for t in [["hero", "Hero"], ["walls", "Cracked walls"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_show_tab.bind(t[0]))
		tabs.add_child(b)
		_tab_buttons[t[0]] = b

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 52
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	pending_buy = ""
	visible = true
	_show_tab(tab)


func _show_tab(t: String) -> void:
	if t != tab:
		_scroll.scroll_vertical = 0
	tab = t
	pending_buy = ""
	for k in _tab_buttons:
		_tab_buttons[k].set_pressed_no_signal(k == t)
	_refresh()


func _refresh() -> void:
	_coins_label.text = "● %d" % game.total_coins
	var keep := _scroll.scroll_vertical
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var items: Array = Skins.HERO if tab == "hero" else Skins.WALLS
	for item in items:
		_grid.add_child(_card(item))
	_scroll.set_deferred("scroll_vertical", keep)


func _card(item: Dictionary) -> Button:
	var equipped: String = game.equipped_hero if tab == "hero" else game.equipped_wall
	var owned: bool = game.owns(item)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 132)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	if item.id == equipped:
		var ring := StyleBoxFlat.new()
		ring.bg_color = Color(1, 1, 1, 0.08)
		ring.border_color = GOLD
		ring.set_border_width_all(3)
		ring.set_corner_radius_all(6)
		for state in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, ring)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.offset_top = 6
	box.offset_bottom = -6
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	b.add_child(box)
	var preview := Preview.new()
	preview.item = item
	preview.kind = "hero" if tab == "hero" else "walls"
	preview.size_flags_vertical = SIZE_EXPAND_FILL
	preview.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(preview)
	box.add_child(_label(item.name, 16))

	var status: Label
	if item.id == equipped:
		status = _label("Equipped", 14, GOLD)
	elif owned:
		status = _label("Tap to use", 14, DIM)
	elif item.get("chest_only", false):
		status = _label("Chest only", 14, Color("ffd700"))
	elif pending_buy == item.id:
		status = _label("Tap to buy!", 14, GOLD)
	elif game.total_coins >= item.price:
		status = _label("● %d" % item.price, 15, GOLD)
	else:
		status = _label("● %d" % item.price, 15, DIM)
	box.add_child(status)
	b.pressed.connect(_on_card.bind(item))
	return b


func _on_card(item: Dictionary) -> void:
	if game.owns(item):
		game.equip(tab, item.id)
		pending_buy = ""
	elif item.get("chest_only", false):
		pending_buy = ""
	elif pending_buy == item.id:
		game.buy(tab, item)
		pending_buy = ""
	elif game.total_coins >= item.price:
		pending_buy = item.id
	else:
		pending_buy = ""
	_refresh()


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
