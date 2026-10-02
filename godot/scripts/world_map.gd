class_name WorldMap
extends Node2D
## Peta eksplorasi: tile, pergerakan grid, NPC, peti, pintu, warp, dan encounter acak.

const TILE := 32
const DIRS := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}
const BLOCK := "TPM~rRwnd|F#K"
const ANIMATED := "~=F"
const ZONES := {
	"grass": {"rate": 0.06, "bg": "field", "table": "grass"},
	"forest": {"rate": 0.1, "bg": "forest", "table": "forest"},
	"cave": {"rate": 0.08, "bg": "cave", "table": "cave"},
}

var maps := {}
var map_id := ""
var def := {}
var grid: Array = []
var w := 0
var h := 0
var ents: Array = []
var px := 0
var py := 0
var rx := 0.0
var ry := 0.0
var facing := "down"
var flip := false
var moving := {}
var steps := 0
var busy := false
var bump_lock := false
var anim_t := 0.0
var t := 0.0

var _tiles: Node2D
var _water: Node2D
var _ents: Node2D
var _dark: Sprite2D
var _water_frame := 0


func _init() -> void:
	_tiles = Node2D.new()
	_water = Node2D.new()
	_ents = Node2D.new()
	add_child(_tiles)
	add_child(_water)
	add_child(_ents)
	_tiles.draw.connect(_draw_tiles)
	_water.draw.connect(_draw_water)
	_ents.draw.connect(_draw_ents)
	_dark = Sprite2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.14, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0.05, 0.02, 0.09, 0), Color(0.05, 0.02, 0.09, 0), Color(0.05, 0.02, 0.09, 0.78), Color(0.05, 0.02, 0.09, 0.78)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 1024
	gt.height = 1024
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	_dark.texture = gt
	add_child(_dark)
	_define_maps()


