@tool
class_name PartyRow
extends HBoxContainer
## Satu baris status party di HUD battle (nama, HP, MP, ATB, BURST).

var _key := ""


func show_member(m: Member, active: bool) -> void:
	var key := "%d|%d|%s|%s" % [m.hp, m.mp, active, m.poison]
	if key != _key:
		_key = key
		$NameBox/Name.text = m.display_name()
		$NameBox/Name.modulate = Color("ffef7a") if active else (Color("ff7a7a") if m.hp <= 0 else Color.WHITE)
		$NameBox/Status.text = "Racun" if m.poison else ""
		$HPBox/HP.text = "%d / %d" % [m.hp, m.s["maxHp"]]
		$HPBox/HP.modulate = Color("ff6060") if m.hp <= 0 else (Color("ffe060") if m.hp < m.s["maxHp"] * 0.25 else Color.WHITE)
		$HPBox/HPBar.value = float(m.hp) / m.s["maxHp"]
		$MP.text = str(m.mp)
	var atb: Bar = $Gauges/ATB
	atb.value = m.atb / 100.0
	atb.color_a = Color.WHITE if m.atb >= 100 else Color("fff2a8")
	atb.color_b = Color("8fe0ff") if m.atb >= 100 else Color("e0a820")
	var burst: Bar = $Gauges/Burst
	burst.value = m.burst / 100.0
	burst.glow = m.burst >= 100
