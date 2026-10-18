extends SceneTree
## Checks the gear opens settings, toggles save, and languages switch the text.
## Run: godot --headless --path . --script res://tests/test_settings.gd

const SAVE := "user://test_settings_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_seed = 3
	root.add_child(game)
	await process_frame

	_expect(game.gear_button.visible, "the gear shows on the title screen")
	game._open_settings()
	_expect(game.settings_screen.visible, "the gear opens settings")
	var sound: bool = game.sfx.enabled
	game.settings_screen._sound.pressed.emit()
	_expect(game.sfx.enabled != sound, "the sound toggle flips sound")
	_expect(game.sfx.music_enabled and game.sfx.music.playing, "music plays by default")
	game.settings_screen._music.pressed.emit()
	_expect(not game.sfx.music_enabled and not game.sfx.music.playing, "the music toggle stops the music")
	var screen = game.settings_screen
	screen._sound.pressed.emit()
	screen._sound_volume.value = 40
	_expect(is_equal_approx(game.sfx.volume, 0.4) and game.sfx._players[0].volume_db < -5.0, "the sound slider turns sounds down")
	_expect(screen._sound_percent.text == "40%", "the slider shows its level")
	screen._music_volume.value = 0
	_expect(game.sfx.music_volume == 0.0 and game.sfx.music.volume_db <= -60.0, "the music slider can mute the music")
	screen._music_volume.value = 70
	_expect(not screen._music_volume.editable, "the music slider is greyed out while music is off")
	game.settings_screen._language_buttons["es"].pressed.emit()
	_expect(TranslationServer.get_locale() == "es", "picking Español switches to Spanish")
	_expect(tr("SHOP") == "TIENDA", "Spanish text is loaded")
	for locale in ["fr", "de", "tr", "ru", "zh_CN", "zh_TW"]:
		game.set_language(locale)
		_expect(tr("SHOP") != "SHOP" or locale == "de", "%s text is loaded" % locale)
	game.set_language("es")
	game._save()
	game.settings_screen.closed.emit()
	_expect(not game.settings_screen.visible, "Back closes settings")

	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	_expect(cfg.get_value("settings", "language", "") == "es", "the language is saved")
	_expect(cfg.get_value("settings", "sound", true) == game.sfx.enabled, "the sound setting is saved")
	_expect(cfg.get_value("settings", "music", true) == false, "the music setting is saved")
	_expect(is_equal_approx(cfg.get_value("settings", "sound_volume", 1.0), 0.4), "the sound volume is saved")
	_expect(is_equal_approx(cfg.get_value("settings", "music_volume", 1.0), 0.7), "the music volume is saved")

	game._on_swipe(Vector2i.UP)
	_expect(not game.gear_button.visible, "the gear hides during a run")
	game.pause()
	_expect(game.gear_button.visible, "the gear (and the volume) is there while paused")
	game.resume()

	for id in ["click", "buy", "error", "open", "countdown", "time_up", "level_clear", "start", "paint", "erase"]:
		_expect(game.sfx.sounds.has(id) and game.sfx.sounds[id].data.size() > 0, "the %s sound is made" % id)
	var clicks := 0
	for c in game.shop_button.pressed.get_connections():
		if c.callable == Callable(game, "_click"):
			clicks += 1
	_expect(clicks == 1, "buttons click once")

	game.set_language("")
	_expect(TranslationServer.get_locale() == game.device_locale(), "auto follows the phone's language")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("PASS: gear, settings toggles, volume and languages" if failures == 0 else "FAIL: %d settings checks" % failures)
	quit(1 if failures else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
