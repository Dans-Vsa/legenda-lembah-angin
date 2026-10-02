extends Node
## Pengendali utama: state game, input, dialog, adegan (judul, cerita, ending, game over),
## transisi battle, dan simpan/muat.

const SAVE_PATH := "user://save.json"
const KEYMAP := {
	KEY_UP: "up", KEY_W: "up", KEY_DOWN: "down", KEY_S: "down",
	KEY_LEFT: "left", KEY_A: "left", KEY_RIGHT: "right", KEY_D: "right",
	KEY_ENTER: "ok", KEY_KP_ENTER: "ok", KEY_SPACE: "ok", KEY_Z: "ok",
	KEY_ESCAPE: "cancel", KEY_X: "cancel", KEY_BACKSPACE: "cancel",
	KEY_TAB: "menu", KEY_M: "mute",
}


class KeyHandler:
	var fn: Callable
	var click := false
	func _init(f: Callable, accept_click := false) -> void:
		fn = f
		click = accept_click
	func on_key(a: String) -> void:
		fn.call(a)


var scene := "boot"
var party: Array = []
var items := {}
var gold := 0
var flags := {}
var play_time := 0.0

var held := {}
var input_stack: Array = []

var main: Node2D
var world: WorldMap
var battle: Battle
var title_bg: Node2D
var ui: Control
var fade: ColorRect
var hint: Label
var _title_t := 0.0
var _stars: Array = []
var _hills: Array = []
var _selftest: RefCounted


func setup(main_node: Node2D) -> void:
	main = main_node
	title_bg = Node2D.new()
	title_bg.draw.connect(_draw_title_bg)
	main.add_child(title_bg)
	world = WorldMap.new()
	world.visible = false
	main.add_child(world)
	battle = Battle.new()
	main.add_child(battle)
	var hint_layer := CanvasLayer.new()
	hint_layer.layer = 5
	main.add_child(hint_layer)
	hint = Label.new()
	hint.text = "Esc: Menu   •   Enter: Bicara/Periksa"
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.position = Vector2(700, 518)
	hint.size = Vector2(250, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_layer.add_child(hint)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	main.add_child(ui_layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = 16
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.85))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 1)
	ui.theme = th
	ui_layer.add_child(ui)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	main.add_child(fade_layer)
	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in 90:
		_stars.append(Vector3(rng.randf() * 960, rng.randf() * 260, rng.randf()))
	for li in 3:
		var hs := []
		for i in 64:
			hs.append(rng.randf())
		_hills.append(hs)
	for arg in ["--selftest", "--shots"]:
		if arg in OS.get_cmdline_user_args():
			var t: GDScript = load("res://tests/%s.gd" % ("selftest" if arg == "--selftest" else "shots"))
			_selftest = t.new()
			_selftest.run()
			return
	show_title()


func _process(dt: float) -> void:
	if scene == "world" or scene == "battle":
		play_time += dt
	if scene == "world":
		world.update(dt)
	if hint:
		hint.visible = scene == "world" and top_input() == world and not world.busy
	if title_bg and title_bg.visible:
		_title_t += dt
		title_bg.queue_redraw()


# ---------- Input ----------
func push_input(h: Object) -> void:
	input_stack.append(h)


func pop_input(h: Object) -> void:
	var i := input_stack.rfind(h)
	if i >= 0:
		input_stack.remove_at(i)


func top_input() -> Object:
	return input_stack.back() if input_stack.size() > 0 else null


func press(a: String) -> void:
	var t := top_input()
	if t and t.has_method("on_key"):
		t.on_key(a)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var a: String = KEYMAP.get(event.physical_keycode, "")
		if a == "":
			return
		get_viewport().set_input_as_handled()
		if event.pressed:
			if a == "mute":
				if not event.echo:
					Snd.toggle_mute()
					toast("Suara: " + ("mati" if Snd.muted else "nyala"), 1.0)
				return
			held[a] = true
			if event.echo and a in ["ok", "cancel", "menu"]:
				return
			press(a)
		else:
			held.erase(a)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var t := top_input()
		if t is KeyHandler and t.click:
			t.on_key("ok")


