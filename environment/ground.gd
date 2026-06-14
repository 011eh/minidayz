extends Node2D

@onready var ground_layer := %GroundLayer
@onready var decoration_layer := %DecorationLayer

@export var map_seed: int = 0
@export var auto_render_decoration := true

@export_group("Decoration Scattering")
@export_range(0.0, 100.0, 0.1, "suffix:%")
var village_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var city_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var military_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var hospital_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var firestation_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var grass_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var water_edge_scattering: float = 20.0
@export_range(0.0, 100.0, 0.1, "suffix:%")
var road_debris_scattering: float = 20.0

const BLOCK_SIZE_IN_TILE := 17
const MAP_SIZE_IN_BLOCKS := 16

# 272
const TOTAL_MAP_SIZE := BLOCK_SIZE_IN_TILE * MAP_SIZE_IN_BLOCKS
const TILE_PX := 60

# 1020
const BLOCK_PX := BLOCK_SIZE_IN_TILE * TILE_PX
const ROAD_WIDTH := 4
const DECO_TILE_PX := 30

# 34
const DECO_BLOCK_SIZE := BLOCK_PX / DECO_TILE_PX

# 2
const DECO_TILES_PER_GROUND_TILE := TILE_PX / DECO_TILE_PX

# 6
const ROAD_MIN_IN_BLOCK := BLOCK_SIZE_IN_TILE / 2 - ROAD_WIDTH / 2

# 10
const ROAD_MAX_IN_BLOCK := ROAD_MIN_IN_BLOCK + ROAD_WIDTH

# 12
const DECO_ROAD_MIN := ROAD_MIN_IN_BLOCK * DECO_TILES_PER_GROUND_TILE

# 20
const DECO_ROAD_MAX := ROAD_MAX_IN_BLOCK * DECO_TILES_PER_GROUND_TILE

# atlas source id
const DECO_SRC_GRASS := 0
const DECO_SRC_ROAD := 1
const DECO_SRC_VILLAGE := 2
const DECO_SRC_CITY := 3
const DECO_SRC_MILITARY := 4
const DECO_SRC_WATER_EDGE := 5


enum BlockType {
	EMPTY,
	VILLAGE,
	CITY,
	MILITARY,
	HOSPITAL,
	FIRESTATION,
	ROAD_H,
	ROAD_V,
	ROAD_CROSS,
	ROAD_H_UP,
	ROAD_H_DOWN,
	ROAD_V_LEFT,
	ROAD_V_RIGHT,
	SECRET,
	WATER,
}

const LOCATION_TYPES := [
	BlockType.VILLAGE, BlockType.CITY, BlockType.MILITARY,
	BlockType.HOSPITAL, BlockType.FIRESTATION,
]

const ROAD_TYPES := [
	BlockType.ROAD_H,
	BlockType.ROAD_V,
	BlockType.ROAD_CROSS,
	BlockType.ROAD_H_UP,
	BlockType.ROAD_H_DOWN,
	BlockType.ROAD_V_LEFT,
	BlockType.ROAD_V_RIGHT,
]

const ROAD_CONNECT_TYPES := [
	BlockType.VILLAGE, BlockType.CITY, BlockType.HOSPITAL, BlockType.FIRESTATION,
]

const LEVEL_LOCATION_COUNTS := {
	0: {"village": 20, "city": 3, "military": 0, "hospital": 1, "firestation": 1, "secret": 1, "gas": 1},
	1: {"village": 15, "city": 5, "military": 2, "hospital": 2, "firestation": 2, "secret": 1, "gas": 2},
	2: {"village": 6, "city": 10, "military": 4, "hospital": 3, "firestation": 3, "secret": 1, "gas": 3},
	3: {"village": 3, "city": 11, "military": 6, "hospital": 4, "firestation": 2, "secret": 1, "gas": 4},
}


var current_level := 0
var grid: Array[Array] = []

# [{ block:Vector2i, type:BlockType, hotspot:Vector2 }]，供阶段 C 实例化
var locations: Array[Dictionary] = []

# 5 类地点的 block 坐标（占位渲染 + 调试用）
var towns: Array[Vector2i] = []
var roads: Array[Array] = []
var gas_station_count := 0
var rng: RandomNumberGenerator


