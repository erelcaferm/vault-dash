extends RefCounted
## Everything the shop sells, and how to draw it.
## Prices are in coins. Items priced 0 are owned from the start.
## Items marked chest_only can't be bought; they only drop from chests.
## Items with an "achievement" id are earned by unlocking that achievement.
## Items with a "level" number are the reward for clearing that level.

const HERO := [
	{"id": "white", "name": "White", "price": 0, "color": Color("f4f1de")},
	{"id": "black", "name": "Black", "price": 0, "color": Color("17171c")},
	{"id": "red", "name": "Red", "price": 300, "color": Color("e63946")},
	{"id": "orange", "name": "Orange", "price": 300, "color": Color("f4a261")},
	{"id": "lemon", "name": "Lemon", "price": 300, "color": Color("f6e05e")},
	{"id": "mint", "name": "Mint", "price": 450, "color": Color("74e0b0")},
	{"id": "green", "name": "Green", "price": 450, "color": Color("40a352")},
	{"id": "sky", "name": "Sky", "price": 600, "color": Color("4cc9f0")},
	{"id": "blue", "name": "Blue", "price": 600, "color": Color("4361ee")},
	{"id": "purple", "name": "Purple", "price": 750, "color": Color("9d4edd")},
	{"id": "pink", "name": "Pink", "price": 750, "color": Color("ff70a6")},
	{"id": "gold", "name": "Gold", "price": 2500, "color": Color("ffc300")},
	{"id": "rainbow", "name": "Rainbow", "price": 6000, "rainbow": true},
	{"id": "neon", "name": "Neon", "price": -1, "chest_only": true, "color": Color("39ff14"), "glow": Color(0.22, 1.0, 0.08, 0.35)},
	{"id": "ember", "name": "Ember", "price": -1, "chest_only": true, "color": Color("ff7b1c"), "glow": Color(1.0, 0.35, 0.0, 0.4)},
	{"id": "void", "name": "Void", "price": -1, "chest_only": true, "color": Color("2b0a3d"), "glow": Color(0.7, 0.3, 0.95, 0.45)},
	{"id": "cloud", "name": "Cloud", "price": -1, "achievement": "sky_high", "color": Color("e3f2ff"), "glow": Color(0.85, 0.93, 1.0, 0.35)},
	{"id": "royal", "name": "Royal", "price": -1, "achievement": "centurion", "color": Color("5a189a"), "glow": Color(1.0, 0.82, 0.25, 0.45)},
	{"id": "speedster", "name": "Speedster", "price": -1, "achievement": "speedrunner", "color": Color("ffe94d"), "glow": Color(1.0, 0.6, 0.0, 0.35)},
	{"id": "ghost", "name": "Ghost", "price": -1, "achievement": "never_give_up", "color": Color(0.85, 0.9, 1.0, 0.55)},
	{"id": "sunrise", "name": "Sunrise", "price": -1, "achievement": "week_streak", "color": Color("ff8f5e"), "glow": Color(1.0, 0.75, 0.3, 0.4)},
	{"id": "starlight", "name": "Starlight", "price": -1, "achievement": "perfectionist", "color": Color("fff3a8"), "glow": Color(1.0, 0.95, 0.5, 0.5)},
	{"id": "pathfinder", "name": "Pathfinder", "price": -1, "level": 3, "color": Color("2ec4b6"), "glow": Color(0.2, 0.9, 0.8, 0.35)},
	{"id": "brick", "name": "Brick", "price": -1, "achievement": "wrecking_ball", "color": Color("b5523b")},
	# Creatures: the same square hero, with animated ears, tails and faces.
	{"id": "frog", "name": "Frog", "price": 3000, "shape": "frog", "color": Color("5cb85c")},
	{"id": "bunny", "name": "Bunny", "price": 3500, "shape": "bunny", "color": Color("ece4dc")},
	{"id": "cat", "name": "Ginger Cat", "price": 4000, "shape": "cat", "color": Color("f08c3a")},
	{"id": "robot", "name": "Robot", "price": 4500, "shape": "robot", "color": Color("9aa5b1")},
	{"id": "tiger", "name": "Tiger", "price": 5500, "shape": "cat", "stripes": true, "color": Color("ff9a1f")},
	{"id": "midnight", "name": "Midnight Cat", "price": -1, "chest_only": true, "shape": "cat", "color": Color("1b1b24"),
		"eyes": Color("7dff6b"), "glow": Color(0.5, 1.0, 0.4, 0.25)},
	# More colours.
	{"id": "coral", "name": "Coral", "price": 350, "color": Color("ff7f6e")},
	{"id": "peach", "name": "Peach", "price": 350, "color": Color("ffc8a2")},
	{"id": "sand", "name": "Sand", "price": 350, "color": Color("e2c99f")},
	{"id": "lime", "name": "Lime", "price": 400, "color": Color("a6e22e")},
	{"id": "teal", "name": "Teal", "price": 400, "color": Color("1fa3a3")},
	{"id": "ice", "name": "Ice", "price": 450, "color": Color("c9f1ff")},
	{"id": "lavender", "name": "Lavender", "price": 450, "color": Color("c3a6ff")},
	{"id": "rose", "name": "Rose", "price": 450, "color": Color("ff9ebb")},
	{"id": "cherry_red", "name": "Cherry", "price": 500, "color": Color("c1121f")},
	{"id": "forest", "name": "Forest", "price": 500, "color": Color("2d6a4f")},
	{"id": "navy", "name": "Navy", "price": 500, "color": Color("23395d")},
	{"id": "plum", "name": "Plum", "price": 550, "color": Color("7b2d6b")},
	{"id": "maroon", "name": "Maroon", "price": 550, "color": Color("6d1a2a")},
	{"id": "olive", "name": "Olive", "price": 550, "color": Color("7d8a2e")},
	{"id": "slate", "name": "Slate", "price": 600, "color": Color("5c677d")},
	{"id": "charcoal", "name": "Charcoal", "price": 600, "color": Color("33363d")},
	{"id": "silver", "name": "Silver", "price": 1800, "color": Color("c8ccd4"), "glow": Color(0.9, 0.92, 1.0, 0.3)},
	{"id": "rose_gold", "name": "Rose Gold", "price": 2200, "color": Color("e8a598"), "glow": Color(1.0, 0.75, 0.65, 0.35)},
	{"id": "toxic", "name": "Toxic", "price": 2800, "color": Color("b6ff3b"), "glow": Color(0.6, 1.0, 0.1, 0.4)},
	{"id": "inferno", "name": "Inferno", "price": -1, "chest_only": true, "color": Color("ff3d00"), "glow": Color(1.0, 0.25, 0.0, 0.5)},
	# Pet lines: unlocked by levelling that pet up (pets.gd).
	{"id": "whiskers", "name": "Whiskers", "price": -1, "pet": "cat", "pet_level": 4, "shape": "whiskers", "color": Color("f6b26b")},
	{"id": "spotty", "name": "Spotty", "price": -1, "pet": "dog", "pet_level": 4, "shape": "spotty", "color": Color("f4f1de")},
	{"id": "crackface", "name": "Crack Face", "price": -1, "pet": "wall", "pet_level": 4, "shape": "crackface", "color": Color("8a8f9c")},
	{"id": "chickling", "name": "Chickling", "price": -1, "pet": "chick", "pet_level": 4, "shape": "chick", "color": Color("ffd84d")},
	{"id": "goo", "name": "Goo", "price": -1, "pet": "slime", "pet_level": 4, "shape": "goo", "color": Color(0.43, 0.86, 0.35, 0.8)},
	{"id": "vamp", "name": "Vamp", "price": -1, "pet": "bat", "pet_level": 4, "shape": "vamp", "color": Color("c9b8e8")},
	{"id": "cyborg", "name": "Cyborg", "price": -1, "pet": "robo", "pet_level": 4, "shape": "cyborg", "color": Color("ffd0b0")},
	{"id": "scales", "name": "Scales", "price": -1, "pet": "dragon", "pet_level": 4, "shape": "scales", "color": Color("e04a3a")},
]

