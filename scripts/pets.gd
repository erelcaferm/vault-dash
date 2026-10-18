extends RefCounted
## Pets: hatched from eggs at the pet station, they follow you around the
## tower. Each eats one kind of food, which shows up in levels while that pet
## is equipped. Feeding levels it up, and each level unlocks one piece of the
## pet's own cosmetic line (a hat, a trail, a hero skin and walls), listed in
## skins.gd with "pet" and "pet_level".

const MAX_LEVEL := 5
## Food needed to go from level n to n + 1 (index 0 is level 1 -> 2).
const FEEDS := [2, 3, 4, 5]
const EGG_PRICE := 1500

const LIST := [
	{"id": "cat", "name": "Kitty", "food": "fish", "food_name": "Fish", "color": Color("f08c3a")},
	{"id": "dog", "name": "Puppy", "food": "bone", "food_name": "Bone", "color": Color("b07b4f")},
	{"id": "wall", "name": "Bricky", "food": "pebble", "food_name": "Pebble", "color": Color("8a8f9c")},
	{"id": "chick", "name": "Chick", "food": "seeds", "food_name": "Seeds", "color": Color("ffd84d")},
	{"id": "slime", "name": "Slimey", "food": "jelly", "food_name": "Jelly", "color": Color("6fdc5a")},
	{"id": "bat", "name": "Batty", "food": "cherry", "food_name": "Cherry", "color": Color("6b4a9c")},
	{"id": "robo", "name": "Robo", "food": "bolt", "food_name": "Bolt", "color": Color("9aa5b1")},
	{"id": "dragon", "name": "Drako", "food": "pepper", "food_name": "Pepper", "color": Color("e04a3a")},
]


static func find(id: String) -> Dictionary:
	for p in LIST:
		if p.id == id:
			return p
	return {}


