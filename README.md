# Vault Dash (prototype)

Swipe to slide across each room until you hit a wall. Climb an endless tower as high as you can before the lava catches you.

This is the first playable prototype. Its only job is to answer one question: is the core loop fun after 20 runs? There are no menus, no art and no monetization yet. The design brief lives in the project's `design/game-design-brief.md`.

## Play it

1. Install [Godot 4.4](https://godotengine.org/download) (the standard build, not .NET).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

Controls: swipe with the mouse (click and drag), or use the arrow keys or WASD. Swipe or press Space to restart after a run.

To play on an Android phone, use Godot's one-click deploy: **Editor → Manage Export Templates**, then **Project → Export → Add… → Android**. Then connect the phone with USB debugging on and press the Android icon at the top right.

## What's in the prototype

| Thing | Where |
|---|---|
| 15 hand-made rooms, easiest to hardest | `scripts/rooms.gd` |
| Endless tower builder and slide rules | `scripts/tower.gd` |
| Game loop, input, lava, drawing, HUD, save | `scripts/main.gd` |

The tiles are: walls, coins, spikes (deadly), cracked walls (stop you once, then crumble), and the exit. Every run builds a new endless tower. After the start room, each floor is picked at random from the rooms you've unlocked so far: a harder room unlocks every 2 floors, and the easiest drop out of the mix. Rooms are randomly mirrored left to right, and the same room never comes twice in a row. The biome changes every 5 floors, cycling through Crypt, Ice Caves and Jungle Temple. The lava speeds up over time and never falls more than 11 tiles behind you. Coins and your best floor are saved between runs.

## Editing rooms

Each room is 11×10 characters, and rooms join through a door in column 5. After any change, run the room test. It builds 8 random towers of 40 floors each and explores every place the player can stop. It fails if a floor can't be reached, if there's a spot where you'd be stuck waiting for the lava, or if a room never came up:

```sh
godot --headless --path . --script res://tests/test_rooms.gd
```

## Tests

```sh
godot --headless --path . --import          # first time only
godot --headless --path . --script res://tests/test_rooms.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_playthrough.gd
```

`test_playthrough.gd` plays the real game scene up a fixed 30-floor tower along the solver's route. It then stands still and checks that the lava kills an idle player.
