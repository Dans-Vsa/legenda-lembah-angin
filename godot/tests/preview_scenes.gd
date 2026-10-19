extends RefCounted
## Memotret scene seperti tampilannya di editor (tanpa script runtime):
##   godot --path . -- --preview-scenes
## Gambar disimpan di user://preview.

const SCENES := [
	"res://main.tscn",
	"res://scenes/battle/battle.tscn",
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/ui/field_menu.tscn",
	"res://scenes/ui/shop.tscn",
	"res://scenes/ui/dialog_box.tscn",
	"res://maps/cave.tscn",
]


func run() -> void:
	var tree := Game.get_tree()
	DirAccess.make_dir_recursive_absolute("user://preview")
	for path in SCENES:
		var n: Node = load(path).instantiate()
		_strip(n)
		Game.main.add_child(n)
		_preview(n)
		for i in 4:
			await tree.process_frame
		var img := Game.get_viewport().get_texture().get_image()
		var name: String = path.get_file().get_basename()
		img.save_png("user://preview/%s.png" % name)
		print("preview: ", name)
		n.queue_free()
		await tree.process_frame
	tree.quit()


# Script non-@tool tidak berjalan di editor, jadi dilepas di sini.
func _strip(n: Node) -> void:
	var s: Script = n.get_script()
	if s and not s.is_tool():
		n.set_script(null)
	for c in n.get_children():
		_strip(c)


func _preview(n: Node) -> void:
	if n is ListMenu:
		n._build_preview()
	if n is PartyCard:
		n._preview()
	for c in n.get_children():
		_preview(c)