func _ready():
	rng = RandomNumberGenerator.new()
	if map_seed != 0:
		rng.seed = map_seed
	else:
		rng.randomize()
	print("种子：", rng.get_seed())
	generate_world()

func generate_world():
	"""Main generation function（对标原版步骤 2→3→4）"""
	init_grid()
	generate_locations()
	generate_roads()
	generate_secret_place()
	collect_locations()
	render_map()

# 重新生成整张地图（道路写入 grid，无法只重算道路，故整图重来）
func regenerate():
	"""清空并重新生成整张地图"""
	ground_layer.clear()
	generate_world()

func set_seed(seed_value: int):
	"""Set random seed for reproducible generation"""
	rng.seed = seed_value

func get_generation_info() -> Dictionary:
	"""Return information about the generated world"""
	return {
		"towns": towns,
		"roads": roads.size(),
		"total_blocks": MAP_SIZE_IN_BLOCKS * MAP_SIZE_IN_BLOCKS,
		"town_distribution": analyze_town_distribution(),
		"connectivity_info": get_connectivity_info()
	}

func get_connectivity_info() -> Dictionary:
	"""获取连接性信息"""
	var connected_towns := {}
	var isolated_count := 0

	for road in roads:
		if road.size() >= 2:
			var start_town = road[0]
			var end_town = road[road.size() - 1]
			connected_towns[start_town] = true
			connected_towns[end_town] = true

	isolated_count = towns.size() - connected_towns.size()

	return {
		"connected_towns": connected_towns.size(),
		"isolated_towns": isolated_count,
		"connection_rate": float(connected_towns.size()) / float(towns.size()) if towns.size() > 0 else 0.0
	}

func init_grid():
	"""把 grid 重置为 16×16 全 EMPTY"""
	grid.clear()
	for y in range(MAP_SIZE_IN_BLOCKS):
		var row := []
		row.resize(MAP_SIZE_IN_BLOCKS)
		row.fill(BlockType.EMPTY)
		grid.append(row)

func is_in_grid(x: int, y: int) -> bool:
	"""block 坐标是否在 16×16 网格内"""
	return x >= 0 and x < MAP_SIZE_IN_BLOCKS and y >= 0 and y < MAP_SIZE_IN_BLOCKS

func get_block(x: int, y: int) -> BlockType:
	"""读取 block 类型；越界返回 EMPTY（便于「扫描相邻格」时无需特判边界）"""
	if not is_in_grid(x, y):
		return BlockType.EMPTY
	return grid[y][x]

func set_block(x: int, y: int, type: BlockType):
	"""写入 block 类型（越界忽略）"""
	if is_in_grid(x, y):
		grid[y][x] = type

func is_location(type: BlockType) -> bool:
	"""是否为 5 类地点之一（村庄/城市/军营/医院/消防站）"""
	return type in LOCATION_TYPES

func is_road(type: BlockType) -> bool:
	"""是否为道路（横/纵/十字/丁字）"""
	return type in ROAD_TYPES

func is_water(type: BlockType) -> bool:
	"""是否为水域"""
	return type == BlockType.WATER

func generate_locations():
	"""按关卡数量表，分 5 类用「3×3 邻域全空」算法落子并写入 grid"""
	var counts = LEVEL_LOCATION_COUNTS.get(current_level, LEVEL_LOCATION_COUNTS[0])
	gas_station_count = counts["gas"]

	_place_type(BlockType.VILLAGE, counts["village"])
	_place_type(BlockType.MILITARY, counts["military"])
	_place_type(BlockType.CITY, counts["city"])
	_place_type(BlockType.HOSPITAL, counts["hospital"])
	_place_type(BlockType.FIRESTATION, counts["firestation"])

func _place_type(type: BlockType, count: int):
	"""随机抽格，要求 3×3 邻域全空则在中心落子，否则重抽，直到放满 count 个"""
	var placed := 0
	var attempts := 0
	var max_attempts := count * 500 + 1000
	while placed < count and attempts < max_attempts:
		attempts += 1
		var p := Vector2i(
			rng.randi_range(0, MAP_SIZE_IN_BLOCKS - 1),
			rng.randi_range(0, MAP_SIZE_IN_BLOCKS - 1)
		)
		if is_3x3_clear_at(p):
			set_block(p.x, p.y, type)
			placed += 1
	if placed < count:
		push_warning("地点落子未放满：type=%d 目标 %d 实放 %d" % [type, count, placed])

