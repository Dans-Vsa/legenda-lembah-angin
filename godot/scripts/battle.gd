class_name Battle
extends Node2D
## Battle dengan sistem ATB (Active Time Battle) mode Wait (scene battle.tscn).
## ATB berhenti saat menu terbuka atau animasi aksi berjalan.
## Posisi musuh diambil dari EnemySlots, sprite party dari node Party,
## dan semua jendela dari node HUD, jadi tata letaknya bisa diubah di editor.

signal finished(result: String)

const BATTLER_SCENE := "res://scenes/battle/battler.tscn"
const CMD_HELP := {
	"attack": "Serangan biasa dengan senjata ke satu musuh.",
	"item": "Gunakan item dari tas.",
	"defend": "Bertahan: damage yang diterima berkurang setengah sampai giliran berikutnya.",
	"flee": "Mencoba kabur dari pertarungan.",
}


class KeyHandler:
	var fn: Callable
	func _init(f: Callable) -> void:
		fn = f
	func on_key(a: String) -> void:
		fn.call(a)


var state := "off"
var boss := false
var party: Array = []
var enemies: Array = []
var ready_q: Array = []
var actor: Member = null
var cursor: Array = []
var click_handler := Callable()
var t := 0.0

# Efek visual
var parts: Array = []
var lines: Array = []
var bolts: Array = []
var rings: Array = []
var pops: Array = []
var fx_flash := 0.0
var fx_flash_color := Color.WHITE
var fx_shake := 0.0

var _font: Font
var _party_base := {}

@onready var _bg: BattleBg = $Background
@onready var _enemy_layer: Node2D = $Enemies
@onready var _party_layer: Node2D = $Party
@onready var _fx: Node2D = $FX
@onready var _hud: Control = $HUD
@onready var _help_win: Win = $HUD/HelpWin
@onready var _help: Label = $HUD/HelpWin/Help
@onready var _enemy_label: Label = $HUD/EnemyWin/EnemyList
@onready var _cmd: ListMenu = $HUD/CmdWin/CmdList
@onready var _sub_win: Win = $HUD/SubWin
@onready var _sub: ListMenu = $HUD/SubWin/SubList
@onready var _victory_win: Win = $HUD/VictoryWin
@onready var _rows := {
	"kael": $HUD/PartyWin/Rows/Kael, "rina": $HUD/PartyWin/Rows/Rina, "lyra": $HUD/PartyWin/Rows/Lyra,
}


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_fx.draw.connect(_draw_fx)
	for n in _party_layer.get_children():
		_party_base[n.name.to_lower()] = n.position
	_clear_enemies()
	_hide_windows()
	visible = false


func _clear_enemies() -> void:
	for c in _enemy_layer.get_children():
		_enemy_layer.remove_child(c)
		c.queue_free()


func _hide_windows() -> void:
	_help_win.visible = false
	_sub_win.visible = false
	_victory_win.visible = false


# Posisi musuh dari marker di EnemySlots/<Satu|Dua|Tiga|Bos>.
func _slots(count: int) -> Array:
	var group: String = "Bos" if boss else ["Satu", "Dua", "Tiga"][clampi(count, 1, 3) - 1]
	var out := []
	for mk in get_node("EnemySlots/" + group).get_children():
		out.append(mk.position)
	return out


# ---------- Mulai ----------
func start(group: Array, p_bg: String, opts := {}) -> void:
	boss = opts.get("boss", false)
	_bg.bg_type = p_bg
	t = 0.0
	party = Game.party
	ready_q = []
	actor = null
	cursor = []
	click_handler = Callable()
	for m in party:
		m.atb = randf_range(0, 45) if m.hp > 0 else 0.0
		m.defending = false
		m.poison = false
		m.ox = 0.0; m.oy = 0.0; m.alpha = 1.0; m.flash = 0.0; m.shake = 0.0
		m.node = _party_layer.get_node(m.display_name())
		m.bx = _party_base[m.id].x
		m.by = _party_base[m.id].y
	var slots := _slots(group.size())
	_clear_enemies()
	enemies = []
	var count := {}
	for id in group:
		count[id] = count.get(id, 0) + 1
	var seen := {}
	for i in group.size():
		var tp: Dictionary = Data.ENEMIES[group[i]]
		var e := Foe.new()
		e.is_enemy = true
		e.tpl = tp
		e.name = tp["name"]
		if count[group[i]] > 1:
			var k: int = seen.get(group[i], 0)
			seen[group[i]] = k + 1
			e.name += " " + String.chr(65 + k)
		e.hp = tp["hp"]; e.max_hp = tp["hp"]; e.atk = tp["atk"]; e.def = tp["def"]; e.mag = tp["mag"]; e.spd = tp["spd"]
		e.atb = randf_range(0, 40)
		e.x = slots[i].x; e.y = slots[i].y
		var node: BattlerNode = load(BATTLER_SCENE).instantiate()
		node.name = e.name.replace(" ", "")
		_enemy_layer.add_child(node)
		node.texture = load("res://assets/characters/%s.png" % tp["sprite"])
		node.sprite_scale = tp["scale"]
		node.position = slots[i]
		e.node = node
		var sz := node.size()
		e.w = sz.x
		e.h = sz.y
		e.phase = randf_range(0, 6)
		enemies.append(e)
	parts = []; lines = []; bolts = []; rings = []; pops = []
	fx_flash = 0.0; fx_shake = 0.0
	_hide_windows()
	close_command()
	_hud.visible = true
	_update_ui()
	Snd.play(opts.get("music", "battle"))
	visible = true
	state = "intro"
	var names := []
	for e in enemies:
		if not names.has(e.tpl["name"]):
			names.append(e.tpl["name"])
	help(("%s menghadang!" if boss else "%s muncul!") % ", ".join(names))
	await wait(1.0)
	if state == "intro":
		help("")
		state = "run"