## Cracked-wall skins. `style` picks the pattern drawn on top of the block.
const WALLS := [
	{"id": "rubble", "name": "Rubble", "price": 0, "style": "crack",
		"base": Color("8a6a4a"), "top": Color("b08a64"), "detail": Color("45352a")},
	{"id": "mud", "name": "Mud", "price": 400, "style": "mud",
		"base": Color("5c4033"), "top": Color("7a5640"), "detail": Color("3b2a20")},
	{"id": "snow", "name": "Snow", "price": 400, "style": "snow",
		"base": Color("dfeaf5"), "top": Color("ffffff"), "detail": Color("9fbcd8")},
	{"id": "wood", "name": "Wood", "price": 600, "style": "planks",
		"base": Color("a0703c"), "top": Color("c08a50"), "detail": Color("6b4423")},
	{"id": "glass", "name": "Glass", "price": 900, "style": "glass",
		"base": Color(0.62, 0.86, 1.0, 0.45), "top": Color(1, 1, 1, 0.75), "detail": Color(1, 1, 1, 0.85)},
	{"id": "crystal", "name": "Crystal", "price": 1200, "style": "crystal",
		"base": Color("7b2cbf"), "top": Color("c77dff"), "detail": Color("e0aaff")},
	{"id": "gold_bars", "name": "Gold Bars", "price": 3000, "style": "bars",
		"base": Color("d4a017"), "top": Color("ffd75e"), "detail": Color("9c7400")},
	{"id": "obsidian", "name": "Obsidian", "price": -1, "chest_only": true, "style": "crystal",
		"base": Color("14111f"), "top": Color("2e2547"), "detail": Color("8c5bd6")},
	{"id": "magma", "name": "Magma", "price": -1, "chest_only": true, "style": "magma",
		"base": Color("2a1410"), "top": Color("4a2218"), "detail": Color("ff7b00")},
	{"id": "treasure", "name": "Treasure", "price": -1, "achievement": "treasure_hunter", "style": "coins",
		"base": Color("6b4a1e"), "top": Color("8a6428"), "detail": Color("ffd23f")},
	{"id": "frozen", "name": "Frozen", "price": -1, "achievement": "trap_dodger", "style": "glass",
		"base": Color(0.45, 0.75, 1.0, 0.7), "top": Color(0.9, 0.97, 1.0, 0.9), "detail": Color(1, 1, 1, 0.9)},
	{"id": "marble", "name": "Marble", "price": -1, "achievement": "tower_legend", "style": "marble",
		"base": Color("ece8e1"), "top": Color("ffffff"), "detail": Color("9a948c")},
	{"id": "moss", "name": "Moss", "price": 600, "style": "moss",
		"base": Color("6b6f5e"), "top": Color("6fbf4a"), "detail": Color("4d8a33")},
	{"id": "brick_wall", "name": "Brick", "price": 750, "style": "bricks",
		"base": Color("a5452f"), "top": Color("c25a3f"), "detail": Color("e8d6c4")},
	{"id": "neon_wall", "name": "Neon", "price": 1500, "style": "neon",
		"base": Color("120c24"), "top": Color("2a1f4d"), "detail": Color("39f0ff")},
	{"id": "candy", "name": "Candy", "price": -1, "level": 15, "style": "candy",
		"base": Color("fff0f5"), "top": Color("ffffff"), "detail": Color("ff4f8b")},
	{"id": "starlight_wall", "name": "Starlight", "price": -1, "level": 24, "style": "neon",
		"base": Color("0d0a1f"), "top": Color("231a45"), "detail": Color("d6a8ff")},
	{"id": "gilded", "name": "Gilded", "price": -1, "achievement": "gold_rush", "style": "neon",
		"base": Color("2b1d05"), "top": Color("4a3410"), "detail": Color("ffd23f")},
	{"id": "cobble", "name": "Cobblestone", "price": 500, "style": "cobble",
		"base": Color("6e6a64"), "top": Color("8c877f"), "detail": Color("4a4743")},
	{"id": "cookie", "name": "Cookie", "price": 900, "style": "cookie",
		"base": Color("c8894a"), "top": Color("dca064"), "detail": Color("4a2a16")},
	{"id": "toy_blocks", "name": "Toy Blocks", "price": 1200, "style": "studs",
		"base": Color("e63946"), "top": Color("ff5a66"), "detail": Color("b02232")},
	{"id": "circuit", "name": "Circuit", "price": 1600, "style": "circuit",
		"base": Color("0f3d2a"), "top": Color("17573c"), "detail": Color("d4af37")},
	{"id": "sandstone", "name": "Sandstone", "price": 450, "style": "crack",
		"base": Color("d8b47a"), "top": Color("ecd09a"), "detail": Color("9c7a45")},
	{"id": "birch", "name": "Birch", "price": 550, "style": "planks",
		"base": Color("e8dcc0"), "top": Color("f5ecd6"), "detail": Color("9c8a6a")},
	{"id": "dark_wood", "name": "Dark Wood", "price": 650, "style": "planks",
		"base": Color("4a2c18"), "top": Color("6b4228"), "detail": Color("26160b")},
	{"id": "ice_bricks", "name": "Ice Bricks", "price": 800, "style": "bricks",
		"base": Color("9fd8f2"), "top": Color("d4f1ff"), "detail": Color("ffffff")},
	{"id": "mossy_cobble", "name": "Mossy Cobble", "price": 700, "style": "cobble",
		"base": Color("5f6b58"), "top": Color("7e8f6a"), "detail": Color("3b4535")},
	{"id": "mint_candy", "name": "Mint Candy", "price": 900, "style": "candy",
		"base": Color("f0fff8"), "top": Color("ffffff"), "detail": Color("2ec4a0")},
	{"id": "ruby", "name": "Ruby", "price": 1300, "style": "crystal",
		"base": Color("8c1027"), "top": Color("e63950"), "detail": Color("ffb3c1")},
	{"id": "emerald", "name": "Emerald", "price": 1300, "style": "crystal",
		"base": Color("0f5c3a"), "top": Color("2ecc71"), "detail": Color("b8ffd8")},
	{"id": "pink_neon", "name": "Pink Neon", "price": 1500, "style": "neon",
		"base": Color("1f0a1a"), "top": Color("3d1433"), "detail": Color("ff4fd8")},
	{"id": "green_neon", "name": "Green Neon", "price": 1500, "style": "neon",
		"base": Color("08180c"), "top": Color("12321a"), "detail": Color("4dff6a")},
	{"id": "blue_blocks", "name": "Blue Blocks", "price": 1200, "style": "studs",
		"base": Color("2f6fd8"), "top": Color("4f8af0"), "detail": Color("1d4a99")},
	{"id": "silver_bars", "name": "Silver Bars", "price": 2500, "style": "bars",
		"base": Color("a7adb8"), "top": Color("dfe3ea"), "detail": Color("6b717c")},
	{"id": "scratch_post", "name": "Scratch Post", "price": -1, "pet": "cat", "pet_level": 5, "style": "scratch",
		"base": Color("c9a97a"), "top": Color("ddc093"), "detail": Color("7a5c36")},
	{"id": "doghouse", "name": "Doghouse", "price": -1, "pet": "dog", "pet_level": 5, "style": "doghouse",
		"base": Color("b5523b"), "top": Color("8a3a28"), "detail": Color("2a1810")},
	{"id": "bricky_wall", "name": "Bricky", "price": -1, "pet": "wall", "pet_level": 5, "style": "bricky",
		"base": Color("8a8f9c"), "top": Color("a9aebb"), "detail": Color("4f5360")},
	{"id": "nest", "name": "Nest", "price": -1, "pet": "chick", "pet_level": 5, "style": "nest",
		"base": Color("b48a4e"), "top": Color("d4aa6a"), "detail": Color("7a5a2e")},
	{"id": "slime_wall", "name": "Slime", "price": -1, "pet": "slime", "pet_level": 5, "style": "slime",
		"base": Color("3d6b35"), "top": Color("6fdc5a"), "detail": Color("a8ff8f")},
	{"id": "cave", "name": "Cave", "price": -1, "pet": "bat", "pet_level": 5, "style": "cave",
		"base": Color("2a2433"), "top": Color("3d3449"), "detail": Color("6b5a80")},
	{"id": "metal_plate", "name": "Metal Plate", "price": -1, "pet": "robo", "pet_level": 5, "style": "plate",
		"base": Color("6b7480"), "top": Color("8d96a3"), "detail": Color("c3cad3")},
	{"id": "dragon_scale", "name": "Dragon Scale", "price": -1, "pet": "dragon", "pet_level": 5, "style": "dscale",
		"base": Color("8c2a1e"), "top": Color("b8402e"), "detail": Color("ffb36b")},
]

## Trails left behind the hero while sliding. `style` picks how it's drawn.
const TRAILS := [
	{"id": "afterimage", "name": "Afterimage", "price": 0, "style": "afterimage"},
	{"id": "pixels", "name": "Pixels", "price": 600, "style": "pixels"},
	{"id": "bubbles", "name": "Bubbles", "price": 750, "style": "bubbles", "color": Color("8fd8ff")},
	{"id": "sparkle", "name": "Sparkle", "price": 1000, "style": "sparkle", "color": Color("fff3a8")},
	{"id": "fire", "name": "Fire", "price": 1500, "style": "fire"},
	{"id": "comet", "name": "Comet", "price": -1, "chest_only": true, "style": "comet"},
	{"id": "gold_dust", "name": "Gold Dust", "price": -1, "achievement": "daily_goal", "style": "sparkle", "color": Color("ffd23f")},
	{"id": "breadcrumbs", "name": "Breadcrumbs", "price": -1, "level": 9, "style": "bubbles", "color": Color("d9a066")},
	{"id": "smoke", "name": "Smoke", "price": 600, "style": "smoke", "color": Color("c8c8d0")},
	{"id": "hearts", "name": "Hearts", "price": 900, "style": "hearts", "color": Color("ff4f8b")},
	{"id": "lightning", "name": "Lightning", "price": 1400, "style": "zap", "color": Color("9be7ff")},
	{"id": "notes", "name": "Music Notes", "price": -1, "level": 18, "style": "notes", "color": Color("ffffff")},
	{"id": "confetti", "name": "Confetti", "price": -1, "level": 21, "style": "confetti"},
	{"id": "leaves", "name": "Autumn Leaves", "price": 900, "style": "leaves"},
	{"id": "snowflakes", "name": "Snowflakes", "price": 1000, "style": "snowflakes", "color": Color("e8f6ff")},
	{"id": "paws", "name": "Paw Prints", "price": 1200, "style": "paws", "color": Color("ffd0e0")},
	{"id": "ribbon", "name": "Rainbow Ribbon", "price": -1, "chest_only": true, "style": "ribbon"},
	{"id": "mint_bubbles", "name": "Mint Bubbles", "price": 750, "style": "bubbles", "color": Color("8fffd0")},
	{"id": "pink_bubbles", "name": "Pink Bubbles", "price": 750, "style": "bubbles", "color": Color("ffa8d9")},
	{"id": "ruby_sparkle", "name": "Ruby Sparkle", "price": 1000, "style": "sparkle", "color": Color("ff4d6d")},
	{"id": "ice_sparkle", "name": "Ice Sparkle", "price": 1000, "style": "sparkle", "color": Color("bff4ff")},
	{"id": "toxic_smoke", "name": "Toxic Smoke", "price": 700, "style": "smoke", "color": Color("9cff57")},
	{"id": "shadow_smoke", "name": "Shadow Smoke", "price": 700, "style": "smoke", "color": Color("3a3445")},
	{"id": "blue_hearts", "name": "Blue Hearts", "price": 900, "style": "hearts", "color": Color("4cc9f0")},
	{"id": "gold_hearts", "name": "Gold Hearts", "price": 1100, "style": "hearts", "color": Color("ffd23f")},
	{"id": "red_lightning", "name": "Red Lightning", "price": 1400, "style": "zap", "color": Color("ff5a5a")},
	{"id": "green_lightning", "name": "Green Lightning", "price": 1400, "style": "zap", "color": Color("6bff8a")},
	{"id": "cat_tail", "name": "Cat Tail", "price": -1, "pet": "cat", "pet_level": 3, "style": "cat_tail", "color": Color("f08c3a")},
	{"id": "bones", "name": "Bones", "price": -1, "pet": "dog", "pet_level": 3, "style": "bones", "color": Color("f4f1de")},
	{"id": "blocks", "name": "Blocks", "price": -1, "pet": "wall", "pet_level": 3, "style": "blocks", "color": Color("8a8f9c")},
	{"id": "feathers", "name": "Feathers", "price": -1, "pet": "chick", "pet_level": 3, "style": "feathers", "color": Color("ffe27a")},
	{"id": "goo_trail", "name": "Goo", "price": -1, "pet": "slime", "pet_level": 3, "style": "goo", "color": Color("6fdc5a")},
	{"id": "bats", "name": "Bats", "price": -1, "pet": "bat", "pet_level": 3, "style": "bats", "color": Color("6b4a9c")},
	{"id": "sparks", "name": "Sparks", "price": -1, "pet": "robo", "pet_level": 3, "style": "sparks", "color": Color("ffd23f")},
	{"id": "embers", "name": "Embers", "price": -1, "pet": "dragon", "pet_level": 3, "style": "embers", "color": Color("ff7b1c")},
]

