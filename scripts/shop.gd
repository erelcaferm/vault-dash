extends Control
## The coin shop: hero colours, hats, cracked-wall skins, slide trails and lava.
## Coins, owned items and what's equipped live in main.gd, which saves them.

signal closed

const Skins := preload("res://scripts/skins.gd")
const Preview := preload("res://scripts/skin_preview.gd")
const Achievements := preload("res://scripts/achievements.gd")
const PillStyle := preload("res://scripts/pill_style.gd")

const GOLD := Color("ffd23f")
const DIM := Color(1, 1, 1, 0.5)

var game
var tab := "hero"
var pending_buy := ""            # the item waiting for a second tap to confirm
var _coins_label: Label
var _scroll: ScrollContainer
var _grid: GridContainer
var _tab_buttons := {}
var _ad_button: Button


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
	tabs.add_theme_constant_override("separation", 5)
	column.add_child(tabs)
	for t in [["hero", "Hero"], ["hat", "Hats"], ["walls", "Walls"], ["trail", "Trails"], ["lava", "Lava"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_show_tab.bind(t[0]))
		var dot := Panel.new()       # shown while the tab has NEW items
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = Color("ff4d4d")
		dot_style.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", dot_style)
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		dot.set_anchors_preset(PRESET_TOP_RIGHT)
		dot.offset_left = -12
		dot.offset_right = -2
		dot.offset_top = 2
		dot.offset_bottom = 12
		b.add_child(dot)
		tabs.add_child(b)
		_tab_buttons[t[0]] = b

	_ad_button = Button.new()
	_ad_button.custom_minimum_size.y = 40
	_ad_button.add_theme_font_size_override("font_size", 15)
	for key in ["normal", "hover", "pressed", "disabled"]:
		_ad_button.add_theme_stylebox_override(key, PillStyle.new(Color("3aa856") if key != "disabled" else Color("3a4a3e"), key == "pressed"))
	_ad_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_ad_button.add_theme_color_override("font_outline_color", Color("10361a"))
	_ad_button.add_theme_constant_override("outline_size", 4)
	_ad_button.pressed.connect(func():
		if game.ad_shop_coins():
			_refresh())
	column.add_child(_ad_button)

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
	back.pressed.connect(func():
		_mark_tab_seen()
		closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	pending_buy = ""
	visible = true
	# Start on a tab with something new in it.
	for t in _tab_buttons:
		if _has_new(t):
			tab = t
			break
	_show_tab(tab)


func _show_tab(t: String) -> void:
	if t != tab:
		_mark_tab_seen()
		_scroll.scroll_vertical = 0
	tab = t
	pending_buy = ""
	_refresh()


func _refresh() -> void:
	_coins_label.text = "● %d" % game.total_coins
	var left: int = game.ad_coins_left()
	_ad_button.visible = game.ads.can_show_rewarded()
	_ad_button.disabled = left <= 0
	_ad_button.text = tr("Watch an ad: +%d coins (%d left today)") % [game.Ads.SHOP_COINS, left] if left > 0 else tr("No more ads today")
	var keep := _scroll.scroll_vertical
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for k in _tab_buttons:
		var b: Button = _tab_buttons[k]
		b.set_pressed_no_signal(k == tab)
		b.get_child(0).visible = _has_new(k) and k != tab
	var items: Array = Skins.list(tab)
	for item in items:
		_grid.add_child(_card(item))
	_scroll.set_deferred("scroll_vertical", keep)


func _card(item: Dictionary) -> Button:
	var equipped: String = {"hero": game.equipped_hero, "hat": game.equipped_hat, "walls": game.equipped_wall, "trail": game.equipped_trail, "lava": game.equipped_lava}[tab]
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
	preview.kind = tab
	preview.hero = game._hero_skin()
	preview.size_flags_vertical = SIZE_EXPAND_FILL
	preview.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(preview)
	var name_label := _label(item.name, 16)
	game.fit_font(name_label, 100, 11)
	box.add_child(name_label)

	var status: Label
	if item.id == equipped:
		status = _label("Equipped", 14, GOLD)
	elif owned:
		status = _label("Tap to use", 14, DIM)
	elif item.get("chest_only", false):
		status = _label("Chest only", 14, Color("ffd700"))
	elif item.has("achievement"):
		status = _label(Achievements.find(item.achievement).get("name", "Achievement"), 13, Color("7fd6ff"))
	elif item.has("level"):
		status = _label(tr("Level %d") % item.level, 13, Color("7fd6ff"))
	elif pending_buy == item.id:
		status = _label("Tap to buy!", 14, GOLD)
	elif game.total_coins >= item.price:
		status = _label("● %d" % item.price, 15, GOLD)
	else:
		status = _label("● %d" % item.price, 15, DIM)
	game.fit_font(status, 100, 10)
	box.add_child(status)
	if game.new_items.has(item.id):
		var badge := _label("NEW", 12, Color.WHITE)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("e8382f")
		badge_style.set_corner_radius_all(4)
		badge_style.content_margin_left = 5
		badge_style.content_margin_right = 5
		badge.add_theme_stylebox_override("normal", badge_style)
		badge.position = Vector2(4, 4)
		b.add_child(badge)
	b.pressed.connect(_on_card.bind(item))
	return b


func _on_card(item: Dictionary) -> void:
	if game.owns(item):
		game.equip(tab, item.id)
		pending_buy = ""
	elif item.get("chest_only", false) or item.has("achievement") or item.has("level"):
		pending_buy = ""
	elif pending_buy == item.id:
		game.buy(tab, item)
		pending_buy = ""
	elif game.total_coins >= item.price:
		pending_buy = item.id
	else:
		pending_buy = ""
		game.sfx.play("error")
	_refresh()


func _has_new(t: String) -> bool:
	for item in Skins.list(t):
		if game.new_items.has(item.id):
			return true
	return false


## Leaving a tab counts as having seen its new items.
func _mark_tab_seen() -> void:
	for item in Skins.list(tab):
		game.seen(item.id)
	game._save()


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
