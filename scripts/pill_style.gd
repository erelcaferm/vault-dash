extends StyleBox
## A capsule-shaped button face split into two halves by an indent across the
## middle, like a pill: a lighter top half, a darker bottom half and a thick
## lip underneath. `glow` (0..1) draws a pulsing gold halo, used by the shop
## button when there are new items to look at.

var color := Color("3a7bd5")
var pressed := false
var glow := 0.0

const LIP := 4.0


func _init(base := Color("3a7bd5"), is_pressed := false) -> void:
	color = base
	pressed = is_pressed
	content_margin_left = 10
	content_margin_right = 10
	content_margin_top = 2
	content_margin_bottom = LIP + 2


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	var face := Rect2(rect.position, rect.size - Vector2(0, LIP))
	if pressed:
		face.position.y += LIP - 1.0
	if glow > 0.0:
		for i in 3:
			var grow := 3.0 + i * 3.0
			rs.canvas_item_add_polygon(to_canvas_item, _capsule(face.grow(grow), 0.0, 1.0),
					PackedColorArray([Color(1.0, 0.82, 0.25, glow * (0.4 - i * 0.12))]))
	# Lip, then the two halves, then the indent between them.
	if not pressed:
		rs.canvas_item_add_polygon(to_canvas_item, _capsule(Rect2(face.position + Vector2(0, LIP), face.size), 0.0, 1.0),
				PackedColorArray([color.darkened(0.55)]))
	rs.canvas_item_add_polygon(to_canvas_item, _capsule(face, 0.5, 1.0), PackedColorArray([color.darkened(0.18)]))
	rs.canvas_item_add_polygon(to_canvas_item, _capsule(face, 0.0, 0.5), PackedColorArray([color.lightened(0.12)]))
	var mid := face.position.y + face.size.y * 0.5
	var inset := face.size.y * 0.5 - sqrt(maxf(face.size.y * 0.25 * face.size.y - 1.0, 0.0)) + 1.5
	var left := face.position.x + inset
	var right := face.end.x - inset
	rs.canvas_item_add_line(to_canvas_item, Vector2(left, mid - 0.5), Vector2(right, mid - 0.5), color.darkened(0.5), 2.0)
	rs.canvas_item_add_line(to_canvas_item, Vector2(left, mid + 1.5), Vector2(right, mid + 1.5), color.lightened(0.25) * Color(1, 1, 1, 0.5), 1.0)
	# A soft shine along the top half.
	var shine := Rect2(face.position + Vector2(face.size.y * 0.35, face.size.y * 0.1), Vector2(face.size.x - face.size.y * 0.7, face.size.y * 0.16))
	if shine.size.x > 0.0:
		rs.canvas_item_add_polygon(to_canvas_item, _capsule(shine, 0.0, 1.0), PackedColorArray([Color(1, 1, 1, 0.22)]))


## The slice of a capsule filling `r` between the fractions `top` and `bottom`
## of its height, as a polygon.
static func _capsule(r: Rect2, top: float, bottom: float) -> PackedVector2Array:
	var rad := minf(r.size.y, r.size.x) * 0.5
	var y0 := r.position.y + r.size.y * top
	var y1 := r.position.y + r.size.y * bottom
	var lc := Vector2(r.position.x + rad, r.position.y + r.size.y * 0.5)
	var rc := Vector2(r.end.x - rad, lc.y)
	var points := PackedVector2Array()
	const STEPS := 10
	# Right end, top to bottom, then the left end, bottom to top.
	for i in STEPS + 1:
		var y := lerpf(y0, y1, float(i) / STEPS)
		points.append(Vector2(rc.x + sqrt(maxf(rad * rad - (y - rc.y) * (y - rc.y), 0.0)), y))
	for i in STEPS + 1:
		var y := lerpf(y1, y0, float(i) / STEPS)
		points.append(Vector2(lc.x - sqrt(maxf(rad * rad - (y - lc.y) * (y - lc.y), 0.0)), y))
	return points
