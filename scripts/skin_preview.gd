extends Control
## A live preview of one shop item, drawn the same way as in the game.

const Skins := preload("res://scripts/skins.gd")

var item: Dictionary
var kind := "hero"
## The hero to show sliding in a trail preview.
var hero: Dictionary = {}
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) * 0.7
	var c := size * 0.5
	if kind == "hero":
		Skins.draw_hero(self, c, Vector2(s, s) * 0.85, Skins.hero_color(item, _time * Skins.RAINBOW_IDLE_SPEED),
				Vector2.ZERO, 1.0, Skins.hero_glow(item))
	elif kind == "trail":
		var hs := Vector2(s, s) * 0.5
		var p := c + Vector2(s * 0.35, 0)
		var color := Skins.hero_color(hero, _time * Skins.RAINBOW_SLIDE_SPEED) if not hero.is_empty() else Color.WHITE
		Skins.draw_trail(self, item, p, Vector2.RIGHT, hs, color, _time)
		Skins.draw_hero(self, p, hs, color, Vector2(2, 0))
	elif kind == "hat":
		var hs := Vector2(s, s) * 0.55
		var p := c + Vector2(0, s * 0.18)
		var color := Skins.hero_color(hero, _time * Skins.RAINBOW_IDLE_SPEED) if not hero.is_empty() else Color.WHITE
		Skins.draw_hero(self, p, hs, color)
		Skins.draw_hat(self, item, p, hs, _time)
	elif kind == "lava":
		var r := Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
		draw_rect(r, Color(0.1, 0.1, 0.16))
		Skins.draw_lava(self, item, r.position.x, r.end.x, r.position.y + s * 0.45, r.end.y, _time)
	elif kind == "coins":
		for i in 3:
			var o := Vector2((i - 1) * s * 0.22, (1 - i) * s * 0.12)
			draw_circle(c + o, s * 0.24, Color("c99700"))
			draw_circle(c + o - Vector2(0, s * 0.04), s * 0.24, Color("ffd23f"))
	else:
		Skins.draw_cracked(self, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), item, _time)
