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
| Achievements and their rewards | `scripts/achievements.gd` |
| Trophies screen | `scripts/achievements_screen.gd` |
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
- **Hats:** worn on top of any colour. No hat is free. Cap, Beanie, Party Hat, Headphones, Top Hat and Wizard cost 150–600. The Crown only drops from chests, Horns come from the Pincushion trophy and the Halo from Mission Master.
- **Cracked-wall skins:** Rubble is free. Mud, Snow, Wood, Glass, Crystal and Gold Bars cost 150–800.
- **Slide trails:** what you leave behind while sliding. Afterimage is free. Pixels, Bubbles, Sparkle and Fire cost 200–500. Comet (a rainbow streak) only drops from chests as a Legendary, and Gold Dust comes from the Goal Getter trophy.
- **Lava:** recolour what rises from below. Lava is free. Acid, Chocolate, Bubblegum and Plasma cost 250–500. Molten Gold only drops from chests, and Ash comes from the Hot Feet trophy (10 lava deaths).

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

## Trophies (achievements)

The **TROPHIES** button lists 32 achievements with your progress on each. A banner pops up when you earn one. Each pays coins or unlocks a skin you can't get any other way:

- **Climbing:** floors 5, 25, 50 (Cloud hero), 100 (Royal hero) and 200 (Marble walls), plus Speedrunner: floor 20 within 60 seconds (Speedster hero).
- **Coins:** collect 10, 250 and 1,000 (Treasure walls), and grab 10 in one slide.
- **Deaths:** die 1, 5 and 50 times (Ghost hero), plus 10 lava deaths (Ash lava), 10 spike deaths (Horns hat) and 5 fake-floor falls.
- **Chests:** open 1 and 5, get a Legendary, and find a bonus chest.
- **Tower:** break 100 cracked walls (Brick hero), reach 25 trap floors (Frozen walls), revive once, grab 25 power-ups, and play 25 runs.
- **Daily Climb:** play one (coins), hit the daily goal 10 times (Gold Dust trail), play 7 days in a row (Sunrise hero), and play on 30 days.
- **Missions:** finish 10 and 50 (Halo hat).
- **Collecting:** own 5 hero colours.

Stats and trophies are saved. To add an achievement, add a line to `scripts/achievements.gd`. For a skin reward, also add the skin to `scripts/skins.gd` with `"achievement": "<id>"`.

## Power-ups

From floor 4, about 3 in 10 floors swap one coin for a power-up. They're seeded with the tower, so the Daily Climb has the same ones for everyone.

- **Shield** (blue): the next thing that would kill you sends you back to where your slide began instead, and pushes the lava down if it's close.
- **Magnet** (red): for 8 seconds, coins within 2 tiles fly to you.
- **Freeze** (ice): the lava stops for 4 seconds and turns icy blue.

Active power-ups are listed under the coin counter. Tune the `POWERUP_*`, `MAGNET_*` and `FREEZE_TIME` constants in `scripts/main.gd`.

## Missions

Three missions show at the top of the menu, such as "Collect 15 coins in one run", "Break 10 cracked walls" or "Reach floor 8 in the Daily Climb". Finishing one pays coins straight away and swaps in a new one with no waiting. Every 3 missions finished, new ones get bigger and pay more. "In one run" missions start from 0 each run. The others count from when the mission appeared. Tap a mission twice to swap it for a different one for 25 coins (`SWAP_COST`), so one you don't fancy never blocks a slot. The templates live in `scripts/missions.gd`.

## Daily Climb

The **DAILY** button on the menu switches to the Daily Climb (press **ENDLESS** to switch back). Everyone gets the same tower that day, built from a seed made from the date. Reaching floor 15 pays 100 coins once a day, today's best is shown on the menu, and playing on days in a row builds a streak. Your best run of the day is recorded and replays as a faint **BEST** ghost on later runs that day, so you can race yourself. Tune `DAILY_GOAL` and `DAILY_REWARD` in `scripts/main.gd`.

## Coin combos

Grab 5 or more coins in a single slide and every coin from the 5th on pays double, with a **COMBO** pop when the slide ends. 10 in one slide earns the Coin Rush trophy. `COMBO_MIN` in `scripts/main.gd` sets where combos start.

## Pause and new best

The **II** button at the top pauses a run (Esc or P on a keyboard), and the game also pauses itself when you switch apps or take a call. The lava, the timer and any slide in progress freeze; tap or swipe to carry on. Passing your best floor in Endless shows **NEW BEST!** with a sound and a ring of gold.

## Helpers on the tower

