extends Node
## Semua grafis pixel art dibuat lewat kode (tanpa file gambar).
## Karakter menghadap KIRI, monster menghadap KANAN.

const OL := "1b1424"

const TPL := {
	"kael": [
		"......o.o.o.....",
		".....ohohoho....",
		"....ohhhhhhhoo..",
		"...ohHHhhhhhhho.",
		"..ohhhhhhhhhhho.",
		"..ohhsshhhhhho..",
		"..osesSshhhhho..",
		"..osssSshhhho...",
		"...ossSSsoo.....",
		"...occcccco.....",
		"..ocCccccCco....",
		"..osocccccso....",
		".gsoocCCCcco....",
		"wg..obbbbbo.....",
		"w...obbobbo.....",
		"w...obbobbo.....",
		"....oBBoBBo.....",
		"....ooo.ooo.....",
	],
	"rina": [
		"................",
		".....oooo.......",
		"....ohhhhoo.....",
		"...ohHhhhhhoo...",
		"..ohhhhhhhhhhoo.",
		"..ohsshhhhhhohho",
		"..oseShhhhhho.oo",
		"..osssShhhho....",
		"...ossSSoo......",
		"...occcccco.....",
		"..ocCcccCcco....",
		".ssocccccccoss..",
		".ss.owwwwwo.ss..",
		"....occcccco....",
		"....obboobbo....",
		"....obbo.obbo...",
		"....oBBo.oBBo...",
		"....ooo..ooo....",
	],
	"lyra": [
		".g....oooo......",
		"gGg..occcco.....",
		".g..occCccco....",
		".w.occcccccco...",
		".w.ochhhhhhcco..",
		".w.ohssshhhhco..",
		".w.oseSshhhhco..",
		".w.osssshhhhco..",
		".w..osssohhhco..",
		".wsoccccccccco..",
		".wssoccCcccco...",
		".w..occcccccco..",
		".w.occCcccCccco.",
		".w.occcccccccco.",
		".w.oCcccccccCco.",
		".w.oCCCCCCCCCo..",
		".w..obbo.obbo...",
		"....oo....oo....",
	],
	"slime": [
		"................",
		"................",
		"................",
		"................",
		"......oooo......",
		"....oocccco.....",
		"...occWccccoo...",
		"..occWWcccccco..",
		"..occcccccccco..",
		".occcoeccoeccco.",
		".occcoeccoeccco.",
		".occcccccccccco.",
		".oCcccmmmmcccCo.",
		".oCCcccccccCCCo.",
		"..oCCCCCCCCCCo..",
		"...oooooooooo...",
	],
	"bee": [
		"................",
		".....oo..oo.....",
		"....oWWooWWo....",
		"....oWWWoWWo....",
		".....oWWoWWo....",
		"......oooooo....",
		"....oyykkyyeo...",
		"...oyykkyykkyo..",
		"..okyykkyykkyyo.",
		"...oyykkyykkyo..",
		"....ooyykkyoo...",
		"......okkoo.....",
		".....os.........",
		"................",
		"................",
		"................",
	],
	"wolf": [
		"................",
		"................",
		"...........o.o..",
		"..........ocoCo.",
		"..........occcco",
		"o.........oceccW",
		"co.......occcccN",
		".co.oooooccccoo.",
		"..ocCcccccccco..",
		"..occcccccccco..",
		"...occCcccccCo..",
		"...ocooCCCooco..",
		"...oc.oc..oc.oc.",
		"...oc.oc..oc.oc.",
		"...oo.oo..oo.oo.",
		"................",
	],
	"mushroom": [
		"................",
		"....oooooooo....",
		"..ooccWcccWcoo..",
		".occWWccccccWco.",
		"occcccccWWccccco",
		"occWccccWWcccWco",
		"oCcccccccccccCCo",
		".oooossssssoooo.",
		"....osessesso...",
		"....ossssssso...",
		"....osSsmmsSo...",
		"....oSsssssSo...",
		"...oSSsssssSSo..",
		"...oooooooooo...",
		"................",
		"................",
	],
	"treant": [
		"..g..g.....g....",
		".gGg.gGg..gGg...",
		"..ggggggggggg...",
		".gGggggGggggGg..",
		"..ooggggggggoo..",
		"...obbbbbbbbo...",
		"...obebbbbebo...",
		"...obbbbbbbbo...",
		"...obboooobbo...",
		"...obbbbbbbbo...",
		"..obbBbbbbBbbo..",
		".obbobbbbbbobbo.",
		"ob.o.obbbbo.o.bo",
		"o...obboobbo...o",
		"...ob.o..o.bo...",
		"...o........o...",
	],
	"bat": [
		"................",
		"................",
		"................",
		".o....o..o....o.",
		".oo...oooo...oo.",
		".oWo.occcco.oWo.",
		".oWWooceceooWWo.",
		".oWWWocccccoWWWo",
		".oWWWWocccoWWWWo",
		".oWoWWoccoWWoWo.",
		".o..oWo.ooWo..o.",
		".....o.....o....",
		"................",
		"................",
		"................",
		"................",
	],
	"wisp": [
		".......o........",
		"......oyo.......",
		".....oyyo..o....",
		"....oyrryo.oyo..",
		"...oyrrrryoyo...",
		"..oyrrWWrrryo...",
		"..oyrWWWWrrryo..",
		".oyrrWeWeWrrryo.",
		".oyrrWWWWWrrryo.",
		".oyrrrWWWrrrryo.",
		"..oyrrrrrrrryo..",
		"...oyyrrrrryo...",
		"....ooyyyyoo....",
		"......oooo......",
		"................",
		"................",
	],
	"golem": [
		"................",
		"....oooooooo....",
		"...occcccccco...",
		"...ocecccceco...",
		"...occcCCccco...",
		".ooooccccccoooo.",
		"occccoCCCCocccco",
		"occCcoccccocCcco",
		"occccoccmcocccco",
		".occoccccccocco.",
		".occoCccccCocco.",
		"..oooccccccooo..",
		"....occoocco....",
		"...occco.occco..",
		"...oCCCo.oCCCo..",
		"...ooooo.ooooo..",
	],
	"wyrm": [
		"........................",
		"................o.......",
		"...............oHo..o...",
		"..............oHHo.oHo..",
		".............occcoooHo..",
		"............occcccccco..",
		"...........occcccccecco.",
		"...........occcccccccWWo",
		"............oCcccccWWWo.",
		".....ooo.....oCcccooooo.",
		"....oMMMo.....occco.....",
		"...oMMMMMo...occcco.....",
		"..oMMmMMMMoooccccco.....",
		"..oMmMMMMMoccccccoo.....",
		"...oMMMMMoccCcccco......",
		"....ooooocccCccccco.....",
		".......occcCcccccccoo...",
		"......occcCccccooocccoo.",
		".....occcCccccco..ocCcco",
		".....occCcccccco...oCco.",
		"......oCCcccccoo....oo..",
		".......ooCCCCoo.........",
		".........oooo...........",
		"........................",
	],
}