# ---------- Utilitas ----------
func wait(sec: float) -> Signal:
	return get_tree().create_timer(sec).timeout


func tw(obj: Object, props: Dictionary, sec: float, ease_in := false) -> Tween:
	var tween := create_tween().set_parallel(true)
	for k in props:
		tween.tween_property(obj, k, float(props[k]), sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN if ease_in else Tween.EASE_OUT)
	return tween


func pos(b: Battler) -> Vector2:
	if b.is_enemy:
		var e: Foe = b
		return Vector2(e.x + e.ox, e.y + e.oy)
	var m: Member = b
	return Vector2(m.bx + m.ox, m.by + m.oy)


func alive_enemies() -> Array:
	return enemies.filter(func(e): return not e.dead)


func random_enemy() -> Foe:
	var a := alive_enemies()
	return a.pick_random() if a.size() > 0 else null


func alive_party() -> Array:
	return party.filter(func(m): return m.hp > 0)


# ---------- UI ----------
func help(text: String, enemy := false) -> void:
	if not is_node_ready():
		return
	_help_win.visible = text != ""
	_help.text = text
	_help.modulate = Color("ffb0b0") if enemy else Color.WHITE


func _update_ui() -> void:
	var names := {}
	var order := []
	for e in enemies:
		if not e.dead:
			if not names.has(e.tpl["name"]):
				order.append(e.tpl["name"])
			names[e.tpl["name"]] = names.get(e.tpl["name"], 0) + 1
	var txt := ""
	for n in order:
		txt += n + (" x%d" % names[n] if names[n] > 1 else "") + "\n"
	_enemy_label.text = txt
	for m in party:
		_rows[m.id].show_member(m, actor == m)


func teardown() -> void:
	close_command()
	_hide_windows()
	_clear_enemies()
	state = "off"
	cursor = []
	actor = null
	visible = false
	for m in Game.party:
		m.poison = false
		m.defending = false


# ---------- Loop ----------
func _process(dt: float) -> void:
	if not visible:
		return
	t += dt
	_update_fx(dt)
	for b in party + enemies:
		b.flash = maxf(0.0, b.flash - dt * 4.0)
		b.shake = maxf(0.0, b.shake - dt)
	_sync_nodes()
	_update_ui()
	_fx.queue_redraw()
	if state != "run":
		return
	for m in party:
		if m.hp <= 0 or m.atb >= 100:
			continue
		m.atb = minf(100.0, m.atb + (m.s["spd"] + 25) * 0.9 * dt)
		if m.atb >= 100:
			ready_q.append(m)
			Snd.sfx("ready")
	for e in enemies:
		if not e.dead and e.atb < 100:
			e.atb = minf(100.0, e.atb + (e.spd + 25) * 0.9 * dt)
	for e in enemies:
		if not e.dead and e.atb >= 100:
			enemy_turn(e)
			return
	ready_q = ready_q.filter(func(m): return m.hp > 0 and m.atb >= 100)
	if ready_q.size() > 0:
		open_command(ready_q[0])


# Menyalin status animasi (ox, oy, flash, dll) ke node sprite.
func _sync_nodes() -> void:
	var sh := (randf() - 0.5) * fx_shake if fx_shake > 0 else 0.0
	var off := Vector2(sh, sh * 0.5)
	_enemy_layer.position = off
	_party_layer.position = off
	_fx.position = off
	for e in enemies:
		var n: BattlerNode = e.node
		var shk := sin(t * 90.0) * 6.0 if e.shake > 0 else 0.0
		n.position = Vector2(e.x + e.ox + shk, e.y + e.oy + sin(t * 2.2 + e.phase) * 3.0)
		n.modulate.a = e.alpha
		n.visible = e.alpha > 0.01
		n.set_flash(e.flash)
	for m in party:
		var n: BattlerNode = m.node
		var shk := sin(t * 90.0) * 5.0 if m.shake > 0 else 0.0
		n.position = Vector2(m.bx + m.ox + shk, m.by + m.oy)
		var ko: bool = m.hp <= 0
		n.sprite.rotation = -PI / 2.0 if ko else 0.0
		var low := 4.0 if m.hp < m.s["maxHp"] * 0.25 else 0.0
		n.sprite.position = Vector2(0, 24) if ko else Vector2(0, low + sin(t * 3.0 + m.bx) * 1.2)
		n.sprite.modulate = Color(0.75, 0.75, 0.8, 0.65) if ko else Color.WHITE
		n.set_flash(0.0 if ko else m.flash)
		n.defending = m.defending and not ko
		n.poison = m.poison and not ko
		n.anim_t = t
		n.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not click_handler.is_valid():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_handler.call(event.position)


# ---------- Perintah pemain ----------
func open_command(m: Member) -> void:
	state = "menu"
	actor = m
	m.defending = false
	tw(m, {"ox": -26}, 0.14)
	_show_commands(m)


func _show_commands(m: Member) -> void:
	var c: Dictionary = Data.CHARS[m.id]
	var items := []
	if m.burst >= 100:
		items.append({"label": Data.BURSTS[m.id]["name"], "value": "burst", "color": Color("ff9ccc"), "help": Data.BURSTS[m.id]["desc"]})
	items.append({"label": "Serang", "value": "attack", "help": CMD_HELP["attack"]})
	items.append({"label": c["skillLabel"], "value": "skill", "disabled": Data.skills_of(m).is_empty(), "help": "Gunakan %s (memakai MP)." % c["skillLabel"].to_lower()})
	items.append({"label": "Item", "value": "item", "disabled": Game.items.is_empty(), "help": CMD_HELP["item"]})
	items.append({"label": "Bertahan", "value": "defend", "help": CMD_HELP["defend"]})
	items.append({"label": "Kabur", "value": "flee", "disabled": boss, "help": "Tidak bisa kabur dari pertarungan ini!" if boss else CMD_HELP["flee"]})
	_cmd.setup(items, {
		"on_select": func(it, _i): _on_command(m, it["value"]),
		"on_move": func(it, _i): help("%s: %s" % [m.display_name(), it["help"]]),
	})


