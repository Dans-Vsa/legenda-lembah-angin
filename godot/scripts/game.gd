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
var ui: Control
var fade: ColorRect
var hint: Label
var _selftest: RefCounted

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const STORY_SCENE := "res://scenes/ui/story_screen.tscn"
const GAMEOVER_SCENE := "res://scenes/ui/game_over.tscn"
const DIALOG_SCENE := "res://scenes/ui/dialog_box.tscn"
const CHOICE_SCENE := "res://scenes/ui/choice_box.tscn"
const NOTICE_SCENE := "res://scenes/ui/notice.tscn"


func setup(main_node: Node2D) -> void:
	main = main_node
	world = main.get_node("World")
	battle = main.get_node("BattleLayer/Battle")
	ui = main.get_node("UILayer/UI")
	fade = main.get_node("FadeLayer/Fade")
	hint = main.get_node("HintLayer/Hint")
	world.visible = false
	for arg in ["--selftest", "--shots", "--preview-scenes"]:
		if arg in OS.get_cmdline_user_args():
			var t: GDScript = load("res://tests/%s.gd" % {"--selftest": "selftest", "--shots": "shots", "--preview-scenes": "preview_scenes"}[arg])
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
	var d: Control = load(DIALOG_SCENE).instantiate()
	ui.add_child(d)
	var txt: Label = d.get_node("Box/Text")
	var tag: Control = d.get_node("NameTag")
	var tag_l: Label = d.get_node("NameTag/Name")
	var more: Label = d.get_node("More")
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
		tag.size = Vector2.ZERO
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
	d.queue_free()


func ask(text: String, options: Array) -> int:
	var d: Control = load(CHOICE_SCENE).instantiate()
	ui.add_child(d)
	d.get_node("Box/Text").text = text
	var cw: Control = d.get_node("ChoiceWin")
	cw.position.y = 388 - 22 - options.size() * 25
	var w := Waiter.new()
	var opts := []
	for i in options.size():
		opts.append({"label": options[i], "value": i})
	var m: ListMenu = d.get_node("ChoiceWin/Choices")
	m.setup(opts, {"on_select": func(it, _i): w.done.emit(it["value"]), "on_cancel": func(): w.done.emit(-1)})
	var r: int = await w.done
	m.deactivate()
	d.queue_free()
	return r


func toast(text: String, sec := 1.8) -> void:
	await _notice(text, 16, Color.WHITE, 14, sec, 0.4)


func banner(text: String) -> void:
	await _notice(text, 20, Color("fff3c4"), 22, 1.8, 0.8)


func _notice(text: String, size: int, col: Color, y: float, sec: float, fade_sec: float) -> void:
	var n: Control = load(NOTICE_SCENE).instantiate()
	var l: Label = n.get_node("Text")
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.modulate = col
	ui.add_child(n)
	await get_tree().process_frame
	if not is_instance_valid(n):
		return
	n.size = Vector2.ZERO
	n.position = Vector2((960 - n.size.x) / 2.0, y)
	await get_tree().create_timer(sec).timeout
	if is_instance_valid(n):
		var tw := n.create_tween()
		tw.tween_property(n, "modulate:a", 0.0, fade_sec)
		tw.tween_callback(n.queue_free)


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
	var title: Control = load(TITLE_SCENE).instantiate()
	ui.add_child(title)
	var can := has_save()
	var on_select := func(it: Dictionary, _i: int) -> void:
		input_stack.clear()
		if it["value"] == "new":
			intro()
		else:
			continue_game()
	title.get_node("MenuWin/Menu").setup([{"label": "Mulai Baru", "value": "new"}, {"label": "Lanjutkan", "value": "load", "disabled": not can}], {
		"start": 1 if can else 0, "on_select": on_select})


func continue_game() -> void:
	await fade_to(1.0, 0.5)
	var d := load_game()
	enter_world(d["map"], int(d["x"]), int(d["y"]), d["f"])
	await fade_to(0.0, 0.5)
	banner(world.def["name"])


func _story(lines: Array, delay: float, hint_text: String, with_bg := false) -> VBoxContainer:
	var story: Control = load(STORY_SCENE).instantiate()
	ui.add_child(story)
	story.get_node("Background").visible = with_bg
	story.get_node("Black").visible = not with_bg
	var vb: VBoxContainer = story.get_node("Lines")
	for c in vb.get_children():
		vb.remove_child(c)
		c.queue_free()
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
	var go: Control = load(GAMEOVER_SCENE).instantiate()
	ui.add_child(go)
	await fade_to(0.0, 0.8)
	var can := has_save()
	var w := Waiter.new()
	var menu: ListMenu = go.get_node("MenuWin/Menu")
	menu.setup([{"label": "Muat Simpanan", "value": "load", "disabled": not can}, {"label": "Ke Layar Judul", "value": "title"}], {
		"start": 0 if can else 1, "on_select": func(it, _i): w.done.emit(it["value"])})
	var v: String = await w.done
	menu.deactivate()
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
	], 1.8, "Tekan Enter ▶", true)
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
	], 1.0, "Tekan Enter untuk kembali ke layar judul ▶", true)
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


func boss_event(e: MapEntity) -> void:
	await say([
		{"s": "???", "t": "...Siapa yang berani mengusik tidurku?"},
		{"s": "Wyrm Kabut", "t": "Manusia kecil... Kabutku akan menelan seluruh lembah ini, dan kalian bersamanya!"},
		{"s": "Kael", "t": "Tidak akan kami biarkan! Rina, Lyra, bersiap!"},
	])
	var r: String = await run_battle(["wyrm"], "boss", {"boss": true, "music": "boss"})
	if r == "win":
		flags["boss"] = true
		world.remove_entity(e)
		await ending()


func open_chest(e: MapChest) -> void:
	var key := e.key()
	if flags["chests"].has(key):
		await say(["Peti ini sudah kosong."])
		return
	flags["chests"][key] = true
	e.set_opened(true)
	Snd.sfx("chest")
	var msgs := []
	if e.gold > 0:
		gold += e.gold
		msgs.append("Mendapat %d Gold!" % e.gold)
	for id in e.items:
		var n := int(e.items[id])
		Data.add_item(id, n)
		msgs.append("Mendapat %s x%d!" % [Data.ITEMS[id]["name"], n])
	if e.equip != "":
		msgs.append(" ".join(Data.gain_equip(e.equip)))
	await say(msgs)


func door_action(kind: String) -> void:
	match kind:
		"shop": await Menus.open_shop()
		"inn": await Menus.open_inn()
		"elder": await say(["Rumah Tetua Baram. Pintunya terkunci, Tetua sedang berada di alun-alun desa."])
		_: await say(["Pintunya terkunci. Terdengar suara dengkuran dari dalam..."])