## Hats worn on top of the hero. `style` picks how it's drawn.
const HATS := [
	{"id": "no_hat", "name": "No hat", "price": 0, "style": "none"},
	{"id": "cap", "name": "Cap", "price": 400, "style": "cap", "color": Color("e63946")},
	{"id": "beanie", "name": "Beanie", "price": 600, "style": "beanie", "color": Color("4361ee")},
	{"id": "party", "name": "Party Hat", "price": 750, "style": "party", "color": Color("ff70a6")},
	{"id": "headphones", "name": "Headphones", "price": 900, "style": "headphones", "color": Color("2b2d42")},
	{"id": "top_hat", "name": "Top Hat", "price": 1400, "style": "top_hat", "color": Color("17171c")},
	{"id": "wizard", "name": "Wizard", "price": 2000, "style": "wizard", "color": Color("5a189a")},
	{"id": "crown", "name": "Crown", "price": -1, "chest_only": true, "style": "crown", "color": Color("ffc300")},
	{"id": "horns", "name": "Horns", "price": -1, "achievement": "pincushion", "style": "horns", "color": Color("c1121f")},
	{"id": "halo", "name": "Halo", "price": -1, "achievement": "mission_master", "style": "halo", "color": Color("fff3a8")},
	{"id": "explorer", "name": "Explorer", "price": -1, "level": 6, "style": "explorer", "color": Color("d4a373")},
	{"id": "laurel", "name": "Laurel", "price": -1, "level": 12, "style": "laurel", "color": Color("6a994e")},
	{"id": "bow", "name": "Bow", "price": 500, "style": "bow", "color": Color("ff4f8b")},
	{"id": "flower", "name": "Flower", "price": 700, "style": "flower", "color": Color("ffd23f")},
	{"id": "chef", "name": "Chef Hat", "price": 1000, "style": "chef", "color": Color("ffffff")},
	{"id": "viking", "name": "Viking", "price": 1500, "style": "viking", "color": Color("8d99ae")},
	{"id": "pirate", "name": "Pirate", "price": 1800, "style": "pirate", "color": Color("1d1d24")},
	{"id": "propeller", "name": "Propeller", "price": 2200, "style": "propeller", "color": Color("4361ee")},
	{"id": "green_cap", "name": "Green Cap", "price": 400, "style": "cap", "color": Color("40a352")},
	{"id": "pink_beanie", "name": "Pink Beanie", "price": 600, "style": "beanie", "color": Color("ff70a6")},
	{"id": "blue_bow", "name": "Blue Bow", "price": 500, "style": "bow", "color": Color("4cc9f0")},
	{"id": "beret", "name": "Beret", "price": 800, "style": "beret", "color": Color("c1121f")},
	{"id": "headband", "name": "Headband", "price": 500, "style": "headband", "color": Color("ff5a5a")},
	{"id": "cowboy", "name": "Cowboy", "price": 1600, "style": "cowboy", "color": Color("8a5a2e")},
	{"id": "tiara", "name": "Tiara", "price": 1900, "style": "tiara", "color": Color("dfe3ea")},
	{"id": "mohawk", "name": "Mohawk", "price": 1200, "style": "mohawk", "color": Color("ff3dbb")},
	{"id": "santa", "name": "Santa Hat", "price": 1300, "style": "santa", "color": Color("e63946")},
	{"id": "white_top_hat", "name": "White Top Hat", "price": 1600, "style": "top_hat", "color": Color("f4f1de")},
	{"id": "cat_ears", "name": "Cat Ears", "price": -1, "pet": "cat", "pet_level": 2, "style": "cat_ears", "color": Color("f08c3a")},
	{"id": "dog_ears", "name": "Dog Ears", "price": -1, "pet": "dog", "pet_level": 2, "style": "dog_ears", "color": Color("8a5a36")},
	{"id": "wall_hat", "name": "Wall Hat", "price": -1, "pet": "wall", "pet_level": 2, "style": "wall_hat", "color": Color("8a8f9c")},
	{"id": "eggshell", "name": "Eggshell", "price": -1, "pet": "chick", "pet_level": 2, "style": "eggshell", "color": Color("fff6e0")},
	{"id": "slime_hat", "name": "Slime Blob", "price": -1, "pet": "slime", "pet_level": 2, "style": "slime_hat", "color": Color("6fdc5a")},
	{"id": "bat_wings", "name": "Bat Wings", "price": -1, "pet": "bat", "pet_level": 2, "style": "bat_wings", "color": Color("6b4a9c")},
	{"id": "antenna", "name": "Antenna", "price": -1, "pet": "robo", "pet_level": 2, "style": "antenna", "color": Color("9aa5b1")},
	{"id": "dragon_horns", "name": "Dragon Horns", "price": -1, "pet": "dragon", "pet_level": 2, "style": "dragon_horns", "color": Color("ffe0a0")},
]

## What rises from below. `color` fills it, `glow` lines the surface, and
## `bubbles` adds popping bubbles of that colour.
const LAVA := [
	{"id": "classic", "name": "Lava", "price": 0, "color": Color("ff5a1f"), "glow": Color("ffb347")},
	{"id": "acid", "name": "Acid", "price": 750, "color": Color("3fbf3f"), "glow": Color("b6ff6b"), "bubbles": Color("d9ff9e")},
	{"id": "chocolate", "name": "Chocolate", "price": 900, "color": Color("5b3420"), "glow": Color("8a5634")},
	{"id": "bubblegum", "name": "Bubblegum", "price": 1000, "color": Color("ff70a6"), "glow": Color("ffc2da"), "bubbles": Color("ffe0ec")},
	{"id": "plasma", "name": "Plasma", "price": 1600, "color": Color("5a189a"), "glow": Color("e0aaff"), "bubbles": Color("c77dff")},
	{"id": "molten_gold", "name": "Molten Gold", "price": -1, "chest_only": true, "color": Color("d4a017"), "glow": Color("fff1a8"), "bubbles": Color("ffe066")},
	{"id": "ash", "name": "Ash", "price": -1, "achievement": "hot_feet", "color": Color("3a3a40"), "glow": Color("ff7b1c"), "bubbles": Color("ff9e4a")},
	{"id": "ocean", "name": "Ocean", "price": 1200, "color": Color("1f6fb2"), "glow": Color("bfe9ff"), "bubbles": Color("e8f8ff")},
	{"id": "honey", "name": "Honey", "price": 1100, "color": Color("e09f1f"), "glow": Color("ffd46b")},
	{"id": "ink", "name": "Ink", "price": 1400, "color": Color("14121c"), "glow": Color("7b5cff"), "bubbles": Color("a28bff")},
	{"id": "aurora", "name": "Aurora", "price": -1, "chest_only": true, "color": Color("0f2a3d"), "glow": Color("6bffcf"), "bubbles": Color("c38bff")},
	{"id": "lime_lava", "name": "Lime", "price": 800, "color": Color("8fd400"), "glow": Color("e0ff8a")},
	{"id": "cherry_lava", "name": "Cherry", "price": 850, "color": Color("b5172f"), "glow": Color("ff6b81"), "bubbles": Color("ff9aa8")},
	{"id": "blueberry", "name": "Blueberry", "price": 900, "color": Color("3a3fa8"), "glow": Color("8a8fff"), "bubbles": Color("b8bbff")},
	{"id": "mint_lava", "name": "Mint", "price": 900, "color": Color("3ccf9a"), "glow": Color("c2ffe8")},
	{"id": "grape", "name": "Grape", "price": 950, "color": Color("6a2c91"), "glow": Color("c58bff"), "bubbles": Color("e0bfff")},
	{"id": "caramel", "name": "Caramel", "price": 1000, "color": Color("b8742a"), "glow": Color("f2b66b")},
	{"id": "lemonade", "name": "Lemonade", "price": 1000, "color": Color("f5d63d"), "glow": Color("fff7b0"), "bubbles": Color("ffffff")},
	{"id": "cola", "name": "Cola", "price": 1100, "color": Color("3a1d0e"), "glow": Color("8a4b2a"), "bubbles": Color("d9b38c")},
	{"id": "tar", "name": "Tar", "price": 1200, "color": Color("111114"), "glow": Color("4a4a55"), "bubbles": Color("5a5a66")},
	{"id": "frost", "name": "Frost", "price": 1500, "color": Color("7fc8ff"), "glow": Color("ffffff"), "bubbles": Color("e8f8ff")},
]

## How fast the rainbow hero cycles through every colour, in full cycles per
## second, standing still and while sliding.
const RAINBOW_IDLE_SPEED := 0.25
const RAINBOW_SLIDE_SPEED := 1.5


## The item list for a kind of cosmetic: "hero", "walls" or "trail".
static func list(kind: String) -> Array:
	match kind:
		"hero":
			return HERO
		"trail":
			return TRAILS
		"lava":
			return LAVA
		"hat":
			return HATS
	return WALLS


## What one of `kind` is called, for messages like "New trail: Fire".
static func kind_name(kind: String) -> String:
	match kind:
		"hero":
			return "colour"
		"trail":
			return "trail"
		"lava":
			return "lava"
		"hat":
			return "hat"
	return "wall skin"


static func find(items: Array, id: String) -> Dictionary:
	for item in items:
		if item.id == id:
			return item
	return items[0]


## `phase` is how far round the colour wheel a rainbow hero is (0-1).
static func hero_color(item: Dictionary, phase: float) -> Color:
	if item.get("rainbow", false):
		return Color.from_hsv(fposmod(phase, 1.0), 0.7, 1.0)
	return item.color


static func hero_glow(item: Dictionary) -> Color:
	return item.get("glow", Color.TRANSPARENT)


## Draws the hero as a square of `size` centred on `center`, eyes looking `look`.
static func draw_hero(canvas: CanvasItem, center: Vector2, size: Vector2, color: Color, look := Vector2.ZERO, alpha := 1.0, glow := Color.TRANSPARENT) -> void:
	var r := Rect2(center - size * 0.5, size)
	if glow.a > 0.0 and alpha >= 1.0:
		canvas.draw_rect(r.grow(size.x * 0.3), Color(glow, glow.a * 0.4))
		canvas.draw_rect(r.grow(size.x * 0.15), glow)
	canvas.draw_rect(r, Color(color, color.a * alpha))
	if alpha < 1.0:
		return
	var dark := color.get_luminance() < 0.3
	if dark:
		# Keep a black hero visible against dark walls.
		canvas.draw_rect(r, Color(1, 1, 1, 0.55), false, 1.5)
	var eye := Color.WHITE if dark else Color("1d2030")
	var s := size.y / 26.0
	canvas.draw_circle(center + Vector2(-5, -3) * s + look, 2.6 * s, eye)
	canvas.draw_circle(center + Vector2(5, -3) * s + look, 2.6 * s, eye)


