extends SceneTree
## Checks pausing freezes the run, and the "New best!" moment.
## Run: godot --headless --path . --script res://tests/test_pause.gd

const SAVE := "user://test_pause_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_seed = 3
	root.add_child(game)
	await process_frame

	_expect(not game.pause_button.visible, "no pause button on the title screen")
	game._on_swipe(Vector2i.UP)
	_expect(game.pause_button.visible, "the pause button shows while playing")
	game.move_dir = Vector2i.UP
	game.pause()
	_expect(game.state == game.State.PAUSED and game.message_label.visible, "pausing shows the pause screen")
	var lava: float = game.lava_y
	var cell: Vector2i = game.cell
	var time: float = game.elapsed
	for i in 30:
		await process_frame
	_expect(game.lava_y == lava and game.cell == cell and game.elapsed == time, "nothing moves while paused")
	game._on_swipe(Vector2i.LEFT)
	_expect(game.state == game.State.PLAYING and game.move_dir == Vector2i.UP, "a swipe resumes the same slide without turning")
	_expect(not game.message_label.visible and game.pause_button.visible, "resuming hides the pause screen")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(game.state == game.State.PAUSED, "leaving the app pauses")
	game._on_tap()
	_expect(game.state == game.State.PLAYING, "a tap resumes")

	game.best_floor = 3
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.cell = Vector2i(6, -2 * 12 - 6)
	game._update_floor()
	_expect(not game.new_best_shown, "matching your best isn't a new best")
	game.cell = Vector2i(6, -3 * 12 - 6)
	game._update_floor()
	_expect(game.new_best_shown and game.toast_label.text == "NEW BEST!", "passing your best celebrates")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: pause freezes the run, new best celebrates")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