func close_command() -> void:
	_cmd.deactivate()
	_cmd.set_items([])


func _on_command(m: Member, v: String) -> void:
	_cmd.deactivate()
	var act := {}
	var targets = null
	match v:
		"attack":
			targets = await select_targets("enemy", m)
			act = {"type": "attack"}
		"burst":
			targets = await select_targets(Data.BURSTS[m.id]["target"], m)
			act = {"type": "burst"}
		"defend":
			targets = []
			act = {"type": "defend"}
		"flee":
			targets = []
			act = {"type": "flee"}
		"skill":
			var items := []
			for id in Data.skills_of(m):
				var sk: Dictionary = Data.SKILLS[id]
				items.append({"label": sk["name"], "right": sk["mp"], "value": id, "disabled": m.mp < sk["mp"], "help": sk["desc"]})
			var r = await _choose_from_list(m, items, func(id): return Data.SKILLS[id]["target"], "last_skill")
			if r != null:
				act = {"type": "skill", "id": r["id"]}
				targets = r["targets"]
		"item":
			var items2 := []
			for id in Game.items:
				items2.append({"label": Data.ITEMS[id]["name"], "right": "x%d" % Game.items[id], "value": id, "help": Data.ITEMS[id]["desc"]})
			var r2 = await _choose_from_list(m, items2, func(id): return "deadAlly" if Data.ITEMS[id]["effect"].has("revive") else "ally", "last_item")
			if r2 != null:
				act = {"type": "item", "id": r2["id"]}
				targets = r2["targets"]
	if targets == null:
		_cmd.activate()
		return
	close_command()
	await perform(m, act, targets)


# Daftar skill/item lalu pilih target. Batal saat memilih target kembali ke daftar.
func _choose_from_list(m: Member, items: Array, target_of: Callable, mem: String):
	while true:
		var w := Waiter.new()
		_sub_win.visible = true
		_sub.setup(items, {
			"cols": 2, "start": m.get(mem), "item_width": 186,
			"on_move": func(it, _i): help(it["help"]),
			"on_select": func(it, i): w.done.emit([it["value"], i]),
			"on_cancel": func(): w.done.emit(null),
		})
		var res = await w.done
		_sub.deactivate()
		_sub_win.visible = false
		if res == null:
			help("")
			return null
		m.set(mem, res[1])
		var targets = await select_targets(target_of.call(res[0]), m)
		if targets != null:
			return {"id": res[0], "targets": targets}
	return null


func select_targets(kind: String, a: Member):
	var cands: Array = []
	var multi := false
	match kind:
		"enemy": cands = alive_enemies()
		"enemies", "randomEnemies":
			cands = alive_enemies()
			multi = true
		"ally": cands = alive_party()
		"allies":
			cands = alive_party()
			multi = true
		"allAllies":
			cands = party.duplicate()
			multi = true
		"deadAlly": cands = party.filter(func(p): return p.hp <= 0)
		"self": cands = [a]
	if cands.is_empty():
		Snd.sfx("buzz")
		help("Tidak ada target yang bisa dipilih.")
		return null
	var st := {"idx": 0}
	if kind == "ally":
		var best = cands[0]
		for c in cands:
			if float(c.hp) / c.s["maxHp"] < float(best.hp) / best.s["maxHp"]:
				best = c
		st["idx"] = cands.find(best)
	var label := func() -> String:
		if multi:
			return "Semua musuh" if cands[0].is_enemy else "Semua kawan"
		return cands[st["idx"]].display_name()
	var w := Waiter.new()
	var on_key := func(k: String) -> void:
		if k == "ok":
			w.done.emit(cands if multi else [cands[st["idx"]]])
		elif k == "cancel":
			w.done.emit(null)
		elif not multi and cands.size() > 1 and k in ["up", "down", "left", "right"]:
			st["idx"] = (st["idx"] + (-1 if k in ["up", "left"] else 1) + cands.size()) % cands.size()
			Snd.sfx("cursor")
			cursor = [cands[st["idx"]]]
			help(label.call())
	var handler := KeyHandler.new(on_key)
	cursor = cands if multi else [cands[st["idx"]]]
	help(label.call())
	click_handler = func(p: Vector2) -> void:
		for b in cands:
			var c := pos(b)
			var hw: float = b.w / 2.0 if b.is_enemy else 32.0
			var hh: float = b.h / 2.0 if b.is_enemy else 36.0
			if absf(p.x - c.x) < hw and absf(p.y - c.y) < hh:
				w.done.emit(cands if multi else [b])
				return
	Game.push_input(handler)
	var r = await w.done
	Game.pop_input(handler)
	cursor = []
	click_handler = Callable()
	Snd.sfx("ok" if r != null else "cancel")
	return r