func is_3x3_clear_at(center: Vector2i) -> bool:
	"""center 周围 3×3 共 9 格在 grid 上全为 EMPTY（越界视为空，照原版）"""
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if get_block(center.x + dx, center.y + dy) != BlockType.EMPTY:
				return false
	return true

func generate_roads():
	"""roads_1 逐行 + roads_2 逐列：只连前两个 9/6/11/15 地点，交叉/贴边支路归一化为对应道路类型"""
	roads.clear()

	# 横向：每一行(y)找前两个可连地点，之间空格填 ROAD_H
	for y in range(MAP_SIZE_IN_BLOCKS):
		var pair := _first_two_connectable_in_row(y)
		if pair.x == -1 or pair.y == -1:
			continue
		for x in range(pair.x + 1, pair.y):
			if get_block(x, y) == BlockType.EMPTY:
				set_block(x, y, BlockType.ROAD_H)
		roads.append(create_straight_path(Vector2i(pair.x, y), Vector2i(pair.y, y)))

	# 纵向：每一列(x)找前两个可连地点，之间 ROAD_H → ROAD_CROSS、EMPTY → ROAD_V
	for x in range(MAP_SIZE_IN_BLOCKS):
		var pair := _first_two_connectable_in_column(x)
		if pair.x == -1 or pair.y == -1:
			continue
		for y in range(pair.x + 1, pair.y):
			var b := get_block(x, y)
			if b == BlockType.ROAD_H:
				set_block(x, y, BlockType.ROAD_CROSS)
			elif b == BlockType.EMPTY:
				set_block(x, y, BlockType.ROAD_V)
		roads.append(create_straight_path(Vector2i(x, pair.x), Vector2i(x, pair.y)))

	_normalize_road_junction_types()
	print("生成了 ", roads.size(), " 条道路连接")

func _first_two_connectable_in_row(y: int) -> Vector2i:
	"""返回第 y 行最先出现的两个可连地点的 x（Vector2i(first,second)，缺则为 -1）"""
	var first := -1
	var second := -1
	for x in range(MAP_SIZE_IN_BLOCKS):
		if get_block(x, y) in ROAD_CONNECT_TYPES:
			if first == -1:
				first = x
			elif second == -1:
				second = x
				break
	return Vector2i(first, second)

func _first_two_connectable_in_column(x: int) -> Vector2i:
	"""返回第 x 列最先出现的两个可连地点的 y（Vector2i(first,second)，缺则为 -1）"""
	var first := -1
	var second := -1
	for y in range(MAP_SIZE_IN_BLOCKS):
		if get_block(x, y) in ROAD_CONNECT_TYPES:
			if first == -1:
				first = y
			elif second == -1:
				second = y
				break
	return Vector2i(first, second)

func _normalize_road_junction_types() -> void:
	for by in range(MAP_SIZE_IN_BLOCKS):
		for bx in range(MAP_SIZE_IN_BLOCKS):
			var type: BlockType = grid[by][bx]
			if not is_road(type):
				continue
			var block := Vector2i(bx, by)
			set_block(bx, by, _road_type_for_connections(_road_connections_for_generation(block, type)))

func _road_connections(left: bool, right: bool, up: bool, down: bool) -> Dictionary:
	return {
		"left": left,
		"right": right,
		"up": up,
		"down": down,
	}

func _road_connections_for_type(type: BlockType) -> Dictionary:
	match type:
		BlockType.ROAD_H:
			return _road_connections(true, true, false, false)
		BlockType.ROAD_H_UP:
			return _road_connections(true, true, true, false)
		BlockType.ROAD_H_DOWN:
			return _road_connections(true, true, false, true)
		BlockType.ROAD_V:
			return _road_connections(false, false, true, true)
		BlockType.ROAD_V_LEFT:
			return _road_connections(true, false, true, true)
		BlockType.ROAD_V_RIGHT:
			return _road_connections(false, true, true, true)
		BlockType.ROAD_CROSS:
			return _road_connections(true, true, true, true)
		_:
			return _road_connections(false, false, false, false)

