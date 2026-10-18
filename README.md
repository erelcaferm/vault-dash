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
| Game loop, input, lava, drawing, HUD, save | `scripts/main.gd` |

Rooms are 13×12 tiles. The tiles are: walls, coins, spikes (deadly), cracked walls (stop you once, then crumble), and fake floor.

Every run builds a new endless tower. After the start room, each floor picks one of the 100 layouts at random:
- The first 10 layouts are unlocked from the start, and 3 more unlock per floor.
- Only the 40 hardest unlocked layouts are in the mix.
- A layout doesn't come back within 12 floors.
- Layouts are randomly mirrored left to right.

**Trap floors:** every 30th floor (30, 60, 90 and so on) is a trap floor. Each layout has fake floor tiles at fixed spots, often on the quickest route or under a coin. On normal floors they're ordinary floor; on trap floors they give way and end the run. A safe route always exists.

The biome changes every 5 floors, cycling through Crypt, Ice Caves and Jungle Temple. The lava speeds up over time and never falls more than 11 tiles behind you. Coins and your best floor are saved between runs.

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
```

`test_rooms.gd` checks each of the 100 layouts on both normal and trap floors (including the stuck check). It also checks that 6 random 62-floor towers can be climbed. `test_playthrough.gd` plays the real game scene up a fixed 32-floor tower, crossing trap floor 30, along the solver's route. It then stands still and checks that the lava kills an idle player.
