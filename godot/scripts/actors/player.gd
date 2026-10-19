class_name PlayerActor
extends Node2D
## Karakter pemain di peta (Kael). Posisi diatur oleh WorldMap.

@onready var sprite: Sprite2D = $Sprite


func set_flip(f: bool) -> void:
	sprite.flip_h = f


## Efek melangkah: sprite naik sedikit di langkah bergantian.
func set_step(walking: bool, t: float) -> void:
	sprite.position.y = -2.0 if walking and int(t * 12.0) % 2 == 1 else 0.0
