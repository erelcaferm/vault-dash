extends Control
## Settings: sound and music (each with a volume slider), vibration and language. Opened from the gear button on
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
var _sound_volume: HSlider
var _music_volume: HSlider
var _sound_percent: Label
var _music_percent: Label
var _preview_cooldown := 0.0
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
	var sound_row := _row(column)
	_sound = _toggle(sound_row, func():
		game.sfx.enabled = not game.sfx.enabled
		game.sfx.play("coin")
		_after_change())
	_sound_volume = _slider(sound_row, func(v: float):
		game.sfx.set_volume(v / 100.0)
		# A coin now and then while dragging, so you hear the new level.
		if _preview_cooldown <= 0.0:
			game.sfx.play("coin")
			_preview_cooldown = 0.15
		_after_change())
	_sound_percent = _percent(sound_row)
	var music_row := _row(column)
	_music = _toggle(music_row, func():
		game.sfx.music_enabled = not game.sfx.music_enabled
		game.sfx.update_music()
		_after_change())
	_music_volume = _slider(music_row, func(v: float):
		game.sfx.set_music_volume(v / 100.0)
		_after_change())
	_music_percent = _percent(music_row)
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


func _process(delta: float) -> void:
	_preview_cooldown = maxf(_preview_cooldown - delta, 0.0)


func _after_change() -> void:
	game._save()
	_refresh()


func _refresh() -> void:
	_sound.text = tr("Sound: %s") % tr("On" if game.sfx.enabled else "Off")
	_music.text = tr("Music: %s") % tr("On" if game.sfx.music_enabled else "Off")
	_vibration.text = tr("Vibration: %s") % tr("On" if game.vibration_on else "Off")
	_sound_volume.set_value_no_signal(roundf(game.sfx.volume * 100.0))
	_music_volume.set_value_no_signal(roundf(game.sfx.music_volume * 100.0))
	_sound_volume.editable = game.sfx.enabled
	_music_volume.editable = game.sfx.music_enabled
	_sound_percent.text = "%d%%" % roundi(game.sfx.volume * 100.0)
	_music_percent.text = "%d%%" % roundi(game.sfx.music_volume * 100.0)
	_sound_percent.modulate.a = 1.0 if game.sfx.enabled else 0.4
	_music_percent.modulate.a = 1.0 if game.sfx.music_enabled else 0.4
	var current: String = game.language if game.language != "" else game.device_locale()
	for locale in _language_buttons:
		_language_buttons[locale].set_pressed_no_signal(locale == current)


func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	return row


## A 0-100 volume slider with a big, easy-to-grab handle.
func _slider(parent: Node, action: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.size_flags_horizontal = SIZE_EXPAND_FILL
	s.size_flags_stretch_ratio = 1.1
	s.size_flags_vertical = SIZE_SHRINK_CENTER
	s.custom_minimum_size.y = 40
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.15)
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", track)
	var fill := track.duplicate()
	fill.bg_color = GOLD
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _knob(Color.WHITE)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.add_theme_icon_override("grabber_disabled", _knob(Color(1, 1, 1, 0.35)))
	s.value_changed.connect(action)
	parent.add_child(s)
	return s


static func _knob(color: Color) -> ImageTexture:
	const SIZE := 26
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var r := SIZE * 0.5
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(color, color.a * clampf(r - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _percent(parent: Node) -> Label:
	var label := _label("", 16, Color(1, 1, 1, 0.8))
	label.custom_minimum_size.x = 48
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(label)
	return label


func _toggle(parent: Node, action: Callable) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 52
	b.add_theme_font_size_override("font_size", 17)
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
