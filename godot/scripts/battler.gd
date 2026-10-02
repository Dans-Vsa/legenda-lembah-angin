class_name Battler
extends RefCounted
## Data bersama untuk anggota party dan musuh di battle.

var hp := 0
var atb := 0.0
var is_enemy := false
# Status visual (dianimasikan dengan tween)
var ox := 0.0
var oy := 0.0
var alpha := 1.0
var flash := 0.0
var shake := 0.0


func display_name() -> String:
	return ""
