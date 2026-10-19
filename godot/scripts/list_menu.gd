@tool
class_name ListMenu
extends GridContainer
## Menu daftar yang bisa dipakai keyboard dan mouse.
## Item: {label, right?, value, disabled?, help?, color?, node?}
## Anak yang diletakkan di editor dan isi "preview" hanya untuk pratinjau;
## saat game berjalan isinya diatur lewat setup().

## Teks pratinjau di editor. Format "Label" atau "Label|Kanan".
@export var preview: PackedStringArray = []:
	set(v):
		preview = v
		if Engine.is_editor_hint() and is_node_ready():
			_build_preview()
@export var item_width := 0.0

var items: Array = []
var idx := 0
var active := false
var silent := false
var on_select := Callable()
var on_cancel := Callable()
var on_move := Callable()
var _rows: Array = []
var _cursors: Array = []


static func make(parent: Node, p_items: Array, opts := {}) -> ListMenu:
	var m := ListMenu.new()
	m.add_theme_constant_override("h_separation", 12)
	m.add_theme_constant_override("v_separation", 1)
	parent.add_child(m)
	m.setup(p_items, opts)
	return m


func _ready() -> void:
	if Engine.is_editor_hint():
		_build_preview()
		return
	for c in get_children():
		remove_child(c)
		c.queue_free()


func _build_preview() -> void:
	var list := []
	for p in preview:
		var parts := p.split("|")
		var it := {"label": parts[0]}
		if parts.size() > 1:
			it["right"] = parts[1]
		list.append(it)
	if list.is_empty() and _rows.is_empty():
		return
	set_items(list)
	if _cursors.size() > 0:
		_cursors[0].modulate.a = 1.0


func setup(p_items: Array, opts := {}) -> ListMenu:
	deactivate()
	columns = opts.get("cols", columns)
	idx = opts.get("start", 0)
	silent = opts.get("silent", false)
	item_width = opts.get("item_width", item_width)
	on_select = opts.get("on_select", Callable())
	on_cancel = opts.get("on_cancel", Callable())
	on_move = opts.get("on_move", Callable())
	set_items(p_items)
	if not opts.get("inactive", false):
		activate()
	return self


func set_items(p_items: Array) -> void:
	items = p_items
	for r in _rows:
		if is_instance_valid(r):
			remove_child(r)
			r.queue_free()
	_rows.clear()
	_cursors.clear()
	if idx >= items.size():
		idx = maxi(0, items.size() - 1)
	for i in items.size():
		var it: Dictionary = items[i]
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.custom_minimum_size = Vector2(item_width, 24)
		row.add_theme_constant_override("separation", 6)
		var cur := CursorMark.new()
		cur.custom_minimum_size = Vector2(16, 16)
		cur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cur.modulate.a = 0.0
		row.add_child(cur)
		_cursors.append(cur)
		if it.has("node"):
			var n: Control = it["node"]
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(n)
		else:
			var l := Label.new()
			l.text = str(it.get("label", ""))
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if it.get("disabled", false):
				l.modulate = Color("7d84b8")
			elif it.has("color"):
				l.modulate = it["color"]
			row.add_child(l)
		if it.has("right"):
			var rl := Label.new()
			rl.text = str(it["right"])
			rl.modulate = Color("8a8a6a") if it.get("disabled", false) else Color("ffe9a0")
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(rl)
		var ii := i
		row.mouse_entered.connect(func() -> void:
			if active and idx != ii:
				idx = ii
				_update())
		row.gui_input.connect(func(ev: InputEvent) -> void:
			if active and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				idx = ii
				_update()
				select())
		add_child(row)
		_rows.append(row)
	_update()


func _update() -> void:
	for i in _cursors.size():
		_cursors[i].modulate.a = 1.0 if active and i == idx else 0.0
	if active and idx < items.size() and on_move.is_valid():
		on_move.call(items[idx], idx)


func activate() -> void:
	if active:
		return
	active = true
	Game.push_input(self)
	_update()


func deactivate() -> void:
	if not active:
		return
	active = false
	Game.pop_input(self)
	_update()


func destroy() -> void:
	deactivate()
	queue_free()


func move(d: int) -> void:
	if items.size() < 2:
		return
	idx = (idx + d + items.size()) % items.size()
	Snd.sfx("cursor")
	_update()


func select() -> void:
	if idx >= items.size():
		return
	var it: Dictionary = items[idx]
	if it.get("disabled", false):
		Snd.sfx("buzz")
		return
	if not silent:
		Snd.sfx("ok")
	if on_select.is_valid():
		on_select.call(it, idx)


func on_key(a: String) -> void:
	match a:
		"up": move(-columns)
		"down": move(columns)
		"left":
			if columns > 1: move(-1)
		"right":
			if columns > 1: move(1)
		"ok": select()
		"cancel":
			if on_cancel.is_valid():
				Snd.sfx("cancel")
				on_cancel.call()
