extends RefCounted
## Everything the shop sells, and how to draw it.
## Prices are in coins. Items priced 0 are owned from the start.
## Items marked chest_only can't be bought; they only drop from chests.
## Items with an "achievement" id are earned by unlocking that achievement.
## Items with a "level" number are the reward for clearing that level.

const HERO := [
	{"id": "white", "name": "White", "price": 0, "color": Color("f4f1de")},
	{"id": "black", "name": "Black", "price": 0, "color": Color("17171c")},
	{"id": "red", "name": "Red", "price": 100, "color": Color("e63946")},
	{"id": "orange", "name": "Orange", "price": 100, "color": Color("f4a261")},
	{"id": "lemon", "name": "Lemon", "price": 100, "color": Color("f6e05e")},
	{"id": "mint", "name": "Mint", "price": 150, "color": Color("74e0b0")},
	{"id": "green", "name": "Green", "price": 150, "color": Color("40a352")},
	{"id": "sky", "name": "Sky", "price": 200, "color": Color("4cc9f0")},
	{"id": "blue", "name": "Blue", "price": 200, "color": Color("4361ee")},
	{"id": "purple", "name": "Purple", "price": 250, "color": Color("9d4edd")},
	{"id": "pink", "name": "Pink", "price": 250, "color": Color("ff70a6")},
	{"id": "gold", "name": "Gold", "price": 600, "color": Color("ffc300")},
	{"id": "rainbow", "name": "Rainbow", "price": 1500, "rainbow": true},
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
]

