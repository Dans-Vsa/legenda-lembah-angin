@tool
class_name Bar
extends Control
## Bar kecil (HP, MP, EXP, ATB, BURST).

const COLORS := {
	"hp": ["9ff59f", "33ad33"],
	"mp": ["a6dcff", "2f84d8"],
	"xp": ["ffe38f", "d39318"],
	"atb": ["fff2a8", "e0a820"],
	"burst": ["ffb6d6", "df2f78"],
}

@export_enum("hp", "mp", "xp", "atb", "burst") var kind := "hp":
	set(v):
		kind = v
		color_a = Color(COLORS[v][0])
		color_b = Color(COLORS[v][1])
		queue_redraw()
@export_range(0.0, 1.0) var value := 1.0:
	set(v):
		if not is_equal_approx(v, value):
			value = v
			queue_redraw()
var color_a := Color("9ff59f")
var color_b := Color("33ad33")
var glow := false


static func make(parent: Node, p_kind: String, w := 120.0, h := 6.0) -> Bar:
	var b := Bar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.kind = p_kind
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