# ---------- Eksekusi aksi ----------
func perform(m: Member, act: Dictionary, targets: Array) -> void:
	state = "anim"
	match act["type"]:
		"attack":
			help("")
			await phys_attack(m, targets[0], {"power": 1.0, "fx": "slash"})
		"skill":
			var sk: Dictionary = Data.SKILLS[act["id"]]
			m.mp -= sk["mp"]
			help(sk["name"])
			await use_skill(m, sk, targets)
		"burst":
			var sk2: Dictionary = Data.BURSTS[m.id]
			m.burst = 0.0
			help("%s: %s!" % [m.display_name(), sk2["name"]])
			fx_flash = 0.8
			fx_flash_color = Color("ffd0e8")
			Snd.sfx("burst")
			await wait(0.3)
			await use_skill(m, sk2, targets)
		"item":
			Data.remove_item(act["id"])
			help(Data.ITEMS[act["id"]]["name"])
			await use_item(m, act["id"], targets[0])
		"defend":
			m.defending = true
			help("%s bertahan" % m.display_name())
			Snd.sfx("defend")
			ring(pos(m), 50, Color("9fd8ff"))
			await wait(0.45)
		"flee":
			if await try_flee():
				return
	help("")
	await tw(m, {"ox": 0, "oy": 0}, 0.14).finished
	m.atb = 0.0
	ready_q.erase(m)
	actor = null
	if m.poison and m.hp > 0:
		var d := maxi(1, floori(m.s["maxHp"] * 0.06))
		m.hp = maxi(1, m.hp - d)
		pop(pos(m) + Vector2(0, -10), str(d), Color("d48cff"))
		Snd.sfx("spore")
		await wait(0.35)
	if not check_end():
		state = "run"


func phys_attack(m: Member, target: Foe, o: Dictionary) -> void:
	var tg := target
	if tg == null or tg.dead:
		tg = random_enemy()
	if tg == null:
		return
	await tw(m, {"ox": tg.x + tg.w / 2.0 + 30 - m.bx, "oy": (tg.y - m.by) * 0.5}, 0.22).finished
	var hits: int = o.get("hits", 1)
	for i in hits:
		var tt: Foe = random_enemy() if tg.dead else tg
		if tt == null:
			break
		await fx(o.get("fx", "slash"), [tt], m)
		hit_enemy(tt, Data.phys_damage(m.s["atk"], tt.def, o["power"]), o.get("elem", ""), true)
		if hits > 1:
			await wait(0.11)
	await wait(0.22)
	await tw(m, {"ox": -26, "oy": 0}, 0.22).finished


func use_skill(m: Member, sk: Dictionary, targets: Array) -> void:
	match sk["kind"]:
		"phys":
			if sk["target"] == "enemy":
				await phys_attack(m, targets[0], sk)
				return
			if sk["target"] == "randomEnemies":
				await tw(m, {"ox": -300, "oy": 0}, 0.24).finished
				for i in int(sk["hits"]):
					var tg := random_enemy()
					if tg == null:
						break
					await fx(sk["fx"], [tg], m)
					hit_enemy(tg, Data.phys_damage(m.s["atk"], tg.def, sk["power"]), sk.get("elem", ""), true)
					await wait(0.12)
				await wait(0.2)
				return
			await tw(m, {"ox": -140}, 0.2).finished
			var live := targets.filter(func(e): return not e.dead)
			await fx(sk["fx"], live, m)
			for e in live:
				hit_enemy(e, Data.phys_damage(m.s["atk"], e.def, sk["power"]), sk.get("elem", ""), true)
			await wait(0.35)
		"mag":
			await cast_anim(m)
			var live := targets.filter(func(e): return not e.dead)
			if live.is_empty():
				var r := random_enemy()
				if r:
					live.append(r)
			await fx(sk["fx"], live, m)
			for e in live:
				hit_enemy(e, Data.mag_damage(m.s["matk"], e.def, sk["power"]), sk.get("elem", ""), false)
			await wait(0.35)
		"heal":
			await cast_anim(m)
			var live := targets.filter(func(p): return p.hp > 0)
			await fx("heal", live, m)
			var amt := Data.heal_power(m, sk)
			for p in live:
				heal_target(p, amt)
			await wait(0.35)
		"revive":
			await cast_anim(m)
			var dead := targets.filter(func(p): return p.hp <= 0)
			await fx("revive", dead, m)
			for p in dead:
				revive_target(p, sk["power"])
			await wait(0.35)
		"fullheal":
			await cast_anim(m)
			await fx("holy", party, m)
			for p in party:
				if p.hp <= 0:
					revive_target(p, 1.0)
				else:
					heal_target(p, p.s["maxHp"] - p.hp)
				p.poison = false
			await wait(0.4)


func use_item(m: Member, id: String, tg: Member) -> void:
	await tw(m, {"oy": -12}, 0.12).finished
	await tw(m, {"oy": 0}, 0.12, true).finished
	var ef: Dictionary = Data.ITEMS[id]["effect"]
	await fx("revive" if ef.has("revive") else "heal", [tg], m)
	var r := Data.apply_item(id, tg)
	var p := pos(tg)
	if r.get("revived", false):
		pop(p + Vector2(0, -40), "Bangkit!", Color("ffe080"), 18)
		tg.atb = 0.0
	if r.get("hp", 0) > 0:
		pop(p + Vector2(0, -10), str(r["hp"]), Color("7dff8a"))
	if r.get("mp", 0) > 0:
		pop(p + Vector2(0, -10), "%d MP" % r["mp"], Color("8ccaff"))
	if r.get("cured", false):
		pop(p + Vector2(0, -40), "Sembuh", Color("e0c0ff"), 18)
	if r.is_empty() or (not r.get("revived", false) and r.get("hp", 0) == 0 and r.get("mp", 0) == 0 and not r.get("cured", false)):
		pop(p + Vector2(0, -10), "Tidak berefek", Color("c0c0c0"), 16)
	await wait(0.4)


func cast_anim(m: Member) -> void:
	Snd.sfx("cast")
	var p := pos(m)
	await tw(m, {"oy": -10}, 0.15).finished
	for i in 16:
		spawn(p + Vector2(randf_range(-30, 30), randf_range(-30, 30)), {"vx": 0, "vy": randf_range(-90, -30), "life": 0.5, "color": [Color.WHITE, Color("cfe8ff"), Color("ffe9a0")].pick_random(), "size": 3, "shape": "star"})
	m.flash = 0.6
	await wait(0.28)
	await tw(m, {"oy": 0}, 0.12).finished


