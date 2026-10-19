@tool
class_name BattlerNode
extends Node2D
## Sprite battler (anggota party atau musuh) di layar battle.

@export var texture: Texture2D:
	set(v):
		texture = v
		_apply()
@export var sprite_scale := 4.0:
	set(v):
		sprite_scale = v
		_apply()

# Diatur oleh Battle setiap frame
var defending := false
var poison := false
var anim_t := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	$Sprite.texture = texture
	$Sprite.scale = Vector2.ONE * sprite_scale
	var sz := size()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * sz.x * 0.38, sz.y / 2.0 - 2.0 + sin(a) * sz.x * 0.38 * 0.22))
	$Shadow.polygon = pts


func size() -> Vector2:
	return texture.get_size() * sprite_scale if texture else Vector2(64, 72)


func set_flash(v: float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("flash", v)


func _draw() -> void:
	if defending:
		draw_arc(Vector2(-6, 0), 40, PI * 0.6, PI * 1.4, 16, Color(0.59, 0.82, 1.0, 0.6), 3.0)
	if poison:
		for i in 3:
			var k := fmod(anim_t * 0.8 + i / 3.0, 1.0)
			draw_circle(Vector2(18 + i * 4, -30 - k * 24), 3, Color(0.75, 0.44, 0.88, 1.0 - k))
