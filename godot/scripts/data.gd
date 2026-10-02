extends Node
## Data game: karakter, skill, item, monster, dan rumus.

const MAX_LVL := 30

const SKILLS := {
	"tebasan":       {"name": "Tebasan Silang", "mp": 5,  "kind": "phys", "power": 1.7, "target": "enemy", "fx": "slash2", "desc": "Tebasan menyilang yang kuat ke satu musuh."},
	"pedangApi":     {"name": "Pedang Api",     "mp": 8,  "kind": "phys", "power": 1.6, "elem": "fire", "target": "enemy", "fx": "fire", "desc": "Pedang berselimut api. Elemen Api."},
	"pedangPetir":   {"name": "Pedang Petir",   "mp": 10, "kind": "phys", "power": 1.7, "elem": "thunder", "target": "enemy", "fx": "thunder", "desc": "Pedang beraliran petir. Elemen Petir."},
	"badaiPedang":   {"name": "Badai Pedang",   "mp": 16, "kind": "phys", "power": 1.25, "target": "enemies", "fx": "slashAll", "desc": "Gelombang tebasan ke semua musuh."},
	"tinjuBeruntun": {"name": "Tinju Beruntun", "mp": 5,  "kind": "phys", "power": 0.7, "hits": 3, "target": "enemy", "fx": "punch", "desc": "Tiga pukulan cepat ke satu musuh."},
	"tendanganEs":   {"name": "Tendangan Es",   "mp": 7,  "kind": "phys", "power": 1.6, "elem": "ice", "target": "enemy", "fx": "ice", "desc": "Tendangan berlapis es. Elemen Es."},
	"fokusChi":      {"name": "Fokus Chi",      "mp": 8,  "kind": "heal", "power": 1.6, "target": "self", "fx": "heal", "field": true, "desc": "Memulihkan HP diri sendiri."},
	"pusaranAngin":  {"name": "Pusaran Angin",  "mp": 14, "kind": "phys", "power": 1.2, "target": "enemies", "fx": "wind", "desc": "Tendangan berputar ke semua musuh."},
	"pulih":         {"name": "Pulih",          "mp": 5,  "kind": "heal", "power": 1.0, "target": "ally", "fx": "heal", "field": true, "desc": "Memulihkan HP satu kawan."},
	"kilat":         {"name": "Kilat",          "mp": 5,  "kind": "mag", "power": 1.2, "elem": "thunder", "target": "enemy", "fx": "thunder", "desc": "Sambaran petir ke satu musuh."},
	"api":           {"name": "Bola Api",       "mp": 6,  "kind": "mag", "power": 1.3, "elem": "fire", "target": "enemy", "fx": "fire", "desc": "Bola api ke satu musuh."},
	"es":            {"name": "Hujan Es",       "mp": 6,  "kind": "mag", "power": 1.3, "elem": "ice", "target": "enemy", "fx": "ice", "desc": "Pecahan es tajam ke satu musuh."},
	"pulihBersama":  {"name": "Pulih Bersama",  "mp": 14, "kind": "heal", "power": 0.7, "target": "allies", "fx": "heal", "field": true, "desc": "Memulihkan HP seluruh party."},
	"hidupkan":      {"name": "Hidupkan",       "mp": 18, "kind": "revive", "power": 0.4, "target": "deadAlly", "fx": "revive", "field": true, "desc": "Membangkitkan kawan yang tumbang (40% HP)."},
	"meteor":        {"name": "Meteor",         "mp": 24, "kind": "mag", "power": 1.35, "target": "enemies", "fx": "meteor", "desc": "Hujan batu langit ke semua musuh."},
}

const BURSTS := {
	"kael": {"name": "Tebasan Fajar", "kind": "phys", "power": 3.6, "target": "enemy", "fx": "burstSlash", "desc": "BURST: tebasan pamungkas yang dahsyat ke satu musuh."},
	"rina": {"name": "Seribu Tinju", "kind": "phys", "power": 0.85, "hits": 6, "target": "randomEnemies", "fx": "punch", "desc": "BURST: rentetan enam pukulan ke musuh acak."},
	"lyra": {"name": "Berkah Cahaya", "kind": "fullheal", "target": "allAllies", "fx": "holy", "desc": "BURST: pulihkan penuh dan bangkitkan seluruh party."},
}