# ---------- UI umum ----------
func clear_ui() -> void:
	for ch in ui.get_children():
		ch.queue_free()
	input_stack.clear()


func fade_to(a: float, sec := 0.35, col := Color.BLACK) -> void:
	var start := fade.color.a
	fade.color = Color(col, start)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, sec)
	await tw.finished


func wait_ok() -> void:
	var w := Waiter.new()
	var on_key := func(a: String) -> void:
		if a == "ok" or a == "cancel":
			w.done.emit(true)
	var h := KeyHandler.new(on_key, true)
	push_input(h)
	await w.done
	pop_input(h)


func say(lines: Array) -> void:
	var box := Win.make(ui, 40, 388, 880, 140)
	var txt := Label.new()
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(850, 0)
	txt.add_theme_font_size_override("font_size", 18)
	box.add_child(txt)
	var tag := Win.make(ui, 56, 370)
	var tag_l := Label.new()
	tag_l.add_theme_font_size_override("font_size", 15)
	tag_l.modulate = Color("ffe98a")
	tag.add_child(tag_l)
	var more := Label.new()
	more.text = "▼"
	more.position = Vector2(894, 500)
	more.add_theme_font_size_override("font_size", 13)
	ui.add_child(more)
	var st := {"typing": false}
	var w := Waiter.new()
	var on_key := func(a: String) -> void:
		if a != "ok" and a != "cancel":
			return
		if st["typing"]:
			st["typing"] = false
			txt.visible_characters = -1
		else:
			w.done.emit(true)
	var h := KeyHandler.new(on_key, true)
	push_input(h)
	for L in lines:
		var s := ""
		var t := ""
		if L is String:
			t = L
		else:
			s = L.get("s", "")
			t = L["t"]
		tag.visible = s != ""
		tag_l.text = s
		txt.text = t
		txt.visible_characters = 0
		more.visible = false
		st["typing"] = true
		while st["typing"] and txt.visible_characters < t.length():
			await get_tree().create_timer(0.022).timeout
			if st["typing"]:
				txt.visible_characters += 2
		st["typing"] = false
		txt.visible_characters = -1
		more.visible = true
		await w.done
		Snd.sfx("cursor")
	pop_input(h)
	box.queue_free()
	tag.queue_free()
	more.queue_free()


func ask(text: String, options: Array) -> int:
	var box := Win.make(ui, 40, 388, 880, 140)
	var txt := Label.new()
	txt.text = text
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(850, 0)
	txt.add_theme_font_size_override("font_size", 18)
	box.add_child(txt)
	var cw := Win.make(ui, 700, 388 - 22 - options.size() * 25, 220)
	var w := Waiter.new()
	var opts := []
	for i in options.size():
		opts.append({"label": options[i], "value": i})
	var m := ListMenu.make(cw, opts, {"on_select": func(it, _i): w.done.emit(it["value"]), "on_cancel": func(): w.done.emit(-1)})
	var r: int = await w.done
	m.destroy()
	box.queue_free()
	cw.queue_free()
	return r


func toast(text: String, sec := 1.8) -> void:
	var t := Win.make(ui, 0, 14)
	var l := Label.new()
	l.text = text
	t.add_child(l)
	await get_tree().process_frame
	t.position.x = (960 - t.size.x) / 2.0
	await get_tree().create_timer(sec).timeout
	if is_instance_valid(t):
		var tw := t.create_tween()
		tw.tween_property(t, "modulate:a", 0.0, 0.4)
		tw.tween_callback(t.queue_free)


func banner(text: String) -> void:
	var b := Win.make(ui, 0, 22)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.modulate = Color("fff3c4")
	b.add_child(l)
	await get_tree().process_frame
	b.position.x = (960 - b.size.x) / 2.0
	await get_tree().create_timer(1.8).timeout
	if is_instance_valid(b):
		var tw := b.create_tween()
		tw.tween_property(b, "modulate:a", 0.0, 0.8)
		tw.tween_callback(b.queue_free)


