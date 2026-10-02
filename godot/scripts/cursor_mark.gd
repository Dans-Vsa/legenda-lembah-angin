class_name CursorMark
extends Control
## Panah kursor putih yang bergoyang pelan.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	if modulate.a > 0.0:
		queue_redraw()


func _draw() -> void:
	var dx := sin(Time.get_ticks_msec() / 75.0) * 2.0
	var pts := PackedVector2Array([Vector2(1 + dx, 1), Vector2(13 + dx, 8), Vector2(1 + dx, 15)])
	draw_colored_polygon(PackedVector2Array([Vector2(2 + dx, 2), Vector2(14 + dx, 9), Vector2(2 + dx, 16)]), Color.BLACK)
	draw_colored_polygon(pts, Color.WHITE)
