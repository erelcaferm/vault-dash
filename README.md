# Vault Dash

A mobile puzzle climber for Android, built in Godot 4 (GDScript) with Python tooling. Swipe to slide across each room until you hit a wall, and climb an endless tower before the lava catches you.

**Status:** in development (2026). Playable from start to finish, with a shop, chests, pets, achievements, daily challenges, a level editor and 8 languages. Ads are stubbed and not connected to any ad network yet.

## Engineering highlights

- **Solver that proves levels are beatable.** `scripts/solver.gd` runs a breadth-first search over every place the player can stop, using the same slide rules as the game. It finds the shortest route, detects rooms where a player could get stuck, and has a state limit so a huge player-made level can't hang the game. The level editor uses it to refuse levels with no way out.
- **Procedural room generator.** `tools/generate_rooms.py` generates thousands of random rooms, keeps only those that pass reachability, no-dead-end and minimum-difficulty checks, then picks 100 spread from easiest to hardest.
- **Automated tests.** 21 headless test scripts in `tests/` cover the rooms, shop, chests, missions, hazards and power-ups, plus full simulated playthroughs that climb 100+ floors along the solver's route.
- **Data-driven balancing.** `tools/economy_sim.gd` plays the real game as a simulated player over many days to measure how fast coins come in and set shop prices, and `tests/test_daily_skill.gd` checks that daily challenge medals land at the intended skill levels.
- **Localization.** All UI text runs through `translations/strings.csv` (English, Spanish, French, German, Turkish, Russian and Simplified and Traditional Chinese), built by `tools/build_translations.py`.

Everything below is the detailed design and developer documentation.

## Play it