const SKIN := {"s": "f3caa0", "S": "d49a74", "e": OL}
var SPR := {
	"kael":   ["kael", {"o": OL, "h": "b5452f", "H": "e8814f", "c": "3a62b4", "C": "24407c", "b": "5b3b29", "B": "2b1f19", "w": "e4ebf7", "g": "e0b040"}, true],
	"rina":   ["rina", {"o": OL, "h": "2a2232", "H": "5a4a74", "c": "c8383c", "C": "86201f", "w": "f2ead8", "b": "e6d8c0", "B": "3a2a22"}, true],
	"lyra":   ["lyra", {"o": OL, "s": "f6d2b0", "S": "d8a888", "e": "3a6ad0", "g": "7ad8ff", "G": "e0faff", "w": "8a5a30", "c": "efeaf8", "C": "a99ad0", "h": "f2cc58", "b": "6a4a8e"}, false],
	"elder":  ["lyra", {"o": OL, "g": "c09040", "G": "f0d080", "w": "7a5028", "c": "6a9a54", "C": "456e38", "h": "eeeeee", "b": "4a3a2a"}, true],
	"woman":  ["rina", {"o": OL, "h": "8a4a2a", "H": "b86a40", "c": "d27aa0", "C": "9a4a70", "w": "f2ead8", "b": "efe0c8", "B": "5a3a28"}, true],
	"kid":    ["kael", {"o": OL, "h": "f0c040", "H": "ffe080", "c": "5aa05a", "C": "3a703a", "b": "4a3a6a", "B": "2a2030"}, true],
	"guard":  ["kael", {"o": OL, "h": "4a3a2a", "H": "6a5a44", "c": "9a9aac", "C": "5e5e70", "b": "4a4a5a", "B": "22222a", "w": "d8dce8", "g": "a0a0b0"}, true],
	"ranger": ["rina", {"o": OL, "h": "6a4a2a", "H": "8a6a44", "c": "4a7a4a", "C": "2e5a2e", "w": "a08050", "b": "6a5a40", "B": "2a2018"}, true],
	"slime":  ["slime", {"o": "14301a", "c": "5ccb5c", "C": "2f8c3b", "W": "d2ffd2", "e": OL, "m": "1a3a1a"}, false],
	"bee":    ["bee", {"o": OL, "y": "f2c21f", "k": "2a2020", "W": "dcf0ffd9", "e": "e02020", "s": "d0d0d0"}, false],
	"wolf":   ["wolf", {"o": OL, "c": "8c8ca4", "C": "5a5a72", "e": "ff3a3a", "W": "ffffff", "N": OL}, false],
	"mushroom": ["mushroom", {"o": OL, "c": "9a3ab2", "C": "621f82", "W": "f2e2ff", "s": "f2e2c8", "S": "c8b08e", "e": OL, "m": "5a2020"}, false],
	"treant": ["treant", {"o": "20140c", "g": "4aa040", "G": "8ad060", "b": "7a5030", "B": "4a3020", "e": "f2e040"}, false],
	"bat":    ["bat", {"o": OL, "c": "5c3c70", "W": "3a2a4e", "e": "ff4040"}, false],
	"wisp":   ["wisp", {"o": "5a1a0a", "y": "ffa22a", "r": "e2442a", "W": "fff2a2", "e": "4a1010"}, false],
	"golem":  ["golem", {"o": "2a2620", "c": "8e8678", "C": "5e584e", "e": "7af0ff", "m": "5ab04a"}, false],
	"wyrm":   ["wyrm", {"o": "1a1028", "c": "9a8ab8", "C": "6a5a8c", "H": "e8e0c8", "e": "ffe040", "W": "ffffff", "M": "5a3a7a", "m": "2e1e44"}, false],
}

