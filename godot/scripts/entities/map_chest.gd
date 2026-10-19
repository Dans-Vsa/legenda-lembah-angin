@tool
class_name MapChest
extends MapEntity
## Peti harta. ID harus unik agar status "sudah dibuka" tersimpan dengan benar.

const CLOSED := preload("res://assets/objects/chest.png")
const OPENED := preload("res://assets/objects/chest_open.png")

@export var chest_id := ""
@export var gold := 0
## Contoh: {"ramuan": 2, "eter": 1}
@export var items: Dictionary = {}
## Senjata/pelindung, contoh: pedangKristal
@export var equip := ""


func key() -> String:
	return chest_id if chest_id != "" else "%s_%d_%d" % [owner.name if owner else "peti", cell().x, cell().y]


func set_opened(o: bool) -> void:
	$Sprite.texture = OPENED if o else CLOSED


func to_entity() -> Dictionary:
	var e := _base("chest")
	e["id"] = key()
	if gold > 0:
		e["gold"] = gold
	var list := []
	for k in items:
		list.append([k, int(items[k])])
	e["items"] = list
	if equip != "":
		e["equip"] = equip
	return e