func hit_enemy(e: Foe, base: float, elem: String, phys: bool) -> void:
	if e.dead:
		return
	var dmg := base * randf_range(0.9, 1.1)
	var tag := ""
	var tag_col := Color.WHITE
	if elem != "" and e.tpl.get("weak", []).has(elem):
		dmg *= 2.0
		tag = "LEMAH!"
		tag_col = Color("ffe040")
	elif elem != "" and e.tpl.get("resist", []).has(elem):
		dmg *= 0.5
		tag = "TAHAN"
		tag_col = Color("a8a8c8")
	if phys and randf() < 0.08:
		dmg *= 1.8
		tag = "KRITIS!"
		tag_col = Color("ff9040")
	var d := maxi(1, roundi(dmg))
	e.hp = maxi(0, e.hp - d)
	e.flash = 1.0
	e.shake = 0.25
	var p := pos(e)
	pop(p + Vector2(0, -10), str(d), Color.WHITE)
	if tag != "":
		pop(p + Vector2(0, -e.h / 2.0 - 6), tag, tag_col, 17)
	Snd.sfx("crit" if tag == "KRITIS!" else "hit")
	if e.hp <= 0:
		kill_enemy(e)


func kill_enemy(e: Foe) -> void:
	e.dead = true
	e.atb = 0.0
	Snd.sfx("enemyDie")
	var big: bool = e.tpl.get("boss", false)
	burst_parts(pos(e), 90 if big else 30, [Color.WHITE, Color("e0d0ff"), Color("a080ff")], {"max": 320.0 if big else 140.0, "lmax": 0.9, "smax": 6.0})
	tw(e, {"alpha": 0}, 1.6 if big else 0.6)


func hit_party(m: Member, base: float, act := {}) -> int:
	if m.hp <= 0:
		return 0
	var dmg := base * randf_range(0.9, 1.1)
	if m.defending:
		dmg *= 0.5
	var d := maxi(1, roundi(dmg))
	m.hp = maxi(0, m.hp - d)
	m.flash = 1.0
	m.shake = 0.25
	m.burst = minf(100.0, m.burst + float(d) / m.s["maxHp"] * 140.0)
	var p := pos(m)
	pop(p + Vector2(0, -10), str(d), Color.WHITE)
	Snd.sfx("hurt")
	if m.hp <= 0:
		m.atb = 0.0
		m.poison = false
		m.defending = false
		pop(p + Vector2(0, -44), "KO", Color("ff6a6a"), 18)
		ready_q.erase(m)
	elif act.has("poison") and not m.poison and randf() < act["poison"]:
		m.poison = true
		pop(p + Vector2(0, -44), "Racun!", Color("d48cff"), 17)
	return d


func heal_target(m: Member, amt: int) -> void:
	if m.hp <= 0:
		return
	var b := m.hp
	m.hp = mini(m.s["maxHp"], m.hp + amt)
	pop(pos(m) + Vector2(0, -10), str(m.hp - b), Color("7dff8a"))


func revive_target(m: Member, ratio: float) -> void:
	if m.hp > 0:
		return
	m.hp = maxi(1, floori(m.s["maxHp"] * ratio))
	m.atb = 0.0
	pop(pos(m) + Vector2(0, -10), str(m.hp), Color("7dff8a"))
	pop(pos(m) + Vector2(0, -44), "Bangkit!", Color("ffe080"), 17)


# ---------- Giliran musuh ----------
func enemy_turn(e: Foe) -> void:
	state = "anim"
	var acts: Array = e.tpl["actions"]
	var total := 0.0
	for a in acts:
		total += a["w"]
	var roll := randf() * total
	var act: Dictionary = acts[0]
	for a in acts:
		roll -= a["w"]
		if roll <= 0:
			act = a
			break
	var alive := alive_party()
	var targets: Array = alive if act.get("target", "") == "all" else [alive.pick_random()]
	help("%s: %s" % [e.name, act["name"]], true)
	if act["kind"] == "phys" and act.get("target", "") != "all":
		var tg: Member = targets[0]
		await tw(e, {"ox": 60}, 0.15).finished
		await fx(act.get("fx", "claw"), targets, e)
		var d := hit_party(tg, Data.phys_damage(e.atk, tg.s["def"], act["power"]), act)
		if act.get("drain", false) and d > 0:
			var hl := floori(d * 0.5)
			e.hp = mini(e.max_hp, e.hp + hl)
			pop(pos(e) + Vector2(0, -10), str(hl), Color("7dff8a"))
		await tw(e, {"ox": 0}, 0.2).finished
	else:
		await enemy_cast(e)
		await fx(act.get("fx", "magic"), targets, e)
		for tg in targets:
			var dmg := Data.phys_damage(e.atk, tg.s["def"], act["power"]) if act["kind"] == "phys" else Data.mag_damage(e.mag, tg.s["def"], act["power"])
			hit_party(tg, dmg, act)
	await wait(0.45)
	help("")
	e.atb = 0.0
	if not check_end():
		state = "run"


func enemy_cast(e: Foe) -> void:
	Snd.sfx("cast")
	var p := pos(e)
	for i in 20:
		spawn(p + Vector2(randf_range(-40, 40), randf_range(-40, 40)), {"vx": 0, "vy": randf_range(-80, -20), "life": 0.5, "color": [Color("ffb0b0"), Color("ff6060"), Color.WHITE].pick_random(), "size": 3, "shape": "star"})
	e.flash = 0.7
	await wait(0.35)


