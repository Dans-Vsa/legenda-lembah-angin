@tool
class_name MapCrystal
extends MapEntity
## Kristal biru: memulihkan HP/MP dan menyimpan permainan.


func to_entity() -> Dictionary:
	return _base("crystal")
