extends SceneTree
## Draws the app icon in the game's own style and saves it as icon.png
## (1024 x 1024, square, no transparency, as the App Store wants; Google
## Play and Godot scale it down).
## Run: xvfb-run godot --path . --script res://tools/make_icon.gd

const SIZE := 1024
const Skins := preload("res://scripts/skins.gd")

var viewport: SubViewport
var frames := 0


class Icon extends Node2D:
	const BG := Color("1d2030")
	const WALL := Color("4a5068")
	const EDGE := Color("7a82a3")
	const COIN := Color("ffd23f")

	func _draw() -> void:
		var s := 1024.0
		var t := s / 8.0                       # one tile
		draw_rect(Rect2(0, 0, s, s), BG.darkened(0.25))
		# Tower walls down both sides, with a ledge to slide past.
		for y in 8:
			for x in [0, 7]:
				_wall(Rect2(x * t, y * t, t, t))
		_wall(Rect2(t, 2 * t, t * 2, t))
		_wall(Rect2(5 * t, 4 * t, t * 2, t))
		# Lava rising from the bottom.
		var lava := Color("ff5a1f")
		for i in 6:
			var a := 0.12 + i * 0.03
			draw_rect(Rect2(0, s - t * 2.6 + i * t * 0.12, s, t * 2.6), Color(lava, a))
		var wave := PackedVector2Array()
		for i in 33:
			var x := s * i / 32.0
			wave.append(Vector2(x, s - t * 1.15 + sin(i * 0.9) * t * 0.12))
		wave.append(Vector2(s, s))
		wave.append(Vector2(0, s))
		draw_colored_polygon(wave, Color("e8471a"))
		draw_rect(Rect2(0, s - t * 0.7, s, t * 0.7), Color("ff8a3d"))
		# Coins above, the hero sliding up with a trail.
		for p in [Vector2(3.5, 1.5), Vector2(3.5, 0.6)]:
			var c: Vector2 = p * t
			draw_circle(c, t * 0.26, COIN)
			draw_circle(c + Vector2(-t * 0.07, -t * 0.07), t * 0.1, COIN.lightened(0.6))
		var hero := Vector2(3.5, 4.6) * t
		var size := Vector2(t, t) * 1.15
		for i in 4:
			var k := 4 - i
			draw_rect(Rect2(hero + Vector2(0, k * t * 0.42) - size * 0.5 * (1.0 - k * 0.08), size * (1.0 - k * 0.08)), Color(1, 1, 1, 0.08 + i * 0.05))
		Skins.draw_hero(self, hero, size, Color("f4f1de"), Vector2(0, -t * 0.06))

	func _wall(r: Rect2) -> void:
		draw_rect(r, WALL)
		draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.15)), EDGE)
		draw_rect(r, WALL.darkened(0.25), false, 6.0)


func _initialize() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.add_child(Icon.new())
	root.add_child(viewport)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 5:
		return false
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png("res://icon.png")
	print("saved icon.png")
	return true