## Draws the equipped hero: a plain square, or a creature built on the same
## square (so it reads the same in play) with ears, a tail and a face that
## blink, twitch and swish. `dir` is the way it's sliding (zero when still).
static func draw_hero_item(canvas: CanvasItem, item: Dictionary, center: Vector2, size: Vector2, color: Color,
		look := Vector2.ZERO, time := 0.0, dir := Vector2.ZERO) -> void:
	var shape: String = item.get("shape", "")
	if shape == "":
		draw_hero(canvas, center, size, color, look, 1.0, hero_glow(item))
		return
	var w := size.x
	var h := size.y
	var r := Rect2(center - size * 0.5, size)
	var top := r.position.y
	var x := center.x
	var u := minf(w, h)
	var glow := hero_glow(item)
	var dark := color.get_luminance() < 0.3
	var line := Color.WHITE if dark else Color("1d2030")
	# Blink for a tenth of a second every few seconds.
	var blink := fposmod(time, 3.4) < 0.12
	var eye_l := center + Vector2(-w * 0.2, -h * 0.1) + look
	var eye_r := center + Vector2(w * 0.2, -h * 0.1) + look

	# Behind the body: glow and tails.
	if glow.a > 0.0:
		canvas.draw_rect(r.grow(u * 0.25), Color(glow, glow.a * 0.4))
	match shape:
		"cat":
			# The tail swishes when still and streams out behind when sliding.
			var base := r.end - Vector2(w * 0.1, h * 0.15)
			var away := Vector2(0.9, -0.5).normalized() if dir == Vector2.ZERO else -dir
			var points := PackedVector2Array()
			for i in 7:
				var t := i / 6.0
				var swish := sin(time * 3.0 - t * 2.5) * 0.6 * t
				points.append(base + away.rotated(swish - t * 0.9 * (1.0 if dir == Vector2.ZERO else 0.2)) * u * 0.75 * t)
			canvas.draw_polyline(points, color.darkened(0.15), u * 0.16)
			if dark:
				canvas.draw_polyline(points, Color(1, 1, 1, 0.35), 1.0)
		"bunny":
			canvas.draw_circle(Vector2(r.position.x + w * 0.12, r.end.y - h * 0.15), u * 0.17, color.lightened(0.3))

	canvas.draw_rect(r, color)
	if dark:
		canvas.draw_rect(r, Color(1, 1, 1, 0.55), false, 1.5)
	if shape in ["whiskers", "spotty", "crackface", "chick", "goo", "vamp", "cyborg", "scales"]:
		_draw_pet_face(canvas, shape, r, color, look, time, blink)
		return

	match shape:
		"cat":
			var twitch := 0.0
			if fposmod(time, 5.0) < 0.25:
				twitch = sin(fposmod(time, 5.0) * 50.0) * u * 0.05
			for side in [-1.0, 1.0]:
				var outer := Vector2(x + side * w * 0.5, top + 1)
				var tip := Vector2(x + side * w * 0.38, top - u * 0.36 + (twitch if side > 0 else 0.0))
				var inner := Vector2(x + side * w * 0.08, top + 1)
				canvas.draw_colored_polygon(PackedVector2Array([outer, tip, inner]), color)
				canvas.draw_colored_polygon(PackedVector2Array([
					outer.lerp(inner, 0.25) + Vector2(0, -1), tip.lerp(Vector2(x, top), 0.25), outer.lerp(inner, 0.75) + Vector2(0, -1)]),
					Color("ff9fb8") if not dark else Color("5a3a4a"))
			if item.get("stripes", false):
				var stripe := color.darkened(0.55)
				for i in 3:
					var sx := x + (i - 1) * w * 0.18
					canvas.draw_line(Vector2(sx, top), Vector2(sx, top + h * 0.18), stripe, u * 0.07)
				for side in [-1.0, 1.0]:
					for i in 2:
						var sy := center.y + h * (0.08 + i * 0.2)
						canvas.draw_line(Vector2(x + side * w * 0.5, sy), Vector2(x + side * w * 0.3, sy + h * 0.04), stripe, u * 0.06)
			_face_eyes(canvas, eye_l, eye_r, u, item.get("eyes", line), blink, true)
			var nose := center + Vector2(0, h * 0.08) + look * 0.5
			canvas.draw_colored_polygon(PackedVector2Array([nose + Vector2(-u * 0.06, -u * 0.03), nose + Vector2(u * 0.06, -u * 0.03), nose + Vector2(0, u * 0.04)]), Color("ff7f9f"))
			canvas.draw_arc(nose + Vector2(-u * 0.05, u * 0.05), u * 0.05, 0.0, PI, 6, line, 1.0)
			canvas.draw_arc(nose + Vector2(u * 0.05, u * 0.05), u * 0.05, 0.0, PI, 6, line, 1.0)
			for side in [-1.0, 1.0]:
				for i in 2:
					var from := nose + Vector2(side * u * 0.14, i * u * 0.06)
					canvas.draw_line(from, from + Vector2(side * u * 0.42, (i - 0.5) * u * 0.1), Color(line, 0.6), 1.0)
		"bunny":
			var flop := sin(time * 2.0) * 0.08
			for side in [-1.0, 1.0]:
				var root := Vector2(x + side * w * 0.2, top + 2)
				var ear := PackedVector2Array()
				var tilt: float = side * (0.12 + (flop if side > 0 else 0.0))
				for i in 13:
					var a := TAU * i / 12.0
					ear.append(root + Vector2(cos(a) * u * 0.12, -u * 0.32 + sin(a) * u * 0.34).rotated(tilt))
				canvas.draw_colored_polygon(ear, color)
				var inner := PackedVector2Array()
				for i in 13:
					var a := TAU * i / 12.0
					inner.append(root + Vector2(cos(a) * u * 0.05, -u * 0.32 + sin(a) * u * 0.24).rotated(tilt))
				canvas.draw_colored_polygon(inner, Color("ffb3c6"))
			_face_eyes(canvas, eye_l, eye_r, u, line, blink, false)
			var sniff := 1.0 + (0.25 * sin(time * 30.0) if fposmod(time, 2.6) < 0.5 else 0.0)
			var nose := center + Vector2(0, h * 0.08) + look * 0.5
			canvas.draw_circle(nose, u * 0.055 * sniff, Color("ff7f9f"))
			canvas.draw_rect(Rect2(nose + Vector2(-u * 0.06, u * 0.07), Vector2(u * 0.12, u * 0.1)), Color.WHITE)
			canvas.draw_line(nose + Vector2(0, u * 0.07), nose + Vector2(0, u * 0.17), Color(0.6, 0.6, 0.6), 1.0)
		"frog":
			# Bulging eyes on top, a wide smile and a throat that puffs.
			for e in [Vector2(x - w * 0.25, top), Vector2(x + w * 0.25, top)]:
				canvas.draw_circle(e, u * 0.2, color)
				canvas.draw_circle(e, u * 0.14, Color.WHITE)
				if blink:
					canvas.draw_circle(e, u * 0.15, color.darkened(0.1))
				else:
					canvas.draw_circle(e + look * 0.6, u * 0.07, Color("1d2030"))
			var puff := maxf(0.0, sin(time * 2.2)) ** 6
			canvas.draw_circle(center + Vector2(0, h * 0.34), u * (0.08 + 0.14 * puff), color.lightened(0.35))
			canvas.draw_arc(center + Vector2(0, -h * 0.02), u * 0.3, 0.35, PI - 0.35, 12, color.darkened(0.5), 1.5)
			canvas.draw_circle(center + Vector2(-w * 0.32, h * 0.12), u * 0.07, Color(1.0, 0.5, 0.5, 0.45))
			canvas.draw_circle(center + Vector2(w * 0.32, h * 0.12), u * 0.07, Color(1.0, 0.5, 0.5, 0.45))
		"robot":
			# An antenna with a blinking light, bolts and a visor that scans.
			var tip := Vector2(x, top - u * 0.32)
			canvas.draw_line(Vector2(x, top), tip, color.darkened(0.4), 2.0)
			var on := fposmod(time, 1.0) < 0.5
			canvas.draw_circle(tip, u * 0.08, Color("ff3b3b") if on else Color("6b1a1a"))
			if on:
				canvas.draw_circle(tip, u * 0.14, Color(1, 0.2, 0.2, 0.3))
			var visor := Rect2(r.position + Vector2(w * 0.12, h * 0.2), Vector2(w * 0.76, h * 0.3))
			canvas.draw_rect(visor, Color("1d2030"))
			var scan := (sin(time * 2.5) * 0.5 + 0.5) * (visor.size.x - u * 0.2) + look.x * 0.5
			canvas.draw_rect(Rect2(visor.position + Vector2(scan, visor.size.y * 0.25), Vector2(u * 0.2, visor.size.y * 0.5)), Color("39f0ff"))
			if blink:
				canvas.draw_rect(visor, Color(0.12, 0.13, 0.19))
			canvas.draw_rect(Rect2(r.position + Vector2(w * 0.25, h * 0.68), Vector2(w * 0.5, h * 0.08)), color.darkened(0.35))
			for c in [r.position + Vector2(w * 0.1, h * 0.1), Vector2(r.end.x - w * 0.1, top + h * 0.1),
					Vector2(r.position.x + w * 0.1, r.end.y - h * 0.1), r.end - Vector2(w * 0.1, h * 0.1)]:
				canvas.draw_circle(c, u * 0.04, color.darkened(0.3))


## The pet-line hero skins: a plain hero with a pet's features.
static func _draw_pet_face(canvas: CanvasItem, shape: String, r: Rect2, color: Color, look: Vector2, time: float, blink: bool) -> void:
	var w := r.size.x
	var h := r.size.y
	var u := minf(w, h)
	var center := r.get_center()
	var x := center.x
	var top := r.position.y
	var line := Color("1d2030")
	var eye_l := center + Vector2(-w * 0.2, -h * 0.1) + look
	var eye_r := center + Vector2(w * 0.2, -h * 0.1) + look
	match shape:
		"whiskers":
			_face_eyes(canvas, eye_l, eye_r, u, line, blink, true)
			var nose := center + Vector2(0, h * 0.1)
			canvas.draw_circle(nose, u * 0.05, Color("ff7f9f"))
			for side in [-1.0, 1.0]:
				for i in 3:
					var from := nose + Vector2(side * u * 0.1, (i - 1) * u * 0.05)
					canvas.draw_line(from, from + Vector2(side * u * 0.5, (i - 1) * u * 0.1), Color(line, 0.7), 1.0)
		"spotty":
			for spot in [Vector2(-0.3, -0.3), Vector2(0.28, 0.25), Vector2(-0.15, 0.3), Vector2(0.32, -0.32)]:
				canvas.draw_circle(center + spot * u, u * 0.09, Color("1d2030"))
			for side in [-1.0, 1.0]:
				canvas.draw_rect(Rect2(Vector2(x + side * w * 0.5 - (u * 0.18 if side > 0 else 0.0), top), Vector2(u * 0.18, h * 0.5)), Color("5a3a24"))
			_face_eyes(canvas, eye_l, eye_r, u, line, blink, false)
			canvas.draw_circle(center + Vector2(0, h * 0.15), u * 0.07, line)
			if fposmod(time, 2.0) < 1.0:
				canvas.draw_rect(Rect2(center + Vector2(-u * 0.05, h * 0.2), Vector2(u * 0.1, u * 0.12)), Color("ff7f9f"))
		"crackface":
			# The crack is the face: two chips for eyes and a jagged mouth.
			canvas.draw_rect(Rect2(r.position, Vector2(w, h * 0.13)), color.lightened(0.2))
			if blink:
				canvas.draw_line(eye_l - Vector2(u * 0.08, 0), eye_l + Vector2(u * 0.08, 0), line, 2.0)
				canvas.draw_line(eye_r - Vector2(u * 0.08, 0), eye_r + Vector2(u * 0.08, 0), line, 2.0)
			else:
				for e in [eye_l, eye_r]:
					canvas.draw_colored_polygon(PackedVector2Array([e + Vector2(-u * 0.08, -u * 0.05), e + Vector2(u * 0.08, -u * 0.07), e + Vector2(u * 0.02, u * 0.07)]), line)
			canvas.draw_polyline(PackedVector2Array([center + Vector2(-u * 0.28, u * 0.18), center + Vector2(-u * 0.12, u * 0.26), center + Vector2(0, u * 0.16), center + Vector2(u * 0.14, u * 0.27), center + Vector2(u * 0.28, u * 0.17)]), line, 2.0)
		"chick":
			_face_eyes(canvas, eye_l, eye_r, u, line, blink, false)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-u * 0.12, u * 0.04), center + Vector2(u * 0.12, u * 0.04), center + Vector2(0, u * 0.2)]), Color("ff8c1a"))
			for i in 3:
				canvas.draw_line(Vector2(x, top), Vector2(x + (i - 1) * u * 0.12, top - u * 0.25), color.darkened(0.15), 2.0)
		"goo":
			var drip := fposmod(time * 0.8, 1.0)
			canvas.draw_line(Vector2(x + w * 0.25, r.end.y), Vector2(x + w * 0.25, r.end.y + u * 0.25 * drip), color, u * 0.1)
			canvas.draw_circle(Vector2(x + w * 0.25, r.end.y + u * 0.25 * drip), u * 0.07, color)
			canvas.draw_circle(r.position + Vector2(w * 0.25, h * 0.22), u * 0.08, Color(1, 1, 1, 0.55))
			_face_eyes(canvas, eye_l, eye_r, u, line, blink, false)
		"vamp":
			canvas.draw_colored_polygon(PackedVector2Array([r.position, Vector2(x, top + h * 0.22), Vector2(r.end.x, top), Vector2(r.end.x, top + h * 0.1), Vector2(x, top + h * 0.3), Vector2(r.position.x, top + h * 0.1)]), Color("2b1d3d"))
			_face_eyes(canvas, eye_l, eye_r, u, Color("c1121f"), blink, false)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(side * u * 0.12, u * 0.15), center + Vector2(side * u * 0.04, u * 0.15), center + Vector2(side * u * 0.08, u * 0.28)]), Color.WHITE)
		"cyborg":
			canvas.draw_rect(Rect2(Vector2(x, top), Vector2(w * 0.5, h)), Color("8d96a3"))
			canvas.draw_line(Vector2(x, top), Vector2(x, r.end.y), Color("5c6470"), 1.5)
			_face_eyes(canvas, eye_l, eye_l, u, line, blink, false)
			var glow := 0.6 + 0.4 * sin(time * 5.0)
			canvas.draw_circle(eye_r, u * 0.12, Color(1, 0.15, 0.15, 0.35 * glow))
			canvas.draw_circle(eye_r, u * 0.07, Color(1, 0.2, 0.2, glow))
		"scales":
			for row in 3:
				for col in 3:
					var p := r.position + Vector2(w * (0.18 + col * 0.32 + (0.16 if row % 2 == 1 else 0.0)), h * (0.45 + row * 0.2))
					if p.x < r.end.x - 2:
						canvas.draw_arc(p, u * 0.11, 0, PI, 6, color.darkened(0.3), 1.5)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + side * w * 0.2, top), Vector2(x + side * w * 0.32, top - u * 0.28), Vector2(x + side * w * 0.42, top)]), Color("ffe0a0"))
			_face_eyes(canvas, eye_l, eye_r, u, Color("ffd23f"), blink, true)


