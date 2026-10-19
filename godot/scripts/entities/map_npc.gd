@tool
class_name MapNpc
extends MapEntity
## NPC yang bisa diajak bicara. Ubah dialognya di Inspector (Lines).

@export_enum("elder", "woman", "kid", "guard", "ranger", "kael", "rina", "lyra") var sprite := "kid":
	set(v):
		sprite = v
		_apply()
@export var npc_name := "Warga"
@export var lines: PackedStringArray = []
## Dialog khusus dari kode (elder / ranger). Kosongkan untuk memakai Lines.
@export var talk := ""
## NPC berjalan-jalan di sekitar posisinya.
@export var wander := false


func _ready() -> void:
	super()
	_apply()


func _apply() -> void:
	if is_node_ready() and has_node("Sprite"):
		$Sprite.texture = load("res://assets/characters/%s.png" % sprite)


func set_flip(f: bool) -> void:
	$Sprite.flip_h = f


func to_entity() -> Dictionary:
	var e := _base("npc")
	e["spr"] = sprite
	e["name"] = npc_name
	e["lines"] = Array(lines) if lines.size() > 0 else ["..."]
	if talk != "":
		e["talk"] = talk
	if wander:
		e["wander"] = true
	return e
