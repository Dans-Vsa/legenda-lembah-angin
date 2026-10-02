class_name Foe
extends Battler
## Musuh di battle.

var tpl := {}
var name := ""
var max_hp := 0
var atk := 0
var def := 0
var mag := 0
var spd := 0
var x := 0.0
var y := 0.0
var tex: Texture2D
var white: Texture2D
var w := 0.0
var h := 0.0
var dead := false
var phase := 0.0


func display_name() -> String:
	return name