const CHARS := {
	"kael": {"name": "Kael", "title": "Pendekar Pedang", "skillLabel": "Teknik", "weapon": "pedangBesi",
		"base": {"hp": 380, "mp": 24, "str": 16, "mag": 7, "def": 9, "spd": 20}, "growth": {"hp": .14, "mp": .10, "str": .11, "mag": .08, "def": .10, "spd": .04},
		"skills": [[1, "tebasan"], [4, "pedangApi"], [7, "pedangPetir"], [10, "badaiPedang"]]},
	"rina": {"name": "Rina", "title": "Petarung Tangan Kosong", "skillLabel": "Teknik", "weapon": "balutanTangan",
		"base": {"hp": 330, "mp": 20, "str": 14, "mag": 6, "def": 7, "spd": 28}, "growth": {"hp": .13, "mp": .10, "str": .12, "mag": .07, "def": .09, "spd": .05},
		"skills": [[1, "tinjuBeruntun"], [3, "tendanganEs"], [6, "fokusChi"], [9, "pusaranAngin"]]},
	"lyra": {"name": "Lyra", "title": "Penyihir Angin", "skillLabel": "Sihir", "weapon": "tongkatKayu",
		"base": {"hp": 270, "mp": 48, "str": 6, "mag": 16, "def": 6, "spd": 22}, "growth": {"hp": .12, "mp": .13, "str": .06, "mag": .12, "def": .08, "spd": .04},
		"skills": [[1, "pulih"], [1, "kilat"], [3, "api"], [4, "es"], [6, "pulihBersama"], [8, "hidupkan"], [11, "meteor"]]},
}

const ITEMS := {
	"ramuan":       {"name": "Ramuan", "price": 30, "kind": "item", "effect": {"hp": 150}, "desc": "Memulihkan 150 HP satu kawan."},
	"ramuanSuper":  {"name": "Ramuan Super", "price": 120, "kind": "item", "effect": {"hp": 450}, "desc": "Memulihkan 450 HP satu kawan."},
	"eter":         {"name": "Eter", "price": 90, "kind": "item", "effect": {"mp": 40}, "desc": "Memulihkan 40 MP satu kawan."},
	"penawar":      {"name": "Penawar", "price": 15, "kind": "item", "effect": {"cure": true}, "battleOnly": true, "desc": "Menyembuhkan racun."},
	"kristalHidup": {"name": "Kristal Kehidupan", "price": 200, "kind": "item", "effect": {"revive": 0.3}, "desc": "Membangkitkan kawan yang tumbang dengan 30% HP."},
	"pedangBesi":     {"name": "Pedang Besi", "kind": "weapon", "owner": "kael", "atk": 3},
	"pedangBaja":     {"name": "Pedang Baja", "price": 250, "kind": "weapon", "owner": "kael", "atk": 9, "desc": "Senjata Kael. Serangan +9."},
	"pedangKristal":  {"name": "Pedang Kristal", "kind": "weapon", "owner": "kael", "atk": 18, "desc": "Senjata Kael. Serangan +18."},
	"balutanTangan":  {"name": "Balutan Tangan", "kind": "weapon", "owner": "rina", "atk": 2},
	"sarungBesi":     {"name": "Sarung Tinju Besi", "price": 230, "kind": "weapon", "owner": "rina", "atk": 8, "desc": "Senjata Rina. Serangan +8."},
	"sarungNaga":     {"name": "Sarung Tinju Naga", "kind": "weapon", "owner": "rina", "atk": 16, "desc": "Senjata Rina. Serangan +16."},
	"tongkatKayu":    {"name": "Tongkat Kayu", "kind": "weapon", "owner": "lyra", "mag": 2},
	"tongkatKristal": {"name": "Tongkat Kristal", "price": 260, "kind": "weapon", "owner": "lyra", "mag": 7, "desc": "Senjata Lyra. Sihir +7."},
	"tongkatBintang": {"name": "Tongkat Bintang", "kind": "weapon", "owner": "lyra", "mag": 14, "desc": "Senjata Lyra. Sihir +14."},
	"bajuKain":    {"name": "Baju Kain", "kind": "armor", "def": 1},
	"rompiKulit":  {"name": "Rompi Kulit", "price": 120, "kind": "armor", "def": 5, "desc": "Pelindung. Pertahanan +5."},
	"zirahRantai": {"name": "Zirah Rantai", "price": 380, "kind": "armor", "def": 10, "desc": "Pelindung. Pertahanan +10."},
}
const SHOP := ["ramuan", "ramuanSuper", "eter", "penawar", "kristalHidup", "pedangBaja", "sarungBesi", "tongkatKristal", "rompiKulit", "zirahRantai"]