# ---------- Definisi peta ----------
func _define_maps() -> void:
	maps["town"] = {
		"name": "Desa Lembah Angin", "music": "town", "pad": "T",
		"rows": [
			"TTTTTTTTTTTTTTTTTTTTTTTTTT",
			"T..:.......TTT.......:...T",
			"T.rrrrr...........RRRRR..T",
			"T.rrrrr...........RRRRR..T",
			"T.wndnw...........wnwdw..T",
			"T...c......ccc.......c...T",
			"T...cccccccccccccccccc...T",
			"T..........cFc...........T",
			"T...:......ccc......:....T",
			"T.rrrrr.....c.....rrrrr..T",
			"T.rrrrr.....c.....rrrrr..T",
			"T.wdnnw.....c.....wnndw..T",
			"T..c........c........c...T",
			"T..ccccccccccccccccccc...T",
			"T..:........c.........:..T",
			"T||||||||...c...|||||||||T",
			"T...........,............T",
			"TTTTTTTTTTTT,TTTTTTTTTTTTT",
		],
		"doors": {"4,4": "elder", "21,4": "shop", "3,11": "inn", "21,11": "locked"},
		"warps": {"12,17": {"map": "world", "x": 8, "y": 18, "f": "right"}},
		"labels": [[4.5, 2.55, "TETUA"], [20.5, 2.55, "TOKO"], [4.5, 9.55, "PENGINAPAN"]],
		"ents": [
			{"type": "npc", "x": 10, "y": 8, "spr": "elder", "name": "Tetua Baram", "talk": "elder"},
			{"type": "npc", "x": 16, "y": 10, "spr": "kid", "name": "Dodi", "wander": true, "lines": [
				"Kata ayah, jangan main di rumput tinggi. Banyak monster!",
				"Kakak mau ke gua? Wah, keren! Aku juga mau jadi petualang kalau sudah besar!"]},
			{"type": "npc", "x": 19, "y": 7, "spr": "woman", "name": "Bu Sari", "lines": [
				"Penginapan ada di barat daya desa. Semalam cuma 20 Gold, dan kalian akan pulih sepenuhnya.",
				"Toko Pak Darmo di timur laut menjual ramuan dan perlengkapan. Senjata baru sangat membantu!"]},
			{"type": "npc", "x": 10, "y": 15, "spr": "guard", "name": "Penjaga Desa", "lines": [
				"Jalan setapak itu aman dari monster. Tapi rumput di kiri-kanannya... hati-hati.",
				"Tekan Esc atau X untuk membuka menu. Jangan lupa menyimpan permainan!"]},
			{"type": "chest", "id": "t1", "x": 24, "y": 1, "items": [["ramuan", 2]]},
		],
	}
	maps["world"] = {
		"name": "Padang Angin", "music": "field", "pad": "M", "rows": _gen_world(),
		"zone": {".": "grass", ":": "grass", "f": "forest"},
		"warps": {"7,18": {"map": "town", "x": 12, "y": 16, "f": "up"}, "41,12": {"map": "cave", "x": 15, "y": 21, "f": "up"}},
		"ents": [
			{"type": "sign", "x": 9, "y": 17, "lines": ["← Desa Lembah Angin        Gua Kabut →\n(Seberangi jembatan, lalu belok ke utara)"]},
			{"type": "sign", "x": 40, "y": 15, "lines": ["GUA KABUT — Monster kuat bersarang di dalam. Bersiaplah dengan baik!"]},
			{"type": "sign", "x": 33, "y": 19, "lines": ["HUTAN KELAM — Monster di sini lebih kuat. Konon ada harta karun tersembunyi di dalamnya..."]},
			{"type": "chest", "id": "w1", "x": 43, "y": 30, "gold": 300, "items": [["eter", 2]]},
			{"type": "chest", "id": "w2", "x": 12, "y": 30, "items": [["ramuan", 3]]},
		],
	}
	maps["cave"] = {
		"name": "Gua Kabut", "music": "cave", "pad": "#", "dark": true,
		"zone": {"g": "cave"},
		"rows": [
			"################################",
			"#############gggg###############",
			"###########gggggggg#############",
			"##########gggggggggg############",
			"##########ggggggggggK###########",
			"###########gggggggg#############",
			"############gggggg##############",
			"#############gggg###############",
			"#####ggggg#####gg######ggggg####",
			"####gggggggg###gg####ggggggggg##",
			"####gg~~~ggg###gg###gggKgggggg##",
			"###ggg~~~ggggggggggggggggggggg##",
			"###gggggggggggggggggg####gggg###",
			"####ggggK####gg#####g####gggg###",
			"######gg#####gg###ggg####gggg###",
			"######gg####gggg##gg#####ggg####",
			"#####gggg###gggggggg####gggg####",
			"####gggggg##gggggggg###ggggg####",
			"####ggKggg###gggggg#####gggg####",
			"#####gggg#####gggg#######ggg####",
			"##############gggg##############",
			"###############gg###############",
			"###############EE###############",
			"################################",
		],
		"warps": {"15,22": {"map": "world", "x": 41, "y": 13, "f": "down"}, "16,22": {"map": "world", "x": 41, "y": 13, "f": "down"}},
		"ents": [
			{"type": "boss", "x": 14, "y": 4},
			{"type": "crystal", "x": 13, "y": 11},
			{"type": "npc", "x": 17, "y": 17, "spr": "ranger", "name": "Arga", "talk": "ranger"},
			{"type": "chest", "id": "c1", "x": 5, "y": 8, "items": [["ramuanSuper", 2]]},
			{"type": "chest", "id": "c2", "x": 5, "y": 19, "equip": "pedangKristal"},
			{"type": "chest", "id": "c3", "x": 26, "y": 19, "items": [["kristalHidup", 2]]},
			{"type": "chest", "id": "c4", "x": 28, "y": 9, "equip": "sarungNaga"},
			{"type": "chest", "id": "c5", "x": 27, "y": 16, "equip": "tongkatBintang"},
		],
	}