func hash2(x: int, y: int) -> int:
	var h := (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return (h ^ (h >> 16)) & 0x7FFFFFFF


# ---------- State & simpan ----------
func new_game() -> void:
	party = []
	for id in ["kael", "rina", "lyra"]:
		party.append(Data.new_member(id))
	items = {"ramuan": 3, "penawar": 1}
	gold = 150
	flags = {"chests": {}}
	play_time = 0.0


func save_game() -> bool:
	var d := {
		"v": 1, "gold": gold, "items": items, "flags": flags, "time": play_time,
		"map": world.map_id, "x": world.px, "y": world.py, "f": world.facing,
		"party": party.map(func(m): return m.to_save()),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d))
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> Dictionary:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	gold = int(d["gold"])
	items = {}
	for k in d["items"]:
		items[k] = int(d["items"][k])
	flags = d["flags"]
	if not flags.has("chests"):
		flags["chests"] = {}
	play_time = float(d["time"])
	party = []
	for p in d["party"]:
		var m := Data.new_member(p["id"])
		m.lvl = int(p["lvl"])
		m.xp = int(p["xp"])
		m.weapon = p["weapon"]
		m.armor = p["armor"]
		m.burst = float(p["burst"])
		Data.refresh_stats(m)
		m.hp = mini(int(p["hp"]), m.s["maxHp"])
		m.mp = mini(int(p["mp"]), m.s["maxMp"])
		party.append(m)
	return d


# ---------- Adegan ----------
func set_scene(s: String) -> void:
	scene = s
	title_bg.visible = s == "title" or s == "ending"
	world.visible = s == "world" or s == "trans"
	if s != "battle" and s != "gameover":
		battle.visible = false


func enter_world(map: String, x: int, y: int, f: String) -> void:
	clear_ui()
	world.load_map(map, x, y, f)
	push_input(world)
	world.busy = false
	set_scene("world")


func show_title() -> void:
	clear_ui()
	set_scene("title")
	Snd.play("title")
	var box := Win.make(ui, 385, 330, 190)
	var can := has_save()
	var on_select := func(it: Dictionary, _i: int) -> void:
		input_stack.clear()
		if it["value"] == "new":
			intro()
		else:
			continue_game()
	ListMenu.make(box, [{"label": "Mulai Baru", "value": "new"}, {"label": "Lanjutkan", "value": "load", "disabled": not can}], {
		"start": 1 if can else 0, "on_select": on_select})
	var help := Label.new()
	help.text = "Panah / WASD: gerak   •   Enter / Z: pilih   •   Esc / X: batal & menu   •   M: suara"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 13)
	help.position = Vector2(0, 508)
	help.size = Vector2(960, 20)
	ui.add_child(help)


func continue_game() -> void:
	await fade_to(1.0, 0.5)
	var d := load_game()
	enter_world(d["map"], int(d["x"]), int(d["y"]), d["f"])
	await fade_to(0.0, 0.5)
	banner(world.def["name"])


