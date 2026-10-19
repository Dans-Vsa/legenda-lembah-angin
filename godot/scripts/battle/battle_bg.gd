@tool
class_name BattleBg
extends Node2D
## Latar battle yang digambar lewat kode. Ganti jenisnya di Inspector.

@export_enum("field", "forest", "cave", "boss") var bg_type := "field":
	set(v):
		bg_type = v
		queue_redraw()


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)


func _grad(y0: float, y1: float, stops: Array) -> void:
	var seg := (y1 - y0) / (stops.size() - 1)
	for i in stops.size() - 1:
		var a := Color(stops[i])
		var b := Color(stops[i + 1])
		var ya := y0 + seg * i
		draw_polygon(PackedVector2Array([Vector2(0, ya), Vector2(960, ya), Vector2(960, ya + seg), Vector2(0, ya + seg)]), PackedColorArray([a, a, b, b]))


func _ridge(base: float, amp: float, col: Color, sd: float) -> void:
	var pts := PackedVector2Array([Vector2(0, 540)])
	var x := 0.0
	while x <= 960.0:
		pts.append(Vector2(x, base - amp * (0.5 + 0.3 * sin(x / 90.0 + sd) + 0.2 * sin(x / 37.0 + sd * 2.0))))
		x += 8.0
	pts.append(Vector2(960, 540))
	draw_colored_polygon(pts, col)


func _tufts(rng: RandomNumberGenerator, y0: float, cols: Array, count: int) -> void:
	for i in count:
		var tx := rng.randf() * 960.0
		var ty := y0 + rng.randf() * (540.0 - y0)
		var s := 1.0 + (ty - y0) / 120.0
		var col := Color(cols[rng.randi() % cols.size()])
		draw_polyline(PackedVector2Array([Vector2(tx - 3 * s, ty - 5 * s), Vector2(tx, ty), Vector2(tx + 3 * s, ty - 6 * s)]), col, 1.5)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = bg_type.length() * 99 + 7
	match bg_type:
		"field":
			_grad(0, 240, ["4f8fd8", "a8d0f4", "e4f2ff"])
			for i in 6:
				var cx := rng.randf() * 960.0
				var cy := 30.0 + rng.randf() * 90.0
				for j in 5:
					_ellipse(Vector2(cx + j * 22 - 44, cy + sin(j) * 6), Vector2(26, 14), Color(1, 1, 1, 0.85))
			_ridge(190, 70, Color("8ea8cc"), 1.0)
			_ridge(212, 40, Color("6f9a6a"), 3.0)
			_grad(205, 540, ["78b85a", "4f9a3c", "2f6e26"])
			for i in 14:
				var y := 210.0 + pow(i / 14.0, 1.7) * 330.0
				draw_rect(Rect2(0, y, 960, 2 + i * 0.5), Color(0, 0, 0, 0.05))
			_tufts(rng, 215, ["3a7a2a", "8ad06a", "2f6a22"], 160)
		"forest":
			_grad(0, 250, ["0f2416", "24502e", "4a7a48"])
			for i in 9:
				var lx := rng.randf() * 960.0
				draw_colored_polygon(PackedVector2Array([Vector2(lx, 0), Vector2(lx + 40, 0), Vector2(lx + 160, 250), Vector2(lx + 90, 250)]), Color(1, 1, 0.78, 0.05))
			for i in 16:
				var tx := rng.randf() * 960.0
				var tw := 16.0 + rng.randf() * 24.0
				draw_rect(Rect2(tx, 0, tw, 250), Color("14281a") if i % 2 else Color("1b3522"))
				_ellipse(Vector2(tx + tw / 2.0, 10 + rng.randf() * 40), Vector2(60 + rng.randf() * 40, 50), Color("1a3a22") if i % 2 else Color("21452a"))
			_ridge(240, 30, Color("24482a"), 2.0)
			_grad(228, 540, ["3d6e30", "2c5524", "1a3616"])
			for i in 14:
				_ellipse(Vector2(rng.randf() * 960, 260 + rng.randf() * 260), Vector2(40 + rng.randf() * 50, 8 + rng.randf() * 8), Color(0, 0, 0, 0.12))
			_tufts(rng, 232, ["5a9a40", "2a5a20", "78b050"], 140)
		_:
			var is_boss := bg_type == "boss"
			_grad(0, 260, ["120818", "2a1438", "3a2050"] if is_boss else ["0e0a16", "1e1828", "2e2640"])
			for i in 20:
				var sx := rng.randf() * 960.0
				var sw := 18.0 + rng.randf() * 34.0
				var sh := 40.0 + rng.randf() * 110.0
				draw_colored_polygon(PackedVector2Array([Vector2(sx, 0), Vector2(sx + sw, 0), Vector2(sx + sw / 2, sh)]), Color("16111f"))
				draw_line(Vector2(sx, 0), Vector2(sx + sw / 2, sh), Color("2e2640"), 1.0)
			for i in 9:
				var cx := rng.randf() * 960.0
				var cy := 60.0 + rng.randf() * 160.0
				var hh := 10.0 + rng.randf() * 16.0
				var glow := Color(0.75, 0.47, 1.0) if is_boss else Color(0.43, 0.86, 1.0)
				for k in 4:
					draw_circle(Vector2(cx, cy), 40.0 - k * 9.0, Color(glow, 0.08))
				draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - hh), Vector2(cx + 5, cy), Vector2(cx, cy + 4), Vector2(cx - 5, cy)]), Color("c080ff") if is_boss else Color("70e0ff"))
			_ridge(250, 30, Color("2a1a3a") if is_boss else Color("2a2236"), 4.0)
			_grad(238, 540, ["3a2a4a", "2a1e36", "160e1e"] if is_boss else ["4a3e56", "342a40", "1c1626"])
			for i in 26:
				_ellipse(Vector2(rng.randf() * 960, 260 + rng.randf() * 260), Vector2(10 + rng.randf() * 30, 4 + rng.randf() * 8), Color(0, 0, 0, 0.18))
			if is_boss:
				for i in 12:
					_ellipse(Vector2(rng.randf() * 960, 120 + rng.randf() * 300), Vector2(120 + rng.randf() * 120, 30 + rng.randf() * 30), Color(0.7, 0.55, 0.86, 0.07))