static func _face_eyes(canvas: CanvasItem, l: Vector2, r: Vector2, u: float, color: Color, blink: bool, slit: bool) -> void:
	for e in [l, r]:
		if blink:
			canvas.draw_line(e - Vector2(u * 0.09, 0), e + Vector2(u * 0.09, 0), color, 1.5)
		else:
			canvas.draw_circle(e, u * 0.1, color)
			if slit:
				canvas.draw_line(e - Vector2(0, u * 0.07), e + Vector2(0, u * 0.07), Color(0, 0, 0, 0.6), 1.5)
			canvas.draw_circle(e + Vector2(-u * 0.03, -u * 0.04), u * 0.03, Color(1, 1, 1, 0.8))


## Draws a hat on a hero drawn at `center` with `size`.
static func draw_hat(canvas: CanvasItem, item: Dictionary, center: Vector2, size: Vector2, time := 0.0) -> void:
	if item.style == "none":
		return
	var c: Color = item.color
	var w := size.x
	var top := center.y - size.y * 0.5
	var x := center.x
	match item.style:
		"cap":
			canvas.draw_rect(Rect2(x - w * 0.5, top - w * 0.28, w, w * 0.3), c)
			canvas.draw_rect(Rect2(x, top - w * 0.06, w * 0.75, w * 0.1), c.darkened(0.25))
			canvas.draw_circle(Vector2(x, top - w * 0.3), w * 0.06, c.lightened(0.3))
		"beanie":
			canvas.draw_rect(Rect2(x - w * 0.5, top - w * 0.3, w, w * 0.32), c)
			canvas.draw_rect(Rect2(x - w * 0.55, top - w * 0.08, w * 1.1, w * 0.14), c.lightened(0.3))
			canvas.draw_circle(Vector2(x, top - w * 0.36), w * 0.12, c.lightened(0.5))
		"party":
			var tip := Vector2(x, top - w * 0.75)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.35, top + 1), tip, Vector2(x + w * 0.35, top + 1)]), c)
			canvas.draw_line(Vector2(x - w * 0.24, top - w * 0.22), Vector2(x + w * 0.24, top - w * 0.22), Color("ffd23f"), w * 0.08)
			canvas.draw_line(Vector2(x - w * 0.12, top - w * 0.5), Vector2(x + w * 0.12, top - w * 0.5), Color("4cc9f0"), w * 0.07)
			canvas.draw_circle(tip, w * 0.1, Color.WHITE)
		"headphones":
			canvas.draw_arc(Vector2(x, top + w * 0.15), w * 0.6, PI * 1.05, PI * 1.95, 16, c, w * 0.1)
			canvas.draw_rect(Rect2(x - w * 0.68, top + w * 0.1, w * 0.2, w * 0.38), Color("e84855"))
			canvas.draw_rect(Rect2(x + w * 0.48, top + w * 0.1, w * 0.2, w * 0.38), Color("e84855"))
		"top_hat":
			canvas.draw_rect(Rect2(x - w * 0.6, top - w * 0.08, w * 1.2, w * 0.1), c)
			canvas.draw_rect(Rect2(x - w * 0.36, top - w * 0.7, w * 0.72, w * 0.64), c)
			canvas.draw_rect(Rect2(x - w * 0.36, top - w * 0.2, w * 0.72, w * 0.1), Color("e63946"))
			canvas.draw_rect(Rect2(x - w * 0.6, top - w * 0.08, w * 1.2, w * 0.1), Color(1, 1, 1, 0.35), false, 1.0)
		"wizard":
			var tip := Vector2(x + w * 0.25, top - w * 0.9)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.42, top), tip, Vector2(x + w * 0.42, top)]), c)
			canvas.draw_rect(Rect2(x - w * 0.6, top - w * 0.06, w * 1.2, w * 0.1), c.darkened(0.2))
			_sparkle(canvas, Vector2(x - w * 0.05, top - w * 0.38), w * (0.12 + 0.03 * sin(time * 5.0)), Color("ffd23f"))
		"crown":
			var base := top - w * 0.02
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(x - w * 0.45, base), Vector2(x - w * 0.45, base - w * 0.42), Vector2(x - w * 0.22, base - w * 0.2),
				Vector2(x, base - w * 0.5), Vector2(x + w * 0.22, base - w * 0.2), Vector2(x + w * 0.45, base - w * 0.42),
				Vector2(x + w * 0.45, base),
			]), c)
			canvas.draw_circle(Vector2(x, base - w * 0.14), w * 0.07, Color("e63946"))
			_sparkle(canvas, Vector2(x + w * 0.3, base - w * 0.5), w * 0.1 * (0.6 + 0.4 * sin(time * 4.0)), Color.WHITE)
		"horns":
			for side in [-1.0, 1.0]:
				var root := Vector2(x + side * w * 0.3, top + 1)
				canvas.draw_colored_polygon(PackedVector2Array([
					root - Vector2(w * 0.12, 0), root + Vector2(side * w * 0.12, -w * 0.42), root + Vector2(w * 0.12, 0),
				]), c)
		"explorer":
			canvas.draw_rect(Rect2(x - w * 0.65, top - w * 0.08, w * 1.3, w * 0.12), c.darkened(0.15))
			canvas.draw_circle(Vector2(x, top - w * 0.08), w * 0.4, c)
			canvas.draw_rect(Rect2(x - w * 0.41, top - w * 0.2, w * 0.82, w * 0.08), Color("6b4423"))
		"laurel":
			# Two branches of leaves curving round the top of the head.
			var hub := Vector2(x, top + w * 0.18)
			for side in [-1.0, 1.0]:
				for i in 5:
					var a := deg_to_rad(100.0 - i * 16.0)
					var p := hub + Vector2(side * sin(a), -cos(a)) * w * 0.52
					canvas.draw_circle(p, w * (0.1 - i * 0.008), c.lightened(0.08 * (i % 2)))
			canvas.draw_circle(Vector2(x, top - w * 0.3), w * 0.06, Color("ffd23f"))
		"halo":
			var bob := sin(time * 3.0) * w * 0.04
			canvas.draw_arc(Vector2(x, top - w * 0.3 + bob), w * 0.36, 0, TAU, 24, Color(c, 0.35), w * 0.16)
			canvas.draw_arc(Vector2(x, top - w * 0.3 + bob), w * 0.36, 0, TAU, 24, c, w * 0.07)
		"bow":
			var knot := Vector2(x + w * 0.28, top + w * 0.02)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(side * w * 0.3, -w * 0.18), knot + Vector2(side * w * 0.3, w * 0.16)]), c)
			canvas.draw_circle(knot, w * 0.08, c.darkened(0.2))
		"flower":
			var mid := Vector2(x - w * 0.22, top - w * 0.08)
			var sway := sin(time * 2.0) * 0.2
			for i in 5:
				canvas.draw_circle(mid + Vector2.from_angle(TAU * i / 5.0 + sway) * w * 0.13, w * 0.1, Color.WHITE)
			canvas.draw_circle(mid, w * 0.09, c)
		"chef":
			canvas.draw_rect(Rect2(x - w * 0.36, top - w * 0.3, w * 0.72, w * 0.3), c)
			for i in 3:
				canvas.draw_circle(Vector2(x + (i - 1) * w * 0.24, top - w * 0.42), w * 0.2, c)
			canvas.draw_line(Vector2(x - w * 0.36, top - w * 0.08), Vector2(x + w * 0.36, top - w * 0.08), Color(0.8, 0.8, 0.85), 1.0)
		"viking":
			canvas.draw_arc(Vector2(x, top + w * 0.05), w * 0.45, PI, TAU, 16, c, w * 0.12)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.45, top + w * 0.05), Vector2(x - w * 0.45, top - w * 0.1), Vector2(x, top - w * 0.42), Vector2(x + w * 0.45, top - w * 0.1), Vector2(x + w * 0.45, top + w * 0.05)]), c)
			canvas.draw_rect(Rect2(x - w * 0.5, top - w * 0.04, w, w * 0.1), Color("b08a4a"))
			for side in [-1.0, 1.0]:
				var root := Vector2(x + side * w * 0.42, top - w * 0.12)
				canvas.draw_colored_polygon(PackedVector2Array([root + Vector2(0, -w * 0.08), root + Vector2(side * w * 0.3, -w * 0.42), root + Vector2(side * w * 0.12, w * 0.06)]), Color("f4f1de"))
		"pirate":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.62, top + 1), Vector2(x - w * 0.3, top - w * 0.42), Vector2(x, top - w * 0.3), Vector2(x + w * 0.3, top - w * 0.42), Vector2(x + w * 0.62, top + 1)]), c)
			canvas.draw_line(Vector2(x - w * 0.55, top - w * 0.03), Vector2(x + w * 0.55, top - w * 0.03), Color("ffd23f"), 1.5)
			canvas.draw_circle(Vector2(x, top - w * 0.2), w * 0.07, Color.WHITE)
			canvas.draw_line(Vector2(x - w * 0.09, top - w * 0.08), Vector2(x + w * 0.09, top - w * 0.12), Color.WHITE, 1.5)
		"beret":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.55, top + 1), Vector2(x - w * 0.4, top - w * 0.25), Vector2(x + w * 0.2, top - w * 0.32), Vector2(x + w * 0.5, top - w * 0.12), Vector2(x + w * 0.45, top + 1)]), c)
			canvas.draw_line(Vector2(x - w * 0.05, top - w * 0.32), Vector2(x, top - w * 0.42), c.darkened(0.3), 2.0)
		"headband":
			canvas.draw_rect(Rect2(x - w * 0.5, top + w * 0.06, w, w * 0.12), c)
			canvas.draw_line(Vector2(x - w * 0.5, top + w * 0.12), Vector2(x - w * 0.75, top + w * 0.3 + sin(time * 6.0) * w * 0.05), c, w * 0.08)
		"cowboy":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.75, top - w * 0.12), Vector2(x - w * 0.6, top + w * 0.02), Vector2(x + w * 0.6, top + w * 0.02), Vector2(x + w * 0.75, top - w * 0.12), Vector2(x + w * 0.4, top - w * 0.05), Vector2(x - w * 0.4, top - w * 0.05)]), c)
			canvas.draw_rect(Rect2(x - w * 0.35, top - w * 0.45, w * 0.7, w * 0.42), c)
			canvas.draw_line(Vector2(x, top - w * 0.45), Vector2(x, top - w * 0.3), c.darkened(0.3), 2.0)
			canvas.draw_rect(Rect2(x - w * 0.35, top - w * 0.14, w * 0.7, w * 0.07), Color("2a1810"))
		"tiara":
			canvas.draw_polyline(PackedVector2Array([Vector2(x - w * 0.4, top), Vector2(x - w * 0.25, top - w * 0.15), Vector2(x - w * 0.12, top - w * 0.05), Vector2(x, top - w * 0.3), Vector2(x + w * 0.12, top - w * 0.05), Vector2(x + w * 0.25, top - w * 0.15), Vector2(x + w * 0.4, top)]), c, 2.0)
			canvas.draw_circle(Vector2(x, top - w * 0.2), w * 0.06, Color("4cc9f0"))
			_sparkle(canvas, Vector2(x + w * 0.3, top - w * 0.3), w * 0.08 * (0.6 + 0.4 * sin(time * 5.0)), Color.WHITE)
		"mohawk":
			for i in 5:
				var px := x + (i - 2) * w * 0.12
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(px - w * 0.07, top + 1), Vector2(px, top - w * (0.35 + 0.08 * (2 - absi(i - 2)))), Vector2(px + w * 0.07, top + 1)]), c)
		"santa":
			var tip := Vector2(x + w * 0.55, top - w * 0.15 + sin(time * 3.0) * w * 0.04)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.45, top), Vector2(x, top - w * 0.55), tip, Vector2(x + w * 0.45, top)]), c)
			canvas.draw_rect(Rect2(x - w * 0.55, top - w * 0.1, w * 1.1, w * 0.16), Color.WHITE)
			canvas.draw_circle(tip, w * 0.1, Color.WHITE)
		"cat_ears":
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + side * w * 0.48, top + 1), Vector2(x + side * w * 0.38, top - w * 0.36), Vector2(x + side * w * 0.1, top + 1)]), c)
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + side * w * 0.4, top), Vector2(x + side * w * 0.36, top - w * 0.24), Vector2(x + side * w * 0.18, top)]), Color("ff9fb8"))
			canvas.draw_rect(Rect2(x - w * 0.5, top - w * 0.02, w, w * 0.06), c.darkened(0.2))
		"dog_ears":
			var flap := sin(time * 4.0) * w * 0.03
			for side in [-1.0, 1.0]:
				var px: float = x + side * w * 0.5
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(px - side * w * 0.15, top - w * 0.06), Vector2(px + side * w * 0.12, top - w * 0.02), Vector2(px + side * w * 0.14, top + w * 0.45 + flap), Vector2(px - side * w * 0.02, top + w * 0.5 + flap)]), c)
		"wall_hat":
			var block := Rect2(x - w * 0.42, top - w * 0.5, w * 0.84, w * 0.5)
			canvas.draw_rect(block, c)
			canvas.draw_rect(Rect2(block.position, Vector2(block.size.x, w * 0.08)), c.lightened(0.25))
			canvas.draw_line(block.position + Vector2(0, block.size.y * 0.55), block.position + Vector2(block.size.x, block.size.y * 0.55), c.darkened(0.3), 1.0)
			canvas.draw_line(block.position + Vector2(block.size.x * 0.5, w * 0.08), block.position + Vector2(block.size.x * 0.5, block.size.y * 0.55), c.darkened(0.3), 1.0)
		"eggshell":
			var pts := PackedVector2Array([Vector2(x - w * 0.42, top + w * 0.06)])
			for i in 9:
				var a := PI + PI * i / 8.0
				pts.append(Vector2(x + cos(a) * w * 0.42, top - w * 0.05 + sin(a) * w * 0.38))
			pts.append(Vector2(x + w * 0.42, top + w * 0.06))
			for i in 6:
				pts.append(Vector2(x + w * (0.42 - (i + 1) * 0.14), top + w * (0.06 if i % 2 == 0 else -0.06)))
			canvas.draw_colored_polygon(pts, c)
		"slime_hat":
			var wob := sin(time * 4.0) * w * 0.04
			canvas.draw_circle(Vector2(x, top - w * 0.12), w * (0.32 + wob / w), Color(c, 0.9))
			canvas.draw_rect(Rect2(x - w * 0.45, top - w * 0.12, w * 0.9, w * 0.16), Color(c, 0.9))
			canvas.draw_line(Vector2(x - w * 0.3, top), Vector2(x - w * 0.3, top + w * 0.18 + wob), Color(c, 0.9), w * 0.1)
			canvas.draw_circle(Vector2(x - w * 0.12, top - w * 0.24), w * 0.06, Color(1, 1, 1, 0.6))
		"bat_wings":
			var flap := sin(time * 8.0) * w * 0.08
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + side * w * 0.2, top + w * 0.05), Vector2(x + side * w * 0.75, top - w * 0.35 - flap), Vector2(x + side * w * 0.65, top - w * 0.05), Vector2(x + side * w * 0.5, top + w * 0.02)]), c)
		"antenna":
			for side in [-1.0, 1.0]:
				var tip := Vector2(x + side * w * 0.3, top - w * 0.45 + sin(time * 5.0 + side) * w * 0.03)
				canvas.draw_line(Vector2(x + side * w * 0.2, top), tip, c, 2.0)
				canvas.draw_circle(tip, w * 0.08, Color("39f0ff") if fposmod(time + side * 0.25, 1.0) < 0.5 else c)
		"dragon_horns":
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + side * w * 0.15, top + 1), Vector2(x + side * w * 0.42, top - w * 0.2), Vector2(x + side * w * 0.6, top - w * 0.5), Vector2(x + side * w * 0.38, top + 1)]), c)
		"propeller":
			canvas.draw_arc(Vector2(x, top + w * 0.05), w * 0.42, PI, TAU, 16, c, w * 0.18)
			canvas.draw_rect(Rect2(x - w * 0.48, top - w * 0.04, w * 0.96, w * 0.08), Color("ffd23f"))
			canvas.draw_line(Vector2(x, top - w * 0.38), Vector2(x, top - w * 0.52), Color(0.3, 0.3, 0.35), 2.0)
			var spin := cos(time * 18.0)
			canvas.draw_line(Vector2(x - w * 0.42 * spin, top - w * 0.55), Vector2(x + w * 0.42 * spin, top - w * 0.55), Color("e63946"), w * 0.1)
			canvas.draw_circle(Vector2(x, top - w * 0.55), w * 0.05, Color(0.3, 0.3, 0.35))