func _story(lines: Array, delay: float, hint_text: String) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.position = Vector2(110, 0)
	vb.size = Vector2(740, 540)
	vb.add_theme_constant_override("separation", 14)
	ui.add_child(vb)
	var all := lines.duplicate()
	all.append(hint_text)
	for i in all.size():
		var l := Label.new()
		l.text = all[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 740
		var last: bool = i == all.size() - 1
		l.add_theme_font_size_override("font_size", 13 if last else 20)
		l.modulate = Color(0.68, 0.71, 0.92, 0) if last else Color(1, 1, 1, 0)
		vb.add_child(l)
		var tw := l.create_tween()
		tw.tween_interval(i * delay)
		tw.tween_property(l, "modulate:a", 1.0, 1.0)
	return vb


func intro() -> void:
	await fade_to(1.0, 0.7)
	clear_ui()
	set_scene("black")
	_story([
		"Di kaki Pegunungan Biru, berdiri sebuah desa damai bernama Lembah Angin.",
		"Namun sejak bulan lalu, kabut ungu merayap keluar dari Gua Kabut di timur.",
		"Tanaman layu. Monster mengamuk. Warga jatuh sakit satu per satu.",
		"Pada suatu pagi, tiga pengembara tiba di gerbang desa...",
		"Kael si pendekar pedang, Rina si petarung, dan Lyra si penyihir angin.",
	], 1.4, "Tekan Enter untuk melanjutkan ▶")
	await fade_to(0.0, 0.6)
	await wait_ok()
	await fade_to(1.0, 0.6)
	new_game()
	enter_world("town", 12, 10, "up")
	await fade_to(0.0, 0.7)
	banner(world.def["name"])
	world.busy = true
	await elder_talk()
	world.busy = false
	world.bump_lock = true


func encounter(zone: String) -> void:
	var z: Dictionary = WorldMap.ZONES[zone]
	run_battle(Data.ENCOUNTERS[z["table"]].pick_random(), z["bg"])


func run_battle(group: Array, bg: String, opts := {}) -> String:
	world.busy = true
	set_scene("trans")
	Snd.stop_music()
	Snd.sfx("encounter")
	for i in 3:
		await fade_to(0.85, 0.07, Color.WHITE)
		await fade_to(0.0, 0.07, Color.WHITE)
	await fade_to(1.0, 0.25)
	clear_ui()
	set_scene("battle")
	battle.start(group, bg, opts)
	await fade_to(0.0, 0.3)
	var r: String = await battle.finished
	if r == "lose":
		await fade_to(1.0, 0.9)
		battle.teardown()
		await game_over()
		return r
	await fade_to(1.0, 0.35)
	battle.teardown()
	clear_ui()
	push_input(world)
	set_scene("world")
	if not opts.get("boss", false):
		Snd.play(world.def["music"])
	await fade_to(0.0, 0.35)
	world.busy = false
	world.bump_lock = true
	return r


func game_over() -> void:
	clear_ui()
	set_scene("gameover")
	Snd.play("gameover")
	var l := Label.new()
	l.text = "GAME OVER"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 60)
	l.modulate = Color("d84040")
	l.position = Vector2(0, 150)
	l.size = Vector2(960, 80)
	ui.add_child(l)
	await fade_to(0.0, 0.8)
	var can := has_save()
	var box := Win.make(ui, 380, 300, 200)
	var w := Waiter.new()
	ListMenu.make(box, [{"label": "Muat Simpanan", "value": "load", "disabled": not can}, {"label": "Ke Layar Judul", "value": "title"}], {
		"start": 0 if can else 1, "on_select": func(it, _i): w.done.emit(it["value"])})
	var v: String = await w.done
	await fade_to(1.0, 0.6)
	if v == "load":
		var d := load_game()
		enter_world(d["map"], int(d["x"]), int(d["y"]), d["f"])
	else:
		show_title()
	await fade_to(0.0, 0.6)


func ending() -> void:
	world.busy = true
	await fade_to(1.0, 1.5, Color.WHITE)
	clear_ui()
	set_scene("ending")
	Snd.play("title")
	_story([
		"Wyrm Kabut tumbang, dan kabut ungu perlahan memudar dari Gua Kabut.",
		"Untuk pertama kalinya dalam berbulan-bulan, matahari menyinari Desa Lembah Angin.",
		"Warga bersorak. Tetua Baram menjuluki ketiga pengembara itu sebagai \"Penjaga Lembah\".",
		"Namun Kael, Rina, dan Lyra tahu... perjalanan mereka baru saja dimulai.",
	], 1.8, "Tekan Enter ▶")
	await fade_to(0.0, 1.5, Color.WHITE)
	await wait_ok()
	clear_ui()
	var lv := []
	for m in party:
		lv.append("%s Lv %d" % [m.display_name(), m.lvl])
	var vb := _story([
		"Terima kasih telah bermain Legenda Lembah Angin!",
		"%s  —  Waktu bermain %s" % ["  •  ".join(lv), Menus.fmt_time(play_time)],
		"Progres telah disimpan. Kamu bisa melanjutkan untuk menjelajah dan naik level.",
	], 1.0, "Tekan Enter untuk kembali ke layar judul ▶")
	var title := Label.new()
	title.text = "TAMAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.modulate = Color("ffe9a0")
	vb.add_child(title)
	vb.move_child(title, 0)
	world.set_facing("down")
	save_game()
	await wait_ok()
	await fade_to(1.0, 0.8)
	show_title()
	await fade_to(0.0, 0.8)


