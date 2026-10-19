extends RefCounted
## Uji otomatis: jalankan dengan
##   godot --headless --path rpg -- --selftest
## Memainkan alur utama game dengan AI sederhana lalu mencetak hasilnya.

var fails := 0
var ai_on := false


func ok(cond: bool, msg: String) -> void:
	if cond:
		print("[OK]   ", msg)
	else:
		fails += 1
		print("[FAIL] ", msg)


func wait(sec: float) -> void:
	await Game.get_tree().create_timer(sec).timeout


func pump(n: int, key := "ok", gap := 0.06) -> void:
	for i in n:
		Game.press(key)
		await wait(gap)


func run() -> void:
	Engine.time_scale = 6.0
	_check_maps()
	await _check_town()
	await _check_battles()
	await _check_boss()
	await _check_save_load()
	Engine.time_scale = 1.0
	print("SELFTEST SELESAI: %d gagal" % fails)
	Game.get_tree().quit(1 if fails > 0 else 0)


# ---------- Peta ----------
func _check_maps() -> void:
	var starts := {"town": Vector2i(12, 10), "world": Vector2i(8, 18), "cave": Vector2i(15, 21)}
	for id in starts:
		var def := WorldMap.read_map(id)
		def["node"].free()
		var rows: Array = def["rows"]
		var w: int = rows[0].length()
		ok(rows.all(func(r): return r.length() == w), "%s: semua baris peta sama panjang" % id)
		var blocked := func(x: int, y: int) -> bool:
			if y < 0 or x < 0 or y >= rows.size() or x >= w:
				return true
			if rows[y][x] in WorldMap.BLOCK:
				return true
			for e in def["ents"]:
				if e["x"] == x and e["y"] == y:
					return true
			return false
		var seen := {starts[id]: true}
		var q := [starts[id]]
		while q.size() > 0:
			var c: Vector2i = q.pop_front()
			for d in WorldMap.DIRS.values():
				var n: Vector2i = c + d
				if not seen.has(n) and not blocked.call(n.x, n.y):
					seen[n] = true
					q.append(n)
		var adj := func(x: int, y: int) -> bool:
			for d in WorldMap.DIRS.values():
				if seen.has(Vector2i(x, y) + d):
					return true
			return false
		var bad := []
		for e in def["ents"]:
			if not adj.call(e["x"], e["y"]):
				bad.append("%s@%d,%d" % [e["type"], e["x"], e["y"]])
		for k in def.get("doors", {}):
			var p: PackedStringArray = k.split(",")
			if not adj.call(int(p[0]), int(p[1])):
				bad.append("door@" + k)
		for k in def.get("warps", {}):
			var p2: PackedStringArray = k.split(",")
			if not seen.has(Vector2i(int(p2[0]), int(p2[1]))):
				bad.append("warp@" + k)
		ok(bad.is_empty(), "%s: semua objek/pintu/warp bisa dicapai (%d petak) %s" % [id, seen.size(), bad])


# ---------- Desa, menu, toko ----------
func _check_town() -> void:
	Game.new_game()
	Game.enter_world("town", 12, 10, "up")
	await wait(0.3)
	ok(Game.scene == "world" and Game.world.map_id == "town", "masuk desa")
	var st := {"done": false}
	var talk := func() -> void:
		await Game.elder_talk()
		st["done"] = true
	talk.call()
	while not st["done"]:
		Game.press("ok")
		await wait(0.05)
	ok(Game.gold == 250 and Game.items.get("ramuan", 0) == 5, "hadiah tetua diterima (gold %d)" % Game.gold)
	# Menu lapangan: Status lalu tutup
	Game.press("cancel")
	await wait(0.3)
	ok(Game.world.busy, "menu lapangan terbuka")
	await pump(2, "down")
	await pump(1, "ok")
	await pump(1, "down")
	await pump(2, "cancel")
	await wait(0.2)
	ok(not Game.world.busy, "menu lapangan tertutup")
	# Toko: beli Rompi Kulit untuk Lyra
	Game.world.use_door("shop")
	await wait(0.5)
	await pump(2, "ok", 0.2)
	await pump(8, "down")
	await pump(1, "ok")
	await wait(0.2)
	await pump(2, "down")
	await pump(1, "ok")
	await wait(0.3)
	var lyra: Member = Data.member("lyra")
	ok(lyra.armor == "rompiKulit" and Game.gold == 130, "beli Rompi Kulit untuk Lyra (gold %d, armor %s)" % [Game.gold, lyra.armor])
	await pump(1, "cancel")
	await pump(3, "ok", 0.2)
	await wait(0.3)
	ok(not Game.world.busy, "keluar toko")
	# Gerak: tahan panah atas
	var y0 := Game.world.py
	Game.held["up"] = true
	await wait(0.4)
	Game.held.erase("up")
	await wait(0.2)
	ok(Game.world.py < y0, "pemain bisa berjalan (y %d -> %d)" % [y0, Game.world.py])


