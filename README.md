# Vault Dash (prototype)

Swipe to slide across each room until you hit a wall. Climb an endless tower as high as you can before the lava catches you.

This is the first playable prototype. Its only job is to answer one question: is the core loop fun after 20 runs? There are no menus, no art and no monetization yet. The design brief lives in the project's `design/game-design-brief.md`.

## Play it

1. Install [Godot 4.7](https://godotengine.org/download) or newer (the standard build, not .NET).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

Controls: swipe with the mouse (click and drag), or use the arrow keys or WASD. Swipe or press Space to restart after a run.

To play on an Android phone, use Godot's one-click deploy: **Editor → Manage Export Templates**, then **Project → Export → Add… → Android**. Then connect the phone with USB debugging on and press the Android icon at the top right.

## What's in the prototype

| Thing | Where |
|---|---|
| Start room and 100 room layouts, easiest to hardest | `scripts/rooms.gd` (generated) |
| Room layout generator and checker | `tools/generate_rooms.py` |
| Endless tower builder and slide rules | `scripts/tower.gd` |
| Game loop, input, lava, drawing, HUD, save, purchases | `scripts/main.gd` |
| Shop items, prices and how they're drawn | `scripts/skins.gd` |
| Shop screen | `scripts/shop.gd`, `scripts/skin_preview.gd` |
| Chest rewards and odds | `scripts/chest.gd` |
| Chest opening animation | `scripts/chest_screen.gd` |

Rooms are 13×12 tiles. The tiles are: walls, coins, spikes (deadly), cracked walls (stop you once, then crumble), and fake floor.

Every run builds a new endless tower. After the start room, each floor picks one of the 100 layouts at random:
- The first 10 layouts are unlocked from the start, and 3 more unlock per floor.
- Only the 40 hardest unlocked layouts are in the mix.
- A layout doesn't come back within 12 floors.
- Layouts are randomly mirrored left to right.

**Trap floors:** each layout has fake floor tiles at fixed spots, often on the quickest route or under a coin. On normal floors they're ordinary floor; on trap floors they give way and end the run. A safe route always exists. Which floors are traps is decided as each floor loads: floors 1–5 never are, every 30th floor always is, and any other floor rolls for one. The chance starts at 6% (only 1% straight after another trap floor) and steps up every 25 floors until it reaches 80% at floor 200. Floors load one at a time as they come into view, so only the first 2–3 exist when a run starts.

The biome changes every 5 floors, cycling through Crypt, Ice Caves and Jungle Temple. The lava speeds up over time and never falls more than 11 tiles behind you. Coins and your best floor are saved between runs.

## Shop

The **SHOP** button appears on the title and game-over screens, and everything in it is bought with banked coins. To buy an item, tap it once, then again to confirm. Tap an item you already own to equip it.

- **Hero colours:** White and Black are free. Ten colours cost 100–600 coins. Rainbow costs 1500 and is the most expensive. It cycles through every colour, about once every 4 seconds standing still and much faster while sliding.
- **Cracked-wall skins:** Rubble is free. Mud, Snow, Wood, Glass, Crystal and Gold Bars cost 150–800.

To change prices or add items, edit `scripts/skins.gd`. Purchases are saved with your coins in `user://save.cfg`.

## Chests

A treasure chest waits on floors 30, 60, 90 and so on (always trap floors too), right where you land when you enter the room. Touching it pauses the run, including the lava, and opens a case: a strip of prizes spins past a marker, slows down and lands on your reward. Tap during the spin to skip it, and tap again to carry on climbing. The HUD shows which floor the next chest is on.

| Rarity | Chance | Reward |
|---|---|---|
| Common | 55% | 50–100 coins |
| Rare | 25% | 150–250 coins |
| Epic | 15% | a random shop item you don't own yet (400 coins if you own them all) |
| Legendary | 5% | a chest-only item: Neon, Ember or Void hero, or Obsidian or Magma walls (1000 coins if you own them all) |

**Bonus chests:** a hidden meter fills by a random 0.5–1 each time you reach a trap floor. When it reaches 5, a bonus chest appears 5 floors ahead. If that floor already has a chest, the bonus moves 10 floors further. If you die before reaching it, it waits on floor 8 of your next run. The meter carries over between runs. All of these numbers are at the top of `scripts/main.gd`.

Chest coins go straight to your bank, so you keep them even if you die. New items are equipped automatically. Chest-only items show in the shop as "Chest only" and can't be bought.

In a debug build (running from the editor), press **F2** to open a chest without climbing 30 floors.

## Changing the rooms

`scripts/rooms.gd` is generated; don't edit it by hand. To make a new set of 100 layouts, run the generator with a different seed:

```sh
python3 tools/generate_rooms.py 2027
```

It builds thousands of random rooms and keeps only the ones that pass every check, with and without the fake floor turned on:
- the exit can be reached,
- there's no spot where you'd be stuck waiting for the lava,
- the room takes at least 3 swipes.

It then picks 100, spread from easiest to hardest. After generating, run the tests below.

## Tests

```sh
godot --headless --path . --import          # first time only
godot --headless --path . --script res://tests/test_rooms.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_playthrough.gd
godot --headless --path . --script res://tests/test_shop.gd
godot --headless --path . --script res://tests/test_chest.gd
```

The tests use their own save file, so they never touch your coins.

`test_shop.gd` checks buying, equipping and saving. `test_chest.gd` checks the chest odds, the hidden trap meter and bonus chests, that you never get an item you already own, that every layout has open floor where the chest goes, and that rewards are granted. `test_rooms.gd` checks each of the 100 layouts on both normal and trap floors (including the stuck check). It also checks that 6 random 62-floor towers can be climbed. `test_playthrough.gd` plays the real game scene up a fixed 102-floor tower, crossing three trap floors, following the solver's route, and opens every chest on the way. It then stands still and checks that the lava kills an idle player.
