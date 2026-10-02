class_name Menus
extends RefCounted
## Menu lapangan (Item, Skill, Status, Simpan), toko, penginapan, dan kristal penyimpanan.


static func label(text: String, size := 16, col := Color.WHITE, wrap_w := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.modulate = col
	if wrap_w > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap_w
	return l


static func kv(parent: Node, k: String, v: String, size := 14, vcol := Color.WHITE) -> void:
	var hb := HBoxContainer.new()
	parent.add_child(hb)
	var a := label(k, size)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(a)
	var b := label(v, size, vcol)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(b)


static func heading(parent: Node, text: String) -> void:
	parent.add_child(label(text, 16, Color("ffe98a")))
	var sep := HSeparator.new()
	parent.add_child(sep)


static func card_node(m: Member) -> Control:
	var c: Dictionary = Data.CHARS[m.id]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	if m.hp <= 0:
		hb.modulate.a = 0.6
	var tr := TextureRect.new()
	tr.texture = Art.sprite(m.id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(48, 54)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(tr)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	top.add_child(label(c["name"], 17))
	top.add_child(label("Lv %d" % m.lvl, 14, Color("ffe98a")))
	vb.add_child(label(c["title"], 12, Color("c0c6f0")))
	var need := Data.xp_next(m.lvl)
	var maxed := m.lvl >= Data.MAX_LVL
	for spec in [["HP", "%d / %d" % [m.hp, m.s["maxHp"]], "hp", float(m.hp) / m.s["maxHp"]],
			["MP", "%d / %d" % [m.mp, m.s["maxMp"]], "mp", float(m.mp) / m.s["maxMp"]],
			["EXP", "MAX" if maxed else "%d / %d" % [m.xp, need], "xp", 1.0 if maxed else float(m.xp) / need]]:
		kv(vb, spec[0], spec[1], 13)
		var b := Bar.make(vb, spec[2], 230, 6)
		b.value = spec[3]
	return hb


static func status_into(parent: Node, m: Member) -> void:
	var c: Dictionary = Data.CHARS[m.id]
	heading(parent, "%s — %s" % [c["name"], c["title"]])
	var rows := [
		["Level", str(m.lvl)],
		["EXP ke level berikut", "-" if m.lvl >= Data.MAX_LVL else str(Data.xp_next(m.lvl) - m.xp)],
		["HP", "%d / %d" % [m.hp, m.s["maxHp"]]], ["MP", "%d / %d" % [m.mp, m.s["maxMp"]]],
		["Serangan", str(m.s["atk"])], ["Sihir", str(m.s["matk"])], ["Pertahanan", str(m.s["def"])], ["Kecepatan", str(m.s["spd"])],
		["Senjata", Data.ITEMS[m.weapon]["name"]], ["Pelindung", Data.ITEMS[m.armor]["name"]],
	]
	for r in rows:
		kv(parent, r[0], r[1], 15, Color("ffe9a0"))
	parent.add_child(label(" ", 6))
	heading(parent, c["skillLabel"])
	for e in c["skills"]:
		if e[0] > m.lvl:
			parent.add_child(label("Lv %d: ???" % e[0], 14, Color("8a90c0")))
		else:
			parent.add_child(label("%s  (%d MP)" % [Data.SKILLS[e[1]]["name"], Data.SKILLS[e[1]]["mp"]], 14))
	parent.add_child(label("BURST: " + Data.BURSTS[m.id]["name"], 14, Color("ff9ccc")))


static func fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


# ---------- Menu lapangan ----------
static func field_menu() -> void:
	Game.world.busy = true
	Snd.sfx("menu")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	Game.ui.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.04, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cmd_w := Win.make(root, 16, 16, 190)
	var info_w := Win.make(root, 16, 410, 190, 114)
	var cards_w := Win.make(root, 216, 16, 370, 508)
	var side_w := Win.make(root, 596, 16, 348, 508)
	var info := VBoxContainer.new()
	info_w.add_child(info)
	var side := VBoxContainer.new()
	side_w.add_child(side)
	var st := {"closed": false}

	var refresh_info := func() -> void:
		for ch in info.get_children():
			ch.queue_free()
		kv(info, "Gold", str(Game.gold), 15, Color("ffe9a0"))
		kv(info, "Waktu", fmt_time(Game.play_time), 15, Color("ffe9a0"))
		info.add_child(label(Game.world.def["name"], 13, Color("c0c6f0")))
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(refresh_info)
	root.add_child(timer)

	var cards := ListMenu.make(cards_w, [], {"inactive": true, "item_width": 330})
	var refresh_cards := func(filter: Callable) -> void:
		var items := []
		for m in Game.party:
			items.append({"node": card_node(m), "value": m, "disabled": filter.is_valid() and not filter.call(m)})
		cards.set_items(items)
	var side_clear := func() -> void:
		for ch in side.get_children():
			side.remove_child(ch)
			ch.queue_free()
	var side_default := func() -> void:
		side_clear.call()
		heading(side, "Kontrol")
		for s in ["Panah / WASD — bergerak", "Enter / Z / Spasi — pilih, bicara, periksa", "Esc / X — batal, buka menu", "M — suara on/off"]:
			side.add_child(label(s, 14))
		side.add_child(label(" ", 6))
		heading(side, "Tips")
		for s in ["• Monster muncul di rumput dan di dalam gua. Jalan setapak aman.",
				"• Bar BURST terisi saat terkena serangan. Jika penuh, jurus pamungkas siap!",
				"• Serang kelemahan elemen musuh untuk damage 2x.",
				"• Penginapan & kristal biru memulihkan HP/MP."]:
			side.add_child(label(s, 14, Color.WHITE, 320))
	refresh_cards.call(Callable())
	refresh_info.call()
	side_default.call()

	var pick_member := func(filter: Callable):
		refresh_cards.call(filter)
		var w := Waiter.new()
		cards.on_select = func(it, _i): w.done.emit(it["value"])
		cards.on_cancel = func(): w.done.emit(null)
		cards.activate()
		var r = await w.done
		cards.deactivate()
		refresh_cards.call(Callable())
		return r
	# Daftar di panel kanan. Mengembalikan [value, index] atau [null, start].
	var side_list := func(title: String, items: Array, start: int, help_box: Array):
		side_clear.call()
		heading(side, title)
		var holder := VBoxContainer.new()
		side.add_child(holder)
		side.add_child(HSeparator.new())
		var help := label("", 14, Color("dfe3ff"), 320)
		help.custom_minimum_size.y = 40
		side.add_child(help)
		help_box.clear()
		help_box.append(help)
		var w := Waiter.new()
		var lm := ListMenu.make(holder, items, {"start": start,
			"on_move": func(it, _i): help.text = it.get("help", ""),
			"on_select": func(it, i): w.done.emit([it["value"], i]),
			"on_cancel": func(): w.done.emit([null, start])})
		var r = await w.done
		lm.deactivate()
		return r

	var flow_item := func() -> void:
		var idx := 0
		while true:
			if Game.items.is_empty():
				side_clear.call()
				heading(side, "Item")
				side.add_child(label("Tas kosong.", 14, Color("aeb6ea")))
				Snd.sfx("buzz")
				return
			var items := []
			for k in Game.items:
				var it: Dictionary = Data.ITEMS[k]
				var bo: bool = it.get("battleOnly", false)
				items.append({"label": it["name"], "right": "x%d" % Game.items[k], "value": k, "disabled": bo, "help": it["desc"] + (" (Hanya di battle.)" if bo else "")})
			var hb := []
			var r = await side_list.call("Item", items, idx, hb)
			idx = r[1]
			if r[0] == null:
				side_default.call()
				return
			var id: String = r[0]
			hb[0].text = "Pakai %s untuk siapa?" % Data.ITEMS[id]["name"]
			var tg = await pick_member.call(func(m): return Data.can_use_item(id, m))
			if tg == null:
				continue
			var res := Data.apply_item(id, tg)
			Data.remove_item(id)
			Snd.sfx("revive" if res.get("revived", false) else "heal")
			refresh_cards.call(Callable())

	var flow_skill := func() -> void:
		while true:
			side_clear.call()
			heading(side, "Skill")
			side.add_child(label("Pilih siapa yang memakai skill penyembuh.\n(Lyra: Pulih dan lainnya. Rina: Fokus Chi di Lv 6)", 14, Color("aeb6ea"), 320))
			var caster = await pick_member.call(func(m): return m.hp > 0 and not Data.field_skills(m).is_empty())
			if caster == null:
				side_default.call()
				return
			var idx := 0
			while true:
				var items := []
				for k in Data.field_skills(caster):
					var sk: Dictionary = Data.SKILLS[k]
					items.append({"label": sk["name"], "right": "%d MP" % sk["mp"], "value": k, "disabled": caster.mp < sk["mp"], "help": sk["desc"]})
				var hb := []
				var r = await side_list.call("%s — %s (MP %d)" % [Data.CHARS[caster.id]["skillLabel"], caster.display_name(), caster.mp], items, idx, hb)
				idx = r[1]
				if r[0] == null:
					break
				var sk: Dictionary = Data.SKILLS[r[0]]
				var targets := []
				if sk["target"] == "allies":
					targets = Game.party.filter(func(m): return m.hp > 0)
				elif sk["target"] == "self":
					targets = [caster]
				else:
					hb[0].text = "%s untuk siapa?" % sk["name"]
					var tg = await pick_member.call(func(m): return m.hp <= 0 if sk["kind"] == "revive" else (m.hp > 0 and m.hp < m.s["maxHp"]))
					if tg == null:
						continue
					targets = [tg]
				caster.mp -= sk["mp"]
				for tg in targets:
					if sk["kind"] == "revive":
						tg.hp = maxi(1, floori(tg.s["maxHp"] * sk["power"]))
					else:
						tg.hp = mini(tg.s["maxHp"], tg.hp + Data.heal_power(caster, sk))
				Snd.sfx("revive" if sk["kind"] == "revive" else "heal")
				refresh_cards.call(Callable())

	var flow_status := func() -> void:
		cards.on_move = func(it, _i):
			side_clear.call()
			status_into(side, it["value"])
		while true:
			var picked = await pick_member.call(Callable())
			if picked == null:
				break
		cards.on_move = Callable()
		side_default.call()

	var flow_save := func() -> void:
		side_clear.call()
		heading(side, "Simpan")
		if Game.save_game():
			Snd.sfx("save")
			side.add_child(label("Permainan tersimpan!", 16))
			side.add_child(label("Pilih \"Lanjutkan\" di layar judul untuk memuatnya.", 14, Color("aeb6ea"), 320))
		else:
			Snd.sfx("buzz")
			side.add_child(label("Gagal menyimpan.", 16))

	var close := func() -> void:
		if st["closed"]:
			return
		st["closed"] = true
		cards.destroy()
		root.queue_free()
		Game.world.busy = false
		Game.world.bump_lock = true

	var flow_title := func() -> void:
		var r = await side_list.call("Kembali ke layar judul?", [{"label": "Ya", "value": "y", "help": "Progres yang belum disimpan akan hilang."}, {"label": "Tidak", "value": "n", "help": ""}], 1, [])
		if r[0] == "y":
			st["closed"] = true
			Game.show_title()
			return
		side_default.call()

	var main := ListMenu.make(cmd_w, [
		{"label": "Item", "value": "item"}, {"label": "Skill", "value": "skill"}, {"label": "Status", "value": "status"},
		{"label": "Simpan", "value": "save"}, {"label": "Ke Judul", "value": "title"}, {"label": "Tutup", "value": "close"},
	], {"inactive": true})
	main.on_cancel = func():
		main.destroy()
		close.call()
	main.on_select = func(it, _i):
		if it["value"] == "close":
			main.destroy()
			close.call()
			return
		main.deactivate()
		match it["value"]:
			"item": await flow_item.call()
			"skill": await flow_skill.call()
			"status": await flow_status.call()
			"save": await flow_save.call()
			"title": await flow_title.call()
		if not st["closed"]:
			main.activate()
	main.activate()


# ---------- Toko ----------
static func open_shop() -> void:
	await Game.say([{"s": "Pak Darmo", "t": "Selamat datang di toko kami! Ramuan, senjata, pelindung... semua ada. Silakan lihat-lihat."}])
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	Game.ui.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.04, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var head_w := Win.make(root, 16, 16, 928, 50)
	var head := HBoxContainer.new()
	head_w.add_child(head)
	var list_w := Win.make(root, 16, 76, 470, 448)
	var info_w := Win.make(root, 496, 76, 448, 448)
	var info := VBoxContainer.new()
	info_w.add_child(info)

	var upd := func() -> void:
		for ch in head.get_children():
			ch.queue_free()
		var a := label("Toko Pak Darmo", 18)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(a)
		head.add_child(label("Gold: %d" % Game.gold, 18, Color("ffe9a0")))
	var mk := func() -> Array:
		var out := []
		for id in Data.SHOP:
			var it: Dictionary = Data.ITEMS[id]
			var owned: bool = it["kind"] == "weapon" and Data.member(it["owner"]).weapon == id
			out.append({"label": it["name"], "right": "Dipakai" if owned else "%d G" % it["price"], "value": id, "disabled": owned or Game.gold < it["price"]})
		return out
	var show_info := func(id: String) -> void:
		for ch in info.get_children():
			info.remove_child(ch)
			ch.queue_free()
		var it: Dictionary = Data.ITEMS[id]
		heading(info, it["name"])
		info.add_child(label(it["desc"], 15, Color.WHITE, 420))
		info.add_child(label("Harga: %d G" % it["price"], 13, Color("aeb6ea")))
		info.add_child(label(" ", 6))
		if it["kind"] == "item":
			kv(info, "Dimiliki", str(Game.items.get(id, 0)), 15, Color("ffe9a0"))
		else:
			heading(info, "Perbandingan")
			for m in Game.party:
				if it["kind"] == "weapon" and it["owner"] != m.id:
					continue
				var cur: Dictionary = Data.ITEMS[m.weapon if it["kind"] == "weapon" else m.armor]
				var key := "def" if it["kind"] == "armor" else ("atk" if it.has("atk") else "mag")
				var nm: String = {"def": "Pertahanan", "atk": "Serangan", "mag": "Sihir"}[key]
				var before: int = m.s["def"] if key == "def" else (m.s["atk"] if key == "atk" else m.s["matk"])
				var after: int = before - int(cur.get(key, 0)) + int(it.get(key, 0))
				kv(info, "%s — %s" % [m.display_name(), nm], "%d → %d" % [before, after], 14, Color("9ff59f") if after >= before else Color("ff9090"))
			var who := []
			for m in Game.party:
				if m.weapon == id or m.armor == id:
					who.append(m.display_name())
			if who.size() > 0:
				info.add_child(label("Dipakai oleh: " + ", ".join(who), 13, Color("aeb6ea"), 420))
		if Game.gold < it["price"]:
			info.add_child(label("Gold tidak cukup.", 15, Color("ff9090")))
	upd.call()
	var w := Waiter.new()
	var lm := ListMenu.make(list_w, mk.call(), {"silent": true, "item_width": 440,
		"on_move": func(it, _i): show_info.call(it["value"]),
		"on_cancel": func(): w.done.emit(null)})
	lm.on_select = func(it, _i):
		var id: String = it["value"]
		var item: Dictionary = Data.ITEMS[id]
		if item["kind"] == "weapon":
			var m := Data.member(item["owner"])
			Game.gold -= item["price"]
			Data.equip(m, "weapon", id)
			Game.toast("%s memakai %s!" % [m.display_name(), item["name"]])
		elif item["kind"] == "armor":
			lm.deactivate()
			var pw := Win.make(root, 496, 300, 448, 150)
			var vb := VBoxContainer.new()
			pw.add_child(vb)
			vb.add_child(label("Pakaikan %s ke siapa?" % item["name"], 15, Color("ffe98a")))
			var w2 := Waiter.new()
			var opts := []
			for p in Game.party:
				opts.append({"label": p.display_name(), "right": Data.ITEMS[p.armor]["name"], "value": p, "disabled": p.armor == id})
			var pm := ListMenu.make(vb, opts, {"item_width": 410, "on_select": func(x, _i): w2.done.emit(x["value"]), "on_cancel": func(): w2.done.emit(null)})
			var m2 = await w2.done
			pm.destroy()
			pw.queue_free()
			lm.activate()
			if m2 == null:
				return
			Game.gold -= item["price"]
			Data.equip(m2, "armor", id)
			Game.toast("%s memakai %s!" % [m2.display_name(), item["name"]])
		else:
			Game.gold -= item["price"]
			Data.add_item(id)
		Snd.sfx("buy")
		upd.call()
		lm.set_items(mk.call())
		show_info.call(id)
	await w.done
	lm.destroy()
	root.queue_free()
	await Game.say([{"s": "Pak Darmo", "t": "Terima kasih! Hati-hati di jalan, ya!"}])


# ---------- Penginapan ----------
static func open_inn() -> void:
	var i: int = await Game.ask("Bu Wina: Selamat datang di Penginapan Angin Sepoi! Menginap semalam 20 Gold. Mau beristirahat?", ["Menginap (20 G)", "Tidak"])
	if i != 0:
		await Game.say([{"s": "Bu Wina", "t": "Datang lagi kapan-kapan, ya!"}])
		return
	if Game.gold < 20:
		Snd.sfx("buzz")
		await Game.say([{"s": "Bu Wina", "t": "Maaf, Gold-mu tidak cukup..."}])
		return
	Game.gold -= 20
	await Game.fade_to(1.0, 0.6)
	Snd.sfx("inn")
	Data.full_heal()
	await Game.get_tree().create_timer(1.5).timeout
	await Game.fade_to(0.0, 0.6)
	await Game.say([{"s": "Bu Wina", "t": "Selamat pagi! Kalian terlihat segar kembali. Semoga perjalanan kalian lancar!"}])


# ---------- Kristal penyimpanan ----------
static func save_crystal() -> void:
	Snd.sfx("holy")
	Data.full_heal()
	await Game.say(["Cahaya biru kristal menyelimuti party... HP dan MP pulih sepenuhnya!"])
	var i: int = await Game.ask("Simpan permainan di sini?", ["Simpan", "Tidak"])
	if i == 0 and Game.save_game():
		Snd.sfx("save")
		await Game.say(["Permainan tersimpan."])
