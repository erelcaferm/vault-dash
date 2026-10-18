extends SceneTree
## Checks the Daily Climb: same tower per day, the top floor and best time,
## the reward, and streaks.
## Run: godot --headless --path . --script res://tests/test_daily.gd

const Skins := preload("res://scripts/skins.gd")
const Achievements := preload("res://scripts/achievements.gd")
const SAVE := "user://test_daily_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = _new_game("2026-10-18")
	await process_frame
	var main_script = game.get_script()
	_expect(main_script.daily_seed("2026-10-18") == main_script.daily_seed("2026-10-18"), "a date always gives the same seed")
	_expect(main_script.daily_seed("2026-10-18") != main_script.daily_seed("2026-10-19"), "each day gets its own seed")

	game.daily_mode = true
	game.reset()
	var first := _layouts(game)
	game.reset()
	_expect(_layouts(game) == first, "the daily tower is the same every run that day")
	game.daily_mode = false
	game.reset()
	_expect(_layouts(game) != first, "endless runs get a random tower")

	game.daily_mode = true
	game.reset()
	game.total_coins = 0
	game._on_swipe(Vector2i.UP)
	_expect(game.daily_streak == 1 and game.stat("daily_days") == 1, "the first Daily Climb starts a streak")
	_expect(game.unlocked.has("daily_climber"), "the first Daily Climb unlocks Daily Climber")
	# Unlock every other trophy first, so only the daily reward pays coins here.
	for a in Achievements.LIST:
		if not game.unlocked.has(a.id) and a.stat != "daily_streak":
			game.unlocked.append(a.id)
	# ...and park the missions on goals out of reach.
	for m in game.missions:
		m.goal = 99999
	var coins_before: int = game.total_coins
	_expect(game.tower.room_limit == game.DAILY_TOP, "the daily tower stops at floor %d" % game.DAILY_TOP)
	_expect(game.tower.get_tile(Vector2i(6, -game.DAILY_TOP * 12 - 3)) == "G", "above the top floor is the finish")
	_reach_floor(game, 15)
	_expect(not game.daily_claimed and game.total_coins == coins_before, "climbing alone doesn't pay the reward")
	_reach_floor(game, 20)
	_expect(game.daily_best == 20 and not game.daily_claimed, "today's best floor is tracked")
	for i in 5:
		await process_frame
	game._die("Test on floor %d", "lava")
	_expect(game.daily_ghost.size() >= 3, "a new daily best is saved as the ghost")
	var ghost: PackedVector2Array = game.daily_ghost
	game.reset()
	game._on_swipe(Vector2i.UP)
	for i in 3:
		await process_frame
	game._die("Test on floor %d", "lava")
	_expect(game.daily_ghost == ghost, "a worse run doesn't replace the ghost")
	game.reset()
	game._on_swipe(Vector2i.UP)
	_expect(game.daily_streak == 1 and game.stat("daily_days") == 1, "a second run the same day doesn't count again")

	# Reaching the top records the time and pays the reward once.
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.elapsed = 95.25
	game.run_coins = 0
	game._win()
	_expect(game.state == game.State.WON and is_equal_approx(game.daily_time, 95.25), "reaching the top records the time")
	_expect(game.daily_claimed and game.total_coins == coins_before + game.DAILY_REWARD, "the first finish pays the daily reward")
	_expect(game.daily_best == game.DAILY_TOP, "a finish counts as the top floor")
	_expect(game.message_label.text.contains("1:35.3"), "the time is shown (got: %s)" % game.message_label.text)
	game.reset()
	_expect(game.message_label.text.contains("1:35.3"), "the daily intro shows today's best time")
	game._on_swipe(Vector2i.UP)
	game.elapsed = 120.0
	game.run_coins = 0
	game._win()
	_expect(is_equal_approx(game.daily_time, 95.25), "a slower finish doesn't replace the best time")
	_expect(game.total_coins == coins_before + game.DAILY_REWARD, "the daily reward pays once")
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.elapsed = 61.0
	game.run_coins = 0
	game._win()
	_expect(is_equal_approx(game.daily_time, 61.0) and game.message_label.text.contains(game.tr("New best time!")), "a faster finish is the new best")
	var finished_ghost: PackedVector2Array = game.daily_ghost
	game.reset()
	game._on_swipe(Vector2i.UP)
	game._die("Test on floor %d", "lava")
	_expect(game.daily_ghost == finished_ghost, "a run that didn't finish never replaces a finished ghost")
	_expect(game.time_text(47.26) == "47.3 s" and game.time_text(125.0) == "2:05.0", "times read as seconds, or minutes past a minute")
	game._save()
	game.queue_free()

	var next_day = _new_game("2026-10-19")
	await process_frame
	_expect(next_day.daily_best == 0 and not next_day.daily_claimed and next_day.daily_time == 0.0, "a new day resets the best, the time and the reward")
	_expect(next_day.daily_ghost.is_empty(), "a new day clears the ghost")
	next_day.daily_mode = true
	next_day.reset()
	next_day._on_swipe(Vector2i.UP)
	_expect(next_day.daily_streak == 2, "the next day continues the streak")
	for day in ["2026-10-20", "2026-10-21", "2026-10-22", "2026-10-23", "2026-10-24"]:
		_expect(not next_day.owns(Skins.find(Skins.HERO, "sunrise")), "Sunrise is locked before a 7-day streak")
		next_day.test_today = day
		next_day.reset()
		next_day._on_swipe(Vector2i.UP)
	_expect(next_day.daily_streak == 7 and next_day.owns(Skins.find(Skins.HERO, "sunrise")), "a 7-day streak unlocks Sunrise")
	next_day.test_today = "2026-10-26"
	next_day.reset()
	next_day._on_swipe(Vector2i.UP)
	_expect(next_day.daily_streak == 1, "missing a day restarts the streak")
	next_day.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: daily tower, goal, reward and streaks")
	quit(1 if failures > 0 else 0)


func _layouts(game) -> Array:
	var out: Array = []
	for k in range(1, 30):
		out.append(game.tower.def_of(k))
	return out


## Puts the player in room `floor_number - 1` and counts the floor.
func _reach_floor(game, floor_number: int) -> void:
	game.cell = Vector2i(6, -(floor_number - 1) * 12 - 6)
	game._update_floor()


func _new_game(date: String):
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_today = date
	root.add_child(game)
	return game


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