# ---------- Battle ----------
func _ai_loop() -> void:
	var b: Battle = Game.battle
	while ai_on:
		await Game.get_tree().process_frame
		if b.state == "end" and Game.top_input() != null and Game.top_input().get("click") == true:
			Game.press("ok")
			continue
		if b.state != "menu" or b.actor == null or b._cmd == null or not b._cmd.active:
			continue
		var m: Member = b.actor
		var foes := b.alive_enemies()
		var alive := b.alive_party()
		var dead := b.party.filter(func(p): return p.hp <= 0)
		var low := alive.filter(func(p): return p.hp < p.s["maxHp"] * 0.45)
		var sk := func(id: String) -> bool: return Data.skills_of(m).has(id) and m.mp >= Data.SKILLS[id]["mp"]
		var act := {"type": "attack"}
		var tg: Array = [foes[0]]
		if m.burst >= 100:
			act = {"type": "burst"}
			var bt: String = Data.BURSTS[m.id]["target"]
			tg = b.party.duplicate() if bt == "allAllies" else ([foes[0]] if bt == "enemy" else foes)
		elif m.id == "lyra" and dead.size() > 0 and sk.call("hidupkan"):
			act = {"type": "skill", "id": "hidupkan"}; tg = [dead[0]]
		elif m.id == "lyra" and low.size() >= 2 and sk.call("pulihBersama"):
			act = {"type": "skill", "id": "pulihBersama"}; tg = alive
		elif m.id == "lyra" and low.size() > 0 and sk.call("pulih"):
			act = {"type": "skill", "id": "pulih"}; tg = [low[0]]
		elif dead.size() > 0 and Game.items.has("kristalHidup"):
			act = {"type": "item", "id": "kristalHidup"}; tg = [dead[0]]
		elif low.size() > 0 and Game.items.has("ramuanSuper"):
			act = {"type": "item", "id": "ramuanSuper"}; tg = [low[0]]
		elif low.size() > 0 and Game.items.has("ramuan") and m.id != "lyra":
			act = {"type": "item", "id": "ramuan"}; tg = [low[0]]
		elif m.id == "lyra" and sk.call("kilat"):
			act = {"type": "skill", "id": "kilat"}
		elif m.id == "kael" and sk.call("pedangPetir") and foes[0].tpl.get("weak", []).has("thunder"):
			act = {"type": "skill", "id": "pedangPetir"}
		b.close_command()
		b.perform(m, act, tg)


func _setup_party(lvl: int, gear: Dictionary, it: Dictionary) -> void:
	for m in Game.party:
		m.lvl = lvl
		m.xp = 0
		m.weapon = gear.get(m.id, Data.CHARS[m.id]["weapon"])
		m.armor = gear.get("armor", "bajuKain")
		Data.refresh_stats(m)
		m.hp = m.s["maxHp"]
		m.mp = m.s["maxMp"]
		m.burst = 0.0
	Game.items = it.duplicate()


