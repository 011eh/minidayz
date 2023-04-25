extends Node2D


var size = 224
@onready
var ground := $Ground
@onready
var player := $Player
@onready
var terrain := ground.terrain as TileMap
  
func _ready():
	PlayerStatus.speed = 5000
	
	pass

func _process(delta):
	var v := terrain.local_to_map(player.global_position)
	$Player/Label.text = '%s' % (v / 14)
	
