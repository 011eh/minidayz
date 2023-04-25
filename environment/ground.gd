extends Node2D


enum Tile {TERRAIN, DECORATION}
enum BlockType {
	GRASSLAND,
	LAKE,
	VILLAGE,
	CITY,
	HOSPITAL,
	FIRE_STATION,
	NATO_MILITARY_CAMP,
	WARSAW_PACT_MILITARY_CAMP,
	SHOOTING_RANGE,
	CAMP_SITE,
	GAS_STATION_X,
	GAS_STATION_Y,
	ROAD_X,
	ROAD_X_NEG_Y,
	ROAD_X_POS_Y,
	ROAD_Y,
	ROAD_Y_NEG_X,
	ROAD_Y_POS_X,
	CROSSROAD,
}


const SIZE_IN_CELLS := 14
const MAP_AREA_SIZE := 16


var noise := FastNoiseLite.new()
@onready
var terrain := %Terrain
@onready
var decoration := %Decoration


func _ready():
	var s := randi()
	print(s)
	seed(s)
	init()
	pass

func init():
	var location_number := 25
	var i := 0
	var location_block: Array[Vector2i]
	while i < location_number:
		var p := Vector2i(randi() % MAP_AREA_SIZE, randi() % MAP_AREA_SIZE)
		var rect := Rect2i(p - Vector2i.ONE, Vector2i.ONE * 3)
		if location_block.any(func(v) -> bool: return rect.has_point(v)):
			continue
		i += 1
		location_block.append(p)
	var block_dict := create_path_block(location_block)
	terr_set_terrain(0, get_cells_in_blocks(location_block, SIZE_IN_CELLS), 0, 0,false)
	terr_set_terrain(0, get_cells_in_path_blocks(block_dict), 0, 1, false)
#	terr_set_terrain(1, get_cells_in_blocks(paths_block_dict.keys(), SIZE_IN_CELLS), 0, 2)

func create_path_block(location_coords: Array[Vector2i]) -> Dictionary:
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
		if array.size() > 1 and randf() < 0.9:
			array.sort()
			var index := randi() % (array.size() - 1)
			var axis_value := int(key.substr(2))
			if key[0] == 'x':
				for n in range(array[index] + 1, array[index + 1]):
					var p := Vector2i(axis_value, n)
					path_dict[p] = terr_get_path_block_type('x', p, path_dict, location_coords)
			else:
				for n in range(array[index] + 1, array[index + 1]):
					var p := Vector2i(n, axis_value)
					path_dict[p] = terr_get_path_block_type('y', p, path_dict, location_coords)
	return path_dict

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

func get_cells_in_path_blocks(path_block_dict: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i]
	for v in path_block_dict.keys():
		var type := path_block_dict.get(v) as BlockType
		if type == BlockType.CROSSROAD:
			cells.append_array(terr_get_crossroad_cells(v, Rect2i(v.x * SIZE_IN_CELLS , v.y * SIZE_IN_CELLS + 5, 14, 4)))
			cells.append_array(terr_get_crossroad_cells(v, Rect2i(v.x * SIZE_IN_CELLS + 5, v.y * SIZE_IN_CELLS, 4, 14)))
			continue
		
		var direction := 'x' if type in [BlockType.ROAD_X, BlockType.ROAD_X_NEG_Y, BlockType.ROAD_X_POS_Y] else 'y'
		var rect := Rect2i(v.x * SIZE_IN_CELLS , v.y * SIZE_IN_CELLS + 5, 14, 4) if direction == 'x' \
			else Rect2i(v.x * SIZE_IN_CELLS + 5, v.y * SIZE_IN_CELLS, 4, 14)
		cells.append_array(terr_get_crossroad_cells(v, rect))
		if type in [BlockType.ROAD_X, BlockType.ROAD_Y]:
			continue
		
		var offset := 0 if type in [BlockType.ROAD_X_NEG_Y, BlockType.ROAD_Y_NEG_X] else 9
		rect = Rect2i(v.x * SIZE_IN_CELLS + 5, v.y * SIZE_IN_CELLS + offset, 4, 5) if direction == 'x' \
			else Rect2i(v.x * SIZE_IN_CELLS + offset, v.y * SIZE_IN_CELLS + 5, 5, 4)
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			for y in range(rect.position.y, rect.position.y + rect.size.y):
				cells.append(Vector2i(x, y))
	return cells

func terr_get_crossroad_cells(block_coords: Vector2i, road_rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i]
	for x in range(road_rect.position.x, road_rect.position.x + road_rect.size.x):
			for y in range(road_rect.position.y, road_rect.position.y + road_rect.size.y):
				cells.append(Vector2i(x, y))
	return cells

func terr_set_terrain(layer: int, cells: Array[Vector2i], terrain_set: int, terr: int, with_grass_layer: bool = true):
	terrain.set_cells_terrain_connect(layer, cells, terrain_set, terr, false)
	if with_grass_layer:
		terr_set_terrain(0, cells, 0, 0, false)

func terr_get_path_block_type(axis: String, coords: Vector2i, paths: Dictionary, locations := [] as Array[Vector2i]) \
	-> BlockType:
	if paths.has(coords):
		return BlockType.CROSSROAD
	else:
		var type: BlockType
		if axis == 'x':
			type = BlockType.ROAD_Y
			if locations.has(Vector2i(coords.x - 1, coords.y)):
					type = BlockType.ROAD_Y_NEG_X
			if locations.has(Vector2i(coords.x + 1, coords.y)):
					type = BlockType.CROSSROAD if type == BlockType.ROAD_Y_NEG_X else BlockType.ROAD_Y_POS_X
		else:
			type = BlockType.ROAD_X
			if locations.has(Vector2i(coords.x, coords.y - 1)):
					type = BlockType.ROAD_X_NEG_Y
			if locations.has(Vector2i(coords.x, coords.y + 1)):
					type = BlockType.CROSSROAD if type == BlockType.ROAD_X_NEG_Y else BlockType.ROAD_X_POS_Y
		return type

# https://github.com/godotengine/godot/blob/b1c18f807bfa3ad2e807ad920bc5f55b5e4061bd/editor/plugins/tiles/tile_map_editor.cpp
func pick_random_tile(tile: Tile, pattern: int, scattering: float = 0) -> Vector2i:
	var tile_map := terrain if tile == Tile.TERRAIN else decoration
	var p := tile_map.tile_set.get_pattern(pattern) as TileMapPattern
	var source := tile_map.tile_set.get_source(0) as TileSetAtlasSource
	var sum := 0.0
	for coords in p.get_used_cells().map(func(c) -> Vector2i: return p.get_cell_atlas_coords(c)):
		sum += source.get_tile_data(coords, 0).probability
	
	var current := 0.0
	var rand = randf_range(0, sum + sum * scattering)
	for cell in p.get_used_cells():
		var coords := p.get_cell_atlas_coords(cell)
		current += source.get_tile_data(coords, 0).probability
		if current >= rand:
			return coords
	return Vector2i(-1, -1)