## Cracked-wall skins. `style` picks the pattern drawn on top of the block.
const WALLS := [
	{"id": "rubble", "name": "Rubble", "price": 0, "style": "crack",
		"base": Color("8a6a4a"), "top": Color("b08a64"), "detail": Color("45352a")},
	{"id": "mud", "name": "Mud", "price": 150, "style": "mud",
		"base": Color("5c4033"), "top": Color("7a5640"), "detail": Color("3b2a20")},
	{"id": "snow", "name": "Snow", "price": 150, "style": "snow",
		"base": Color("dfeaf5"), "top": Color("ffffff"), "detail": Color("9fbcd8")},
	{"id": "wood", "name": "Wood", "price": 200, "style": "planks",
		"base": Color("a0703c"), "top": Color("c08a50"), "detail": Color("6b4423")},
	{"id": "glass", "name": "Glass", "price": 300, "style": "glass",
		"base": Color(0.62, 0.86, 1.0, 0.45), "top": Color(1, 1, 1, 0.75), "detail": Color(1, 1, 1, 0.85)},
	{"id": "crystal", "name": "Crystal", "price": 400, "style": "crystal",
		"base": Color("7b2cbf"), "top": Color("c77dff"), "detail": Color("e0aaff")},
	{"id": "gold_bars", "name": "Gold Bars", "price": 800, "style": "bars",
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
]

## Trails left behind the hero while sliding. `style` picks how it's drawn.
const TRAILS := [
	{"id": "afterimage", "name": "Afterimage", "price": 0, "style": "afterimage"},
	{"id": "pixels", "name": "Pixels", "price": 200, "style": "pixels"},
	{"id": "bubbles", "name": "Bubbles", "price": 250, "style": "bubbles", "color": Color("8fd8ff")},
	{"id": "sparkle", "name": "Sparkle", "price": 350, "style": "sparkle", "color": Color("fff3a8")},
	{"id": "fire", "name": "Fire", "price": 500, "style": "fire"},
	{"id": "comet", "name": "Comet", "price": -1, "chest_only": true, "style": "comet"},
	{"id": "gold_dust", "name": "Gold Dust", "price": -1, "achievement": "daily_goal", "style": "sparkle", "color": Color("ffd23f")},
	{"id": "breadcrumbs", "name": "Breadcrumbs", "price": -1, "level": 9, "style": "bubbles", "color": Color("d9a066")},
]

## Hats worn on top of the hero. `style` picks how it's drawn.
const HATS := [
	{"id": "no_hat", "name": "No hat", "price": 0, "style": "none"},
	{"id": "cap", "name": "Cap", "price": 150, "style": "cap", "color": Color("e63946")},
	{"id": "beanie", "name": "Beanie", "price": 200, "style": "beanie", "color": Color("4361ee")},
	{"id": "party", "name": "Party Hat", "price": 250, "style": "party", "color": Color("ff70a6")},
	{"id": "headphones", "name": "Headphones", "price": 300, "style": "headphones", "color": Color("2b2d42")},
	{"id": "top_hat", "name": "Top Hat", "price": 450, "style": "top_hat", "color": Color("17171c")},
	{"id": "wizard", "name": "Wizard", "price": 600, "style": "wizard", "color": Color("5a189a")},
	{"id": "crown", "name": "Crown", "price": -1, "chest_only": true, "style": "crown", "color": Color("ffc300")},
	{"id": "horns", "name": "Horns", "price": -1, "achievement": "pincushion", "style": "horns", "color": Color("c1121f")},
	{"id": "halo", "name": "Halo", "price": -1, "achievement": "mission_master", "style": "halo", "color": Color("fff3a8")},
	{"id": "explorer", "name": "Explorer", "price": -1, "level": 6, "style": "explorer", "color": Color("d4a373")},
	{"id": "laurel", "name": "Laurel", "price": -1, "level": 12, "style": "laurel", "color": Color("6a994e")},
]

## What rises from below. `color` fills it, `glow` lines the surface, and
## `bubbles` adds popping bubbles of that colour.
const LAVA := [
	{"id": "classic", "name": "Lava", "price": 0, "color": Color("ff5a1f"), "glow": Color("ffb347")},
	{"id": "acid", "name": "Acid", "price": 250, "color": Color("3fbf3f"), "glow": Color("b6ff6b"), "bubbles": Color("d9ff9e")},
	{"id": "chocolate", "name": "Chocolate", "price": 300, "color": Color("5b3420"), "glow": Color("8a5634")},
	{"id": "bubblegum", "name": "Bubblegum", "price": 350, "color": Color("ff70a6"), "glow": Color("ffc2da"), "bubbles": Color("ffe0ec")},
	{"id": "plasma", "name": "Plasma", "price": 500, "color": Color("5a189a"), "glow": Color("e0aaff"), "bubbles": Color("c77dff")},
	{"id": "molten_gold", "name": "Molten Gold", "price": -1, "chest_only": true, "color": Color("d4a017"), "glow": Color("fff1a8"), "bubbles": Color("ffe066")},
	{"id": "ash", "name": "Ash", "price": -1, "achievement": "hot_feet", "color": Color("3a3a40"), "glow": Color("ff7b1c"), "bubbles": Color("ff9e4a")},
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


static func draw_cracked(canvas: CanvasItem, r: Rect2, skin: Dictionary, time := 0.0) -> void:
	var base: Color = skin.base
	var top: Color = skin.top
	var detail: Color = skin.detail
	var w := r.size.x
	var h := r.size.y
	var p := r.position
	var mid := r.get_center()
	canvas.draw_rect(r, base)
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
			for i in 3:
				var x := p.x + w * (0.2 + i * 0.3)
				var drip := h * (0.25 + 0.12 * ((i * 7) % 3))
				canvas.draw_line(Vector2(x, p.y + h * 0.1), Vector2(x, p.y + h * 0.1 + drip), top, w * 0.12)
				canvas.draw_circle(Vector2(x, p.y + h * 0.1 + drip), w * 0.07, top)
			canvas.draw_circle(mid + Vector2(-w * 0.15, h * 0.22), w * 0.08, detail)
			canvas.draw_circle(mid + Vector2(w * 0.2, h * 0.3), w * 0.06, detail)
		"snow":
			# A snow cap and a couple of sparkles.
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
		"bars":
			for i in 2:
				var bar := Rect2(p + Vector2(w * 0.1, h * (0.2 + i * 0.4)), Vector2(w * 0.8, h * 0.32))
				canvas.draw_rect(bar, top)
				canvas.draw_rect(bar, detail, false, 1.5)
			var shine := fposmod(time * 0.6, 1.6) - 0.3
			if shine >= 0.0 and shine <= 1.0:
				var x := p.x + w * shine
				canvas.draw_line(Vector2(x, p.y + 2), Vector2(x - w * 0.2, r.end.y - 2), Color(1, 1, 1, 0.6), 2.0)


static func _sparkle(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_line(c - Vector2(s, 0), c + Vector2(s, 0), color, 1.5)
	canvas.draw_line(c - Vector2(0, s), c + Vector2(0, s), color, 1.5)