func _road_connections_for_generation(block: Vector2i, type: BlockType) -> Dictionary:
	var connections := _road_connections_for_type(type)
	if _is_road_connect_location(block + Vector2i(-1, 0)):
		connections["left"] = true
	if _is_road_connect_location(block + Vector2i(1, 0)):
		connections["right"] = true
	if _is_road_connect_location(block + Vector2i(0, -1)):
		connections["up"] = true
	if _is_road_connect_location(block + Vector2i(0, 1)):
		connections["down"] = true
	return connections

func _road_type_for_connections(connections: Dictionary) -> BlockType:
	var left: bool = connections["left"]
	var right: bool = connections["right"]
	var up: bool = connections["up"]
	var down: bool = connections["down"]

	if left and right and up and down:
		return BlockType.ROAD_CROSS
	if left and right:
		if up:
			return BlockType.ROAD_H_UP
		if down:
			return BlockType.ROAD_H_DOWN
		return BlockType.ROAD_H
	if up and down:
		if left:
			return BlockType.ROAD_V_LEFT
		if right:
			return BlockType.ROAD_V_RIGHT
		return BlockType.ROAD_V

	return BlockType.ROAD_CROSS

func _is_road_connect_location(block: Vector2i) -> bool:
	return is_in_grid(block.x, block.y) and get_block(block.x, block.y) in ROAD_CONNECT_TYPES

func create_straight_path(start: Vector2i, end: Vector2i) -> Array:
	"""创建两点间的直线路径"""
	var path := []
	var current := start
	path.append(current)

	if start.x == end.x:
		# 垂直移动
		var direction := 1 if end.y > start.y else -1
		while current.y != end.y:
			current.y += direction
			path.append(Vector2i(current))
	elif start.y == end.y:
		# 水平移动
		var direction := 1 if end.x > start.x else -1
		while current.x != end.x:
			current.x += direction
			path.append(Vector2i(current))

	return path

func generate_secret_place():
	"""扫描「3×3 块全空 + 坐标在 2~15」的候选格，随机选一个在中心标 SECRET"""
	var counts = LEVEL_LOCATION_COUNTS.get(current_level, LEVEL_LOCATION_COUNTS[0])
	var secret_count: int = counts["secret"]
	for _i in range(secret_count):
		var candidates: Array[Vector2i] = []

		# CurX/CurY ∈ [2,15]，落子中心 = (cx-1, cy-1) ∈ [1,14]
		for cy in range(2, MAP_SIZE_IN_BLOCKS):
			for cx in range(2, MAP_SIZE_IN_BLOCKS):
				var center := Vector2i(cx - 1, cy - 1)
				if is_3x3_clear_at(center):
					candidates.append(center)
		if candidates.is_empty():
			break
		var pick := candidates[rng.randi_range(0, candidates.size() - 1)]
		set_block(pick.x, pick.y, BlockType.SECRET)

func collect_locations():
	"""遍历 grid，把 5 类地点 + 秘密地点收集为 locations，并记录 hotspot = block × 1020px"""
	locations.clear()
	towns.clear()
	for y in range(MAP_SIZE_IN_BLOCKS):
		for x in range(MAP_SIZE_IN_BLOCKS):
			var t: BlockType = grid[y][x]
			if not (is_location(t) or t == BlockType.SECRET):
				continue
			var block := Vector2i(x, y)
			locations.append({
				"block": block,
				"type": t,
				"hotspot": Vector2(block) * BLOCK_PX,
			})
			if is_location(t):
				towns.append(block)
	print("汇总地点 ", locations.size(), " 个（其中 5 类地点 ", towns.size(), " 个）")
	analyze_connectivity()

func analyze_connectivity():
	"""分析城镇连接情况"""
	var connected_towns := {}
	var isolated_towns := []

	# 统计连接的城镇
	for road in roads:
		if road.size() >= 2:
			var start_town = road[0]
			var end_town = road[road.size() - 1]
			connected_towns[start_town] = true
			connected_towns[end_town] = true

	# 找出孤立的城镇
	for town in towns:
		if not connected_towns.has(town):
			isolated_towns.append(town)

	print("连接的城镇数量: ", connected_towns.size())
	print("孤立的城镇数量: ", isolated_towns.size())
	if isolated_towns.size() > 0:
		print("孤立城镇位置: ", isolated_towns)