func try_flee() -> bool:
	help("Mencoba kabur...")
	await wait(0.4)
	if randf() < 0.65:
		Snd.sfx("flee")
		help("Berhasil kabur!")
		for m in party:
			if m.hp > 0:
				tw(m, {"ox": 320}, 0.5)
		await wait(0.65)
		state = "end"
		finished.emit("flee")
		return true
	Snd.sfx("buzz")
	help("Gagal kabur!")
	await wait(0.65)
	return false


func check_end() -> bool:
	if enemies.all(func(e): return e.dead):
		victory()
		return true
	if party.all(func(m): return m.hp <= 0):
		defeat()
		return true
	return false


func victory() -> void:
	state = "end"
	close_command()
	help("")
	actor = null
	await wait(1.8 if boss else 0.8)
	Snd.play("victory")
	var xp := 0
	var gold := 0
	var drops := []
	for e in enemies:
		xp += e.tpl["xp"]
		gold += e.tpl["gold"]
		if e.tpl.has("drop") and randf() < e.tpl["drop"][1]:
			drops.append(e.tpl["drop"][0])
	Game.gold += gold
	for d in drops:
		Data.add_item(d)
	var msgs := []
	for m in party:
		if m.hp > 0:
			msgs.append_array(Data.gain_xp(m, xp))
	for m in party:
		if m.hp <= 0:
			m.hp = 1
		m.poison = false
		m.defending = false
	for m in party:
		_victory_hop(m)
	var rows: VBoxContainer = _victory_win.get_node("VBox/Rows")
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()
	var lines_out := [["EXP didapat", str(xp)], ["Gold didapat", str(gold)]]
	if drops.size() > 0:
		var names := []
		for d in drops:
			names.append(Data.ITEMS[d]["name"])
		lines_out.append(["Item", ", ".join(names)])
	for r in lines_out:
		var hb := HBoxContainer.new()
		rows.add_child(hb)
		var a := Label.new()
		a.text = r[0]
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(a)
		var b := Label.new()
		b.text = r[1]
		b.modulate = Color("ffe9a0")
		hb.add_child(b)
	for msg in msgs:
		var l := Label.new()
		l.text = "★ " + msg
		l.modulate = Color("9ff59f")
		rows.add_child(l)
	_victory_win.size = Vector2.ZERO
	_victory_win.visible = true
	if msgs.size() > 0:
		get_tree().create_timer(0.3).timeout.connect(func(): Snd.sfx("levelup"))
	await wait(0.5)
	await Game.wait_ok()
	finished.emit("win")


func _victory_hop(m: Member) -> void:
	await tw(m, {"ox": 0}, 0.15).finished
	for i in 2:
		await tw(m, {"oy": -20}, 0.17).finished
		await tw(m, {"oy": 0}, 0.17, true).finished


func defeat() -> void:
	state = "end"
	close_command()
	actor = null
	help("Seluruh party tumbang...")
	await wait(1.5)
	finished.emit("lose")


# ---------- Efek visual ----------
func spawn(p: Vector2, o: Dictionary) -> void:
	var life: float = o.get("life", 0.6)
	parts.append({"p": p, "v": Vector2(o.get("vx", randf_range(-60, 60)), o.get("vy", randf_range(-60, 60))), "life": life, "max": life,
		"color": o.get("color", Color.WHITE), "size": float(o.get("size", 4)), "grav": float(o.get("grav", 0)), "shape": o.get("shape", "sq"), "trail": o.get("trail", false)})


func burst_parts(p: Vector2, n: int, colors: Array, o := {}) -> void:
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(o.get("min", 40.0), o.get("max", 160.0))
		spawn(p, {"vx": cos(a) * sp, "vy": sin(a) * sp + o.get("up", 0.0), "life": randf_range(o.get("lmin", 0.3), o.get("lmax", 0.7)),
			"color": colors.pick_random(), "size": randf_range(o.get("smin", 2.0), o.get("smax", 5.0)), "grav": o.get("grav", 0.0), "shape": o.get("shape", "sq")})


func line(a: Vector2, b: Vector2, col := Color.WHITE, width := 4.0, life := 0.25) -> void:
	lines.append({"a": a, "b": b, "color": col, "w": width, "life": life, "max": life})


func bolt(p: Vector2) -> void:
	var pts := PackedVector2Array()
	var cx := p.x + randf_range(-40, 40)
	var cy := -10.0
	while cy < p.y:
		pts.append(Vector2(cx, cy))
		cy += randf_range(18, 34)
		cx += randf_range(-22, 22)
	pts.append(p)
	bolts.append({"pts": pts, "life": 0.3, "max": 0.3})


func ring(p: Vector2, r1: float, col := Color.WHITE, life := 0.4) -> void:
	rings.append({"p": p, "r1": r1, "color": col, "life": life, "max": life})


func pop(p: Vector2, text: String, col: Color, size := 26) -> void:
	var near := 0
	for q in pops:
		if absf(q["p"].x - p.x) < 30 and q["t"] < 0.5:
			near += 1
	pops.append({"p": p + Vector2(0, -near * 22), "text": text, "color": col, "size": size, "t": 0.0})


func _update_fx(dt: float) -> void:
	for q in parts:
		q["life"] -= dt
		var v: Vector2 = q["v"]
		v.y += q["grav"] * dt
		q["v"] = v
		q["p"] += v * dt
	parts = parts.filter(func(q): return q["life"] > 0)
	for arr in [lines, bolts, rings]:
		for o in arr:
			o["life"] -= dt
	lines = lines.filter(func(o): return o["life"] > 0)
	bolts = bolts.filter(func(o): return o["life"] > 0)
	rings = rings.filter(func(o): return o["life"] > 0)
	for q in pops:
		q["t"] += dt
	pops = pops.filter(func(q): return q["t"] < 1.25)
	fx_flash = maxf(0.0, fx_flash - dt * 3.0)
	fx_shake = maxf(0.0, fx_shake - dt * 30.0)