var _cache := {}


func _ready() -> void:
	# Palet dengan kulit default (kode warna kulit sama untuk banyak karakter)
	for k in SPR:
		var entry: Array = SPR[k]
		if entry[2]:
			var pal: Dictionary = SKIN.duplicate()
			pal.merge(entry[1], true)
			entry[1] = pal


func _rows_image(rows: Array, pal: Dictionary, white := false) -> Image:
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if not pal.has(ch):
				continue
			img.set_pixel(x, y, Color.WHITE if white else Color.html(pal[ch]))
	return img


func sprite(key: String, white := false, flip := false) -> ImageTexture:
	var k := "s|%s|%s|%s" % [key, white, flip]
	if not _cache.has(k):
		var d: Array = SPR[key]
		var img := _rows_image(TPL[d[0]], d[1], white)
		if flip:
			img.flip_x()
		_cache[k] = ImageTexture.create_from_image(img)
	return _cache[k]


# ---------- Tile peta (16x16, ditampilkan 2x) ----------
class Painter:
	var img: Image
	var rng := RandomNumberGenerator.new()

	func _init(seed_value: int) -> void:
		img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		rng.seed = seed_value

	func p(x: int, y: int, col: Color) -> void:
		if x < 0 or y < 0 or x > 15 or y > 15:
			return
		if col.a < 1.0:
			img.set_pixel(x, y, img.get_pixel(x, y).blend(col))
		else:
			img.set_pixel(x, y, col)

	func r(x: int, y: int, w: int, h: int, col: Color) -> void:
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				p(xx, yy, col)

	func ri(n: int) -> int:
		return rng.randi_range(0, n - 1)

	func rf() -> float:
		return rng.randf()


