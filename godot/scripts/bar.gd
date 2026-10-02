class_name Bar
extends Control
## Bar kecil (HP, MP, EXP, ATB, BURST).

var value := 0.0:
	set(v):
		if not is_equal_approx(v, value):
			value = v
			queue_redraw()
var color_a := Color.WHITE
var color_b := Color.GRAY
var glow := false


static func make(parent: Node, kind: String, w := 120.0, h := 6.0) -> Bar:
	var b := Bar.new()
	b.custom_minimum_size = Vector2(w, h)
	match kind:
		"hp": b.color_a = Color("9ff59f"); b.color_b = Color("33ad33")
		"mp": b.color_a = Color("a6dcff"); b.color_b = Color("2f84d8")
		"xp": b.color_a = Color("ffe38f"); b.color_b = Color("d39318")
		"atb": b.color_a = Color("fff2a8"); b.color_b = Color("e0a820")
		"burst": b.color_a = Color("ffb6d6"); b.color_b = Color("df2f78")
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


func _process(_dt: float) -> void:
	if glow:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0a0d26"))
	var w := (size.x - 2) * clampf(value, 0.0, 1.0)
	if w > 0:
		var a := color_a
		var b := color_b
		if glow:
			var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 60.0)
			a = a.lerp(Color.WHITE, k * 0.6)
			b = b.lerp(Color.WHITE, k * 0.4)
		var hh := size.y - 2
		draw_polygon(PackedVector2Array([Vector2(1, 1), Vector2(1 + w, 1), Vector2(1 + w, 1 + hh), Vector2(1, 1 + hh)]), PackedColorArray([a, a, b, b]))
	draw_rect(Rect2(Vector2.ZERO, size), Color("9aa2d8"), false, 1.0)
