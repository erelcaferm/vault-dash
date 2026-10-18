extends SceneTree
## Draws a contact sheet of shop items, for reviewing new cosmetics.
## Run: xvfb-run godot --path . --script res://tools/cosmetics_sheet.gd -- <out.png> [id,id,...]

const Skins := preload("res://scripts/skins.gd")

class Sheet extends Node2D:
	var ids: Array = []
	var t := 0.0
	var font: Font

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 2000, 2000), Color("1b1d2b"))
		var cols := 3
		var cell := Vector2(120, 126)
		var n := 0
		for kind in ["hero", "hat", "trail", "walls", "lava"]:
			for item in Skins.list(kind):
				if not ids.is_empty() and not ids.has(item.id):
					continue
				var o := Vector2((n % cols) * cell.x, floorf(n / cols) * cell.y)
				var c := o + Vector2(60, 58)
				var plain := Skins.find(Skins.HERO, "sky")
				match kind:
					"hero":
						Skins.draw_hero_item(self, item, c, Vector2(38, 38), Skins.hero_color(item, t * 0.25), Vector2(3, 0), t)
					"hat":
						Skins.draw_hero_item(self, plain, c + Vector2(0, 14), Vector2(38, 38), plain.color, Vector2.ZERO, t)
						Skins.draw_hat(self, item, c + Vector2(0, 14), Vector2(38, 38), t)
					"trail":
						Skins.draw_trail(self, item, c + Vector2(32, 0), Vector2.RIGHT, Vector2(30, 30), plain.color, t)
						Skins.draw_hero_item(self, plain, c + Vector2(32, 0), Vector2(30, 30), plain.color, Vector2(3, 0), t, Vector2.RIGHT)
					"walls":
						for k in 2:
							for j in 2:
								Skins.draw_cracked(self, Rect2(c + Vector2(-36 + j * 36, -36 + k * 36), Vector2(36, 36)), item, t, k == 0)
					"lava":
						Skins.draw_lava(self, item, o.x + 10, o.x + cell.x - 10, c.y - 10, c.y + 40, t)
				draw_string(font, o + Vector2(6, cell.y - 10), "%s  %d" % [item.name, item.price], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
				n += 1

var sheet: Sheet
var frames := 0
var out := "user://sheet.png"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	sheet = Sheet.new()
	sheet.font = ThemeDB.fallback_font
	if args.size() > 1:
		sheet.ids = Array(args[1].split(","))
	root.add_child(sheet)
	root.size = Vector2i(720, 1280)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 40:
		root.get_viewport().get_texture().get_image().save_png(out)
		quit()
	return false
