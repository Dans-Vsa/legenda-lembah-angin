@tool
class_name MapSign
extends MapEntity
## Papan petunjuk.

@export var lines: PackedStringArray = []


func to_entity() -> Dictionary:
	var e := _base("sign")
	e["lines"] = Array(lines) if lines.size() > 0 else ["..."]
	return e