func fx(kind: String, targets: Array, src: Battler) -> void:
	var P := []
	for b in targets:
		P.append(pos(b))
	match kind:
		"slash":
			Snd.sfx("slash")
			for p in P:
				line(p + Vector2(-34, -34), p + Vector2(34, 34), Color.WHITE, 5)
				burst_parts(p, 6, [Color.WHITE, Color("d8e8ff")])
			await wait(0.12)
		"slash2":
			Snd.sfx("slash")
			for p in P:
				line(p + Vector2(-40, -40), p + Vector2(40, 40), Color.WHITE, 6)
				line(p + Vector2(40, -40), p + Vector2(-40, 40), Color.WHITE, 6, 0.35)
				burst_parts(p, 14, [Color.WHITE, Color("cfe8ff")])
			await wait(0.16)
		"slashAll":
			for p in P:
				Snd.sfx("slash")
				line(p + Vector2(-44, 30), p + Vector2(44, -30), Color("cfe8ff"), 6)
				burst_parts(p, 12, [Color.WHITE, Color("9fd0ff")])
				await wait(0.08)
			await wait(0.12)
		"burstSlash":
			Snd.sfx("crit")
			fx_flash = 1.0
			fx_flash_color = Color("fff4d0")
			fx_shake = 12.0
			for p in P:
				for i in 6:
					line(p + Vector2(randf_range(-70, 70), -80), p + Vector2(randf_range(-70, 70), 80), [Color.WHITE, Color("ffe080"), Color("ffb040")].pick_random(), 7, 0.55)
				burst_parts(p, 50, [Color.WHITE, Color("ffe080"), Color("ff9040")], {"max": 300.0, "smax": 7.0})
				ring(p, 140, Color("ffe080"), 0.5)
			await wait(0.32)
		"punch":
			Snd.sfx("punch")
			for p in P:
				var q: Vector2 = p + Vector2(randf_range(-18, 18), randf_range(-18, 18))
				burst_parts(q, 12, [Color.WHITE, Color("ffe060"), Color("ffa030")], {"max": 180.0, "lmax": 0.35})
				ring(q, 32, Color.WHITE, 0.2)
			await wait(0.08)
		"claw":
			Snd.sfx("slash")
			for p in P:
				for i in [-1, 0, 1]:
					line(p + Vector2(-22 + i * 11, -30), p + Vector2(8 + i * 11, 30), Color("ff9090"), 3)
			await wait(0.12)
		"fire":
			Snd.sfx("fire")
			for k in 7:
				for p in P:
					for i in 6:
						spawn(p + Vector2(randf_range(-30, 30), randf_range(0, 34)), {"vx": randf_range(-20, 20), "vy": randf_range(-190, -80), "life": randf_range(0.4, 0.7),
							"color": [Color("fff0a0"), Color("ffb030"), Color("ff6020"), Color("e02010")].pick_random(), "size": randf_range(4, 9)})
				await wait(0.05)
			fx_flash = 0.25
			fx_flash_color = Color("ff9a50")
		"ice":
			Snd.sfx("ice")
			for p in P:
				for i in 16:
					var a := randf() * TAU
					var d := randf_range(60, 90)
					spawn(p + Vector2(cos(a), sin(a)) * d, {"vx": -cos(a) * d * 3, "vy": -sin(a) * d * 3, "life": 0.33, "color": [Color.WHITE, Color("bff0ff"), Color("6ad0ff")].pick_random(), "size": randf_range(5, 8), "shape": "dia"})
			await wait(0.33)
			for p in P:
				burst_parts(p, 22, [Color.WHITE, Color("bff0ff"), Color("6ad0ff")], {"shape": "dia", "smax": 7.0})
			fx_flash = 0.25
			fx_flash_color = Color("c8f4ff")
		"thunder":
			Snd.sfx("thunder")
			for p in P:
				bolt(p)
				bolt(p + Vector2(10, 0))
				burst_parts(p, 18, [Color.WHITE, Color("fff6a0"), Color("a0c8ff")])
			fx_flash = 0.7
			fx_flash_color = Color("fffbe0")
			await wait(0.2)
		"wind":
			Snd.sfx("wind")
			for k in 9:
				for p in P:
					var a := k * 0.8
					spawn(p + Vector2(cos(a) * 44, sin(a) * 22), {"vx": -sin(a) * 170, "vy": cos(a) * 80 - 40, "life": 0.5, "color": [Color("d0ffd8"), Color("80e0a0"), Color.WHITE].pick_random(), "size": 4})
				await wait(0.04)
		"meteor":
			Snd.sfx("meteor")
			for p in P:
				for i in 3:
					spawn(p + Vector2(-160 + randf_range(-30, 30), -260), {"vx": 355, "vy": 578, "life": 0.45, "color": Color("ffa050"), "size": 12, "trail": true})
				await wait(0.09)
			await wait(0.38)
			fx_shake = 14.0
			fx_flash = 0.6
			fx_flash_color = Color("ffd6a8")
			for p in P:
				burst_parts(p, 34, [Color("ffe0a0"), Color("ff8030"), Color("a04020"), Color("604030")], {"max": 230.0, "smax": 7.0})
		"heal":
			Snd.sfx("heal")
			for k in 5:
				for p in P:
					for i in 4:
						spawn(p + Vector2(randf_range(-28, 28), randf_range(-10, 32)), {"vx": 0, "vy": randf_range(-90, -40), "life": 0.7, "color": [Color.WHITE, Color("b0ffb0"), Color("60e080")].pick_random(), "size": randf_range(3, 6), "shape": "star"})
				await wait(0.06)
		"revive":
			Snd.sfx("revive")
			for k in 6:
				for p in P:
					for i in 5:
						spawn(p + Vector2(randf_range(-14, 14), 40), {"vx": randf_range(-10, 10), "vy": randf_range(-260, -160), "life": 0.6, "color": [Color("fff6c0"), Color("ffe060"), Color.WHITE].pick_random(), "size": randf_range(3, 5), "shape": "star"})
				await wait(0.06)
			for p in P:
				ring(p, 70, Color("ffe080"))
		"holy":
			Snd.sfx("holy")
			fx_flash = 1.0
			fx_flash_color = Color.WHITE
			for p in P:
				ring(p, 90, Color("fff6c0"), 0.6)
				for i in 24:
					spawn(p + Vector2(randf_range(-34, 34), randf_range(-34, 34)), {"vx": 0, "vy": randf_range(-120, -40), "life": randf_range(0.6, 1.0), "color": [Color.WHITE, Color("fff6a0"), Color("ffe060")].pick_random(), "size": randf_range(3, 6), "shape": "star"})
			await wait(0.5)
		"spore":
			Snd.sfx("spore")
			for k in 6:
				for p in P:
					spawn(p + Vector2(randf_range(-32, 32), randf_range(-20, 30)), {"vx": randf_range(-20, 20), "vy": randf_range(-40, -10), "life": 0.8, "color": [Color(0.78, 0.44, 0.88, 0.8), Color(0.56, 0.25, 0.69, 0.8), Color(0.88, 0.63, 1.0, 0.8)].pick_random(), "size": randf_range(6, 12), "shape": "circ"})
				await wait(0.06)
		"mist":
			Snd.sfx("mist")
			var sx := pos(src).x if src else 250.0
			for k in 16:
				spawn(Vector2(sx, randf_range(60, 340)), {"vx": randf_range(650, 800), "vy": randf_range(-20, 20), "life": 0.9, "color": [Color(0.82, 0.75, 0.94, 0.75), Color(0.59, 0.51, 0.75, 0.75)].pick_random(), "size": randf_range(16, 28), "shape": "circ"})
				await wait(0.035)
			await wait(0.25)
			fx_flash = 0.35
			fx_flash_color = Color("d8c8f0")
		"quake":
			Snd.sfx("quake")
			fx_shake = 16.0
			for p in P:
				burst_parts(p + Vector2(0, 30), 18, [Color("8a6a4a"), Color("5a4a3a"), Color("b09070")], {"grav": 500.0, "up": -150.0})
			await wait(0.32)
		_:
			Snd.sfx("magic")
			for p in P:
				ring(p, 50, Color("ffb0b0"))
				burst_parts(p, 16, [Color.WHITE, Color("ffb0b0"), Color("ff6060")])
			await wait(0.22)


