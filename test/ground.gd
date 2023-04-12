extends Node2D


enum DecoPattern {
	GRASS, PATH, HUMAN, GRASS_SNOW
}


const BLOCK_SIZE_IN_TERRAIN_CELLS := 14
const MAP_SIZE := 16


var noise := FastNoiseLite.new()
@onready
var terrain := %Terrain
@onready
var decoration := %Decoration


func _ready():
#	init()
	var points: Array[Vector2i] = []

# 生成25个点
	for i in range(25):
		var x = ((i % 5) * 3) + randf_range(-1.5, 1.5)
		var y = (floor(i / 5) * 3) + randf_range(-1.5, 1.5)
		points.append(Vector2i(x, y))

#	var a: Array[Vector2i] = []
#	for i in range(20):
#		a.append(Vector2i(randi() % 16, randi() % 16))
	terr_set_terrain(2, get_cells_in_blocks(points, BLOCK_SIZE_IN_TERRAIN_CELLS), 0, 3)
	pass

func init() -> void:
	noise.seed = randi()
	var grass: Array[Vector2i]
	var path: Array[Vector2i]
	var sand: Array[Vector2i]
	var water: Array[Vector2i]
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var n := noise.get_noise_2d(x, y)
			if n < 0:
				grass.append(Vector2i(x, y))
			elif n < 0.3:
				path.append(Vector2i(x, y))
			elif n < 0.4:
				sand.append(Vector2i(x, y))
			else:
				water.append(Vector2i(x, y))
	terr_set_terrain(0, get_cells_in_blocks(grass, BLOCK_SIZE_IN_TERRAIN_CELLS), 0, 0, false)
	terr_set_terrain(0, get_cells_in_blocks(path, BLOCK_SIZE_IN_TERRAIN_CELLS), 0, 1, false)
	terr_set_terrain(1, get_cells_in_blocks(sand, BLOCK_SIZE_IN_TERRAIN_CELLS), 0, 2)
	terr_set_terrain(2, get_cells_in_blocks(water, BLOCK_SIZE_IN_TERRAIN_CELLS), 0, 3)
	for v in get_cells_in_blocks(grass,BLOCK_SIZE_IN_TERRAIN_CELLS * 2):
		decoration.set_cell(0, v, 0, deco_pick_random_tile(DecoPattern.GRASS, 5))

func get_cells_in_blocks(blocks: Array[Vector2i], size: int) -> Array[Vector2i]:
	var cells: Array[Vector2i]
	for array in blocks.map(func(v):
		var cells_in_block: Array[Vector2i]
		for x in range(size):
			for y in range(size):
				cells_in_block.append(v * size + Vector2i(x, y))
		return cells_in_block
	):
		cells.append_array(array)
	return cells

func terr_set_terrain(layer: int, cells: Array[Vector2i], terrain_set: int, terr: int, with_grass_layer: bool = true):
	terrain.set_cells_terrain_connect(layer, cells, terrain_set, terr, false)
	if with_grass_layer:
		terr_set_terrain(0, cells, 0, 0, false)

# https://github.com/godotengine/godot/blob/b1c18f807bfa3ad2e807ad920bc5f55b5e4061bd/editor/plugins/tiles/tile_map_editor.cpp
func deco_pick_random_tile(pattern: DecoPattern, scattering: float) -> Vector2i:
	var p: TileMapPattern = decoration.tile_set.get_pattern(pattern)
	var source: TileSetAtlasSource = decoration.tile_set.get_source(0)
	var sum: float = 0
	for v in p.get_used_cells():
		sum += source.get_tile_data(v, 0).probability
	
	var current := 0.0
	var rand = randf_range(0, sum + sum * scattering)
	for v in p.get_used_cells():
		current += source.get_tile_data(v, 0).probability
		if current >= rand:
			return v
	return Vector2(-1, -1)