func analyze_town_distribution() -> Dictionary:
	"""分析城镇分布的均匀性"""
	if towns.size() < 2:
		return {"average_distance": 0, "min_distance": 0, "max_distance": 0}

	var distances := []
	for i in range(towns.size()):
		for j in range(i + 1, towns.size()):
			distances.append(towns[i].distance_to(towns[j]))

	distances.sort()
	var avg_distance = distances.reduce(func(sum, d): return sum + d, 0) / float(distances.size())

	return {
		"average_distance": avg_distance,
		"min_distance": distances[0],
		"max_distance": distances[distances.size() - 1]
	}

# --- 渲染：草地基底 → 道路 → 装饰（顺序对标 render_map 调用流）---

func render_map():
	"""Render roads and decoration on the tilemap

	城镇不在地面层渲染（建筑在阶段 C 实例化）；调试时由 WorldInspector 叠加层
	标出地点范围与类型，地面这里保持草地即可。
	"""

	render_grass_base()
	render_roads_from_grid()
	if auto_render_decoration:
		render_decoration()

func render_grass_base():
	"""用加权随机铺满整张地图的草地基底（变体靠低 probability 自然冒出）"""
	var pick := create_pick_random_tile_callable(ground_layer, 0, 32.33)
	for x in range(TOTAL_MAP_SIZE):
		for y in range(TOTAL_MAP_SIZE):
			var tile = pick.call()
			if tile != Vector2i(-1, -1):
				ground_layer.set_cell(Vector2i(x, y), 0, tile)

func render_roads_from_grid() -> void:
	"""按 grid 中保存的道路类型绘制道路。"""
	var road_cells := {}
	for by in range(MAP_SIZE_IN_BLOCKS):
		for bx in range(MAP_SIZE_IN_BLOCKS):
			var type: BlockType = grid[by][bx]
			if is_road(type):
				_add_road_cells_for_type(road_cells, Vector2i(bx, by), type)
	if not road_cells.is_empty():
		ground_layer.set_cells_terrain_connect(road_cells.keys(), 0, 1, false)

func _add_road_cells_for_type(road_cells: Dictionary, block: Vector2i, type: BlockType) -> void:
	match type:
		BlockType.ROAD_H:
			_add_road_rect(road_cells, block, 0, ROAD_MIN_IN_BLOCK, BLOCK_SIZE_IN_TILE, ROAD_MAX_IN_BLOCK)
		BlockType.ROAD_H_UP:
			_add_road_rect(road_cells, block, 0, ROAD_MIN_IN_BLOCK, BLOCK_SIZE_IN_TILE, ROAD_MAX_IN_BLOCK)
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, 0, ROAD_MAX_IN_BLOCK, ROAD_MAX_IN_BLOCK)
		BlockType.ROAD_H_DOWN:
			_add_road_rect(road_cells, block, 0, ROAD_MIN_IN_BLOCK, BLOCK_SIZE_IN_TILE, ROAD_MAX_IN_BLOCK)
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, ROAD_MIN_IN_BLOCK, ROAD_MAX_IN_BLOCK, BLOCK_SIZE_IN_TILE)
		BlockType.ROAD_V:
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, 0, ROAD_MAX_IN_BLOCK, BLOCK_SIZE_IN_TILE)
		BlockType.ROAD_V_LEFT:
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, 0, ROAD_MAX_IN_BLOCK, BLOCK_SIZE_IN_TILE)
			_add_road_rect(road_cells, block, 0, ROAD_MIN_IN_BLOCK, ROAD_MAX_IN_BLOCK, ROAD_MAX_IN_BLOCK)
		BlockType.ROAD_V_RIGHT:
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, 0, ROAD_MAX_IN_BLOCK, BLOCK_SIZE_IN_TILE)
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, ROAD_MIN_IN_BLOCK, BLOCK_SIZE_IN_TILE, ROAD_MAX_IN_BLOCK)
		BlockType.ROAD_CROSS:
			_add_road_rect(road_cells, block, 0, ROAD_MIN_IN_BLOCK, BLOCK_SIZE_IN_TILE, ROAD_MAX_IN_BLOCK)
			_add_road_rect(road_cells, block, ROAD_MIN_IN_BLOCK, 0, ROAD_MAX_IN_BLOCK, BLOCK_SIZE_IN_TILE)

