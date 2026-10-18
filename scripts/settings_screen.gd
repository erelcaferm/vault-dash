extends Control
## Settings: sound, music, vibration and language. Opened from the gear button on
## the menu; the values live in main.gd, which saves them.

signal closed

## Every language the game is translated into, as [locale, its own name].
const LANGUAGES := [
	["en", "English"],
	["es", "Español"],
	["fr", "Français"],
	["de", "Deutsch"],
	["tr", "Türkçe"],
	["ru", "Русский"],
	["zh_CN", "简体中文"],
	["zh_TW", "繁體中文"],
]

const GOLD := Color("ffd23f")

var game
var _sound: Button
var _vibration: Button
var _music: Button
var _language_buttons := {}


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
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_label("SETTINGS", 28))
	_sound = _toggle(column, func():
		game.sfx.enabled = not game.sfx.enabled
		game.sfx.play("coin")
		_after_change())
	_music = _toggle(column, func():
		game.sfx.music_enabled = not game.sfx.music_enabled
		game.sfx.update_music()
		_after_change())
	_vibration = _toggle(column, func():
		game.vibration_on = not game.vibration_on
		game.vibrate(40)
		_after_change())

	var heading := _label("LANGUAGE", 16, Color(1, 1, 1, 0.6))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for lang in LANGUAGES:
		var b := Button.new()
		b.text = lang[1]
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func():
			game.set_language(lang[0])
			_after_change())
		grid.add_child(b)
		_language_buttons[lang[0]] = b

	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(spacer)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 52
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	visible = true
	_refresh()


func _after_change() -> void:
	game._save()
	_refresh()


func _refresh() -> void:
	_sound.text = tr("Sound: %s") % tr("On" if game.sfx.enabled else "Off")
	_music.text = tr("Music: %s") % tr("On" if game.sfx.music_enabled else "Off")
	_vibration.text = tr("Vibration: %s") % tr("On" if game.vibration_on else "Off")
	var current: String = game.language if game.language != "" else game.device_locale()
	for locale in _language_buttons:
		_language_buttons[locale].set_pressed_no_signal(locale == current)


func _toggle(parent: Node, action: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size.y = 52
	b.add_theme_font_size_override("font_size", 20)
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
