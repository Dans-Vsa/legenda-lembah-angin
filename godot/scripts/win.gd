@tool
class_name Win
extends PanelContainer
## Jendela biru bergaya RPG klasik dengan gradasi dan bingkai terang.

const TOP := Color("3a50b8")
const MID := Color("1f2b78")
const BOTTOM := Color("121a4c")


func _init() -> void:
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	resized.connect(queue_redraw)


static func make(parent: Node, x: float, y: float, w := -1.0, h := -1.0) -> Win:
	var win := Win.new()
	win.position = Vector2(x, y)
	win.custom_minimum_size = Vector2(maxf(w, 0.0), maxf(h, 0.0))
	parent.add_child(win)
	return win


func _draw() -> void:
	var w := size.x
	var h := size.y
	var mid := h * 0.55
	draw_rect(Rect2(Vector2(-3, -1), size + Vector2(6, 8)), Color(0, 0, 0, 0.35))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, mid), Vector2(0, mid)]), PackedColorArray([TOP, TOP, MID, MID]))
	draw_polygon(PackedVector2Array([Vector2(0, mid), Vector2(w, mid), Vector2(w, h), Vector2(0, h)]), PackedColorArray([MID, MID, BOTTOM, BOTTOM]))
	draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), Color("0b0f2e"), false, 2.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color("e6eaff"), false, 2.0)