# Padang Angin dibuat prosedural dengan seed tetap, jadi selalu sama.
func _gen_world() -> Array:
	var W := 50
	var H := 36
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var g := []
	for y in H:
		var row := []
		for x in W:
			var v := rng.randf()
			row.append("T" if v < 0.05 else (":" if v < 0.085 else "."))
		g.append(row)
	var set_t := func(x: int, y: int, c: String) -> void:
		if x >= 0 and y >= 0 and x < W and y < H:
			g[y][x] = c
	for y in H:
		for x in W:
			var d := mini(mini(x, y), mini(W - 1 - x, H - 1 - y))
			if d < 2 or (d == 2 and rng.randf() < 0.45):
				g[y][x] = "M"
	for y in range(2, 14):
		for x in range(35, 48):
			if rng.randf() < 0.8:
				g[y][x] = "M"
	for y in H:
		for x in W:
			var dx := (x - 22) / 7.0
			var dy := (y - 7) / 3.6
			if dx * dx + dy * dy < 1.0:
				g[y][x] = "~"
	for y in range(10, H - 2):
		var rxx := 22 + roundi(2.0 * sin(y / 3.0))
		set_t.call(rxx, y, "~")
		set_t.call(rxx + 1, y, "~")
	for y in range(21, 34):
		for x in range(30, 48):
			if g[y][x] != "M":
				g[y][x] = "P" if rng.randf() < 0.22 else "f"
	var path := func(x: int, y: int) -> void:
		set_t.call(x, y, "=" if g[y][x] == "~" else ",")
	for x in range(8, 42):
		path.call(x, 18)
	for y in range(13, 19):
		path.call(41, y)
	for y in range(19, 23):
		path.call(34, y)
	var clear := func(cx: int, cy: int, c: String) -> void:
		for y in range(cy - 1, cy + 2):
			for x in range(cx - 1, cx + 2):
				if not (g[y][x] in [",", "=", "~"]):
					set_t.call(x, y, c)
	clear.call(7, 18, ".")
	set_t.call(7, 18, "V")
	set_t.call(41, 12, "C")
	for p in [[9, 17], [40, 15], [33, 19], [12, 30]]:
		clear.call(p[0], p[1], ".")
	clear.call(43, 30, "f")
	var out := []
	for row in g:
		out.append("".join(row))
	return out


# ---------- Memuat peta ----------
func load_map(id: String, x: int, y: int, f: String) -> void:
	def = maps[id]
	map_id = id
	var rows: Array = def["rows"]
	w = 0
	for r in rows:
		w = maxi(w, r.length())
	grid = []
	for r in rows:
		grid.append(r.rpad(w, def["pad"]))
	h = grid.size()
	ents = []
	for e in def["ents"]:
		if e["type"] == "boss" and Game.flags.get("boss", false):
			continue
		var c: Dictionary = e.duplicate(true)
		c["hx"] = c["x"]
		c["hy"] = c["y"]
		c["rx"] = float(c["x"] * TILE)
		c["ry"] = float(c["y"] * TILE)
		c["wt"] = randf_range(1.0, 3.0)
		c["flip"] = false
		ents.append(c)
	px = x
	py = y
	rx = x * TILE
	ry = y * TILE
	set_facing(f)
	moving = {}
	steps = 0
	bump_lock = true
	_dark.visible = def.get("dark", false)
	_tiles.queue_redraw()
	_water.queue_redraw()
	Snd.play(def["music"])
	_update_camera()


