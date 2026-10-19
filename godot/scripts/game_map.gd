@tool
class_name GameMap
extends Node2D
## Akar scene peta. Anak-anaknya:
##   Ground  : TileMapLayer (lukis tile di sini)
##   Labels  : tulisan di atas bangunan
##   Objects : NPC, peti, papan, kristal, bos
##   Warps   : titik pindah peta
##   Doors   : pintu bangunan

@export var map_name := ""
@export_enum("town", "field", "cave") var music := "town"
## Peta gelap dengan cahaya di sekitar pemain.
@export var dark := false
## Tile pengganti untuk petak kosong.
@export var pad := "T"
## Tile yang memicu monster: karakter tile -> zona (grass / forest / cave).
@export var zones: Dictionary = {}
