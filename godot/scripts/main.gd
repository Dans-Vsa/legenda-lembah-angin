extends Node2D
## Scene utama: World, BattleLayer, HintLayer, UILayer, dan FadeLayer.
## Kendali permainan diserahkan ke autoload Game.


func _ready() -> void:
	Game.setup(self)