func tile_at(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= w or y >= h:
		return "#"
	return grid[y][x]


func ent_at(x: int, y: int):
	for e in ents:
		if e["x"] == x and e["y"] == y:
			return e
	return null


func walkable(x: int, y: int) -> bool:
	return not (tile_at(x, y) in BLOCK) and ent_at(x, y) == null


func set_facing(d: String) -> void:
	facing = d
	if d == "left":
		flip = false
	elif d == "right":
		flip = true


# ---------- Update ----------
func update(dt: float) -> void:
	t += dt
	var wf := int(t * 2.0) % 2
	if wf != _water_frame:
		_water_frame = wf
		_water.queue_redraw()
	for e in ents:
		if e.get("wander", false) and not busy:
			e["wt"] -= dt
			if e["wt"] <= 0.0:
				e["wt"] = randf_range(1.5, 3.5)
				var d: Vector2i = DIRS.values().pick_random()
				var nx: int = e["x"] + d.x
				var ny: int = e["y"] + d.y
				if absi(nx - e["hx"]) <= 2 and absi(ny - e["hy"]) <= 2 and walkable(nx, ny) and not (nx == px and ny == py):
					e["x"] = nx
					e["y"] = ny
					if d.x != 0:
						e["flip"] = d.x > 0
		e["rx"] += (e["x"] * TILE - e["rx"]) * minf(1.0, dt * 8.0)
		e["ry"] += (e["y"] * TILE - e["ry"]) * minf(1.0, dt * 8.0)
	_ents.queue_redraw()
	if not moving.is_empty():
		moving["t"] += dt
		anim_t += dt
		var k := minf(1.0, moving["t"] / 0.15)
		rx = lerpf(moving["fx"], px * TILE, k)
		ry = lerpf(moving["fy"], py * TILE, k)
		_update_camera()
		if k >= 1.0:
			moving = {}
			_arrive()
		return
	if busy or Game.top_input() != self or Game.scene != "world":
		return
	var dir := ""
	for a in ["up", "down", "left", "right"]:
		if Game.held.has(a):
			dir = a
			break
	if dir == "":
		bump_lock = false
		return
	set_facing(dir)
	var dv: Vector2i = DIRS[dir]
	var nx := px + dv.x
	var ny := py + dv.y
	if walkable(nx, ny):
		moving = {"fx": rx, "fy": ry, "t": 0.0}
		px = nx
		py = ny
	elif not bump_lock:
		bump_lock = true
		var e = ent_at(nx, ny)
		if e != null:
			interact(e)
		elif def.has("doors") and def["doors"].has("%d,%d" % [nx, ny]):
			use_door(def["doors"]["%d,%d" % [nx, ny]])


func _arrive() -> void:
	var key := "%d,%d" % [px, py]
	if def.has("warps") and def["warps"].has(key):
		warp(def["warps"][key])
		return
	if not def.has("zone"):
		return
	var zone: String = def["zone"].get(tile_at(px, py), "")
	if zone == "":
		return
	steps += 1
	if steps >= 7 and randf() < ZONES[zone]["rate"]:
		steps = 0
		Game.encounter(zone)


func warp(wp: Dictionary) -> void:
	busy = true
	await Game.fade_to(1.0, 0.26)
	load_map(wp["map"], wp["x"], wp["y"], wp["f"])
	await Game.fade_to(0.0, 0.26)
	Game.banner(def["name"])
	busy = false


func on_key(a: String) -> void:
	if busy or not moving.is_empty() or Game.scene != "world":
		return
	if a == "ok":
		var dv: Vector2i = DIRS[facing]
		var nx := px + dv.x
		var ny := py + dv.y
		var e = ent_at(nx, ny)
		if e != null:
			interact(e)
		elif def.has("doors") and def["doors"].has("%d,%d" % [nx, ny]):
			use_door(def["doors"]["%d,%d" % [nx, ny]])
	elif a == "cancel" or a == "menu":
		Menus.field_menu()


func interact(e: Dictionary) -> void:
	busy = true
	if e["type"] == "npc":
		e["flip"] = px > e["x"]
	match e["type"]:
		"chest": await Game.open_chest(e)
		"crystal": await Menus.save_crystal()
		"boss": await Game.boss_event(e)
		"sign": await Game.say(e["lines"])
		_:
			if e.has("talk"):
				await Game.npc_talk(e["talk"])
			else:
				var li: int = (e.get("li", -1) + 1) % e["lines"].size()
				e["li"] = li
				await Game.say([{"s": e["name"], "t": e["lines"][li]}])
	if Game.scene == "world":
		busy = false
		bump_lock = true


func use_door(kind: String) -> void:
	busy = true
	await Game.door_action(kind)
	if Game.scene == "world":
		busy = false
		bump_lock = true


# ---------- Kamera & gambar ----------
func _update_camera() -> void:
	var mw := w * TILE
	var mh := h * TILE
	var vw := 960.0
	var vh := 540.0
	var cx := -(vw - mw) / 2.0 if mw <= vw else clampf(rx + 16 - vw / 2.0, 0, mw - vw)
	var cy := -(vh - mh) / 2.0 if mh <= vh else clampf(ry + 16 - vh / 2.0, 0, mh - vh)
	position = Vector2(-roundf(cx), -roundf(cy))
	_dark.position = Vector2(rx + 16, ry + 16)


func _draw_tiles() -> void:
	for y in h:
		for x in w:
			var ch: String = grid[y][x]
			if ch in ANIMATED:
				continue
			_tiles.draw_texture_rect(Art.tile(ch, Game.hash2(x, y) % 4, 0), Rect2(x * TILE, y * TILE, TILE, TILE), false)
	var font := ThemeDB.fallback_font
	for L in def.get("labels", []):
		var pos := Vector2(L[0] * TILE + 16 - 60, L[1] * TILE + 4)
		_tiles.draw_string_outline(font, pos, L[2], HORIZONTAL_ALIGNMENT_CENTER, 120, 11, 4, Color("2a1408"))
		_tiles.draw_string(font, pos, L[2], HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("fff4d0"))


func _draw_water() -> void:
	for y in h:
		for x in w:
			var ch: String = grid[y][x]
			if ch in ANIMATED:
				_water.draw_texture_rect(Art.tile(ch, Game.hash2(x, y) % 4, _water_frame), Rect2(x * TILE, y * TILE, TILE, TILE), false)


func _shadow(x: float, y: float, sw := 22.0) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(x + 16 + cos(a) * sw / 2.0, y + 30 + sin(a) * 4.0))
	_ents.draw_colored_polygon(pts, Color(0, 0, 0, 0.28))