const ENEMIES := {
	"lendir":    {"name": "Lendir Hijau", "sprite": "slime", "scale": 5, "hp": 70, "atk": 12, "def": 3, "mag": 5, "spd": 16, "xp": 9, "gold": 6, "weak": ["fire"], "drop": ["ramuan", 0.15],
		"actions": [{"name": "Tubrukan", "kind": "phys", "power": 1.0, "w": 1}]},
	"lebah":     {"name": "Lebah Raksasa", "sprite": "bee", "scale": 5, "hp": 60, "atk": 13, "def": 3, "mag": 5, "spd": 34, "xp": 10, "gold": 7, "weak": ["ice"],
		"actions": [{"name": "Sengat", "kind": "phys", "power": 1.0, "w": 3}, {"name": "Sengat Racun", "kind": "phys", "power": 0.8, "poison": 0.6, "w": 1}]},
	"serigala":  {"name": "Serigala Abu", "sprite": "wolf", "scale": 5, "hp": 110, "atk": 16, "def": 5, "mag": 4, "spd": 30, "xp": 14, "gold": 10, "weak": ["fire"], "drop": ["ramuan", 0.2],
		"actions": [{"name": "Gigitan", "kind": "phys", "power": 1.0, "w": 3}, {"name": "Cakaran Ganas", "kind": "phys", "power": 1.4, "w": 1}]},
	"jamur":     {"name": "Jamur Racun", "sprite": "mushroom", "scale": 5, "hp": 180, "atk": 26, "def": 6, "mag": 19, "spd": 22, "xp": 20, "gold": 14, "weak": ["fire"], "drop": ["penawar", 0.3],
		"actions": [{"name": "Hantaman", "kind": "phys", "power": 1.0, "w": 2}, {"name": "Spora Racun", "kind": "mag", "power": 0.6, "target": "all", "poison": 0.4, "fx": "spore", "w": 1}]},
	"akar":      {"name": "Akar Hidup", "sprite": "treant", "scale": 5, "hp": 250, "atk": 30, "def": 9, "mag": 10, "spd": 24, "xp": 26, "gold": 18, "weak": ["fire"], "resist": ["thunder"], "drop": ["eter", 0.15],
		"actions": [{"name": "Cambuk Akar", "kind": "phys", "power": 1.0, "w": 1}]},
	"kelelawar": {"name": "Kelelawar Gua", "sprite": "bat", "scale": 5, "hp": 210, "atk": 31, "def": 8, "mag": 8, "spd": 40, "xp": 30, "gold": 20, "weak": ["thunder"], "drop": ["ramuan", 0.25],
		"actions": [{"name": "Gigitan", "kind": "phys", "power": 1.0, "w": 3}, {"name": "Hisap Darah", "kind": "phys", "power": 0.9, "drain": true, "w": 1}]},
	"rohApi":    {"name": "Roh Api", "sprite": "wisp", "scale": 5, "hp": 250, "atk": 22, "def": 6, "mag": 33, "spd": 30, "xp": 38, "gold": 26, "weak": ["ice"], "resist": ["fire"], "drop": ["eter", 0.25],
		"actions": [{"name": "Sentuhan Panas", "kind": "phys", "power": 0.8, "w": 1}, {"name": "Semburan Api", "kind": "mag", "power": 1.1, "fx": "fire", "w": 2}]},
	"golem":     {"name": "Golem Batu", "sprite": "golem", "scale": 6, "hp": 480, "atk": 39, "def": 20, "mag": 6, "spd": 14, "xp": 55, "gold": 45, "weak": ["ice"], "resist": ["fire"], "drop": ["ramuanSuper", 0.2],
		"actions": [{"name": "Tinju Batu", "kind": "phys", "power": 1.1, "w": 3}, {"name": "Gempa", "kind": "phys", "power": 0.7, "target": "all", "fx": "quake", "w": 1}]},
	"wyrm":      {"name": "Wyrm Kabut", "sprite": "wyrm", "scale": 8, "hp": 7000, "atk": 50, "def": 14, "mag": 42, "spd": 70, "xp": 1200, "gold": 800, "weak": ["thunder"], "boss": true,
		"actions": [
			{"name": "Cakar Wyrm", "kind": "phys", "power": 1.0, "w": 3},
			{"name": "Hempasan Ekor", "kind": "phys", "power": 1.5, "w": 1},
			{"name": "Napas Kabut", "kind": "mag", "power": 0.9, "target": "all", "fx": "mist", "w": 2},
			{"name": "Kabut Racun", "kind": "mag", "power": 0.4, "target": "all", "poison": 0.7, "fx": "spore", "w": 1},
		]},
}

