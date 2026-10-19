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


# Memuat PNG dari res://assets bila ada (bisa diedit), jika tidak dibuat dari template.
func _png(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _whiten(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, img.get_pixel(x, y).a))


func sprite(key: String, white := false, flip := false) -> ImageTexture:
	var k := "s|%s|%s|%s" % [key, white, flip]
	if not _cache.has(k):
		var img := _png("res://assets/characters/%s.png" % key)
		if img == null:
			var d: Array = SPR[key]
			img = _rows_image(TPL[d[0]], d[1])
		if white:
			_whiten(img)
		if flip:
			img.flip_x()
		_cache[k] = ImageTexture.create_from_image(img)
	return _cache[k]


# ---------- Kanvas kecil untuk menggambar objek ----------
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


# ---------- Objek peta ----------
func obj(kind: String, state := false) -> Texture2D:
	var k := "o|%s|%s" % [kind, state]
	if _cache.has(k):
		return _cache[k]
	var path := "res://assets/objects/%s.png" % ("chest_open" if kind == "chest" and state else kind)
	if ResourceLoader.exists(path):
		_cache[k] = load(path)
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