# ---------- Gambar ----------
# Efek (partikel, garis, petir, angka damage, kursor target) digambar di node FX.
func _draw_fx() -> void:
	var n := _fx
	for r in rings:
		var k: float = 1.0 - r["life"] / r["max"]
		var c: Color = r["color"]
		n.draw_arc(r["p"], 5.0 + (r["r1"] - 5.0) * k, 0, TAU, 32, Color(c, r["life"] / r["max"]), 4.0)
	for q in parts:
		var a := minf(1.0, q["life"] / q["max"] * 1.5)
		var c: Color = q["color"]
		c.a *= a
		var s: float = q["size"]
		var p: Vector2 = q["p"]
		if q["trail"]:
			n.draw_line(p, p - q["v"] * 0.12, Color(1, 0.78, 0.47, 0.6 * a), s * 0.7)
		match q["shape"]:
			"circ": n.draw_circle(p, s, c)
			"dia": n.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.6, 0), p + Vector2(0, s), p + Vector2(-s * 0.6, 0)]), c)
			"star":
				n.draw_rect(Rect2(p.x - s, p.y - 1, s * 2, 2), c)
				n.draw_rect(Rect2(p.x - 1, p.y - s, 2, s * 2), c)
			_: n.draw_rect(Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), c)
	for l in lines:
		var k: float = l["life"] / l["max"]
		var c: Color = l["color"]
		n.draw_line(l["a"], l["b"], Color(c, k), l["w"] * k + 1.0, true)
	for b in bolts:
		var a: float = b["life"] / b["max"]
		n.draw_polyline(b["pts"], Color(0.63, 0.78, 1.0, 0.5 * a), 9.0)
		n.draw_polyline(b["pts"], Color(1, 1, 1, a), 3.0)
	for q in pops:
		var tt: float = q["t"]
		var yo := -tt / 0.15 * 26.0 if tt < 0.15 else (-26.0 + (tt - 0.15) / 0.15 * 14.0 if tt < 0.3 else -12.0)
		var a := maxf(0.0, 1.0 - (tt - 0.95) / 0.3) if tt > 0.95 else 1.0
		var c: Color = q["color"]
		var p: Vector2 = q["p"] + Vector2(-100, yo)
		n.draw_string_outline(_font, p, q["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, q["size"], 6, Color(0, 0, 0, a))
		n.draw_string(_font, p, q["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, q["size"], Color(c, a))
	for b in cursor:
		var p := pos(b)
		var top: float = (p.y - b.h / 2.0 - 12) if b.is_enemy else p.y - 46
		var bob := sin(t * 10.0) * 4.0
		var tri := PackedVector2Array([Vector2(p.x - 10, top - 16 + bob), Vector2(p.x + 10, top - 16 + bob), Vector2(p.x, top - 2 + bob)])
		n.draw_colored_polygon(tri, Color.WHITE)
		n.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color.BLACK, 2.0)
	if fx_flash > 0:
		n.draw_rect(Rect2(-20, -20, 1000, 580), Color(fx_flash_color, minf(1.0, fx_flash) * 0.8))