func _add_road_rect(road_cells: Dictionary, block: Vector2i, x0: int, y0: int, x1: int, y1: int) -> void:
	var org := block * BLOCK_SIZE_IN_TILE
	for y in range(y0, y1):
		for x in range(x0, x1):
			road_cells[org + Vector2i(x, y)] = true

func render_decoration() -> void:
	"""按 grid 地块类型散布装饰"""
	decoration_layer.clear()
	for by in range(MAP_SIZE_IN_BLOCKS):
		for bx in range(MAP_SIZE_IN_BLOCKS):
			var type: BlockType = grid[by][bx]
			var org := Vector2i(bx * DECO_BLOCK_SIZE, by * DECO_BLOCK_SIZE)
			if is_road(type):
				_scatter_road_block(type, org)
			elif is_location(type):
				var sid := _location_deco_source(type)
				var scattering := _location_deco_scattering(type)
				_scatter_band(org, sid, scattering, 0, 0, DECO_BLOCK_SIZE, DECO_BLOCK_SIZE)
			elif is_water(type):
				_scatter_water_block(org)
			else:
				_scatter_band(org, DECO_SRC_GRASS, grass_scattering, 0, 0, DECO_BLOCK_SIZE, DECO_BLOCK_SIZE)

func _location_deco_source(type: BlockType) -> int:
	"""地点类型 → 对应 decoration source（医院/消防站复用城市装饰集）"""
	match type:
		BlockType.VILLAGE: return DECO_SRC_VILLAGE
		BlockType.CITY: return DECO_SRC_CITY
		BlockType.MILITARY: return DECO_SRC_MILITARY
		BlockType.HOSPITAL: return DECO_SRC_CITY
		BlockType.FIRESTATION: return DECO_SRC_CITY
		_: return DECO_SRC_GRASS

func _location_deco_scattering(type: BlockType) -> float:
	match type:
		BlockType.VILLAGE: return village_scattering
		BlockType.CITY: return city_scattering
		BlockType.MILITARY: return military_scattering
		BlockType.HOSPITAL: return hospital_scattering
		BlockType.FIRESTATION: return firestation_scattering
		_: return grass_scattering

func _scatter_water_block(org: Vector2i) -> void:
	_scatter_band(org, DECO_SRC_WATER_EDGE, water_edge_scattering, 0, 0, DECO_BLOCK_SIZE, DECO_BLOCK_SIZE)

func _scatter_road_block(type: BlockType, org: Vector2i):
	"""道路块按 grid 中保存的道路类型散布装饰。"""
	var road_min := DECO_ROAD_MIN
	var road_max := DECO_ROAD_MAX
	var road_width := road_max - road_min
	var connections := _road_connections_for_type(type)

	# 道路块会被道路分割最多4块区域
	var grass_bands: Array[Rect2i] = [
		Rect2i(0, 0, road_min, road_min),
		Rect2i(road_max, 0, DECO_BLOCK_SIZE - road_max, road_min),
		Rect2i(0, road_max, road_min, DECO_BLOCK_SIZE - road_max),
		Rect2i(road_max, road_max, DECO_BLOCK_SIZE - road_max, DECO_BLOCK_SIZE - road_max),
	]
	if not connections["left"]:
		grass_bands.append(Rect2i(0, road_min, road_min, road_width))
	if not connections["right"]:
		grass_bands.append(Rect2i(road_max, road_min, DECO_BLOCK_SIZE - road_max, road_width))
	if not connections["up"]:
		grass_bands.append(Rect2i(road_min, 0, road_width, road_min))
	if not connections["down"]:
		grass_bands.append(Rect2i(road_min, road_max, road_width, DECO_BLOCK_SIZE - road_max))

	_scatter_rects(org, DECO_SRC_GRASS, grass_scattering, grass_bands)
	_scatter_road_debris_for_connections(org, connections)

