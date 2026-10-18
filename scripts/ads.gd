extends RefCounted
## Ads, before any ad network is plugged in. Every rewarded ad pays out
## straight away, so the buttons can be tested now; when an ad SDK is added,
## only show_rewarded() and _show_interstitial() need to change.
##
## Rules from the design brief:
##   - Rewarded ads are always the player's choice (a button they tap).
##   - Forced ads (interstitials between runs) stop for good once the player
##     buys anything with real money (no_forced_ads).
##   - The Steam version has no ads at all: export it with the "steam"
##     feature tag and every ad button disappears.

## Rewarded ads in the shop: coins per ad, and how many a day.
const SHOP_COINS := 50
const SHOP_PER_DAY := 3
## A forced ad after every this-many finished runs (stub; shows nothing yet).
const INTERSTITIAL_EVERY := 4

var enabled := not OS.has_feature("steam")
var no_forced_ads := false
var runs_since_interstitial := 0


func can_show_rewarded() -> bool:
	return enabled


## Plays a rewarded ad for `placement` ("revive", "double_coins", "shop_coins")
## and calls `on_reward` if the player watched it through.
func show_rewarded(_placement: String, on_reward: Callable) -> void:
	if not enabled:
		return
	# No ad network yet: the player always "watches" the whole ad.
	on_reward.call()


## Called when a run ends. Returns true when a forced ad would have played.
func after_run() -> bool:
	if not enabled or no_forced_ads:
		return false
	runs_since_interstitial += 1
	if runs_since_interstitial < INTERSTITIAL_EVERY:
		return false
	runs_since_interstitial = 0
	_show_interstitial()
	return true


func _show_interstitial() -> void:
	pass    # no ad network yet


## Call after any real-money purchase.
func purchase_completed() -> void:
	no_forced_ads = true
