extends Control
## The shop's preview window: your hero, hat and trail sliding back and
## forth between two cracked walls above the lava, so you can see a whole
## look before buying. main.gd's equipped items are used unless `trying`
## holds an item for that kind.

const Skins := preload("res://scripts/skins.gd")

var game
var trying := {}                 # kind -> item being tried on
var _time := 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func item(kind: String) -> Dictionary:
	if trying.has(kind):
		return trying[kind]
	match kind:
		"hero":
			return Skins.find(Skins.HERO, game.equipped_hero)
		"hat":
			return Skins.find(Skins.HATS, game.equipped_hat)
		"trail":
			return Skins.find(Skins.TRAILS, game.equipped_trail)
		"lava":
			return Skins.find(Skins.LAVA, game.equipped_lava)
	return Skins.find(Skins.WALLS, game.equipped_wall)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.09, 0.09, 0.14))
	var tile := minf(size.y * 0.34, 34.0)
	var floor_y := size.y - tile * 0.9
	# Two cracked walls to slide between, with the lava creeping below.
	var left := Rect2(Vector2(size.x * 0.12, floor_y - tile), Vector2(tile, tile))
	var right := Rect2(Vector2(size.x * 0.88 - tile, floor_y - tile), Vector2(tile, tile))
	Skins.draw_cracked(self, left, item("walls"), _time)
	Skins.draw_cracked(self, right, item("walls"), _time)
	Skins.draw_lava(self, item("lava"), 0.0, size.x, floor_y + tile * 0.35, size.y, _time)

	# Slide right, pause, slide left, pause.
	var span := right.position.x - left.end.x - tile
	var cycle := fposmod(_time, 2.4) / 2.4
	var t := 0.0
	var dir := Vector2.ZERO
	if cycle < 0.3:
		t = cycle / 0.3
		dir = Vector2.RIGHT
	elif cycle < 0.5:
		t = 1.0
	elif cycle < 0.8:
		t = 1.0 - (cycle - 0.5) / 0.3
		dir = Vector2.LEFT
	var center := Vector2(left.end.x + tile * 0.5 + span * t, floor_y - tile * 0.5)
	var hero := item("hero")
	var color := Skins.hero_color(hero, _time * (Skins.RAINBOW_SLIDE_SPEED if dir != Vector2.ZERO else Skins.RAINBOW_IDLE_SPEED))
	var body := Vector2(tile - 6, tile - 6)
	if dir != Vector2.ZERO:
		body *= Vector2(1.2, 0.82)
		Skins.draw_trail(self, item("trail"), center, dir, body, color, _time)
	Skins.draw_hero_item(self, hero, center, body, color, dir * 3.0, _time, dir)
	Skins.draw_hat(self, item("hat"), center, body, _time)
	draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)