func _draw_ents() -> void:
	var list := []
	for e in ents:
		list.append([e["ry"], e])
	list.append([ry + 0.1, null])
	list.sort_custom(func(a, b): return a[0] < b[0])
	for item in list:
		var e = item[1]
		if e == null:
			var bob := -2.0 if not moving.is_empty() and int(anim_t * 12.0) % 2 == 1 else 0.0
			_shadow(rx, ry)
			_ents.draw_texture_rect(Art.sprite("kael", false, flip), Rect2(rx, ry - 4 + bob, 32, 36), false)
			continue
		var x: float = e["rx"]
		var y: float = e["ry"]
		match e["type"]:
			"chest": _ents.draw_texture_rect(Art.obj("chest", Game.flags["chests"].has(e["id"])), Rect2(x, y, 32, 32), false)
			"sign": _ents.draw_texture_rect(Art.obj("sign"), Rect2(x, y, 32, 32), false)
			"crystal":
				var a := 0.35 + sin(t * 3.0) * 0.15
				for i in 4:
					_ents.draw_circle(Vector2(x + 16, y + 16), 40.0 - i * 9.0, Color(0.55, 0.9, 1.0, a * 0.18))
				_ents.draw_texture_rect(Art.obj("crystal"), Rect2(x, y - 4 + sin(t * 2.0) * 2.0, 32, 32), false)
			"boss":
				for i in 5:
					_ents.draw_circle(Vector2(x + 16, y + 10), 70.0 - i * 12.0, Color(0.67, 0.47, 0.9, 0.07))
				_shadow(x, y, 40)
				_ents.draw_texture_rect(Art.sprite("wyrm"), Rect2(x - 8, y - 20 + sin(t * 1.5) * 2.0, 48, 48), false)
			_:
				_shadow(x, y)
				_ents.draw_texture_rect(Art.sprite(e["spr"], false, e["flip"]), Rect2(x, y - 4, 32, 36), false)
