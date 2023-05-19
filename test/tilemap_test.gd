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
	queue_redraw()

func _draw():
	var p := player.global_position / 16 / 60 as Vector2i
	print(p)
	draw_rect(Rect2(p.x,p.y, 60 * 17, 60 * 17),Color.RED)