## Draws a slide trail behind a hero at `center` moving along `dir`.
## `color` is the hero's colour; `time` animates it.
static func draw_trail(canvas: CanvasItem, item: Dictionary, center: Vector2, dir: Vector2, size: Vector2, color: Color, time: float) -> void:
	var side := Vector2(-dir.y, dir.x)
	# Squashing while sliding narrows the hero, so size particles by its long side.
	var base := maxf(size.x, size.y)
	var tile := base + 6.0
	match item.style:
		"afterimage":
			for i in range(3, 0, -1):
				draw_hero(canvas, center - dir * tile * 0.4 * i, size, color, Vector2.ZERO, 0.12 * (4 - i))
		"pixels":
			for i in 7:
				var back := tile * (0.4 + i * 0.22)
				var wobble := side * sin(time * 30.0 + i * 2.1) * base * 0.25
				var s := base * (0.3 - i * 0.03)
				canvas.draw_rect(Rect2(center - dir * back + wobble - Vector2(s, s) * 0.5, Vector2(s, s)), Color(color, 0.8 - i * 0.1))
		"bubbles":
			var c: Color = item.color
			for i in 6:
				var back := tile * (0.45 + i * 0.3)
				var wobble := side * sin(time * 12.0 + i * 1.7) * base * 0.3
				var r := base * (0.12 + 0.06 * ((i * 5) % 3))
				canvas.draw_arc(center - dir * back + wobble, r, 0, TAU, 14, Color(c, 0.85 - i * 0.12), 1.5)
				canvas.draw_circle(center - dir * back + wobble + Vector2(-r, -r) * 0.35, r * 0.25, Color(1, 1, 1, 0.7 - i * 0.1))
		"sparkle":
			var c: Color = item.color
			for i in 6:
				var back := tile * (0.4 + i * 0.28)
				var off := side * sin(time * 17.0 + i * 2.5) * base * 0.45
				var twinkle := 0.5 + 0.5 * sin(time * 25.0 + i * 1.3)
				_sparkle(canvas, center - dir * back + off, base * (0.22 - i * 0.025) * (0.6 + twinkle * 0.4), Color(c, 1.0 - i * 0.14))
		"fire":
			for i in 8:
				var back := tile * (0.35 + i * 0.2)
				var flicker := side * sin(time * 40.0 + i * 1.9) * base * 0.18
				var r := base * (0.42 - i * 0.045)
				var heat := Color("fff3a0").lerp(Color("ff3d00"), i / 7.0)
				canvas.draw_circle(center - dir * back + flicker, r, Color(heat, 0.9 - i * 0.1))
		"comet":
			for i in 10:
				var back := tile * (0.3 + i * 0.18)
				var hue := fposmod(time * 0.8 + i * 0.06, 1.0)
				var r := base * (0.45 - i * 0.04)
				canvas.draw_circle(center - dir * back, r, Color.from_hsv(hue, 0.65, 1.0, 0.75 - i * 0.07))
			_sparkle(canvas, center - dir * tile * 0.6 + side * base * 0.5, base * 0.2, Color(1, 1, 1, 0.9))
		"smoke":
			var c: Color = item.color
			for i in 6:
				var back := tile * (0.4 + i * 0.28)
				var drift := side * sin(time * 6.0 + i * 1.4) * base * 0.25
				canvas.draw_circle(center - dir * back + drift, base * (0.18 + i * 0.05), Color(c, 0.45 - i * 0.07))
		"hearts":
			var c: Color = item.color
			for i in 5:
				var back := tile * (0.45 + i * 0.32)
				var bob := side * sin(time * 10.0 + i * 2.0) * base * 0.3
				_heart(canvas, center - dir * back + bob, base * (0.2 - i * 0.025), Color(c, 0.95 - i * 0.17))
		"zap":
			var c: Color = item.color
			var points := PackedVector2Array([center - dir * tile * 0.35])
			for i in 6:
				var jag := side * base * 0.35 * (1.0 if (i + int(time * 20.0)) % 2 == 0 else -1.0)
				points.append(center - dir * tile * (0.6 + i * 0.3) + jag)
			canvas.draw_polyline(points, Color(c, 0.35), 5.0)
			canvas.draw_polyline(points, Color(1, 1, 1, 0.9), 1.5)
		"notes":
			var c: Color = item.color
			for i in 4:
				var back := tile * (0.5 + i * 0.4)
				var bob := side * sin(time * 8.0 + i * 1.9) * base * 0.35
				var p := center - dir * back + bob
				var r := base * (0.12 - i * 0.015)
				canvas.draw_circle(p, r, Color(c, 0.9 - i * 0.18))
				canvas.draw_line(p + Vector2(r * 0.9, 0), p + Vector2(r * 0.9, -r * 3.0), Color(c, 0.9 - i * 0.18), 1.5)
		"confetti":
			for i in 9:
				var back := tile * (0.35 + i * 0.2)
				var spread := side * sin(time * 23.0 + i * 2.7) * base * 0.5
				var hue := fmod(i * 0.13, 1.0)
				var s := base * 0.13
				canvas.draw_rect(Rect2(center - dir * back + spread - Vector2(s, s * 0.5), Vector2(s * 2.0, s)), Color.from_hsv(hue, 0.7, 1.0, 0.9 - i * 0.08))
		"leaves":
			var colors := [Color("e76f2a"), Color("d93f2b"), Color("f2b134"), Color("a8552c")]
			for i in 6:
				var back := tile * (0.4 + i * 0.3)
				var drift := side * sin(time * 7.0 + i * 2.3) * base * 0.4
				var spin := time * 6.0 + i
				var p := center - dir * back + drift
				var a := Vector2.from_angle(spin) * base * (0.2 - i * 0.02)
				var b := Vector2.from_angle(spin + PI * 0.5) * base * (0.1 - i * 0.01)
				canvas.draw_colored_polygon(PackedVector2Array([p - a, p + b, p + a, p - b]), Color(colors[i % 4], 0.95 - i * 0.13))
		"snowflakes":
			var c: Color = item.color
			for i in 6:
				var back := tile * (0.4 + i * 0.3)
				var drift := side * sin(time * 5.0 + i * 1.9) * base * 0.4
				var p := center - dir * back + drift
				var r := base * (0.18 - i * 0.02)
				for k in 3:
					var a := Vector2.from_angle(time * 2.0 + i + k * PI / 3.0) * r
					canvas.draw_line(p - a, p + a, Color(c, 0.95 - i * 0.14), 1.5)
		"paws":
			# Little paw prints left on the floor, alternating sides.
			var c: Color = item.color
			var step := tile * 0.45
			for i in 5:
				var p := center - dir * (tile * 0.5 + i * step) + side * base * (0.18 if i % 2 == 0 else -0.18)
				var col := Color(c, 0.9 - i * 0.17)
				var s := base * 0.09
				canvas.draw_circle(p, s * 1.3, col)
				for k in 3:
					canvas.draw_circle(p - dir * s * 1.8 + side * s * (k - 1) * 1.2, s * 0.6, col)
		"cat_tail":
			var c: Color = item.color
			var points := PackedVector2Array()
			for i in 8:
				var t := i / 7.0
				points.append(center - dir * tile * (0.4 + t * 0.9) + side * sin(time * 8.0 - t * 4.0) * base * 0.35 * t)
			canvas.draw_polyline(points, c, base * 0.18)
			canvas.draw_circle(points[points.size() - 1], base * 0.1, c.lightened(0.3))
		"bones":
			for i in 4:
				var p := center - dir * tile * (0.5 + i * 0.4) + side * sin(time * 6.0 + i) * base * 0.2
				var a := Vector2.from_angle(time * 3.0 + i) * base * 0.2
				var col := Color(item.color, 0.95 - i * 0.2)
				canvas.draw_line(p - a, p + a, col, base * 0.08)
				canvas.draw_circle(p - a, base * 0.07, col)
				canvas.draw_circle(p + a, base * 0.07, col)
		"blocks":
			var c: Color = item.color
			for i in 5:
				var s := base * (0.32 - i * 0.04)
				var p := center - dir * tile * (0.45 + i * 0.3)
				canvas.draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), Color(c, 0.95 - i * 0.16))
				canvas.draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s * 0.2)), Color(c.lightened(0.25), 0.95 - i * 0.16))
		"feathers":
			var c: Color = item.color
			for i in 5:
				var p := center - dir * tile * (0.45 + i * 0.32) + side * sin(time * 5.0 + i * 1.7) * base * 0.4
				var a := Vector2.from_angle(sin(time * 3.0 + i) * 0.8 + 0.6) * base * 0.22
				canvas.draw_line(p - a, p + a, Color(c, 0.95 - i * 0.17), base * 0.1)
				canvas.draw_line(p - a, p + a, Color(1, 1, 1, 0.5 - i * 0.09), 1.0)
		"goo":
			var c: Color = item.color
			var points := PackedVector2Array()
			for i in 8:
				points.append(center - dir * tile * (0.3 + i * 0.18))
			canvas.draw_polyline(points, Color(c, 0.6), base * 0.35)
			for i in 3:
				var p := center - dir * tile * (0.6 + i * 0.4) + side * base * 0.2
				canvas.draw_circle(p + Vector2(0, fposmod(time * 2.0 + i * 0.3, 1.0) * base * 0.4), base * 0.08, Color(c, 0.8))
		"bats":
			var c: Color = item.color
			for i in 4:
				var p := center - dir * tile * (0.5 + i * 0.45) + side * sin(time * 9.0 + i * 2.0) * base * 0.4
				var flap := sin(time * 20.0 + i) * base * 0.12
				var s := base * (0.25 - i * 0.03)
				canvas.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-s, -s * 0.5 - flap), p + Vector2(-s * 0.5, s * 0.1), p + Vector2(0, s * 0.3), p + Vector2(s * 0.5, s * 0.1), p + Vector2(s, -s * 0.5 - flap)]), Color(c, 0.95 - i * 0.18))
		"sparks":
			var c: Color = item.color
			for i in 8:
				var life := fposmod(time * 3.0 + i * 0.13, 1.0)
				var p := center - dir * tile * (0.4 + life * 1.2) + side * float(i % 2 * 2 - 1) * base * life * 0.5
				canvas.draw_line(p, p - dir * base * 0.2 + side * base * 0.1, Color(c, 1.0 - life), 2.0)
		"embers":
			for i in 9:
				var life := fposmod(time * 1.5 + i * 0.11, 1.0)
				var p := center - dir * tile * (0.35 + i * 0.18) + Vector2(0, -life * base * 0.6) + side * sin(time * 7.0 + i) * base * 0.25
				canvas.draw_circle(p, base * (0.1 - life * 0.06), Color("ffd23f").lerp(Color("ff3d00"), life) * Color(1, 1, 1, 1.0 - life * 0.8))
		"ribbon":
			for band in 3:
				var points := PackedVector2Array()
				for i in 10:
					var back := tile * (0.3 + i * 0.2)
					points.append(center - dir * back + side * (sin(time * 10.0 - i * 0.7) * base * 0.3 + (band - 1) * base * 0.14))
				var hue := fposmod(time * 0.5 + band * 0.12, 1.0)
				canvas.draw_polyline(points, Color.from_hsv(hue, 0.65, 1.0, 0.8), base * 0.14)


