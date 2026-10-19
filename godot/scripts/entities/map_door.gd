@tool
class_name MapDoor
extends MapEntity
## Pintu bangunan. Hanya terlihat di editor; letakkan di atas tile pintu.

@export_enum("shop", "inn", "elder", "locked") var kind := "locked":
	set(v):
		kind = v
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(0, 0, 32, 32), Color(1.0, 0.6, 0.1, 0.3))
	draw_rect(Rect2(0, 0, 32, 32), Color(1.0, 0.7, 0.2), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 44), kind, HORIZONTAL_ALIGNMENT_CENTER, 92, 11, Color(1.0, 0.85, 0.5))