# ---------- Cerita & interaksi ----------
func npc_talk(kind: String) -> void:
	if kind == "elder":
		await elder_talk()
	elif kind == "ranger":
		await ranger_talk()


func elder_talk() -> void:
	var E := "Tetua Baram"
	if not flags.get("metElder", false):
		flags["metElder"] = true
		await say([
			{"s": E, "t": "Oh! Kalian para pengembara yang datang dari utara? Syukurlah... desa kami sedang dalam bahaya besar."},
			{"s": E, "t": "Sejak bulan lalu, kabut ungu merayap keluar dari Gua Kabut di timur. Monster menjadi buas, dan warga jatuh sakit."},
			{"s": E, "t": "Konon di dasar gua itu tidur Wyrm Kabut, naga purba yang kini terbangun. Dialah sumber kabut terkutuk ini."},
			{"s": "Kael", "t": "Serahkan pada kami, Tetua. Kami akan menghentikannya."},
			{"s": "Rina", "t": "Hmph, naga ya? Tinjuku sudah gatal!"},
			{"s": "Lyra", "t": "Tapi kita harus bersiap dulu. Bertarung dengan monster di padang akan membuat kita lebih kuat."},
			{"s": E, "t": "Terimalah bekal ini. Belilah perlengkapan di toko, dan beristirahatlah di penginapan bila lelah."},
		])
		gold += 100
		Data.add_item("ramuan", 2)
		Snd.sfx("chest")
		await say(["Menerima 100 Gold dan Ramuan x2!"])
		await say([{"s": E, "t": "Gua Kabut ada di timur. Ikuti jalan setapak, seberangi jembatan, lalu belok ke utara. Semoga angin melindungi kalian!"}])
	elif not flags.get("boss", false):
		await say([{"s": E, "t": [
			"Jalan setapak aman dari monster. Kalau ingin berlatih, berjalanlah di rumput.",
			"Monster di Hutan Kelam di tenggara lebih kuat, tapi memberi lebih banyak EXP dan Gold.",
			"Bar BURST terisi saat kalian terkena serangan. Saat penuh, keluarkan jurus pamungkas kalian!",
			"Setiap monster punya kelemahan. Api, Es, atau Petir... amatilah baik-baik.",
			"Di dalam gua ada kristal biru bercahaya. Sentuhlah untuk memulihkan diri dan menyimpan perjalanan.",
			"Kudengar Wyrm Kabut sangat kuat. Sebaiknya capai setidaknya Level 8 sebelum menantangnya.",
		].pick_random()}])
	else:
		await say([{"s": E, "t": "Kabut telah sirna berkat kalian. Desa ini berutang budi selamanya, wahai Penjaga Lembah!"}])


func ranger_talk() -> void:
	var A := "Arga"
	if not flags.get("metRanger", false):
		flags["metRanger"] = true
		await say([
			{"s": A, "t": "Ugh... kalian hendak menantang Wyrm itu? Aku sudah mencoba... dan beginilah jadinya."},
			{"s": A, "t": "Dengar baik-baik. Sisiknya keras, tapi ia lemah terhadap PETIR. Kilat dan Pedang Petir akan sangat berguna."},
			{"s": A, "t": "Napas kabutnya menyerang semua orang sekaligus. Siapkan banyak penyembuh."},
			{"s": A, "t": "Ambil ini. Aku sudah tidak membutuhkannya."},
		])
		Data.add_item("ramuanSuper", 1)
		Snd.sfx("chest")
		await say(["Menerima Ramuan Super x1!"])
	else:
		await say([{"s": A, "t": "Kristal biru di persimpangan utara akan memulihkan kalian. Semoga berhasil..."}])


func boss_event(e: Dictionary) -> void:
	await say([
		{"s": "???", "t": "...Siapa yang berani mengusik tidurku?"},
		{"s": "Wyrm Kabut", "t": "Manusia kecil... Kabutku akan menelan seluruh lembah ini, dan kalian bersamanya!"},
		{"s": "Kael", "t": "Tidak akan kami biarkan! Rina, Lyra, bersiap!"},
	])
	var r: String = await run_battle(["wyrm"], "boss", {"boss": true, "music": "boss"})
	if r == "win":
		flags["boss"] = true
		world.ents.erase(e)
		await ending()