func _sim(lvl: int, group: Array, bg: String, gear: Dictionary, it: Dictionary, opts := {}) -> Dictionary:
	_setup_party(lvl, gear, it)
	var min_hp := {}
	ai_on = true
	_ai_loop()
	var st := {"r": ""}
	var runner := func() -> void:
		st["r"] = await Game.run_battle(group, bg, opts)
	runner.call()
	var t0 := Time.get_ticks_msec()
	while st["r"] == "" and Game.scene != "gameover" and Time.get_ticks_msec() - t0 < 120000:
		await Game.get_tree().process_frame
		for m in Game.party:
			min_hp[m.id] = mini(min_hp.get(m.id, 999999), m.hp)
	ai_on = false
	var pct := []
	for m in Game.party:
		pct.append(roundi(100.0 * min_hp.get(m.id, 0) / m.s["maxHp"]))
	return {"r": "lose" if Game.scene == "gameover" else st["r"], "min_hp_pct": pct}


func _check_battles() -> void:
	var r := await _sim(1, ["serigala", "lendir", "lebah"], "field", {}, {"ramuan": 3})
	ok(r["r"] == "win", "battle padang Lv1 menang (HP minimum %s%%)" % [r["min_hp_pct"]])
	ok(Data.member("kael").lvl >= 1 and Game.scene == "world", "kembali ke peta setelah battle")
	var shop := {"kael": "pedangBaja", "rina": "sarungBesi", "lyra": "tongkatKristal", "armor": "rompiKulit"}
	r = await _sim(5, ["golem", "kelelawar"], "cave", shop, {"ramuan": 3})
	ok(r["r"] == "win", "battle gua Lv5 menang (HP minimum %s%%)" % [r["min_hp_pct"]])
	# Kabur
	_setup_party(3, {}, {})
	ai_on = false
	var st := {"r": ""}
	var runner := func() -> void:
		st["r"] = await Game.run_battle(["lendir"], "field")
	runner.call()
	var t0 := Time.get_ticks_msec()
	while st["r"] == "" and Time.get_ticks_msec() - t0 < 60000:
		await Game.get_tree().process_frame
		var b: Battle = Game.battle
		if b.state == "menu" and b._cmd and b._cmd.active:
			b.close_command()
			b.perform(b.actor, {"type": "flee"}, [])
	ok(st["r"] == "flee" or st["r"] == "win", "kabur dari battle (hasil: %s)" % st["r"])


func _check_boss() -> void:
	var chest := {"kael": "pedangKristal", "rina": "sarungNaga", "lyra": "tongkatBintang", "armor": "zirahRantai"}
	var r := await _sim(8, ["wyrm"], "boss", chest, {"ramuan": 5, "ramuanSuper": 3, "eter": 2, "kristalHidup": 2}, {"boss": true, "music": "boss"})
	ok(r["r"] == "win", "bos Lv8 dengan perlengkapan peti bisa dikalahkan (HP minimum %s%%)" % [r["min_hp_pct"]])
	var r2 := await _sim(4, ["wyrm"], "boss", {}, {"ramuan": 3}, {"boss": true, "music": "boss"})
	ok(r2["r"] == "lose", "bos Lv4 tanpa persiapan mengalahkan party (hasil: %s)" % r2["r"])
	await wait(0.5)
	ok(Game.scene == "gameover", "layar game over muncul")
	await wait(0.5)
	await pump(1, "ok")
	await wait(1.0)
	ok(Game.scene == "title", "kembali ke layar judul dari game over")


func _check_save_load() -> void:
	Game.new_game()
	Game.enter_world("cave", 13, 12, "up")
	await wait(0.2)
	Data.member("kael").lvl = 6
	Data.refresh_stats(Data.member("kael"))
	Game.flags["chests"]["c1"] = true
	ok(Game.save_game(), "simpan permainan")
	Game.new_game()
	var d := Game.load_game()
	ok(d["map"] == "cave" and Data.member("kael").lvl == 6 and Game.flags["chests"].has("c1"), "muat permainan mengembalikan state")
	Game.enter_world(d["map"], int(d["x"]), int(d["y"]), d["f"])
	await wait(0.2)
	ok(Game.world.px == 13 and Game.world.py == 12, "posisi pemain dipulihkan")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))