## Food still needed to reach the next level, or 0 at the top level.
static func feeds_to_next(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return FEEDS[level - 1]


## Draws `pet` at `c`, about `s` pixels across. `dir` is the way it's moving.
static func draw_pet(canvas: CanvasItem, pet: Dictionary, c: Vector2, s: float, time: float, dir := Vector2.ZERO) -> void:
	var col: Color = pet.color
	var bob := sin(time * 6.0) * s * 0.05
	c.y += bob
	var face := 1.0 if dir.x >= 0.0 else -1.0
	var eye := Color("1d2030")
	var blink := fposmod(time + pet.id.length(), 3.1) < 0.12
	var h := s * 0.5
	match pet.id:
		"cat":
			var tail := PackedVector2Array()
			for i in 5:
				var t := i / 4.0
				tail.append(c + Vector2(-face * h * (0.8 + t * 0.6), h * (0.3 - t * 0.9) + sin(time * 4.0 + t * 2.0) * h * 0.25 * t))
			canvas.draw_polyline(tail, col.darkened(0.15), s * 0.12)
			canvas.draw_rect(Rect2(c - Vector2(h, h * 0.8), Vector2(s, s * 0.8)), col)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(side * h, -h * 0.8), c + Vector2(side * h * 0.75, -h * 1.35), c + Vector2(side * h * 0.2, -h * 0.8)]), col)
		"dog":
			canvas.draw_rect(Rect2(c - Vector2(h, h * 0.8), Vector2(s, s * 0.8)), col)
			for side in [-1.0, 1.0]:
				canvas.draw_rect(Rect2(c + Vector2(side * h - (s * 0.22 if side > 0 else 0.0), -h * 0.85), Vector2(s * 0.22, s * 0.5)), col.darkened(0.35))
			canvas.draw_circle(c + Vector2(face * h * 0.2, h * 0.15), s * 0.08, eye)
			var wag := sin(time * 18.0) * 0.6
			canvas.draw_line(c + Vector2(-face * h, -h * 0.2), c + Vector2(-face * h * 1.5, -h * 0.6).rotated(wag * 0.2), col.darkened(0.15), s * 0.1)
		"wall":
			var r := Rect2(c - Vector2(h, h), Vector2(s, s))
			canvas.draw_rect(r, col)
			canvas.draw_rect(Rect2(r.position, Vector2(s, s * 0.15)), col.lightened(0.2))
			canvas.draw_line(r.position + Vector2(0, s * 0.55), r.position + Vector2(s, s * 0.55), col.darkened(0.3), 1.0)
			canvas.draw_line(r.position + Vector2(s * 0.5, s * 0.15), r.position + Vector2(s * 0.5, s * 0.55), col.darkened(0.3), 1.0)
		"chick":
			canvas.draw_circle(c, h, col)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(face * h * 0.8, 0), c + Vector2(face * h * 1.3, h * 0.12), c + Vector2(face * h * 0.8, h * 0.25)]), Color("ff8c1a"))
			canvas.draw_line(c + Vector2(0, -h), c + Vector2(face * h * 0.2, -h * 1.35), col.darkened(0.2), 2.0)
			var flap := sin(time * 14.0) * h * 0.2
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-face * h * 0.2, 0), c + Vector2(-face * h * 0.9, -flap), c + Vector2(-face * h * 0.6, h * 0.4)]), col.darkened(0.12))
		"slime":
			var squish := 1.0 + sin(time * 5.0) * 0.08
			var body := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				body.append(c + Vector2(cos(a) * h * squish, h * 0.6 + sin(a) * s * 0.85 / squish))
			canvas.draw_colored_polygon(body, Color(col, 0.85))
			canvas.draw_circle(c + Vector2(-h * 0.35, -h * 0.25), s * 0.08, Color(1, 1, 1, 0.6))
		"bat":
			var flap := sin(time * 16.0)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(side * h * 0.4, -h * 0.2), c + Vector2(side * h * 1.4, -h * 0.6 + flap * h * 0.5), c + Vector2(side * h * 1.1, h * 0.3), c + Vector2(side * h * 0.4, h * 0.2)]), col.darkened(0.2))
			canvas.draw_circle(c, h * 0.62, col)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(side * h * 0.15, -h * 0.5), c + Vector2(side * h * 0.45, -h * 1.0), c + Vector2(side * h * 0.5, -h * 0.35)]), col)
		"robo":
			canvas.draw_rect(Rect2(c - Vector2(h, h * 0.8), Vector2(s, s * 0.8)), col)
			canvas.draw_line(c + Vector2(0, -h * 0.8), c + Vector2(0, -h * 1.3), col.darkened(0.4), 1.5)
			canvas.draw_circle(c + Vector2(0, -h * 1.35), s * 0.07, Color("ff3b3b") if fposmod(time, 1.0) < 0.5 else Color("6b1a1a"))
			canvas.draw_rect(Rect2(c + Vector2(-h * 0.7, -h * 0.45), Vector2(s * 0.7, s * 0.22)), Color("1d2030"))
			canvas.draw_rect(Rect2(c + Vector2(-h * 0.7 + (sin(time * 3.0) * 0.5 + 0.5) * s * 0.5, -h * 0.4), Vector2(s * 0.18, s * 0.12)), Color("39f0ff"))
		"dragon":
			var flap := sin(time * 10.0)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-face * h * 0.1, -h * 0.4), c + Vector2(-face * h * 1.2, -h * (1.1 + flap * 0.3)), c + Vector2(-face * h * 0.9, 0)]), col.darkened(0.3))
			canvas.draw_rect(Rect2(c - Vector2(h, h * 0.8), Vector2(s, s * 0.8)), col)
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(side * h * 0.6, -h * 0.8), c + Vector2(side * h * 0.85, -h * 1.3), c + Vector2(side * h * 0.25, -h * 0.8)]), Color("ffe0a0"))
			canvas.draw_rect(Rect2(c + Vector2(-h, h * 0.15), Vector2(s, s * 0.15)), Color("ffb36b"))
			if fposmod(time, 2.5) < 0.3:
				canvas.draw_circle(c + Vector2(face * h * 1.3, 0), s * 0.12, Color(1.0, 0.6, 0.1, 0.8))
	# Eyes (the slime and wall share the same face as everyone else).
	if pet.id != "dog":
		var ey := c.y - h * (0.3 if pet.id != "slime" else 0.0)
		for side in [-1.0, 1.0]:
			var e := Vector2(c.x + side * h * 0.35 + face * h * 0.1, ey)
			if blink:
				canvas.draw_line(e - Vector2(s * 0.07, 0), e + Vector2(s * 0.07, 0), eye, 1.5)
			else:
				canvas.draw_circle(e, s * 0.07, eye if pet.id != "robo" else Color(0, 0, 0, 0))


