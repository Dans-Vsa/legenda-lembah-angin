class_name WorldMap
extends Node2D
## Eksplorasi (scene world.tscn): memuat peta dari res://maps/ ke MapHolder,
## menaruh Player di dalam Objects peta, lalu mengurus pergerakan grid,
## interaksi, warp, kamera, dan encounter acak.

const TILE := 32
const DIRS := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}
const BLOCK := "TPM~rRwnd|F#K"
const ZONES := {
	"grass": {"rate": 0.06, "bg": "field", "table": "grass"},
	"forest": {"rate": 0.1, "bg": "forest", "table": "forest"},
	"cave": {"rate": 0.08, "bg": "cave", "table": "cave"},
}
const PLAYER_SCENE := "res://scenes/actors/player.tscn"

var map_id := ""
var def := {}
var grid: Array = []
var w := 0
var h := 0
var ents: Array = []
var player: PlayerActor
var px := 0
var py := 0
var rx := 0.0
var ry := 0.0
var facing := "down"
var moving := {}
var steps := 0
var busy := false
var bump_lock := false
var anim_t := 0.0

var _map: GameMap
@onready var _holder: Node2D = $MapHolder
@onready var _dark: Sprite2D = $Darkness
@onready var _cam: Camera2D = $Camera2D


func _ready() -> void:
	# Peta pratinjau di MapHolder hanya untuk editor.
	for c in _holder.get_children():
		_holder.remove_child(c)
		c.queue_free()


# ---------- Membaca peta ----------
static func read_map(id: String) -> Dictionary:
	var m: GameMap = load("res://maps/%s.tscn" % id).instantiate()
	var out := read_map_node(m)
	out["node"] = m
	return out


static func read_map_node(m: GameMap) -> Dictionary:
	var ground: TileMapLayer = m.get_node("Ground")
	var used := ground.get_used_rect()
	var rows := []
	for y in used.end.y:
		var row := ""
		for x in used.end.x:
			var td := ground.get_cell_tile_data(Vector2i(x, y))
			row += str(td.get_custom_data("ch")) if td else m.pad
		rows.append(row)
	var d := {"name": m.map_name, "music": m.music, "dark": m.dark, "zone": m.zones, "rows": rows, "ents": [], "warps": {}, "doors": {}}
	for n in m.get_node("Objects").get_children():
		if n is MapEntity:
			d["ents"].append(n.to_entity())
	for n in m.get_node("Warps").get_children():
		if n is MapWarp:
			var c: Vector2i = n.cell()
			d["warps"]["%d,%d" % [c.x, c.y]] = n.to_warp()
	for n in m.get_node("Doors").get_children():
		if n is MapDoor:
			var c2: Vector2i = n.cell()
			d["doors"]["%d,%d" % [c2.x, c2.y]] = n.kind
	return d


# ---------- Memuat peta ----------
func load_map(id: String, x: int, y: int, f: String) -> void:
	if _map:
		_holder.remove_child(_map)
		_map.queue_free()
	_map = load("res://maps/%s.tscn" % id).instantiate()
	_holder.add_child(_map)
	def = read_map_node(_map)
	map_id = id
	grid = def["rows"]
	h = grid.size()
	w = grid[0].length() if h > 0 else 0
	var objects: Node2D = _map.get_node("Objects")
	ents = []
	for n in objects.get_children():
		if not n is MapEntity:
			continue
		if n is MapBoss and Game.flags.get("boss", false):
			n.queue_free()
			continue
		n.grid = n.cell()
		n.home = n.grid
		n.position = Vector2(n.grid * TILE)
		n.wt = randf_range(1.0, 3.0)
		if n is MapChest:
			n.set_opened(Game.flags["chests"].has(n.key()))
		ents.append(n)
	player = load(PLAYER_SCENE).instantiate()
	objects.add_child(player)
	px = x
	py = y
	rx = x * TILE
	ry = y * TILE
	player.position = Vector2(rx, ry)
	set_facing(f)
	moving = {}
	steps = 0
	bump_lock = true
	_dark.visible = def["dark"]
	Snd.play(def["music"])
	_update_camera()


