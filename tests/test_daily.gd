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
	_expect(game.daily_medal == 0 and game.total_coins == coins_before, "climbing alone doesn't pay a medal")
	_reach_floor(game, 20)
	_expect(game.daily_best == 20 and game.daily_medal == 0, "today's best floor is tracked")
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

	# Reaching the top records the time and wins a medal. Better medals later
	# in the day pay only the prizes not yet won.
	var times: Array = game.medal_times()
	_expect(times[0] > 20.0 and times[1] > times[0] and times[1] < 200.0, "medal times are sensible (%s)" % str(times))
	_expect(game.medal_times() == times, "medal times are the same all day")
	var bronze: float = times[1] + 10.25
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.elapsed = bronze
	game.run_coins = 0
	game._win()
	_expect(game.state == game.State.WON and is_equal_approx(game.daily_time, bronze), "reaching the top records the time")
	_expect(game.daily_medal == 1 and game.total_coins == coins_before + game.BRONZE_COINS, "a slow finish wins bronze and its coins")
	_expect(game.daily_best == game.DAILY_TOP, "a finish counts as the top floor")
	_expect(game.message_label.text.contains(game.time_text(bronze)), "the time is shown (got: %s)" % game.message_label.text)
	game.reset()
	_expect(game.message_label.text.contains(game.time_text(bronze)), "the daily intro shows today's best time")
	_expect(game.message_label.text.contains(game.time_text(times[0])), "the daily intro shows the gold time")
	game._on_swipe(Vector2i.UP)
	game.elapsed = bronze + 20.0
	game.run_coins = 0
	game._win()
	_expect(is_equal_approx(game.daily_time, bronze), "a slower finish doesn't replace the best time")
	_expect(game.total_coins == coins_before + game.BRONZE_COINS, "bronze pays once")
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.elapsed = (times[0] + times[1]) / 2.0
	game.run_coins = 0
	game._win()
	_expect(game.daily_medal == 2 and game.message_label.text.contains(game.tr("New best time!")), "a faster finish wins silver")
	_expect(game.total_coins == coins_before + game.BRONZE_COINS + game.SILVER_COINS, "going up to silver pays only silver's prize")
	_expect(game.pending_chests == 0, "silver has no chest")
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.elapsed = times[0] - 5.0
	game.run_coins = 0
	game._win()
	_expect(game.daily_medal == 3 and game.pending_chests == 1, "gold wins a chest")
	_expect(game.total_coins == coins_before + game.BRONZE_COINS + game.SILVER_COINS, "gold pays no coins twice")
	_expect(game.stat("daily_golds") == 1 and game.unlocked.has("first_gold"), "the first gold unlocks Podium")
	game._on_tap()
	_expect(game.chest_screen.visible, "the gold chest opens as the run ends")
	game.chest_screen.visible = false
	game.pending_chests = 0
	game.state = game.State.WON
	var finished_ghost: PackedVector2Array = game.daily_ghost
	game.reset()
	game._on_swipe(Vector2i.UP)
	game._die("Test on floor %d", "lava")
	_expect(game.daily_ghost == finished_ghost, "a run that didn't finish never replaces a finished ghost")
	_expect(game.time_text(47.26) == "47.3 s" and game.time_text(125.0) == "2:05.0", "times read as seconds, or minutes past a minute")

	# Climbing 200 floors in a day, over any runs, earns a chest once.
	game.daily_mode = false
	game.reset()
	game.floors_today = 0
	game.floors_day = game.today()
	game._count_daily_floors(150)
	_expect(game.pending_chests == 0 and game.daily_chest_left() == 50, "150 floors: 50 to go")
	game._count_daily_floors(60)
	_expect(game.pending_chests == 1 and game.daily_chest_left() == 0, "200 floors in a day earns a chest")
	game._count_daily_floors(200)
	_expect(game.pending_chests == 1, "only one daily chest a day")
	game.pending_chests = 0
	game._save()
	game.queue_free()

	var next_day = _new_game("2026-10-19")
	await process_frame
	_expect(next_day.daily_best == 0 and next_day.daily_medal == 0 and next_day.daily_time == 0.0, "a new day resets the best, the time and the medal")
	_expect(next_day.daily_chest_left() == next_day.DAILY_CHEST_FLOORS, "a new day starts the daily chest count again")
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