func tile(ch: String, v: int, f: int) -> ImageTexture:
	var k := "t|%s|%d|%d" % [ch, v, f]
	if _cache.has(k):
		return _cache[k]
	var P := Painter.new(v * 977 + ch.unicode_at(0) * 131 + 17)
	var grass := func() -> void:
		P.r(0, 0, 16, 16, C("5da544"))
		for i in 16: P.p(P.ri(16), P.ri(16), C("4e9238"))
		for i in 5:
			var gx := P.ri(15); var gy := P.ri(14) + 1
			P.p(gx, gy, C("7cc456")); P.p(gx + 1, gy - 1, C("7cc456"))
	var forest_floor := func() -> void:
		P.r(0, 0, 16, 16, C("3b7d35"))
		for i in 18: P.p(P.ri(16), P.ri(16), C("2f6a2b"))
		for i in 5: P.p(P.ri(16), P.ri(16), C("4f9440"))
	var cave_floor := func() -> void:
		P.r(0, 0, 16, 16, C("5e5068"))
		for i in 18: P.p(P.ri(16), P.ri(16), C("52465c"))
		for i in 8: P.p(P.ri(16), P.ri(16), C("6e6078"))
		if P.rf() < 0.5:
			var sx := P.ri(12) + 2; var sy := P.ri(12) + 2
			P.r(sx, sy, 2, 1, C("7a6c84")); P.p(sx, sy + 1, C("3a3044")); P.p(sx + 1, sy + 1, C("3a3044"))
	var cobble := func() -> void:
		P.r(0, 0, 16, 16, C("8a867e"))
		var by := 0
		while by < 16:
			var bx := (2 if by % 8 else 0) - 4
			while bx < 16:
				P.r(bx + 1, by + 1, 3, 3, C("b2ada2") if P.rf() < 0.5 else C("a39f95"))
				P.p(bx + 1, by + 1, C("c8c3b8"))
				bx += 4
			by += 4
	var mountain := func() -> void:
		for py in range(1, 16):
			var half := (py - 1) * 0.55 + 0.5
			for px in 16:
				var dx := px - 7.5
				if absf(dx) > half: continue
				var col := C("9a9aa8") if dx < 0 else C("72727f")
				if absf(dx) > half - 1: col = C("4a4a58")
				if py < 5 and absf(dx) < half - 0.5: col = C("f4f4fa") if py < 4 else C("d8d8e4")
				P.p(px, py, col)
	var wall := func() -> void:
		P.r(0, 0, 16, 16, C("e8dcc0"))
		P.r(0, 0, 16, 1, C("7a5432")); P.r(0, 0, 1, 16, C("7a5432")); P.r(15, 0, 1, 16, C("7a5432"))
		P.r(0, 15, 16, 1, C("a89878"))
		for i in 6: P.p(P.ri(14) + 1, P.ri(13) + 1, C("d8ccb0"))
	var roof := func(base: String, dark: String, light: String) -> void:
		P.r(0, 0, 16, 16, C(base))
		var y := 0
		while y < 16:
			P.r(0, y + 3, 16, 1, C(dark))
			var x0 := 2 if y % 8 else 0
			while x0 < 16:
				P.p(x0, y, C(light)); P.p(x0, y + 1, C(light)); P.r(x0 + 3, y, 1, 3, C(dark))
				x0 += 4
			y += 4

	match ch:
		".": grass.call()
		":":
			grass.call()
			for i in 3:
				var fx := P.ri(12) + 2; var fy := P.ri(12) + 2
				var col: Color = [C("f05a5a"), C("f8e050"), C("ffffff"), C("e080f0")][P.ri(4)]
				P.p(fx, fy - 1, col); P.p(fx - 1, fy, col); P.p(fx + 1, fy, col); P.p(fx, fy + 1, col); P.p(fx, fy, C("f8e050"))
		"f": forest_floor.call()
		",":
			P.r(0, 0, 16, 16, C("d4b483"))
			for i in 14: P.p(P.ri(16), P.ri(16), C("c4a170") if P.rf() < 0.5 else C("e2c79a"))
			for i in 2: P.r(P.ri(14), P.ri(14), 2, 1, C("a88a60"))
		"~", "=":
			P.r(0, 0, 16, 16, C("3d7fd0"))
			for i in 6: P.p(P.ri(16), P.ri(16), C("356fbc"))
			for wy in [3, 9, 14]:
				var xo: int = (f * 4 + v * 5 + wy * 3) % 16
				for k2 in 4: P.p((xo + k2) % 16, wy, C("8cc4f4"))
				P.p((xo + 1) % 16, wy - 1, C("c8e4fc"))
			if ch == "=":
				P.r(0, 1, 16, 14, C("9a6a3a"))
				for py in [1, 5, 9, 13]: P.r(0, py, 16, 1, C("6e4824"))
				P.r(0, 0, 16, 1, C("4a2e14")); P.r(0, 15, 16, 1, C("4a2e14"))
				for i in 4: P.p(P.ri(16), 2 + P.ri(12), C("b07c48"))
		"T":
			grass.call()
			P.r(4, 14, 8, 1, Color(0, 0, 0, 0.25))
			P.r(7, 10, 2, 5, C("6a4424"))
			for py in 13:
				for px in 16:
					var d := pow(px - 7.5, 2) + pow(py - 6.5, 2)
					if d < 42:
						var col2: Color = C("1d5424") if d > 32 else (C("4aa346") if pow(px - 5.5, 2) + pow(py - 4.5, 2) < 9 else C("2f7d33"))
						P.p(px, py, col2)
			P.p(5, 4, C("78c868")); P.p(9, 8, C("255f2a")); P.p(11, 6, C("255f2a"))
		"P":
			forest_floor.call()
			P.r(7, 13, 2, 3, C("5a3a1a"))
			for py in range(1, 14):
				var w := 1 + ((py - 1) % 4) + floorf((py - 1) / 4.0) * 1.4
				var x1 := roundi(7.5 - w); var x2 := roundi(7.5 + w)
				for px in range(x1, x2 + 1):
					var edge := px == x1 or px == x2
					P.p(px, py, C("16452a") if edge else (C("3f9a4c") if px < 7 else C("2a7038")))
		"M":
			grass.call(); mountain.call()
		"C":
			grass.call(); mountain.call()
			P.r(5, 9, 6, 7, C("141018")); P.r(6, 8, 4, 1, C("141018")); P.r(4, 11, 1, 5, C("2a2430")); P.r(11, 11, 1, 5, C("2a2430"))
		"V":
			grass.call()
			P.r(1, 7, 6, 6, C("e8dcc0")); P.r(0, 5, 8, 3, C("c04030")); P.r(3, 10, 2, 3, C("6a4020"))
			P.r(9, 8, 6, 5, C("e8dcc0")); P.r(8, 6, 8, 3, C("3a60b0")); P.r(11, 10, 2, 3, C("6a4020"))
			P.r(0, 13, 16, 1, Color(0, 0, 0, 0.2))
		"c": cobble.call()
		"r": roof.call("b8402e", "7e2a1e", "e0664a")
		"R": roof.call("3a64b8", "24427e", "6a92e0")
		"w": wall.call()
		"n":
			wall.call()
			P.r(4, 3, 8, 8, C("5a3a20")); P.r(5, 4, 6, 6, C("8ad0f0")); P.r(5, 4, 2, 2, C("d0f0ff")); P.r(7, 4, 2, 6, C("5a3a20")); P.r(5, 6, 6, 1, C("5a3a20"))
			P.r(3, 11, 10, 1, C("7a5432"))
		"d":
			wall.call()
			P.r(4, 2, 8, 14, C("4a2a10")); P.r(5, 3, 6, 13, C("8a5a30"))
			P.r(7, 3, 1, 13, C("6a4020")); P.p(9, 9, C("f0d050")); P.r(4, 15, 8, 1, C("3a2a1a"))
		"|":
			grass.call()
			P.r(2, 6, 2, 9, C("7a4a24")); P.r(12, 6, 2, 9, C("7a4a24"))
			P.r(0, 8, 16, 2, C("b07844")); P.r(0, 12, 16, 2, C("b07844")); P.r(0, 9, 16, 1, C("8a5a30")); P.r(0, 13, 16, 1, C("8a5a30"))
		"F":
			cobble.call()
			for py in 16:
				for px in 16:
					var d2 := pow(px - 7.5, 2) + pow(py - 8, 2)
					if d2 < 56:
						var col3: Color = C("7a7a88") if d2 > 40 else (C("5a5a68") if d2 > 34 else (C("8cc8f8") if f and (px + py) % 3 == 0 else C("4a90e0")))
						P.p(px, py, col3)
			P.r(7, 3, 2, 6, C("c0d8ff")); P.p(7, 2, Color.WHITE); P.p(8, 2, Color.WHITE)
		"g": cave_floor.call()
		"E":
			cave_floor.call()
			P.r(0, 0, 16, 16, Color(1, 0.94, 0.78, 0.35))
			for i in 6: P.p(P.ri(16), P.ri(16), C("fff4d8"))
		"#":
			P.r(0, 0, 16, 16, C("140f1a"))
			var by2 := 0
			while by2 < 16:
				var bx2 := -3 if by2 % 10 else 0
				while bx2 < 16:
					P.r(bx2 + 1, by2 + 1, 5, 4, C("211a2a") if P.rf() < 0.5 else C("261e30"))
					P.r(bx2 + 1, by2 + 1, 5, 1, C("30263c"))
					bx2 += 6
				by2 += 5
		"K":
			P.r(0, 0, 16, 16, C("140f1a"))
			for i in 10: P.p(P.ri(16), P.ri(16), C("261e30"))
			for spec in [[5, 11, 2], [9, 14, 3], [12, 8, 2]]:
				var cx: int = spec[0]; var hh: int = spec[1]; var w2: int = spec[2]
				for py in hh:
					var ww := maxi(0, roundi(w2 * minf(minf(1.0, (hh - py) / 4.0), py / 3.0 + 0.4)))
					for px in range(cx - ww, cx + ww + 1):
						P.p(px, 15 - py, C("a8f0ff") if px < cx else (C("60d8f8") if px == cx else C("2a90c0")))
		_: grass.call()
	var tex := ImageTexture.create_from_image(P.img)
	_cache[k] = tex
	return tex


