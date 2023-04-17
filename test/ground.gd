extends Node2D


enum DecoPattern {
	GRASS, PATH, HUMAN, GRASS_SNOW
}


const BLOCK_AREA_SIZE_IN_TERRAIN_CELLS := 14
const MAP_AREA_SIZE := 16


var noise := FastNoiseLite.new()
@onready
var terrain := %Terrain
@onready
var decoration := %Decoration
@onready
var tilemap := $TileMap


func _ready():
#	init()
	seed(1)
	init_area(25)
	pass

func init_area(location_number: int):
	var i := 0
	var location_block: Array[Vector2i]
	while i < location_number:
		var p := Vector2i(randi() % MAP_AREA_SIZE, randi() % MAP_AREA_SIZE)
		var rect := Rect2i(p - Vector2i.ONE, Vector2i.ONE * 3)
		if location_block.any(func(v) -> bool: return rect.has_point(v)):
			continue
		i += 1
		location_block.append(p)
	var paths_block_dict := create_path(location_block)
#	terr_set_terrain(2, get_cells_in_blocks(location_block, BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 3)
#	terr_set_terrain(1, get_cells_in_blocks(paths_block_dict.keys(), BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 2)

func create_path(location_coords: Array[Vector2i]) -> Dictionary:
	var path_dict: Dictionary
	var axis_dict: Dictionary
	for p in location_coords:
		var axis := 'x-%d' % p.x
		if not axis_dict.has(axis):
			axis_dict[axis] = PackedInt32Array([p.y])
		else:
			axis_dict[axis].append(p.y)
		
		axis = 'y-%d' % p.y
		if not axis_dict.has(axis):
			axis_dict[axis] = PackedInt32Array([p.x])
		else:
			axis_dict[axis].append(p.x)
	for key in axis_dict.keys():
		var array := axis_dict.get(key) as PackedInt32Array
		if array.size() > 1:
			array.sort()
			var index := randi() % (array.size() - 1)
			var axis_value := int(key.substr(2))
			if key[0] == 'x':
				for n in range(array[index] + 1, array[index + 1]):
					var p := Vector2i(axis_value, n)
					path_dict[p] = terr_get_path_type('x', p, path_dict, location_coords)
			else: 
				for n in range(array[index] + 1, array[index + 1]):
					var p := Vector2i(n, axis_value)
					path_dict[p] = terr_get_path_type('y', p, path_dict, location_coords)
	return path_dict

func init() -> void:
	noise.seed = randi()
	var grass: Array[Vector2i]
	var path: Array[Vector2i]
	var sand: Array[Vector2i]
	var water: Array[Vector2i]
	for x in range(MAP_AREA_SIZE):
		for y in range(MAP_AREA_SIZE):
			var n := noise.get_noise_2d(x, y)
			if n < 0:
				grass.append(Vector2i(x, y))
			elif n < 0.3:
				path.append(Vector2i(x, y))
			elif n < 0.4:
				sand.append(Vector2i(x, y))
			else:
				water.append(Vector2i(x, y))
	terr_set_terrain(0, get_cells_in_blocks(grass, BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 0, false)
	terr_set_terrain(0, get_cells_in_blocks(path, BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 1, false)
	terr_set_terrain(1, get_cells_in_blocks(sand, BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 2)
	terr_set_terrain(2, get_cells_in_blocks(water, BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 3)
	for v in get_cells_in_blocks(grass,BLOCK_AREA_SIZE_IN_TERRAIN_CELLS * 2):
		decoration.set_cell(0, v, 0, deco_pick_random_tile(DecoPattern.GRASS, 5))

func get_cells_in_blocks(blocks: Array, area_size: int) -> Array[Vector2i]:
	var cells: Array[Vector2i]
	for array in blocks.map(func(v):
		var cells_in_block: Array[Vector2i]
		for x in range(area_size):
			for y in range(area_size):
				cells_in_block.append(v * area_size + Vector2i(x, y))
		return cells_in_block
	):
		cells.append_array(array)
	return cells

func terr_set_terrain(layer: int, cells: Array[Vector2i], terrain_set: int, terr: int, with_grass_layer: bool = true):
	terrain.set_cells_terrain_connect(layer, cells, terrain_set, terr, false)
	if with_grass_layer:
		terr_set_terrain(0, cells, 0, 0, false)

func terr_get_path_type(axis: String, coord: Vector2i, paths: Dictionary, locations: Array[Vector2i]) -> Vector2i:
	if paths.has(coord):
		return Vector2i(2, 2)
	else:
		var v: Vector2
		if axis == 'x':
			v = Vector2i(0, 2)
			if locations.has(Vector2i(coord.x - 1, coord.y)):
					v.x = -1
			if locations.has(Vector2i(coord.x + 1, coord.y)):
					v.x = 1 if v.x == 0 else 2
		else:
			v = Vector2i(2, 0)
			if locations.has(Vector2i(coord.x, coord.y - 1)):
					v.y = -1
			if locations.has(Vector2i(coord.x, coord.y + 1)):
					v.y = 1 if v.y == 0 else 2
		return v

# https://github.com/godotengine/godot/blob/b1c18f807bfa3ad2e807ad920bc5f55b5e4061bd/editor/plugins/tiles/tile_map_editor.cpp
func deco_pick_random_tile(pattern: DecoPattern, scattering: float) -> Vector2i:
	var p := decoration.tile_set.get_pattern(pattern) as TileMapPattern
	var source := decoration.tile_set.get_source(0) as TileSetAtlasSource
	var sum := 0.0
	for v in p.get_used_cells():
		sum += source.get_tile_data(v, 0).probability
	
	var current := 0.0
	var rand = randf_range(0, sum + sum * scattering)
	for v in p.get_used_cells():
		current += source.get_tile_data(v, 0).probability
		if current >= rand:
			return v
	return Vector2(-1, -1)