func tile_at(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= w or y >= h:
		return "#"
	return grid[y][x]


func ent_at(x: int, y: int) -> MapEntity:
	for e in ents:
		if is_instance_valid(e) and e.grid == Vector2i(x, y):
			return e
	return null


func walkable(x: int, y: int) -> bool:
	return not (tile_at(x, y) in BLOCK) and ent_at(x, y) == null


func set_facing(d: String) -> void:
	facing = d
	if d == "left":
		player.set_flip(false)
	elif d == "right":
		player.set_flip(true)


# ---------- Update ----------
func update(dt: float) -> void:
	for e in ents:
		if not is_instance_valid(e):
			continue
		if e is MapNpc and e.wander and not busy:
			e.wt -= dt
			if e.wt <= 0.0:
				e.wt = randf_range(1.5, 3.5)
				var d: Vector2i = DIRS.values().pick_random()
				var n: Vector2i = e.grid + d
				if absi(n.x - e.home.x) <= 2 and absi(n.y - e.home.y) <= 2 and walkable(n.x, n.y) and not (n.x == px and n.y == py):
					e.grid = n
					if d.x != 0:
						e.set_flip(d.x > 0)
		e.position = e.position.lerp(Vector2(e.grid * TILE), minf(1.0, dt * 8.0))
	if not moving.is_empty():
		moving["t"] += dt
		anim_t += dt
		var k := minf(1.0, moving["t"] / 0.15)
		rx = lerpf(moving["fx"], px * TILE, k)
		ry = lerpf(moving["fy"], py * TILE, k)
		player.position = Vector2(rx, ry)
		player.set_step(true, anim_t)
		_update_camera()
		if k >= 1.0:
			moving = {}
			player.set_step(false, 0)
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
		_touch(nx, ny)


func _touch(x: int, y: int) -> void:
	var e := ent_at(x, y)
	if e:
		interact(e)
	elif def["doors"].has("%d,%d" % [x, y]):
		use_door(def["doors"]["%d,%d" % [x, y]])


func _arrive() -> void:
	var key := "%d,%d" % [px, py]
	if def["warps"].has(key):
		warp(def["warps"][key])
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
		_touch(px + dv.x, py + dv.y)
	elif a == "cancel" or a == "menu":
		Menus.field_menu()


func interact(e: MapEntity) -> void:
	busy = true
	if e is MapNpc:
		e.set_flip(px > e.grid.x)
		if e.talk != "":
			await Game.npc_talk(e.talk)
		else:
			var lines: Array = Array(e.lines) if e.lines.size() > 0 else ["..."]
			e.li = (e.li + 1) % lines.size()
			await Game.say([{"s": e.npc_name, "t": lines[e.li]}])
	elif e is MapChest:
		await Game.open_chest(e)
	elif e is MapCrystal:
		await Menus.save_crystal()
	elif e is MapBoss:
		await Game.boss_event(e)
	elif e is MapSign:
		await Game.say(Array(e.lines))
	if Game.scene == "world":
		busy = false
		bump_lock = true


func remove_entity(e: MapEntity) -> void:
	ents.erase(e)
	e.queue_free()


func use_door(kind: String) -> void:
	busy = true
	await Game.door_action(kind)
	if Game.scene == "world":
		busy = false
		bump_lock = true


# ---------- Kamera ----------
func _update_camera() -> void:
	var mw := w * TILE
	var mh := h * TILE
	var cx := -(960.0 - mw) / 2.0 if mw <= 960 else clampf(rx + 16 - 480.0, 0, mw - 960.0)
	var cy := -(540.0 - mh) / 2.0 if mh <= 540 else clampf(ry + 16 - 270.0, 0, mh - 540.0)
	_cam.position = Vector2(roundf(cx) + 480.0, roundf(cy) + 270.0)
	_dark.position = Vector2(rx + 16, ry + 16)
