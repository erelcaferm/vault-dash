extends SceneTree
## Checks missions: three at a time, progress, payout, replacement and saving.
## Run: godot --headless --path . --script res://tests/test_missions.gd

const Missions := preload("res://scripts/missions.gd")
const SAVE := "user://test_missions_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = _new_game()
	await process_frame
	_expect(game.missions.size() == Missions.ACTIVE, "there are always %d missions" % Missions.ACTIVE)
	var ids: Array = game._mission_ids()
	_expect(ids.size() == _unique(ids).size(), "active missions are all different")

	# A cumulative mission only counts progress made after it started.
	game.add_stat("walls_broken", 500)
	game.missions = [Missions.make(game.mission_rng, 0, _others("walls"), game.stat)]
	game._fill_missions()
	var walls: Dictionary = game.missions[0]
	_expect(walls.id == "walls" and walls.goal == 10 and walls.start == 500, "a new mission starts from the current count")
	game.total_coins = 0
	var done_before: int = game.stat("missions_done")
	game.add_stat("walls_broken", 9)
	_expect(walls.progress == 9 and game.missions[0] == walls, "progress counts up")
	game.add_stat("walls_broken")
	_expect(game.total_coins == walls.reward, "a finished mission pays its reward")
	_expect(game.stat("missions_done") == done_before + 1 and game.missions.size() == Missions.ACTIVE, "a finished mission is replaced")
	_expect(not game._mission_ids().has("walls") or game.missions[0] != walls, "the finished mission is gone")

	# A one-run mission resets each run.
	game.missions = [{"id": "coins_run", "goal": 20, "reward": 50, "progress": 0, "start": 0}]
	game._fill_missions()
	game._on_swipe(Vector2i.UP)
	game.report_run("run_coins", 15)
	_expect(game.missions[0].progress == 15, "one-run progress is tracked")
	game._die("Test on floor %d", "lava")
	game.reset()
	game._on_swipe(Vector2i.UP)
	_expect(game.missions[0].progress == 0, "one-run progress starts again each run")
	var before: int = game.total_coins
	game.report_run("run_coins", 20)
	_expect(game.total_coins == before + 50 and game.missions[0].id != "coins_run", "reaching the goal in one run pays")

	# Missions grow with the number finished.
	var easy := Missions.make(game.mission_rng, 0, [], func(_s): return 0)
	var t := Missions.find(easy.id)
	var hard := Missions.make(game.mission_rng, 30, _others(easy.id), func(_s): return 0)
	_expect(hard.goal > easy.goal and hard.reward > easy.reward, "later missions are bigger and pay more")
	_expect(t.has("text"), "missions have text")
	var saved: Array = game.missions.duplicate(true)
	game._save()
	game.queue_free()

	var again = _new_game()
	await process_frame
	_expect(again.missions == saved, "missions survive a restart")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: missions track, pay, refill and save")
	quit(1 if failures > 0 else 0)


func _others(id: String) -> Array:
	var out: Array = []
	for t in Missions.TEMPLATES:
		if t.id != id:
			out.append(t.id)
	return out


func _unique(a: Array) -> Array:
	var out: Array = []
	for x in a:
		if not out.has(x):
			out.append(x)
	return out


func _new_game():
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_seed = 3
	root.add_child(game)
	return game


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
