extends Node2D

var size := 14
var noise := FastNoiseLite.new()
@onready
var ground := $Ground

func _ready():
	noise.seed = randi()
	PlayerStatus.speed = 500
	var a0:=[]
	var a1:=[]
	var a2:=[]
	var a3:=[]
	for x in range(size + 1):
		for y in range(size + 1):
			a0.append(Vector2i(x, y))
			var n := noise.get_noise_2d(x, y)
			if n < 0:
				continue
#			elif n < 0.3:
#				a1.append(Vector2i(x, y))
#			elif n < 0.6:
#				a2.append(Vector2i(x, y))
			else:
				a3.append(Vector2i(x, y))

	ground.set_cells_terrain_connect(0, a0, 0, 0, false)
	Thread.new().start(func(): ground.set_cells_terrain_connect(0, a1, 0, 1, false))
	Thread.new().start(func(): ground.set_cells_terrain_connect(1, a2, 0, 3, false))
	Thread.new().start(func(): ground.set_cells_terrain_connect(2, a3, 0, 2, false))
