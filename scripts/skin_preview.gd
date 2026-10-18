extends Control
## A live preview of one shop item, drawn the same way as in the game.

const Skins := preload("res://scripts/skins.gd")

var item: Dictionary
var kind := "hero"
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) * 0.7
	var c := size * 0.5
	if kind == "hero":
		Skins.draw_hero(self, c, Vector2(s, s), Skins.hero_color(item, _time * Skins.RAINBOW_IDLE_SPEED))
	else:
		Skins.draw_cracked(self, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), item, _time)
