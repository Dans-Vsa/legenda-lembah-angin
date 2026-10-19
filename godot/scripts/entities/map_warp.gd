@tool
class_name MapWarp
extends MapEntity
## Titik pindah peta. Hanya terlihat di editor.

@export_enum("town", "world", "cave") var target_map := "world":
	set(v):
		target_map = v
		queue_redraw()
## Petak tujuan di peta target.
@export var target_cell := Vector2i.ZERO
@export_enum("up", "down", "left", "right") var facing := "down"


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(0, 0, 32, 32), Color(0.2, 0.6, 1.0, 0.35))
	draw_rect(Rect2(0, 0, 32, 32), Color(0.4, 0.8, 1.0), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, -4), "→ " + target_map, HORIZONTAL_ALIGNMENT_CENTER, 92, 11, Color(0.6, 0.9, 1.0))


func to_warp() -> Dictionary:
	return {"map": target_map, "x": target_cell.x, "y": target_cell.y, "f": facing}