- A dashed gold line marks the door you need to pass to beat your best floor (today's best in the Daily Climb), so you can see it coming.
- When the lava gets within 5 tiles, the screen edges pulse red and a heartbeat plays, faster the closer it gets (`DANGER_GAP` in `scripts/main.gd`).
- In a player's first 3 runs, standing still for over a second on floors 1 and 2 shows pulsing arrows for each way you can slide. Tune `HINT_RUNS` and `HINT_DELAY` in `scripts/main.gd`.

## Revive

When you die, a **REVIVE** button offers one second chance per run for 50 coins plus 2 per floor (rounded to 10). You go back to where your last slide started, the lava drops 8 tiles below you and waits 1.5 seconds. Coins from before the death are already banked, so the run's counter starts again from 0. The button is greyed out when you can't afford it. Tune the `REVIVE_*` constants in `scripts/main.gd`. A "watch an ad to revive" option could slot in here later.

## Levels and the level editor

**LEVELS** on the menu opens 12 handmade levels and the player's own. A level has no lava: you slide to an exit (the gold ring) before the time limit runs out, and the screen pulses red in the last 5 seconds. Fake floor is always a trap in levels, so it's drawn faintly cracked. Coins in levels are only a score (●&nbsp;7/10), so made-up levels can't be used to farm coins or missions.

- **Handmade levels** (`scripts/levels.gd`): each unlocks the next and pays once, the first time it's cleared: coins, or one of four level-only cosmetics (Pathfinder hero on 3, Explorer hat on 6, Breadcrumbs trail on 9, Laurel hat on 12). The best time is kept. The layouts came from a search for levels whose shortest solution grows from 7 to 19 moves, with a new hazard every few levels; `moves` in each entry is that shortest solution.
- **Editor** (`scripts/level_editor.gd`): paint walls, floor, coins, spikes, cracked walls, fake floor, the start and exits, and set a time limit from 10 seconds to 5 minutes. Levels start at 13 × 18 and can be 7 to 16 tiles wide and 8 to 24 tall (`MIN_W`…`MAX_H` in `level_code.gd`); the cells shrink to fit, and in play a level bigger than the screen scrolls with the hero. **TEST** refuses a level with no way to an exit. A level can only be shared after its maker has beaten it since the last change, so every shared level is possible in its time.
- **Share codes** (`scripts/level_code.gd`): a level becomes a code of about 130 characters starting `VD2` (older `VD1` codes, always 13 × 18, still load), which **SHARE** shows and copies. **ADD CODE** takes one (with a Paste button). A checksum rejects codes that were cut short or mistyped. The same format could back an online level browser later: upload the code, list codes, download one.

## Settings and languages

The gear at the top of the screen (shown on the title and death screens, never during a run) opens **Settings**: sound, vibration and language. The choice is saved. Until a player picks a language, the game follows the phone's language, falling back to English.

The game speaks English, Spanish, French, German, Turkish, Russian, and Simplified and Traditional Chinese. These are first-pass translations, so have a native speaker check them before release. To change or add text:

1. Edit `tools/translations_table.py` (English text on the left, then es, fr, de, tr, ru, zh_CN, zh_TW).
2. Run `python3 tools/build_translations.py` to rebuild `translations/strings.csv`. Godot turns it into `.translation` files when it imports.
3. Run `python3 tools/i18n_keys.py --check`, which lists any text in the scripts that has no translation, or whose `%d`/`{name}` placeholders don't match.

In code, a Label or Button whose text is exactly an English key translates itself; anything built from parts goes through `tr()`. Chinese text uses the phone's own font, which every Android, iOS and Windows device has. Text that runs long in some languages shrinks to fit (`fit_font` in `main.gd`).

## Sound and vibration

Every sound is made from code at startup (`scripts/sfx.gd`), so there are no audio files yet: swipe, stop, coin, wall break, death, trap warning, trophy, the chest tick and reveal, a click on every button, buying, a refusal buzz, levels (start, the last-5-seconds countdown, time up, level clear) and painting in the editor. To use a real recording instead, load it into `sounds` under the same name.

On phones, breaking a wall, dying and opening a chest give a short buzz. Settings turns these on and off, and the choice is saved. For Android, the export preset needs the **Vibrate** permission, or the phone won't buzz (the ready-made preset below has it on).

## Exporting to Android

`tools/export_presets.android.cfg` is a ready-made Android preset: package `com.erelcaferm.vaultdash`, arm64 and armv7, full screen, Vibrate on, and the tests and tools left out of the build. If you don't have an `export_presets.cfg` yet, copy it to the project folder under that name, then in Godot:

1. **Editor > Manage Export Templates**: download the templates for your version.
2. **Editor > Editor Settings > Export > Android**: set the Android SDK path and a debug keystore (Godot can make one).
3. **Project > Export**, pick **Android**, and **Export Project** (or plug in a phone and press the Android button to run it there).

`export_presets.cfg` stays out of git (see `.gitignore`), so your own preset never clashes with this one. Bump `version/code` for every Play Store upload.

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
godot --headless --path . --script res://tests/test_achievements.gd
godot --headless --path . --script res://tests/test_daily.gd
godot --headless --path . --script res://tests/test_revive.gd
godot --headless --path . --script res://tests/test_pause.gd
godot --headless --path . --script res://tests/test_missions.gd
godot --headless --path . --script res://tests/test_powerups.gd
godot --headless --path . --script res://tests/test_settings.gd
godot --headless --path . --script res://tests/test_levels.gd
```

The tests use their own save file, so they never touch your coins.

`test_shop.gd` checks buying, equipping and saving. `test_achievements.gd` checks achievements unlock, pay out and save. `test_chest.gd` checks the chest odds, the hidden trap meter and bonus chests, that you never get an item you already own, that every layout has open floor where the chest goes, and that rewards are granted. `test_rooms.gd` checks each of the 100 layouts on both normal and trap floors (including the stuck check). It also checks that 6 random 62-floor towers can be climbed. `test_playthrough.gd` plays the real game scene up a fixed 102-floor tower, crossing three trap floors, following the solver's route, and opens every chest on the way. It then stands still and checks that the lava kills an idle player.