const ENCOUNTERS := {
	"grass":  [["lendir"], ["lendir", "lendir"], ["serigala"], ["lebah", "lebah"], ["lendir", "lebah"], ["serigala", "lendir"], ["lebah", "lebah", "lendir"]],
	"forest": [["jamur"], ["jamur", "serigala"], ["akar"], ["akar", "lebah"], ["serigala", "serigala"], ["jamur", "jamur", "lebah"]],
	"cave":   [["kelelawar", "kelelawar"], ["rohApi"], ["golem"], ["kelelawar", "rohApi"], ["rohApi", "rohApi"], ["golem", "kelelawar"], ["kelelawar", "kelelawar", "kelelawar"]],
}


# ---------- Party ----------
func new_member(id: String) -> Member:
	var m := Member.new()
	m.id = id
	m.weapon = CHARS[id]["weapon"]
	refresh_stats(m)
	m.hp = m.s["maxHp"]
	m.mp = m.s["maxMp"]
	return m


func refresh_stats(m: Member) -> void:
	var c: Dictionary = CHARS[m.id]
	var g := func(k: String) -> int: return roundi(c["base"][k] * (1.0 + c["growth"][k] * (m.lvl - 1)))
	var w: Dictionary = ITEMS.get(m.weapon, {})
	var a: Dictionary = ITEMS.get(m.armor, {})
	m.s = {
		"maxHp": g.call("hp"), "maxMp": g.call("mp"), "str": g.call("str"), "mag": g.call("mag"),
		"def": g.call("def") + int(a.get("def", 0)), "spd": g.call("spd"),
		"atk": g.call("str") + int(w.get("atk", 0)), "matk": g.call("mag") + int(w.get("mag", 0)),
	}
	m.hp = mini(m.hp, m.s["maxHp"])
	m.mp = mini(m.mp, m.s["maxMp"])


func xp_next(lvl: int) -> int:
	return roundi(12.0 * pow(lvl, 1.7) + 12.0)


func skills_of(m: Member) -> Array:
	var out := []
	for e in CHARS[m.id]["skills"]:
		if e[0] <= m.lvl:
			out.append(e[1])
	return out


func field_skills(m: Member) -> Array:
	return skills_of(m).filter(func(id): return SKILLS[id].get("field", false))