func _scatter_road_debris_for_connections(org: Vector2i, connections: Dictionary) -> void:
	var road_min := DECO_ROAD_MIN
	var road_max := DECO_ROAD_MAX
	var road_width := road_max - road_min
	var debris_bands: Array[Rect2i] = []

	if connections["left"] and connections["right"]:
		debris_bands.append(Rect2i(0, road_min, DECO_BLOCK_SIZE, road_width))
	else:
		if connections["left"]:
			debris_bands.append(Rect2i(0, road_min, road_max, road_width))
		if connections["right"]:
			debris_bands.append(Rect2i(road_min, road_min, DECO_BLOCK_SIZE - road_min, road_width))

	if connections["up"] and connections["down"]:
		debris_bands.append(Rect2i(road_min, 0, road_width, DECO_BLOCK_SIZE))
	else:
		if connections["up"]:
			debris_bands.append(Rect2i(road_min, 0, road_width, road_max))
		if connections["down"]:
			debris_bands.append(Rect2i(road_min, road_min, road_width, DECO_BLOCK_SIZE - road_min))

	_scatter_rects(org, DECO_SRC_ROAD, road_debris_scattering, debris_bands)

func _scatter_rects(org: Vector2i, source_id: int, scattering: float, bands: Array[Rect2i]) -> void:
	for band in bands:
		_scatter_band(
			org,
			source_id,
			scattering,
			band.position.x,
			band.position.y,
			band.position.x + band.size.x,
			band.position.y + band.size.y
		)

func _scatter_band(org: Vector2i, source_id: int, scattering: float, x0: int, y0: int, x1: int, y1: int) -> void:
	"""在 block 内 [x0,x1)×[y0,y1) 区域逐格散布装饰。"""
	if x1 <= x0 or y1 <= y0:
		return
	var scattering_density := clampf(scattering / 100.0, 0.0, 1.0)
	if scattering_density <= 0.0:
		return
	var pick := create_pick_random_tile_callable(
		decoration_layer,
		-1,
		_scattering_density_to_factor(scattering_density),
		source_id
	)
	for x in range(x0, x1):
		for y in range(y0, y1):
			var coords: Vector2i = pick.call()
			if coords == Vector2i(-1, -1):
				continue
			decoration_layer.set_cell(org + Vector2i(x, y), source_id, coords)

func _scattering_density_to_factor(scattering_density: float) -> float:
	return 1.0 / scattering_density - 1.0

# 参考: editor/plugins/tiles/tile_map_editor.cpp
func create_pick_random_tile_callable(layer: TileMapLayer, pattern_id: int = -1, scattering: float = 0.0, source_id: int = 0) -> Callable:
	var tile_set := layer.tile_set
	if tile_set == null:
		return func() -> Vector2i:
			return Vector2i(-1, -1)

	if not tile_set.has_source(source_id):
		return func() -> Vector2i:
			return Vector2i(-1, -1)

	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null:
		return func() -> Vector2i:
			return Vector2i(-1, -1)

	var coords_list: Array[Vector2i] = []

	var cumulative: Array[float] = []
	var sum := 0.0

	if pattern_id >= 0 and pattern_id < tile_set.get_patterns_count():
		var pattern := tile_set.get_pattern(pattern_id)
		for cell in pattern.get_used_cells():
			if pattern.get_cell_source_id(cell) != source_id:
				continue
			var c := pattern.get_cell_atlas_coords(cell)
			sum += source.get_tile_data(c, 0).probability
			coords_list.append(c)
			cumulative.append(sum)
	else:
		for i in range(source.get_tiles_count()):
			var c := source.get_tile_id(i)
			sum += source.get_tile_data(c, 0).probability
			coords_list.append(c)
			cumulative.append(sum)

	return func() -> Vector2i:
		if coords_list.is_empty() or sum <= 0.0:
			return Vector2i(-1, -1)
		var rand := rng.randf_range(0, sum + sum * scattering)
		for i in coords_list.size():
			if cumulative[i] >= rand:
				return coords_list[i]
		return Vector2i(-1, -1)
