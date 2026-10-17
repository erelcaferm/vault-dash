# Vault Dash (prototype)

Swipe to slide across each room until you hit a wall. Climb 15 floors of the tower before the lava catches you.

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
| 15 hand-made rooms, bottom to top | `scripts/rooms.gd` |
| Grid and slide rules | `scripts/tower.gd` |
| Game loop, input, lava, drawing, HUD, save | `scripts/main.gd` |

The tiles are: walls, coins, spikes (deadly), cracked walls (stop you once, then crumble), and the exit. There are three biomes (Crypt, Ice Caves, Jungle Temple) with five rooms each. The lava speeds up over time and never falls more than 11 tiles behind you. Coins and your best floor are saved between runs.

## Editing rooms

Each room is 11×10 characters, and rooms join through a door in column 5. After any change, run the room test. It explores every place the player can stop and fails if the exit is unreachable or if there is a spot where you'd be stuck waiting for the lava:

```sh
godot --headless --path . --script res://tests/test_rooms.gd
```

## Tests

```sh
godot --headless --path . --import          # first time only
godot --headless --path . --script res://tests/test_rooms.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_playthrough.gd
```

`test_playthrough.gd` plays the real game scene along the solver's route to the exit. It then stands still and checks that the lava kills an idle player.
