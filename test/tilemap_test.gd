extends Node2D


@onready
var ground := $Ground
var size = 50
var noise := FastNoiseLite.new()

func _ready():
	print($Node2D/B.get_viewport_rect())

func _draw():
	pass

func _process(delta):
	queue_redraw()
	var direction = Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
	$Skin.position += direction * 500 * delta
	var v := Rect2($Skin/Camera2D.global_position - $Skin/Camera2D.get_viewport_rect().size / 2, $Skin/Camera2D.get_viewport_rect().size)
	print(v)
	print(v.intersects(Rect2($Node2D/B.global_position + $Node2D/B.offset,$Node2D/B.get_rect().size)))
	print(Rect2($Node2D/B.global_position + $Node2D/B.offset,$Node2D/B.get_rect().size))

func noise_map():
	noise.seed = randi()
	PlayerStatus.speed = 500
	var a0:=[]
	var a1:=[]
	var a2:=[]
	var a3:=[]
	for x in range(size):
		for y in range(size):
			var n := noise.get_noise_2d(x, y)
			if n > 0:
				a1.append(Vector2i(x, y))
			a0.append(Vector2i(x, y))
#
#	tile_map.set_cells_terrain_connect(0, a0, 0, 0, false)
#	tile_map.set_cells_terrain_connect(0, a1, 0, 1, false)
