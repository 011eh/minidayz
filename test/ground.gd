extends Node2D


const TERRAIN_BLOCK_SIZE_IN_CELLS := 14
const MAP_SIZE := 16


var noise := FastNoiseLite.new()
@onready
var terrain := %Terrain
@onready
var decoration := %Decoration


func _ready():
	init()
	pass

func init() -> void:
	noise.seed = randi()
	var grass: Array[Vector2i]
	var path: Array[Vector2i]
	var sand: Array[Vector2i]
	var water: Array[Vector2i]
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			grass.append(Vector2i(x, y))
			var n := noise.get_noise_2d(x, y)
			if n < 0:
				continue
			elif n < 0.3:
				path.append(Vector2i(x, y))
			elif n < 0.6:
				sand.append(Vector2i(x, y))
			else:
				water.append(Vector2i(x, y))
	
	Thread.new().start(func(): terrain.set_cells_terrain_connect(1, get_cells_in_blocks(sand), 0, 2, false))
	Thread.new().start(func(): terrain.set_cells_terrain_connect(2, get_cells_in_blocks(water), 0, 3, false))
	terrain.set_cells_terrain_connect(0, get_cells_in_blocks(grass), 0, 0, false)
	terrain.set_cells_terrain_connect(0, get_cells_in_blocks(path), 0, 1, false)

func get_cells_in_blocks(blocks: Array[Vector2i]) -> Array[Vector2i]:
	var cells: Array[Vector2i]
	for array in blocks.map(func(v):
		var cells_in_block: Array[Vector2i]
		for x in range(TERRAIN_BLOCK_SIZE_IN_CELLS + 1):
			for y in range(TERRAIN_BLOCK_SIZE_IN_CELLS + 1):
				cells_in_block.append(v * TERRAIN_BLOCK_SIZE_IN_CELLS + Vector2i(x, y))
		return cells_in_block
	):
		cells.append_array(array)
	return cells
