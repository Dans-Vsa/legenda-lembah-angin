@tool
class_name TitleBg
extends Control
## Latar layar judul dan ending: langit senja, bintang, dan pegunungan bergerak.

var _t := 0.0
var _stars: Array = []
var _hills: Array = []


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in 90:
		_stars.append(Vector3(rng.randf() * 960, rng.randf() * 260, rng.randf()))
	for li in 3:
		var hs := []
		for i in 64:
			hs.append(rng.randf())
		_hills.append(hs)


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var stops := [Color("0d0b2a"), Color("3a2a6a"), Color("c86a6a"), Color("f2b880")]
	var ys := [0.0, 243.0, 405.0, 540.0]
	for i in 3:
		draw_polygon(PackedVector2Array([Vector2(0, ys[i]), Vector2(960, ys[i]), Vector2(960, ys[i + 1]), Vector2(0, ys[i + 1])]),
			PackedColorArray([stops[i], stops[i], stops[i + 1], stops[i + 1]]))
	for s in _stars:
		var a := 0.3 + 0.7 * absf(sin(_t * (0.5 + s.z) + s.z * 10.0))
		draw_rect(Rect2(s.x, s.y, 2, 2), Color(1, 1, 1, a))
	var cols := [Color("4a3a78"), Color("2e2452"), Color("191433")]
	for li in 3:
		var hs: Array = _hills[li]
		var speed := 6.0 + li * 10.0
		var base := 330.0 + li * 60.0
		var amp := 110.0 - li * 25.0
		var seg := 960.0 / 16.0
		var off := fmod(_t * speed, seg * hs.size())
		var pts := PackedVector2Array([Vector2(0, 540)])
		for i in 18:
			var gi := int(off / seg) + i
			pts.append(Vector2(i * seg - fmod(off, seg), base - hs[gi % hs.size()] * amp))
		pts.append(Vector2(960, 540))
		draw_colored_polygon(pts, cols[li])
		draw_rect(Rect2(0, base - 10 + sin(_t * 0.4 + li) * 6, 960, 30), Color(0.9, 0.78, 1.0, 0.05 + li * 0.02))
