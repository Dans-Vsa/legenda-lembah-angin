@tool
class_name PartyCard
extends HBoxContainer
## Kartu anggota party di menu lapangan (potret, level, HP, MP, EXP).

## Karakter yang ditampilkan di editor.
@export_enum("kael", "rina", "lyra") var preview_id := "kael":
	set(v):
		preview_id = v
		if Engine.is_editor_hint() and is_node_ready():
			_preview()


func _ready() -> void:
	if Engine.is_editor_hint():
		_preview()


func _preview() -> void:
	var names := {"kael": ["Kael", "Pendekar Pedang"], "rina": ["Rina", "Petarung Tangan Kosong"], "lyra": ["Lyra", "Penyihir Angin"]}
	$Portrait.texture = load("res://assets/characters/%s.png" % preview_id)
	$Info/Top/Name.text = names[preview_id][0]
	$Info/Title.text = names[preview_id][1]


func show_member(m: Member) -> void:
	var c: Dictionary = Data.CHARS[m.id]
	modulate.a = 0.6 if m.hp <= 0 else 1.0
	$Portrait.texture = load("res://assets/characters/%s.png" % m.id)
	$Info/Top/Name.text = c["name"]
	$Info/Top/Level.text = "Lv %d" % m.lvl
	$Info/Title.text = c["title"]
	var need := Data.xp_next(m.lvl)
	var maxed := m.lvl >= Data.MAX_LVL
	$Info/HPRow/Value.text = "%d / %d" % [m.hp, m.s["maxHp"]]
	$Info/HPBar.value = float(m.hp) / m.s["maxHp"]
	$Info/MPRow/Value.text = "%d / %d" % [m.mp, m.s["maxMp"]]
	$Info/MPBar.value = float(m.mp) / m.s["maxMp"]
	$Info/XPRow/Value.text = "MAX" if maxed else "%d / %d" % [m.xp, need]
	$Info/XPBar.value = 1.0 if maxed else float(m.xp) / need
