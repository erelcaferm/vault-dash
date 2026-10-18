extends SceneTree
## Checks Crack the Vault: hits and misses, prizes, and daily tries.
## Run: godot --headless --path . --script res://tests/test_vault.gd

const SAVE := "user://test_vault_save.cfg"
const VaultGame := preload("res://scripts/vault_game.gd")

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_today = "2026-11-02"
	root.add_child(game)
	await process_frame
	var vault = game.vault_game
	vault.open()

	_expect(game.vault_free_left() == VaultGame.FREE_PER_DAY, "one free try a day")
	var before: int = game.total_coins
	vault._start()
	_expect(vault.playing and game.vault_free_left() == 0, "starting spends the free try")
	for i in VaultGame.TUMBLERS:
		vault.angle = vault.target + vault.width * 0.4
		_expect(vault.tap(), "tapping on the mark clicks tumbler %d" % (i + 1))
	_expect(not vault.playing and vault.result == 3, "three tumblers open the vault")
	_expect(game.total_coins == before + VaultGame.PRIZES[3], "an open vault pays its prize")
	vault._start()
	_expect(not vault.playing, "no more free tries today")

	_expect(game.vault_ad_left() == VaultGame.AD_PER_DAY, "ads give extra tries")
	vault._ad.pressed.emit()
	_expect(vault.playing and game.vault_ad_left() == VaultGame.AD_PER_DAY - 1, "an ad starts another try")
	before = game.total_coins
	vault.angle = vault.target + vault.width * 0.4
	vault.tap()
	vault.angle = vault.target + PI
	_expect(not vault.tap() and not vault.playing, "a miss ends the try")
	_expect(vault.result == 1 and game.total_coins == before + VaultGame.PRIZES[1], "one tumbler pays a little")
	_expect(absf(vault.speed) > VaultGame.START_SPEED and vault.width < VaultGame.START_WIDTH, "each click is harder")

	game.test_today = "2026-11-03"
	_expect(game.vault_free_left() == VaultGame.FREE_PER_DAY and game.vault_ad_left() == VaultGame.AD_PER_DAY, "tries come back the next day")
	game.ads.enabled = false
	_expect(game.vault_free_left() == VaultGame.FREE_PER_DAY + VaultGame.AD_PER_DAY and game.vault_ad_left() == 0, "without ads (Steam) the ad tries are free")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: vault hits, misses, prizes and daily tries")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
