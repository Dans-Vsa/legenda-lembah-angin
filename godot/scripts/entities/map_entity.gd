@tool
class_name MapEntity
extends Node2D
## Dasar semua objek peta (NPC, peti, papan, dll).
## Posisi otomatis menempel ke grid 32 piksel saat digeser di editor.

const TILE := 32

# Status saat game berjalan
var grid := Vector2i.ZERO
var home := Vector2i.ZERO
var wt := 0.0
var li := -1


func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		var snapped_pos := Vector2(cell() * TILE)
		if snapped_pos != position:
			position = snapped_pos


func cell() -> Vector2i:
	return Vector2i(roundi(position.x / TILE), roundi(position.y / TILE))


func to_entity() -> Dictionary:
	return {}


func _base(type: String) -> Dictionary:
	var c := cell()
	return {"type": type, "x": c.x, "y": c.y}