1. Install [Godot 4.7](https://godotengine.org/download) or newer (the standard build, not .NET).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

Controls: swipe with the mouse (click and drag), or use the arrow keys or WASD. Swipe or press Space to restart after a run.

To play on an Android phone, use Godot's one-click deploy: **Editor → Manage Export Templates**, then **Project → Export → Add… → Android**. Then connect the phone with USB debugging on and press the Android icon at the top right.

## Where things are

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
| Pets, their foods and how they're drawn | `scripts/pets.gd` |
| Pet station (eggs, feeding) | `scripts/pet_station.gd` |
| Crack the Vault minigame | `scripts/vault_game.gd` |
| Daily gift | `scripts/daily_gift.gd` |
| Moving blocks and spike traps | `scripts/hazards.gd` |
| Shop preview window | `scripts/look_preview.gd` |
| Bottom bar pill buttons | `scripts/pill_style.gd` |

Rooms are 13×12 tiles. The tiles are: walls, coins, spikes (deadly), cracked walls (stop you once, then crumble), and fake floor. Plain walls stacked on top of each other only show a lit top edge on the top one, so a column reads as one block; cracked walls always keep their top edge.

Every run builds a new endless tower. After the start room, each floor picks one of the 100 layouts at random:
- The first 10 layouts are unlocked from the start, and 3 more unlock per floor.
- Only the 40 hardest unlocked layouts are in the mix.
- A layout doesn't come back within 12 floors.
- Layouts are randomly mirrored left to right.

**Trap floors:** each layout has fake floor tiles at fixed spots, often on the quickest route or under a coin. On normal floors they're ordinary floor; on trap floors they give way and end the run. On trap floors they look like normal floor with a dark crack edged in white, so they're easy to spot. A safe route always exists. Which floors are traps is decided as each floor loads: floors 1–5 never are, every 30th floor always is, and any other floor rolls for one. The chance starts at 6% (only 1% straight after another trap floor) and steps up every 25 floors until it reaches 80% at floor 200. Floors load one at a time as they come into view, so only the first 2–3 exist when a run starts.

The biome changes every 5 floors, cycling through The Crypt, Ice Caves, Jungle Temple, Crystal Mine, Deep Sea, Lava Forge and Sky Ruins. Each has its own colours and a faint, partly animated background pattern on open tiles (mortar lines, icicles, swaying vines, glowing crystal shards, seaweed and bubbles, rising embers, drifting clouds), kept dim so coins and hazards always read first. They're in `BIOMES` and `_draw_deco` in `scripts/main.gd`. The lava speeds up over time and never falls more than 11 tiles behind you. Coins and your best floor are saved between runs.

## Shop

The **SHOP** button appears on the title and game-over screens, and everything in it is bought with banked coins. To buy an item, tap it once, then again to confirm. Tap an item you already own to equip it.

Items you win (from chests, trophies or levels) are never equipped for you. They're marked **NEW** in the shop, their tab gets a red dot, and the SHOP button pulses gold until you've looked. Leaving a tab (or equipping the item) clears its NEW marks. A chest that drops an item also shows an **EQUIP** button, so you can put it on straight away or tap anywhere to keep what you're wearing.

Prices go by how good an item looks, in tiers, and are set from a simulated playthrough (see **Economy** below) so a casual player earns a typical item in 20 to 60 minutes of play:

| Tier | Price | What's in it | Casual player |
|---|---|---|---|
| Starter | 600 | Red, Orange and Lemon, so the first session ends with a buy | ~12 min |
| Plain | 1,200–1,600 | solid colours, simple hats, plain wall and lava recolours, Pixels and Smoke | ~30 min |
| Patterned | 2,000–2,600 | patterned walls, bubbles, hearts, leaves, detailed hats, bubbling lava | ~50 min |
| Fancy | 2,800–4,000 | animated or glowing trails, hats and walls (Fire, Lightning, Propeller, Neon, Circuit, Plasma) | ~60–85 min |
| Shiny | 4,500–6,000 | Silver, Rose Gold, Toxic and Gold heroes, Silver and Gold Bars | ~2 h |
| Creatures | 7,000–9,000 | the animated characters, from Frog to Tiger | ~3 h |
| Legendary | 12,000–18,000 | rainbow effects: Rainbow Wall, Rainbow hero, Rainbow lava and the Unicorn | 4–6 h |

Buying everything costs about 453,000 coins, so the shop stays a long-term goal; chests drop shop items along the way.

- **Hero colours:** White and Black are free. Plain colours cost 600–1600 coins, Silver, Rose Gold and Toxic 4500–5000, Gold 6000 and Rainbow 14,000. Rainbow cycles through every colour, about once every 4 seconds standing still and much faster while sliding.
- **Creatures:** the same square hero with animated parts drawn in code (`draw_hero_item` in `skins.gd`). Frog (7000) blinks its bulging eyes and puffs its throat. Bunny (7500) flops its ears and twitches its nose. Ginger Cat (8000) and Tiger (9000, striped) blink, twitch an ear now and then and swish their tail, which streams out behind while sliding. Robot (8500) has a blinking antenna and a scanning visor. Midnight Cat, a black cat with green eyes, only drops from chests.
- **Hats:** worn on top of any hero. No hat is free. Cap, Bow, Beanie, Flower, Party Hat, Headphones, Chef Hat, Top Hat, Viking, Pirate, Wizard and Propeller (it spins) cost 1400–4000. The Crown only drops from chests, Horns come from the Pincushion trophy and the Halo from Mission Master.
- **Cracked-wall skins:** Rubble is free. Mud, Snow, Cobblestone, Moss, Wood, Brick, Cookie, Glass, Crystal, Toy Blocks, Neon, Circuit (with a blinking light) and Gold Bars cost 1400–6000. Candy and Starlight come from levels 15 and 24, and Gilded from the Gold Rush trophy.
- **Slide trails:** what you leave behind while sliding. Afterimage is free. Pixels, Smoke, Bubbles, Hearts, Autumn Leaves, Snowflakes, Sparkle, Paw Prints, Lightning and Fire cost 1600–4000. Comet and Rainbow Ribbon only drop from chests as Legendaries, Gold Dust comes from the Goal Getter trophy, and Music Notes and Confetti come from levels 18 and 21.
- **Lava:** recolour what rises from below. Lava is free. Acid, Chocolate, Bubblegum, Honey, Ocean, Ink and Plasma cost 1500–3500. Molten Gold and Aurora only drop from chests, and Ash comes from the Hot Feet trophy (10 lava deaths).

- **Pet lines:** each of the 8 pets has its own hat, trail, hero and wall skin, earned only by levelling that pet up (see Pets below). They show in the shop with the pet's name and the level that unlocks them.
- **Variants:** 20 more hero colours, 10 hats, 10 trails, 12 wall skins and 10 lavas were added on 2026-10-19, bringing the shop to 192 items.
- **Kid picks:** 23 cosmetics designed the way a five-year-old would want them, added 2026-10-18 (215 items now). Creatures: **Unicorn** (18,000, the priciest item: a rainbow mane and tail that cycle colours, a golden horn, eyelashes and sparkles popping around it), **Dino** (spikes, a wagging tail and a roar every few seconds), **Shark** (fin, tail, gills and chomping teeth), **Panda**, **Penguin** (flippers flap faster while sliding), **Alien** (glowing antennae that bob) and **Fuzzy Monster** (one big eye that looks where you're going). Hats: **Unicorn Horn**, **Space Helmet** (a glass bubble with a blinking light), **Fire Helmet**, **Ice Cream** (two scoops, a cherry and a drip) and **Balloon** (bobs on its string). Trails: **Stars** (colour-changing), **Sweets** (spinning wrapped candies), **Butterflies** (flapping), **Dino Tracks** and **Sprinkles**. Walls: **Birthday Cake** (icing drips and a cherry on the top block), **Present** (a ribbon and a bow that wiggles), **Jelly** (wobbly, with bubbles) and **Rainbow**. Lava: **Rainbow** (bands of colour drift along) and **Glitter Goo** (twinkling sparkles). The creature drawings are `_draw_kid_hero` in `skins.gd`.

**Preview:** tapping any item puts it on the preview window at the top of the shop, where your hero slides between two cracked walls above the lava wearing your whole look. Tap more items to try a full outfit; tapping an item you own takes it back off the preview. Leaving the shop clears the preview.

**Daily deal and free coins:** under the preview, a grey pill holds an **AD: +50 coins** button (3 a day) and a **DEAL** button. Each day one item you don't own is 30% off; the deal button jumps to it and previews it. The deal is picked from the date, so it's the same all day.

Every item id must be unique across all kinds, because owned and new items share one list (`test_chest.gd` checks this).

To change prices or add items, edit `scripts/skins.gd`. Purchases are saved with your coins in `user://save.cfg`.

## Economy

`tools/economy_sim.gd` plays the real game from a brand-new save as a simulated person, for 7 days of 30 minutes, and reports coins per minute, where they came from and how often the player can buy something. The player follows a route two floors ahead after a short think (longer when a new floor appears), detours for coins, now and then swipes the wrong way (sometimes into spikes or fake floor, less often as the days go on), and waits for blocks, traps and lasers. Each day they claim the daily gift, play the Daily Climb and the vault once and clear two handmade levels; with `ads` they also take the shop's coin ads and double a third of their runs. Time on menus and chests counts. They buy the next item on a shuffled, cheapest-first wish list as soon as they can afford it.

```
godot --headless --path . --script res://tools/economy_sim.gd -- skill=casual [ads] [days=7] [minutes=30] [out=report.txt]
```

`skill` is `beginner`, `casual` or `good`. Results on 2026-10-18 (minutes of play per purchase, after the first hour):

| Player | Coins a minute | Old prices | Final prices |
|---|---|---|---|
| Beginner | 34 | 14 | 39 |
| Casual | 46 | 11 | 31 |
| Casual, watches ads | 48 | 10 | 31 |
| Good | 60 | 9 | 26 |

About half the coins come from tower runs, then missions and trophies, chests, the Daily Climb and levels; ads add about a quarter for players who watch them. Chests also drop an item about once an hour. `tools/cosmetics_sheet.gd` draws a contact sheet of shop items (`xvfb-run godot --path . --script res://tools/cosmetics_sheet.gd -- out.png unicorn,dino`) for checking new cosmetics.

## Daily gift

The first time you open the game each day, a strip of 7 gifts shows: 25, 50, 75, 100, 125 and 150 coins, then a chest on day 7. You claim the next one. Missing a day never resets the strip, and after the chest it starts again at day 1.

## Stats

The Trophies screen has a **Stats** tab: runs played, time climbing, floors climbed, best floor, coins collected, cracked walls broken, deaths (and by what), chests, levels, missions and cosmetics owned.

## Crack the Vault

A timing minigame, opened from the vault icon at the top of the title screen. A needle sweeps round a vault dial; tap while it's on the glowing mark to click a tumbler. Each click flips the needle's direction, speeds it up by 1.4x and shrinks the next mark. Three tumblers open the vault. Prizes are 10, 25 and 60 coins for 1, 2 and 3 tumblers. You get 1 free try a day and 2 more for watching an ad. Tuning is at the top of `scripts/vault_game.gd`.

## Pets

Opened from the paw icon at the top of the title screen. Your first egg is free and later ones cost 1,500 coins; each egg hatches one of the pets you don't have yet, straight away (no timers). Eight pets, each with its own food:

| Pet | Food | Lv 2 hat | Lv 3 trail | Lv 4 hero | Lv 5 walls |
|---|---|---|---|---|---|
| Kitty (cat) | Fish | Cat Ears | Cat Tail | Whiskers | Scratch Post |
| Puppy (dog) | Bone | Dog Ears | Bones | Spotty | Doghouse |
| Bricky (wall) | Pebble | Wall Hat | Blocks | Crack Face | Bricky |
| Chick | Seeds | Eggshell | Feathers | Chickling | Nest |
| Slimey | Jelly | Slime Blob | Goo | Goo | Slime |
| Batty | Cherry | Bat Wings | Bats | Vamp | Cave |
| Robo | Bolt | Antenna | Sparks | Cyborg | Metal Plate |
| Drako (dragon) | Pepper | Dragon Horns | Embers | Scales | Dragon Scale |

Tap **TAKE ALONG** to make a pet follow you up the tower and through levels. While a pet is with you, its food appears once in each level (LEVELS menu), always somewhere on the level's solution route, so a clean solve picks it up. Feeding takes 2, 3, 4 and then 5 food to reach levels 2 to 5. Each level unlocks that pet's next item, and it's marked NEW in the shop. Pets, levels, food and the equipped pet are saved. Names, foods and the feeding curve are in `scripts/pets.gd`.

## Chests

A treasure chest waits on floors 30, 60, 90 and so on (always trap floors too), right where you land when you enter the room. Touching it saves it and the climb carries on. When the run ends (a death or a finish), saved chests open one after another, each as a case: a strip of prizes spins past a marker, slows down and lands on your reward ("CHEST 1 OF 3"). Tap during the spin to skip it, and tap again for the next chest; after the last one the end-of-run screen and the revive come back. The pause screen shows how many chests you're carrying. Saved chests are written to the save file, so closing the app mid-run doesn't lose them: they open on the next launch. The HUD shows which floor the next chest is on.

| Rarity | Chance | Reward |
|---|---|---|
| Common | 55% | 30–60 coins |
| Rare | 25% | 80–150 coins |
| Epic | 15% | a random shop item you don't own yet (800 coins if you own them all) |
| Legendary | 5% | a chest-only item, such as the Neon, Ember, Void or Midnight Cat hero, the Crown, Obsidian or Magma walls, the Comet or Rainbow Ribbon trail, or Molten Gold or Aurora lava (2000 coins if you own them all) |

**Bonus chests:** a hidden meter fills by a random 0.5–1 each time you reach a trap floor. When it reaches 5, a bonus chest appears 5 floors ahead. If that floor already has a chest, the bonus moves 10 floors further. If you die before reaching it, it waits on floor 8 of your next run. The meter carries over between runs. All of these numbers are at the top of `scripts/main.gd`.

Chest coins go straight to your bank, so you keep them even if you die. New items are not equipped automatically (see the shop). Chest-only items show in the shop as "Chest only" and can't be bought.

In a debug build (running from the editor), press **F2** to open a chest without climbing 30 floors.

## Trophies (achievements)

The **TROPHIES** button lists 32 achievements with your progress on each. A banner pops up when you earn one. Each pays coins or unlocks a skin you can't get any other way:

- **Climbing:** floors 5, 25, 50 (Cloud hero), 100 (Royal hero) and 200 (Marble walls), plus Speedrunner: floor 20 within 60 seconds (Speedster hero).
- **Coins:** collect 10, 250 and 1,000 (Treasure walls), and grab 10 in one slide.
- **Deaths:** die 1, 5 and 50 times (Ghost hero), plus 10 lava deaths (Ash lava), 10 spike deaths (Horns hat) and 5 fake-floor falls.
- **Chests:** open 1 and 5, get a Legendary, and find a bonus chest.
- **Tower:** break 100 cracked walls (Brick hero), reach 25 trap floors (Frozen walls), revive once, grab 25 power-ups, and play 25 runs.
- **Daily Climb:** play one (coins), reach the Daily Climb top 10 times (Gold Dust trail), play 7 days in a row (Sunrise hero), and play on 30 days.
- **Missions:** finish 10 and 50 (Halo hat).
- **Collecting:** own 5 hero colours.

Stats and trophies are saved. To add an achievement, add a line to `scripts/achievements.gd`. For a skin reward, also add the skin to `scripts/skins.gd` with `"achievement": "<id>"`.

## Moving blocks, spike traps and lasers

Three hazards on the endless tower, from `scripts/hazards.gd`. None appear on their own in the Daily Climb (so medal times stay fair), and all are rolled per floor from their own seed. Blocks and traps can also be placed in levels (see below).

**Moving blocks** (from floor 8, on 15% of floors rising to 50% by floor 150; two on some floors from floor 60). A spiky block with angry eyes and a red glow wanders its room one tile at a time, about 2.6 tiles a second. It goes straight, sometimes turns at a side opening, and turns or reverses when something is in the way. It can't leave its room or pass walls or cracked walls. Touching it ends the run (a shield saves you, as with spikes). It looks different in each background: a stone block, an ice cube, a mossy block, a crystal, a pufferfish, molten rock or a storm cloud, always with the spikes and red rim.

Fairness rules, so a block is an obstacle to time, never a wall:
- **Standing still is always safe.** A block never steps onto the tile you're standing on; it turns away instead. The danger is only in sliding through its path, so you can wait for a gap.
- **No dead ends.** Blocks only use tiles with at least two ways out (dead ends and doorways are peeled away), so a block can't get cornered by you standing in its only exit.
- **Room to roam.** A block only spawns where its area is at least 10 tiles and no single row or column holds more than half of it, so it can't patrol the one corridor you must use.
- It never spawns within 4 tiles of where you land in the room or in front of the bottom door, and never on chest floors.
- After a shield or revive, hazards can't hurt you for 1.5 seconds. The freeze power-up stops blocks and traps too.

**Spike traps** (from floor 12, on 20% of floors rising to 45%). 2–4 dark plates with a red rim and spike tips just showing. They only go on open tiles with nothing solid on any side, so you can only slide over them, never stop on one. Every 3 seconds the spikes poke out and flash (warning), then shoot up; sliding over one while it's up kills you. All traps in a room share one timer.

**Laser gates** (from floor 20, on 15% of floors rising to 35%). A beam across one row, between two plain walls (never a cracked wall, which could crumble), 3–9 tiles long, never on a room's door rows. Every 3.6 seconds it's off (a faint dotted line shows where it fires) for 2 seconds, flickers for half a second, then fires for 1.1 seconds; sliding into the beam while it's firing kills you. **It never fires while you're standing in its beam:** it stays off until you leave, then gives you the full off time.

**In levels:** the level builder has two new tiles, **M** (a moving block starts here) and **T** (a spike trap). A trap must have open floor on all four sides, and a block needs at least two open sides, or the level can't be tested or shared. Share codes carry both. Levels 25–27 (Block Party, Trap Timing, Rush Hour) use them; par time allows 3 extra seconds per block or trap, up to 4.

The first time you reach a floor with hazards, a tip says standing still is safe. `test_hazards.gd` checks the placement rules and that blocks never step onto a standing player. `test_hazard_climb.gd` has a patient player climb 80 floors (blocks, traps and lasers) along the solver's route with hazards on, waiting before each slide until it's clear; it must never die or wait more than 15 seconds (the longest wait is about 5).

## Power-ups

From floor 4, about 3 in 10 floors swap one coin for a power-up. They're seeded with the tower, so the Daily Climb has the same ones for everyone.

- **Shield** (blue): the next thing that would kill you sends you back to where your slide began instead, and pushes the lava down if it's close.
- **Magnet** (red): for 8 seconds, coins within 2 tiles fly to you.
- **Freeze** (ice): the lava stops for 4 seconds and turns icy blue.

Active power-ups are listed under the coin counter. Tune the `POWERUP_*`, `MAGNET_*` and `FREEZE_TIME` constants in `scripts/main.gd`.

## Missions

Three missions show at the top of the menu, such as "Collect 15 coins in one run", "Break 10 cracked walls" or "Reach floor 8 in the Daily Climb". Finishing one pays coins straight away and swaps in a new one with no waiting. Every 3 missions finished, new ones get bigger and pay more. "In one run" missions start from 0 each run. The others count from when the mission appeared. Tap a mission twice to swap it for a different one for 25 coins (`SWAP_COST`), so one you don't fancy never blocks a slot. The templates live in `scripts/missions.gd`.

## Daily Climb

The **DAILY** button on the menu switches to the Daily Climb (press **ENDLESS** to switch back). Everyone gets the same tower that day, built from a seed made from the date. The tower is 20 floors high (`DAILY_TOP`): reaching the top ends the run and records your time, the fastest finish of the day is today's best time, and it earns a medal. Bronze is for finishing; the silver and gold times come from that day's tower (the slide time of its quickest route plus 0.75 or 0.42 seconds of thinking per swipe), and the intro shows them. Bronze pays 50 coins, silver 75 more, and gold a chest. Retrying for a better medal pays only the prizes you haven't won yet that day, so gold after bronze pays silver's coins and the chest. The daily lava is gentler than the endless tower's and hangs further back, so slower climbers can finish: `tests/test_daily_skill.gd` plays several days as simulated expert, good, casual and beginner players and checks they get gold, silver, bronze and bronze. The HUD shows the floor out of 20 and a running clock. Today's best time (or best floor, before your first finish) is shown on the menu, and playing on days in a row builds a streak. Your best run of the day (the fastest finish, or the highest climb before you've finished) is recorded and replays as a faint **BEST** ghost on later runs that day, so you can race yourself. Tune `DAILY_TOP`, `BRONZE_COINS`, `SILVER_COINS`, `GOLD_THINK`, `SILVER_THINK` and the `DAILY_LAVA_*` settings in `scripts/main.gd`.

**Daily chest:** climbing 200 floors in a day, over any runs and either mode, earns a free chest (once a day). The title screen shows how many floors are left.

## Coin combos

Grab 5 or more coins in a single slide and every coin from the 5th on pays double, with a **COMBO** pop when the slide ends. 10 in one slide earns the Coin Rush trophy. `COMBO_MIN` in `scripts/main.gd` sets where combos start.

## Pause and new best

The **II** button at the top pauses a run (Esc or P on a keyboard), and the game also pauses itself when you switch apps or take a call. The lava, the timer and any slide in progress freeze; tap or swipe to carry on. Passing your best floor in Endless shows **NEW BEST!** with a sound and a ring of gold.

## Helpers on the tower

- A dashed gold line marks the door you need to pass to beat your best floor (today's best in the Daily Climb), so you can see it coming.
- When the lava gets within 5 tiles, the screen edges pulse red and a heartbeat plays, faster the closer it gets (`DANGER_GAP` in `scripts/main.gd`).
- In a player's first 3 runs, standing still for over a second on floors 1 and 2 shows pulsing arrows for each way you can slide. Tune `HINT_RUNS` and `HINT_DELAY` in `scripts/main.gd`.

## Revive

When you die, a **REVIVE** button offers one second chance per run for 50 coins plus 2 per floor (rounded to 10). You go back to where your last slide started, the lava drops 8 tiles below you and waits 1.5 seconds. Coins from before the death are already banked, so the run's counter starts again from 0. The button is greyed out when you can't afford it. Tune the `REVIVE_*` constants in `scripts/main.gd`.

## Ads

`scripts/ads.gd` holds the ad rules, with no ad network yet: every rewarded ad pays out straight away, so the buttons can be tried now. When an ad SDK is added, only `show_rewarded()` and `_show_interstitial()` need to change.

- **On the death screen:** **FREE REVIVE (AD)** is the same once-per-run revive as the coin one, for free. **2x COINS (AD)** pays the run's coins a second time, once per run (it also shows after a Daily Climb finish).
- **In the shop:** "Watch an ad: +50 coins", 3 times a day (`SHOP_COINS`, `SHOP_PER_DAY`).
- **Forced ads:** `after_run()` counts deaths and would show an interstitial every 4 runs (`INTERSTITIAL_EVERY`). It shows nothing yet, and it stops for good after `purchase_completed()` (any real-money purchase), saved as `no_forced_ads`.
- **Steam:** export with the custom feature tag `steam` and every ad button disappears.

## Levels and the level editor

**LEVELS** on the menu opens 24 handmade levels (levels 13–24 come in different sizes, from 9 × 16 to 16 × 24) and the player's own. A level has no lava: you slide to an exit (the gold ring) before the time limit runs out, and the screen pulses red in the last 5 seconds. Fake floor is always a trap in levels, so it always shows its white-edged crack. Coins in levels are only a score (●&nbsp;7/10), so made-up levels can't be used to farm coins or missions.

- **Handmade levels** (`scripts/levels.gd`): each unlocks the next and pays once, the first time it's cleared: coins, or one of four level-only cosmetics (Pathfinder hero on 3, Explorer hat on 6, Breadcrumbs trail on 9, Laurel hat on 12). The best time is kept. The layouts came from a search for levels whose shortest solution grows from 7 to 19 moves, with a new hazard every few levels; `moves` in each entry is that shortest solution.
- **Stars**: each handmade level has 3 stars, for clearing it, clearing it within its par time (1.5 seconds per move of the shortest solution, plus 5), and grabbing every coin. Stars from different runs add up. Trophies: Maze Runner (6 levels), Level Master (12), Grand Master (all 24), Star Collector (18 stars) and Perfectionist (36 stars, which gives the Starlight hero).
- **Editor** (`scripts/level_editor.gd`): opened with the gold **+ BUILD YOUR OWN LEVEL** button at the top of the LEVELS screen, or EDIT on one of your levels. You can paint walls, floor, coins, spikes, cracked walls, fake floor, the start and exits, and set a time limit from 10 seconds to 5 minutes. Levels start at 13 × 18 and can be 7 to 16 tiles wide and 8 to 24 tall (`MIN_W`…`MAX_H` in `level_code.gd`); the cells shrink to fit, and in play a level bigger than the screen scrolls with the hero. **TEST** refuses a level with no way to an exit. A level can only be shared after its maker has beaten it since the last change, so every shared level is possible in its time.
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

**Screen sizes:** the game is laid out for a 360 × 640 portrait screen and stretches to fit (`canvas_items` stretch with `expand` aspect), so taller or wider phones see a little more of the tower rather than black bars. On phones with a notch, camera hole or gesture bar, the HUD, buttons and menu contents move into the phone's safe area (`_apply_safe_area` in `main.gd`), while the tower, lava and menu backgrounds still fill the whole screen. Phones without a notch get no extra margin.

**Music:** a 16-second chiptune loop in A minor (`sounds/music.wav`), written by `tools/make_music.gd` from the notes listed at its top; change them and rerun `godot --headless --path . --script res://tools/make_music.gd` for a new tune. It plays quietly behind menus, speeds up a little as the lava does, and has its own switch in Settings. Sound effects and music each have a volume slider next to their switch (saved, 0–100%); Settings is also reachable from the pause screen. To use a real track instead, drop it in `sounds/` and point `music.stream` at it in `sfx.gd`.

On phones, breaking a wall, dying and opening a chest give a short buzz. Settings turns these on and off, and the choice is saved. For Android, the export preset needs the **Vibrate** permission, or the phone won't buzz (the ready-made preset below has it on).

## App icon

`icon.png` (1024 × 1024) is drawn in code by `tools/make_icon.gd`, in the game's own style: the hero sliding up the tower past coins with the lava below. It's set as the project icon, which Godot uses for the Android launcher icon too. Change the drawing and rerun `xvfb-run godot --path . --script res://tools/make_icon.gd` (or run it from the editor on a desktop) to make a new one. Google Play also wants a 512 × 512 copy for the listing; any image editor can scale this one down.

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
godot --headless --path . --script res://tests/test_daily_skill.gd   # slow: about a minute
godot --headless --path . --script res://tests/test_scroll.gd
godot --headless --path . --script res://tests/test_revive.gd
godot --headless --path . --script res://tests/test_ads.gd
godot --headless --path . --script res://tests/test_pause.gd
godot --headless --path . --script res://tests/test_missions.gd
godot --headless --path . --script res://tests/test_powerups.gd
godot --headless --path . --script res://tests/test_settings.gd
godot --headless --path . --script res://tests/test_levels.gd
godot --headless --path . --script res://tests/test_gift.gd
godot --headless --path . --script res://tests/test_vault.gd
godot --headless --path . --script res://tests/test_pets.gd
godot --headless --path . --script res://tests/test_hazards.gd
godot --headless --fixed-fps 60 --path . --script res://tests/test_hazard_climb.gd
```

The tests use their own save file, so they never touch your coins.

`test_shop.gd` checks buying, equipping and saving. `test_achievements.gd` checks achievements unlock, pay out and save. `test_chest.gd` checks the chest odds, the hidden trap meter and bonus chests, that you never get an item you already own, that every layout has open floor where the chest goes, and that rewards are granted. `test_rooms.gd` checks each of the 100 layouts on both normal and trap floors (including the stuck check). It also checks that 6 random 62-floor towers can be climbed. `test_playthrough.gd` plays the real game scene up a fixed 102-floor tower, crossing three trap floors, following the solver's route, and picks up every chest on the way, then checks they open one by one at the end. It then stands still and checks that the lava kills an idle player.