## Draws lava (or whatever the skin is) with its wavy surface at `top`,
## filling `left`..`right` down to `bottom`. `tint` blends it toward ice.
static func draw_lava(canvas: CanvasItem, item: Dictionary, left: float, right: float, top: float, bottom: float, time: float, tint := 0.0) -> void:
	var color: Color = item.color
	var glow: Color = item.glow
	if tint > 0.0:
		color = color.lerp(Color("6fc3e8"), tint)
		glow = glow.lerp(Color("e8fbff"), tint)
	var points := PackedVector2Array()
	var steps := 40
	for i in steps + 1:
		var x := lerpf(left, right, float(i) / steps)
		points.append(Vector2(x, top + sin(x * 0.045 + time * 3.0) * 5.0))
	var surface := points.duplicate()
	points.append(Vector2(right, bottom))
	points.append(Vector2(left, bottom))
	canvas.draw_colored_polygon(points, color)
	canvas.draw_polyline(surface, glow, 4.0)
	if item.has("bubbles") and tint < 0.5:
		var bubble: Color = item.bubbles
		var width := right - left
		# About one bubble per 60 pixels of surface.
		for i in maxi(3, int(width / 60.0)):
			# Each bubble rises a little way and pops, then starts again elsewhere.
			var life := fposmod(time * 0.7 + i * 0.37, 1.0)
			var x := left + fposmod(i * 0.29 + floorf(time * 0.7 + i * 0.37) * 0.53, 1.0) * width
			var y := top + 18.0 - life * 16.0
			canvas.draw_arc(Vector2(x, y), 2.0 + life * 3.5, 0, TAU, 12, Color(bubble, 1.0 - life), 2.0)


