extends StyleBox
## One segment of a pill-shaped button bar: the whole bar reads as a single
## capsule, and each button is a slice of it, split from its neighbour by an
## indented line. `round_left` / `round_right` give the end segments their
## rounded caps (a lone button gets both). The face has a lighter top half,
## a darker bottom half and a thick lip underneath. `glow` (0..1) draws a
## pulsing gold halo, used by the shop button when there are new items.

var color := Color("3a7bd5")
var pressed := false
var glow := 0.0
var round_left := true
var round_right := true
var divider := false             # draw the indent on the right edge

const LIP := 4.0


func _init(base := Color("3a7bd5"), is_pressed := false) -> void:
	color = base
	pressed = is_pressed
	content_margin_left = 8
	content_margin_right = 8
	content_margin_top = 2
	content_margin_bottom = LIP + 2


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	var face := Rect2(rect.position, rect.size - Vector2(0, LIP))
	if glow > 0.0:
		for i in 3:
			var grow := 3.0 + i * 3.0
			rs.canvas_item_add_polygon(to_canvas_item, _shape(face.grow(grow), 0.0, 1.0),
					PackedColorArray([Color(1.0, 0.82, 0.25, glow * (0.4 - i * 0.12))]))
	# Lip, then the two halves of the face; pressed segments sink into the lip.
	rs.canvas_item_add_polygon(to_canvas_item, _shape(Rect2(face.position + Vector2(0, LIP), face.size), 0.0, 1.0),
			PackedColorArray([color.darkened(0.55)]))
	if pressed:
		face.position.y += LIP - 1.0
	var tint := color.darkened(0.12) if pressed else color
	rs.canvas_item_add_polygon(to_canvas_item, _shape(face, 0.5, 1.0), PackedColorArray([tint.darkened(0.18)]))
	rs.canvas_item_add_polygon(to_canvas_item, _shape(face, 0.0, 0.5), PackedColorArray([tint.lightened(0.12)]))
	# A soft shine along the top.
	var pad_l := face.size.y * 0.35 if round_left else 2.0
	var pad_r := face.size.y * 0.35 if round_right else 2.0
	var shine := Rect2(face.position + Vector2(pad_l, face.size.y * 0.1), Vector2(face.size.x - pad_l - pad_r, face.size.y * 0.14))
	if shine.size.x > 0.0:
		rs.canvas_item_add_rect(to_canvas_item, shine, Color(1, 1, 1, 0.18))
	# The indent between this button and the next one.
	if divider:
		var x := rect.end.x
		var y0 := rect.position.y + 4.0
		var y1 := rect.end.y - 2.0
		rs.canvas_item_add_line(to_canvas_item, Vector2(x - 1.0, y0), Vector2(x - 1.0, y1), color.darkened(0.6), 2.0)
		rs.canvas_item_add_line(to_canvas_item, Vector2(x + 0.5, y0), Vector2(x + 0.5, y1), Color(color.lightened(0.35), 0.5), 1.0)


## The slice of the segment filling `r` between the fractions `top` and
## `bottom` of its height, as a polygon: rounded at whichever ends are caps.
func _shape(r: Rect2, top: float, bottom: float) -> PackedVector2Array:
	var rad := minf(r.size.y, r.size.x) * 0.5
	var y0 := r.position.y + r.size.y * top
	var y1 := r.position.y + r.size.y * bottom
	var cy := r.position.y + r.size.y * 0.5
	var lx := r.position.x + rad
	var rx := r.end.x - rad
	var points := PackedVector2Array()
	const STEPS := 10
	# Right edge, top to bottom, then the left edge, bottom to top.
	for i in STEPS + 1:
		var y := lerpf(y0, y1, float(i) / STEPS)
		points.append(Vector2(rx + sqrt(maxf(rad * rad - (y - cy) * (y - cy), 0.0)) if round_right else r.end.x, y))
	for i in STEPS + 1:
		var y := lerpf(y1, y0, float(i) / STEPS)
		points.append(Vector2(lx - sqrt(maxf(rad * rad - (y - cy) * (y - cy), 0.0)) if round_left else r.position.x, y))
	return points
