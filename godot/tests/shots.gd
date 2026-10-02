extends RefCounted
## Mengambil screenshot beberapa adegan untuk pengecekan visual:
##   godot --path rpg -- --shots
## Gambar disimpan di folder user://shots.


func wait(sec: float) -> void:
	await Game.get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await Game.get_tree().process_frame
	await Game.get_tree().process_frame
	var img := Game.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://shots")
	img.save_png("user://shots/%s.png" % name)
	print("shot: ", ProjectSettings.globalize_path("user://shots/%s.png" % name))


func run() -> void:
	Game.show_title()
	await wait(1.0)
	await shot("1_title")
	Game.new_game()
	Game.enter_world("town", 12, 10, "up")
	await wait(0.5)
	Game.say([{"s": "Tetua Baram", "t": "Oh! Kalian para pengembara yang datang dari utara? Syukurlah... desa kami sedang dalam bahaya besar."}])
	await wait(2.5)
	await shot("2_town_dialog")
	Game.press("ok")
	await wait(0.3)
	Menus.field_menu()
	await wait(0.3)
	Game.press("down"); Game.press("down"); Game.press("ok")
	await wait(0.4)
	await shot("3_menu_status")
	Game.press("cancel"); await wait(0.1); Game.press("cancel")
	await wait(0.3)
	Game.enter_world("world", 30, 18, "right")
	await wait(0.6)
	await shot("4_world")
	Game.enter_world("cave", 15, 12, "up")
	await wait(0.6)
	await shot("5_cave")
	Game.run_battle(["serigala", "lendir", "lebah"], "field")
	while Game.battle.state != "menu":
		await wait(0.1)
	await wait(0.3)
	await shot("6_battle_menu")
	var b: Battle = Game.battle
	b.close_command()
	b.perform(b.actor, {"type": "skill", "id": "kilat" if b.actor.id == "lyra" else ("tebasan" if b.actor.id == "kael" else "tinjuBeruntun")}, [b.alive_enemies()[0]])
	await wait(0.75)
	await shot("7_battle_fx")
	Game.party[0].lvl = 9
	Data.refresh_stats(Game.party[0])
	b.teardown()
	Game.clear_ui()
	Game.set_scene("battle")
	b.start(["wyrm"], "boss", {"boss": true, "music": "boss"})
	await wait(1.5)
	await shot("8_boss")
	Game.get_tree().quit()
