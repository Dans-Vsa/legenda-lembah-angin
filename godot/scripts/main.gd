extends Node2D
## Scene utama: hanya menyerahkan kendali ke autoload Game.


func _ready() -> void:
	Game.setup(self)
