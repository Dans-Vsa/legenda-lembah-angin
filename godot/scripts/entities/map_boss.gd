@tool
class_name MapBoss
extends MapEntity
## Wyrm Kabut. Menyentuhnya memulai pertarungan bos.


func to_entity() -> Dictionary:
	return _base("boss")
