extends SceneTree
## Checks the Daily Climb: same tower per day, the daily goal, and streaks.
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
	_reach_floor(game, 14)
	_expect(not game.daily_claimed, "floor 14 isn't the daily goal")
	_reach_floor(game, 15)
	_expect(game.daily_claimed and game.total_coins == coins_before + game.DAILY_REWARD, "floor 15 pays the daily reward")
	_reach_floor(game, 20)
	_expect(game.total_coins == coins_before + game.DAILY_REWARD, "the daily reward pays once")
	_expect(game.daily_best == 20, "today's best is tracked")
	game._die("Test on floor %d", "lava")
	game.reset()
	game._on_swipe(Vector2i.UP)
	_expect(game.daily_streak == 1 and game.stat("daily_days") == 1, "a second run the same day doesn't count again")
	game._save()
	game.queue_free()

	var next_day = _new_game("2026-10-19")
	await process_frame
	_expect(next_day.daily_best == 0 and not next_day.daily_claimed, "a new day resets the best and the reward")
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
