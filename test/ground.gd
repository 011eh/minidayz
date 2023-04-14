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


func _ready():
#	init()
	init_area()
	pass

func init_area():
	var number := 25
	var map_size_in_area := ceil(sqrt(number)) as int
	var area_size := MAP_AREA_SIZE / float(map_size_in_area)
	var points: Array[Vector2i]
	var areas: Array[Vector2]
	
	for x in range(map_size_in_area):
		for y in range(map_size_in_area):
			areas.append(Vector2(x * area_size, y * area_size))
	
	areas.shuffle()
	for i in range(areas.size() - number):
		areas.pop_back()
	
	var i := 0
	while i < number:
		var p := Vector2i(areas[i].x + randi() % int(area_size), areas[i].y +  randi() % int(area_size))
		var rect := Rect2i(p - Vector2i.ONE, Vector2i.ONE * 3)
		if points.any(func(v) -> bool: return rect.has_point(v)):
			continue
		i += 1
		points.append(p)
	terr_set_terrain(2, get_cells_in_blocks(points, BLOCK_AREA_SIZE_IN_TERRAIN_CELLS), 0, 3)
	create_path(points)

func create_path(location_coord: Array[Vector2i]):
	var path_blocks: Array[Vector2i]
	var dict: Dictionary
	for p in location_coord:
		var k:= 'x-%d' % p.x
		if not dict.has(k):
			dict[k] = [p.x]
		else:
			dict[k].append(p.x)
		
		k = 'y-%d' % p.y
		if not dict.has(k):
			dict[k] =[p.y]
		else:
			dict[k].append(p.y)
	var keys := dict.keys()
	keys.sort()
	for key in keys:
		var array := dict.get(key) as Array
		if array.size() > 1:
			var s := array.pop_back() as int
			var e := array.pop_back() as int
			if key[0] == 'x':
				for n in range(s, e, 1 if s > e else -1):
					path_blocks.append(Vector2i(n, int(key[2])))
			else:
				for n in range(s, e, 1 if s > e else -1):
					path_blocks.append(Vector2i(int(key[2]), n))
	print(path_blocks)

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

func get_cells_in_blocks(blocks: Array[Vector2i], area_size: int) -> Array[Vector2i]:
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
