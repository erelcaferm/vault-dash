extends StyleBox
## One segment of a pill-shaped button bar: the whole bar reads as a single
## capsule, and each button is a slice of it, split from its neighbour by an
## indented line. `round_left` / `round_right` give the end segments their
## rounded caps (a lone button gets both). The fill is see-through, with a
## thin light rim. `glow` (0..1) draws a
## pulsing gold halo, used by the shop button when there are new items.

var color := Color("3a7bd5")
var pressed := false
var glow := 0.0
var round_left := true
var round_right := true
var divider := false             # draw the indent on the right edge


func _init(base := Color("3a7bd5"), is_pressed := false) -> void:
	color = base
	pressed = is_pressed
	content_margin_left = 8
	content_margin_right = 8
	content_margin_top = 2
	content_margin_bottom = 2


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	var face := rect
	if glow > 0.0:
		for i in 3:
			var grow := 3.0 + i * 3.0
			rs.canvas_item_add_polygon(to_canvas_item, _shape(face.grow(grow), 0.0, 1.0),
					PackedColorArray([Color(1.0, 0.82, 0.25, glow * (0.4 - i * 0.12))]))
	# A see-through fill (brighter while pressed) with a thin light rim.
	var fill := Color(color, minf(color.a + 0.2, 1.0)).lightened(0.15) if pressed else color
	var points := _shape(face, 0.0, 1.0)
	rs.canvas_item_add_polygon(to_canvas_item, points, PackedColorArray([fill]))
	# The rim runs along the top, bottom and rounded caps, not across the joins.
	var half := points.size() / 2
	var rim := PackedColorArray([Color(1, 1, 1, 0.22)])
	if round_right:
		rs.canvas_item_add_polyline(to_canvas_item, points.slice(0, half), rim, 1.5, true)
	if round_left:
		rs.canvas_item_add_polyline(to_canvas_item, points.slice(half), rim, 1.5, true)
	rs.canvas_item_add_line(to_canvas_item, points[points.size() - 1], points[0], rim[0], 1.5)
	rs.canvas_item_add_line(to_canvas_item, points[half - 1], points[half], rim[0], 1.5)
	# The indent between this button and the next one.
	if divider:
		var x := rect.end.x
		var y0 := rect.position.y + 7.0
		var y1 := rect.end.y - 7.0
		rs.canvas_item_add_line(to_canvas_item, Vector2(x - 1.0, y0), Vector2(x - 1.0, y1), Color(0, 0, 0, 0.35), 2.0)
		rs.canvas_item_add_line(to_canvas_item, Vector2(x + 0.5, y0), Vector2(x + 0.5, y1), Color(1, 1, 1, 0.18), 1.0)


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