# ---------- Objek peta ----------
func obj(kind: String, state := false) -> ImageTexture:
	var k := "o|%s|%s" % [kind, state]
	if _cache.has(k):
		return _cache[k]
	var P := Painter.new(1)
	if kind == "chest":
		P.r(2, 14, 12, 1, Color(0, 0, 0, 0.3))
		if not state:
			P.r(1, 5, 14, 10, C(OL)); P.r(2, 6, 12, 8, C("8a5a2a")); P.r(2, 6, 12, 3, C("b07838")); P.r(2, 6, 12, 1, C("d09858"))
			P.r(2, 9, 12, 1, C("e0b040")); P.r(7, 8, 2, 3, C("f8e070")); P.r(7, 10, 2, 1, C("6a4a10"))
		else:
			P.r(1, 2, 14, 5, C(OL)); P.r(2, 3, 12, 3, C("6a4420"))
			P.r(1, 7, 14, 8, C(OL)); P.r(2, 8, 12, 6, C("8a5a2a")); P.r(3, 8, 10, 2, C("1a0e06")); P.r(2, 10, 12, 1, C("e0b040"))
	elif kind == "sign":
		P.r(7, 9, 2, 7, C("5a3a1a")); P.r(1, 2, 14, 8, C(OL)); P.r(2, 3, 12, 6, C("c09058"))
		P.r(3, 4, 9, 1, C("7a5428")); P.r(3, 6, 7, 1, C("7a5428")); P.r(2, 3, 12, 1, C("e0b47a"))
	elif kind == "crystal":
		P.r(3, 14, 10, 2, C("3a3046"))
		for py in 14:
			var w := py * 0.75 if py < 7 else (14 - py) * 0.75
			for px in range(roundi(8 - w), roundi(7 + w) + 1):
				P.p(px, py, C("b8f4ff") if px < 8 else C("4cc8f0"))
		P.r(6, 3, 1, 3, Color.WHITE)
	var tex := ImageTexture.create_from_image(P.img)
	_cache[k] = tex
	return tex


func C(h: String) -> Color:
	return Color.html(h)
