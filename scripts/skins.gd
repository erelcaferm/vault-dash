extends RefCounted
## Everything the shop sells, and how to draw it.
## Prices are in coins. Items priced 0 are owned from the start.
## Items marked chest_only can't be bought; they only drop from chests.
## Items with an "achievement" id are earned by unlocking that achievement.

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

## How fast the rainbow hero cycles through every colour, in full cycles per
## second, standing still and while sliding.
const RAINBOW_IDLE_SPEED := 0.25
const RAINBOW_SLIDE_SPEED := 1.5


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
