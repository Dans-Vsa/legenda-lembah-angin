class_name Member
extends Battler
## Anggota party (Kael, Rina, Lyra).

var id := ""
var lvl := 1
var xp := 0
var mp := 0
var burst := 0.0
var weapon := ""
var armor := "bajuKain"
var poison := false
var defending := false
var s := {}          # stat hasil hitungan: maxHp, maxMp, str, mag, def, spd, atk, matk
var bx := 0.0        # posisi dasar di battle
var by := 0.0
var last_skill := 0
var last_item := 0


func display_name() -> String:
	return Data.CHARS[id]["name"]


func to_save() -> Dictionary:
	return {"id": id, "lvl": lvl, "xp": xp, "hp": hp, "mp": mp, "burst": burst, "weapon": weapon, "armor": armor}