func gain_xp(m: Member, amount: int) -> Array:
	var msgs := []
	var nm: String = CHARS[m.id]["name"]
	m.xp += amount
	while m.lvl < MAX_LVL and m.xp >= xp_next(m.lvl):
		m.xp -= xp_next(m.lvl)
		var old_hp: int = m.s["maxHp"]
		var old_mp: int = m.s["maxMp"]
		m.lvl += 1
		refresh_stats(m)
		m.hp += m.s["maxHp"] - old_hp
		m.mp += m.s["maxMp"] - old_mp
		msgs.append("%s naik ke Level %d! (HP +%d)" % [nm, m.lvl, m.s["maxHp"] - old_hp])
		for e in CHARS[m.id]["skills"]:
			if e[0] == m.lvl:
				msgs.append("%s mempelajari %s!" % [nm, SKILLS[e[1]]["name"]])
	if m.lvl >= MAX_LVL:
		m.xp = 0
	return msgs


func equip(m: Member, slot: String, id: String) -> void:
	m.set(slot, id)
	refresh_stats(m)


func member(id: String) -> Member:
	for m in Game.party:
		if m.id == id:
			return m
	return null


func gain_equip(id: String) -> Array:
	var it: Dictionary = ITEMS[id]
	var msgs := ["Mendapat %s!" % it["name"]]
	if it["kind"] == "weapon":
		var m := member(it["owner"])
		var cur: Dictionary = ITEMS[m.weapon]
		var score := func(x: Dictionary) -> int: return int(x.get("atk", 0)) + int(x.get("mag", 0))
		if score.call(it) > score.call(cur):
			equip(m, "weapon", id)
			msgs.append("%s langsung memakainya." % m.display_name())
		else:
			msgs.append("...tapi senjata yang dipakai sekarang lebih kuat.")
	return msgs


# ---------- Item ----------
func add_item(id: String, n := 1) -> void:
	Game.items[id] = int(Game.items.get(id, 0)) + n


func remove_item(id: String) -> void:
	Game.items[id] = maxi(0, int(Game.items.get(id, 0)) - 1)
	if Game.items[id] == 0:
		Game.items.erase(id)


func can_use_item(id: String, m: Member) -> bool:
	var ef: Dictionary = ITEMS[id]["effect"]
	if ef.has("revive"):
		return m.hp <= 0
	if m.hp <= 0:
		return false
	if ef.has("hp"):
		return m.hp < m.s["maxHp"]
	if ef.has("mp"):
		return m.mp < m.s["maxMp"]
	if ef.has("cure"):
		return m.poison
	return false


func apply_item(id: String, m: Member) -> Dictionary:
	var ef: Dictionary = ITEMS[id]["effect"]
	var r := {}
	if ef.has("revive"):
		if m.hp > 0:
			return r
		m.hp = maxi(1, floori(m.s["maxHp"] * ef["revive"]))
		r["revived"] = true
		r["hp"] = m.hp
		return r
	if m.hp <= 0:
		return r
	if ef.has("hp"):
		var b := m.hp
		m.hp = mini(m.s["maxHp"], m.hp + int(ef["hp"]))
		r["hp"] = m.hp - b
	if ef.has("mp"):
		var b2 := m.mp
		m.mp = mini(m.s["maxMp"], m.mp + int(ef["mp"]))
		r["mp"] = m.mp - b2
	if ef.has("cure"):
		r["cured"] = m.poison
		m.poison = false
	return r


func full_heal() -> void:
	for m in Game.party:
		m.hp = m.s["maxHp"]
		m.mp = m.s["maxMp"]
		m.poison = false


# ---------- Rumus damage ----------
func phys_damage(atk: float, def: float, power: float) -> float:
	return atk * atk / (atk + def) * 3.0 * power


func mag_damage(mag: float, def: float, power: float) -> float:
	return mag * mag / (mag + def * 0.6) * 3.2 * power


func heal_power(m: Member, sk: Dictionary) -> int:
	return roundi((maxf(m.s["matk"], m.s["atk"] * 0.8) * 5.0 + 40.0) * sk["power"])