func open_chest(e: Dictionary) -> void:
	if flags["chests"].has(e["id"]):
		await say(["Peti ini sudah kosong."])
		return
	flags["chests"][e["id"]] = true
	Snd.sfx("chest")
	var msgs := []
	if e.has("gold"):
		gold += int(e["gold"])
		msgs.append("Mendapat %d Gold!" % e["gold"])
	for pair in e.get("items", []):
		Data.add_item(pair[0], pair[1])
		msgs.append("Mendapat %s x%d!" % [Data.ITEMS[pair[0]]["name"], pair[1]])
	if e.has("equip"):
		msgs.append(" ".join(Data.gain_equip(e["equip"])))
	await say(msgs)


func door_action(kind: String) -> void:
	match kind:
		"shop": await Menus.open_shop()
		"inn": await Menus.open_inn()
		"elder": await say(["Rumah Tetua Baram. Pintunya terkunci, Tetua sedang berada di alun-alun desa."])
		_: await say(["Pintunya terkunci. Terdengar suara dengkuran dari dalam..."])


# ---------- Latar layar judul ----------
func _draw_title_bg() -> void:
	var n := title_bg
	var t := _title_t
	var stops := [Color("0d0b2a"), Color("3a2a6a"), Color("c86a6a"), Color("f2b880")]
	var ys := [0.0, 243.0, 405.0, 540.0]
	for i in 3:
		n.draw_polygon(PackedVector2Array([Vector2(0, ys[i]), Vector2(960, ys[i]), Vector2(960, ys[i + 1]), Vector2(0, ys[i + 1])]),
			PackedColorArray([stops[i], stops[i], stops[i + 1], stops[i + 1]]))
	for s in _stars:
		var a := 0.3 + 0.7 * absf(sin(t * (0.5 + s.z) + s.z * 10.0))
		n.draw_rect(Rect2(s.x, s.y, 2, 2), Color(1, 1, 1, a))
	var cols := [Color("4a3a78"), Color("2e2452"), Color("191433")]
	for li in 3:
		var hs: Array = _hills[li]
		var speed := 6.0 + li * 10.0
		var base := 330.0 + li * 60.0
		var amp := 110.0 - li * 25.0
		var seg := 960.0 / 16.0
		var off := fmod(t * speed, seg * hs.size())
		var pts := PackedVector2Array([Vector2(0, 540)])
		for i in 18:
			var gi := int(off / seg) + i
			pts.append(Vector2(i * seg - fmod(off, seg), base - hs[gi % hs.size()] * amp))
		pts.append(Vector2(960, 540))
		n.draw_colored_polygon(pts, cols[li])
		n.draw_rect(Rect2(0, base - 10 + sin(t * 0.4 + li) * 6, 960, 30), Color(0.9, 0.78, 1.0, 0.05 + li * 0.02))
	if scene != "title":
		return
	var font := ThemeDB.fallback_font
	n.draw_string(font, Vector2(0, 118), "~ Legenda ~", HORIZONTAL_ALIGNMENT_CENTER, 960, 24, Color("ffe9b0"))
	n.draw_string_outline(font, Vector2(0, 196), "LEMBAH ANGIN", HORIZONTAL_ALIGNMENT_CENTER, 960, 70, 12, Color("2a1408"))
	n.draw_string(font, Vector2(0, 196), "LEMBAH ANGIN", HORIZONTAL_ALIGNMENT_CENTER, 960, 70, Color("ffd060"))
	n.draw_string(font, Vector2(0, 232), "Sebuah Petualangan RPG Turn-Based", HORIZONTAL_ALIGNMENT_CENTER, 960, 17, Color("f0e0ff"))
	var heroes := ["kael", "rina", "lyra"]
	for i in 3:
		n.draw_texture_rect(Art.sprite(heroes[i], false, true), Rect2(480 - 110 + i * 76, 248 + sin(t * 2.0 + i) * 3.0, 48, 54), false)