## `roof` is false when another wall sits right on top, so a stack of walls
## reads as one solid block with a single lit top edge.
static func draw_cracked(canvas: CanvasItem, r: Rect2, skin: Dictionary, time := 0.0, roof := true) -> void:
	var base: Color = skin.base
	var top: Color = skin.top
	var detail: Color = skin.detail
	var w := r.size.x
	var h := r.size.y
	var p := r.position
	var mid := r.get_center()
	canvas.draw_rect(r, base)
	if roof:
		canvas.draw_rect(Rect2(p, Vector2(w, h * 0.13)), top)
	match skin.style:
		"crack":
			canvas.draw_polyline(PackedVector2Array([
				p + Vector2(w * 0.2, h * 0.25), mid + Vector2(-w * 0.06, 0),
				mid + Vector2(w * 0.12, h * 0.12), r.end - Vector2(w * 0.16, h * 0.18),
			]), detail, 2.0)
			canvas.draw_line(mid + Vector2(-w * 0.06, 0), mid + Vector2(w * 0.2, -h * 0.25), detail, 2.0)
		"mud":
			# Drips running down from the top edge, and a few lumps.
			for i in 3 if roof else 0:
				var x := p.x + w * (0.2 + i * 0.3)
				var drip := h * (0.25 + 0.12 * ((i * 7) % 3))
				canvas.draw_line(Vector2(x, p.y + h * 0.1), Vector2(x, p.y + h * 0.1 + drip), top, w * 0.12)
				canvas.draw_circle(Vector2(x, p.y + h * 0.1 + drip), w * 0.07, top)
			canvas.draw_circle(mid + Vector2(-w * 0.15, h * 0.22), w * 0.08, detail)
			canvas.draw_circle(mid + Vector2(w * 0.2, h * 0.3), w * 0.06, detail)
		"snow":
			# A snow cap and a couple of sparkles.
			if roof:
				canvas.draw_rect(Rect2(p, Vector2(w, h * 0.3)), top)
				canvas.draw_circle(p + Vector2(w * 0.3, h * 0.3), w * 0.12, top)
				canvas.draw_circle(p + Vector2(w * 0.72, h * 0.28), w * 0.1, top)
			var twinkle := 0.5 + 0.5 * sin(time * 4.0 + p.x)
			_sparkle(canvas, mid + Vector2(-w * 0.15, h * 0.2), w * 0.12, Color(detail, 0.5 + twinkle * 0.5))
			_sparkle(canvas, mid + Vector2(w * 0.22, h * 0.05), w * 0.08, Color(detail, 1.0 - twinkle * 0.5))
		"planks":
			for i in 3:
				var y := p.y + h * (0.13 + i * 0.29)
				canvas.draw_line(Vector2(p.x, y), Vector2(r.end.x, y), detail, 1.5)
			canvas.draw_circle(p + Vector2(w * 0.25, h * 0.42), w * 0.04, detail)
			canvas.draw_circle(p + Vector2(w * 0.7, h * 0.72), w * 0.04, detail)
		"glass":
			canvas.draw_rect(r.grow(-1), Color(detail, 0.6), false, 1.5)
			canvas.draw_line(p + Vector2(w * 0.2, h * 0.75), p + Vector2(w * 0.55, h * 0.25), detail, 2.0)
			canvas.draw_line(p + Vector2(w * 0.45, h * 0.85), p + Vector2(w * 0.75, h * 0.45), Color(detail, 0.6), 1.5)
		"crystal":
			canvas.draw_colored_polygon(PackedVector2Array([
				mid + Vector2(0, -h * 0.38), mid + Vector2(w * 0.3, 0), mid + Vector2(0, h * 0.38), mid + Vector2(-w * 0.3, 0),
			]), top)
			canvas.draw_colored_polygon(PackedVector2Array([
				mid + Vector2(0, -h * 0.38), mid + Vector2(w * 0.3, 0), mid,
			]), detail)
		"magma":
			# Cracks that glow and pulse like the lava.
			var glow := Color(detail, 0.55 + 0.45 * sin(time * 3.0 + p.y * 0.1))
			var path := PackedVector2Array([
				p + Vector2(w * 0.15, h * 0.3), mid + Vector2(-w * 0.08, -h * 0.02),
				mid + Vector2(w * 0.1, h * 0.15), r.end - Vector2(w * 0.12, h * 0.15),
			])
			canvas.draw_polyline(path, Color(glow, glow.a * 0.4), 5.0)
			canvas.draw_polyline(path, glow, 2.0)
			canvas.draw_line(mid + Vector2(-w * 0.08, -h * 0.02), mid + Vector2(w * 0.22, -h * 0.28), glow, 2.0)
		"coins":
			# A heap of coins.
			for i in 5:
				var o := Vector2(w * (0.22 + (i % 3) * 0.28), h * (0.72 - floorf(i / 3.0) * 0.3))
				canvas.draw_circle(p + o, w * 0.15, detail.darkened(0.25))
				canvas.draw_circle(p + o - Vector2(0, h * 0.04), w * 0.15, detail)
		"marble":
			canvas.draw_polyline(PackedVector2Array([
				p + Vector2(0, h * 0.35), p + Vector2(w * 0.35, h * 0.45),
				p + Vector2(w * 0.55, h * 0.75), p + Vector2(w, h * 0.85),
			]), detail, 1.5)
			canvas.draw_line(p + Vector2(w * 0.35, h * 0.45), p + Vector2(w * 0.8, h * 0.2), Color(detail, 0.6), 1.0)
		"moss":
			# Moss growing over the top and creeping down the sides.
			if roof:
				canvas.draw_rect(Rect2(p, Vector2(w, h * 0.22)), top)
				for i in 3:
					canvas.draw_circle(p + Vector2(w * (0.2 + i * 0.3), h * 0.22), w * 0.1, top)
			canvas.draw_circle(p + Vector2(w * 0.15, h * 0.65), w * 0.09, detail)
			canvas.draw_circle(p + Vector2(w * 0.8, h * 0.5), w * 0.07, detail)
			canvas.draw_polyline(PackedVector2Array([p + Vector2(w * 0.3, h * 0.35), mid + Vector2(w * 0.05, h * 0.1), p + Vector2(w * 0.62, h * 0.8)]), Color(0, 0, 0, 0.35), 1.5)
		"bricks":
			var row_h := h / 3.0
			for i in 3:
				var y := p.y + row_h * i
				canvas.draw_line(Vector2(p.x, y), Vector2(r.end.x, y), detail, 1.0)
				var off := w * (0.5 if i % 2 == 0 else 0.25)
				canvas.draw_line(Vector2(p.x + off, y), Vector2(p.x + off, y + row_h), detail, 1.0)
				if i % 2 == 1:
					canvas.draw_line(Vector2(p.x + w * 0.75, y), Vector2(p.x + w * 0.75, y + row_h), detail, 1.0)
			canvas.draw_line(mid + Vector2(-w * 0.15, -h * 0.05), mid + Vector2(w * 0.12, h * 0.2), Color(0, 0, 0, 0.45), 1.5)
		"neon":
			var pulse := 0.6 + 0.4 * sin(time * 3.0 + p.x * 0.05 + p.y * 0.03)
			canvas.draw_rect(r.grow(-2), Color(detail, 0.25 * pulse), false, 4.0)
			canvas.draw_rect(r.grow(-2), Color(detail, pulse), false, 1.5)
			canvas.draw_polyline(PackedVector2Array([p + Vector2(w * 0.25, h * 0.3), mid, r.end - Vector2(w * 0.25, h * 0.3)]), Color(detail, pulse), 1.5)
		"candy":
			for x0 in [0.05, 0.35, 0.65]:
				canvas.draw_line(p + Vector2(w * x0, h * 0.04), p + Vector2(w * (x0 + 0.28), h * 0.96), detail, w * 0.12)
			canvas.draw_line(mid + Vector2(-w * 0.2, -h * 0.1), mid + Vector2(w * 0.15, h * 0.15), Color(0, 0, 0, 0.3), 1.5)
		"cobble":
			for i in 5:
				var o := Vector2([0.28, 0.72, 0.5, 0.22, 0.78][i] * w, [0.35, 0.33, 0.62, 0.8, 0.8][i] * h)
				var rad: float = w * [0.17, 0.16, 0.15, 0.14, 0.13][i]
				canvas.draw_circle(p + o, rad, top if i % 2 == 0 else base.lightened(0.08))
				canvas.draw_arc(p + o, rad, 0, TAU, 12, detail, 1.2)
		"cookie":
			canvas.draw_rect(r.grow(-1), Color(detail, 0.25), false, 1.5)
			for i in 6:
				var o := Vector2([0.25, 0.7, 0.45, 0.2, 0.62, 0.82][i] * w, [0.35, 0.3, 0.55, 0.75, 0.82][mini(i, 4)] * h)
				canvas.draw_circle(p + o, w * 0.07, detail)
			canvas.draw_line(mid + Vector2(-w * 0.1, -h * 0.25), mid + Vector2(w * 0.05, h * 0.1), Color(0, 0, 0, 0.3), 1.5)
		"studs":
			for i in 2:
				var o := p + Vector2(w * (0.28 + i * 0.44), h * 0.13)
				canvas.draw_rect(Rect2(o - Vector2(w * 0.13, h * 0.12), Vector2(w * 0.26, h * 0.12)), top)
				canvas.draw_rect(Rect2(o - Vector2(w * 0.13, h * 0.12), Vector2(w * 0.26, h * 0.04)), top.lightened(0.25))
			canvas.draw_line(p + Vector2(w * 0.5, h * 0.3), p + Vector2(w * 0.5, h * 0.95), Color(detail, 0.7), 1.0)
			canvas.draw_line(mid + Vector2(-w * 0.2, h * 0.05), mid + Vector2(w * 0.1, h * 0.3), Color(0, 0, 0, 0.35), 1.5)
		"circuit":
			canvas.draw_polyline(PackedVector2Array([p + Vector2(0, h * 0.4), p + Vector2(w * 0.35, h * 0.4), p + Vector2(w * 0.5, h * 0.6), p + Vector2(w, h * 0.6)]), detail, 1.5)
			canvas.draw_polyline(PackedVector2Array([p + Vector2(w * 0.3, h), p + Vector2(w * 0.3, h * 0.78), p + Vector2(w * 0.7, h * 0.78)]), detail, 1.5)
			canvas.draw_rect(Rect2(p + Vector2(w * 0.6, h * 0.25), Vector2(w * 0.22, h * 0.16)), Color("1d2030"))
			canvas.draw_circle(p + Vector2(w * 0.7, h * 0.78), w * 0.05, detail)
			var led := 0.4 + 0.6 * float(fposmod(time + p.x * 0.01, 1.2) < 0.6)
			canvas.draw_circle(p + Vector2(w * 0.22, h * 0.22), w * 0.06, Color(0.3, 1.0, 0.4, led))
		"scratch":
			for i in 3:
				canvas.draw_line(p + Vector2(w * (0.25 + i * 0.22), h * 0.3), p + Vector2(w * (0.15 + i * 0.22), h * 0.8), detail, 2.0)
			canvas.draw_line(p + Vector2(0, h * 0.2), p + Vector2(w, h * 0.2), Color(detail, 0.5), 1.0)
		"doghouse":
			if roof:
				canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-1, h * 0.3), p + Vector2(w * 0.5, 0), p + Vector2(w + 1, h * 0.3)]), top)
			canvas.draw_rect(Rect2(p + Vector2(w * 0.32, h * 0.5), Vector2(w * 0.36, h * 0.5)), detail)
			canvas.draw_circle(p + Vector2(w * 0.5, h * 0.5), w * 0.18, detail)
		"bricky":
			canvas.draw_line(p + Vector2(0, h * 0.5), p + Vector2(w, h * 0.5), detail, 1.0)
			canvas.draw_line(p + Vector2(w * 0.5, h * 0.13), p + Vector2(w * 0.5, h * 0.5), detail, 1.0)
			canvas.draw_circle(mid + Vector2(-w * 0.18, h * 0.12), w * 0.05, Color("1d2030"))
			canvas.draw_circle(mid + Vector2(w * 0.18, h * 0.12), w * 0.05, Color("1d2030"))
			canvas.draw_arc(mid + Vector2(0, h * 0.2), w * 0.12, 0.3, PI - 0.3, 6, Color("1d2030"), 1.5)
		"nest":
			for i in 6:
				var y := p.y + h * (0.2 + i * 0.13)
				canvas.draw_line(Vector2(p.x, y + (i % 2) * 3.0), Vector2(r.end.x, y - (i % 2) * 3.0), Color(detail if i % 2 == 0 else top, 0.9), 1.5)
			canvas.draw_circle(mid + Vector2(w * 0.15, -h * 0.1), w * 0.12, Color("fff6e0"))
		"slime":
			if roof:
				canvas.draw_rect(Rect2(p, Vector2(w, h * 0.22)), top)
				for i in 3:
					var drip := h * (0.15 + 0.075 * sin(time * 2.0 + i * 2.0 + p.x) + 0.1 * (i % 2))
					canvas.draw_line(Vector2(p.x + w * (0.2 + i * 0.3), p.y + h * 0.2), Vector2(p.x + w * (0.2 + i * 0.3), p.y + h * 0.2 + drip), top, w * 0.1)
			canvas.draw_circle(mid + Vector2(w * 0.15, h * 0.2), w * 0.07, Color(detail, 0.6))
		"cave":
			for i in 3:
				var x0 := p.x + w * (0.12 + i * 0.32)
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x0, p.y + h * 0.13), Vector2(x0 + w * 0.2, p.y + h * 0.13), Vector2(x0 + w * 0.1, p.y + h * (0.45 + 0.1 * (i % 2)))]), detail)
			canvas.draw_circle(mid + Vector2(-w * 0.1, h * 0.25), w * 0.04, Color(0.8, 1.0, 0.6, 0.4 + 0.4 * sin(time * 3.0 + p.x)))
		"plate":
			canvas.draw_rect(r.grow(-2), Color(detail, 0.35), false, 1.0)
			for c in [p + Vector2(w * 0.15, h * 0.25), p + Vector2(w * 0.85, h * 0.25), p + Vector2(w * 0.15, h * 0.85), p + Vector2(w * 0.85, h * 0.85)]:
				canvas.draw_circle(c, w * 0.05, detail)
			canvas.draw_line(p + Vector2(w * 0.3, h * 0.55), p + Vector2(w * 0.7, h * 0.55), Color(0, 0, 0, 0.3), 1.5)
		"dscale":
			for row in 3:
				for col in 3:
					var c := p + Vector2(w * (0.17 + col * 0.33 - (0.16 if row % 2 == 1 else 0.0)), h * (0.35 + row * 0.24))
					canvas.draw_arc(c, w * 0.16, 0.2, PI - 0.2, 6, detail, 1.5)
		"bars":
			for i in 2:
				var bar := Rect2(p + Vector2(w * 0.1, h * (0.2 + i * 0.4)), Vector2(w * 0.8, h * 0.32))
				canvas.draw_rect(bar, top)
				canvas.draw_rect(bar, detail, false, 1.5)
			var shine := fposmod(time * 0.6, 1.6) - 0.3
			if shine >= 0.0 and shine <= 1.0:
				var x := p.x + w * shine
				canvas.draw_line(Vector2(x, p.y + 2), Vector2(x - w * 0.2, r.end.y - 2), Color(1, 1, 1, 0.6), 2.0)


static func _heart(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, color)
	canvas.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, color)
	canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.0, 0), c + Vector2(s * 1.0, 0), c + Vector2(0, s * 1.1)]), color)


static func _sparkle(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_line(c - Vector2(s, 0), c + Vector2(s, 0), color, 1.5)
	canvas.draw_line(c - Vector2(0, s), c + Vector2(0, s), color, 1.5)