## Food drawn on a level tile.
static func draw_food(canvas: CanvasItem, food: String, c: Vector2, s: float, time: float) -> void:
	var bob := sin(time * 4.0) * s * 0.06
	c.y += bob
	canvas.draw_circle(c, s * 0.6, Color(1, 1, 1, 0.12 + 0.06 * sin(time * 5.0)))
	match food:
		"fish":
			canvas.draw_circle(c, s * 0.28, Color("5fb3e8"))
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, 0), c + Vector2(s * 0.5, -s * 0.22), c + Vector2(s * 0.5, s * 0.22)]), Color("3d8cc4"))
			canvas.draw_circle(c + Vector2(-s * 0.12, -s * 0.06), s * 0.05, Color("1d2030"))
		"bone":
			canvas.draw_line(c - Vector2(s * 0.3, 0), c + Vector2(s * 0.3, 0), Color("f4f1de"), s * 0.16)
			for x in [-1.0, 1.0]:
				canvas.draw_circle(c + Vector2(x * s * 0.33, -s * 0.09), s * 0.1, Color("f4f1de"))
				canvas.draw_circle(c + Vector2(x * s * 0.33, s * 0.09), s * 0.1, Color("f4f1de"))
		"pebble":
			canvas.draw_circle(c, s * 0.26, Color("a9a39a"))
			canvas.draw_circle(c + Vector2(-s * 0.08, -s * 0.08), s * 0.08, Color("c9c4bc"))
		"seeds":
			for i in 5:
				canvas.draw_circle(c + Vector2.from_angle(TAU * i / 5.0) * s * 0.17, s * 0.08, Color("e3c27a"))
		"jelly":
			canvas.draw_rect(Rect2(c - Vector2(s * 0.25, s * 0.2), Vector2(s * 0.5, s * 0.4)), Color(1.0, 0.3, 0.55, 0.85))
			canvas.draw_rect(Rect2(c - Vector2(s * 0.2, s * 0.15), Vector2(s * 0.12, s * 0.08)), Color(1, 1, 1, 0.6))
		"cherry":
			canvas.draw_circle(c + Vector2(-s * 0.13, s * 0.1), s * 0.15, Color("d81e3c"))
			canvas.draw_circle(c + Vector2(s * 0.13, s * 0.12), s * 0.15, Color("d81e3c"))
			canvas.draw_line(c + Vector2(-s * 0.1, 0), c + Vector2(s * 0.05, -s * 0.3), Color("4d8a33"), 1.5)
			canvas.draw_line(c + Vector2(s * 0.12, 0), c + Vector2(s * 0.05, -s * 0.3), Color("4d8a33"), 1.5)
		"bolt":
			canvas.draw_rect(Rect2(c - Vector2(s * 0.07, s * 0.1), Vector2(s * 0.14, s * 0.4)), Color("b8bec6"))
			canvas.draw_rect(Rect2(c - Vector2(s * 0.22, s * 0.25), Vector2(s * 0.44, s * 0.16)), Color("d0d5dc"))
		"pepper":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.2, -s * 0.15), c + Vector2(s * 0.2, -s * 0.15), c + Vector2(s * 0.05, s * 0.35)]), Color("e8382f"))
			canvas.draw_line(c + Vector2(0, -s * 0.15), c + Vector2(s * 0.08, -s * 0.32), Color("4d8a33"), 2.0)
