extends Node2D

@onready var ground_layer := %GroundLayer
@onready var decoration_layer := %DecorationLayer

@export var map_seed: int = 0  # 地图种子：0 = 每次随机；非 0 = 用此种子固定复现

# Constants
const BLOCK_SIZE = 17                            # 1 个 block = 17×17 terrain tile
const MAP_SIZE_IN_BLOCKS = 16
const TOTAL_MAP_SIZE = BLOCK_SIZE * MAP_SIZE_IN_BLOCKS # 272
const TILE_PX = 60                               # terrain tile 像素尺寸（见 尺度规格）
const BLOCK_PX = BLOCK_SIZE * TILE_PX            # 1 个 block 的世界像素尺寸 = 1020（= 原版地点间距）

# Road settings
const ROAD_WIDTH = 4

# Decoration settings（装饰层：30px tile，每 block 34×34，对标原版 ground_enviroment/t221）
const DECO_TILE_PX = 30
const DECO_BLOCK_SIZE = BLOCK_PX / DECO_TILE_PX  # 1020/30 = 34，1 个 block 的装饰格数
# 各 block 类型对应的 decoration source（ground_decoration.tres 已按类型拆成 6 个 atlas source，
# 每个 source 内的 tile 自带 probability，散布时按权重抽取——对标原版每类地点各撒自己一套装饰 tile）：
const DECO_SRC_GRASS = 0      # 草地：草丛/石头/枯木/灌木（路两侧带、地点过渡）
const DECO_SRC_ROAD = 1       # 残骸：轮胎/木头/血迹/杂物（路面中带）
const DECO_SRC_VILLAGE = 2    # 村庄装饰
const DECO_SRC_CITY = 3       # 城市装饰（医院/消防站共用：原版同属 town 装饰集）
const DECO_SRC_MILITARY = 4   # 军营装饰
const DECO_SRC_FOREST = 5     # 野外植被（空地 / 秘密地点）
# 每 block 散布数量（对标原版 map_generation.decoded.txt 各地点的 Repeat(n)）：
const DECO_COUNT_TOWN = 250                       # 村庄/城市/医院/消防站（原版 Repeat(250)）
const DECO_COUNT_MILITARY = 200                   # 军营（原版 Repeat(200)）
const DECO_COUNT_BAND = 70                        # 道路块每条带（原版每带 Repeat(70)，共 3 带）
const DECO_COUNT_FOREST = 210                     # 野外/秘密地点整块（原版野外 70×3 竖带 = 210）

# 地块类型（统一数据源）：用枚举替代原版魔法数字（9/6/13…），
# 注释标注原版网格类型码（见 城镇生成逻辑.md §3.3）以便对照照搬算法。
enum BlockType {
	EMPTY,        # 原版 0：空地 / 森林
	VILLAGE,      # 原版 9：村庄
	CITY,         # 原版 6：城市
	MILITARY,     # 原版 5：军营
	HOSPITAL,     # 原版 11：医院
	FIRESTATION,  # 原版 15：消防站
	ROAD_H,       # 原版 13：横向道路（roads_1 生成）
	ROAD_V,       # 原版 12：纵向道路（roads_2 生成）
	ROAD_CROSS,   # 原版 14：十字路口（roads_2 生成）
	SECRET,       # 原版 2：秘密地点（roads_2 生成）
}

# 5 类地点的集合（供「扫描相邻格找地点」等原版算法复用）
const LOCATION_TYPES := [
	BlockType.VILLAGE, BlockType.CITY, BlockType.MILITARY,
	BlockType.HOSPITAL, BlockType.FIRESTATION,
]
# 3 种道路的集合
const ROAD_TYPES := [BlockType.ROAD_H, BlockType.ROAD_V, BlockType.ROAD_CROSS]
# 道路连接的地点类型（原版 roads_1/2 只连 9/6/11/15，军营 5 不连）
const ROAD_CONNECT_TYPES := [
	BlockType.VILLAGE, BlockType.CITY, BlockType.HOSPITAL, BlockType.FIRESTATION,
]

# 各关卡地点数量表（完全照原版 §3.1）：villages/cities/militaries/hospitals/firestations/secret/gas
const LEVEL_LOCATION_COUNTS := {
	0: {"village": 20, "city": 3, "military": 0, "hospital": 1, "firestation": 1, "secret": 1, "gas": 1},
	1: {"village": 15, "city": 5, "military": 2, "hospital": 2, "firestation": 2, "secret": 1, "gas": 2},
	2: {"village": 6, "city": 10, "military": 4, "hospital": 3, "firestation": 3, "secret": 1, "gas": 3},
	3: {"village": 3, "city": 11, "military": 6, "hospital": 4, "firestation": 2, "secret": 1, "gas": 4},
}

# Data structures
var current_level := 0           # 当前关卡（决定地点数量表）
var grid: Array = []             # 16×16，grid[y][x] = BlockType，生成与渲染的统一数据源
var locations: Array[Dictionary] = []  # [{ block:Vector2i, type:BlockType, hotspot:Vector2 }]，供阶段 C 实例化
var towns: Array[Vector2i] = []  # 5 类地点的 block 坐标（占位渲染 + 调试用）
var roads: Array[Array] = []     # Road segments
var gas_station_count := 0       # 加油站数量（阶段 C 后处理用，A 阶段仅记录）
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
	generate_locations()      # 步骤2：5 类地点落子，写入 grid
	generate_roads()          # 步骤3+4：roads_1 横向 / roads_2 纵向 + 十字
	generate_secret_place()   # 步骤4 尾：秘密地点
	collect_locations()       # 扫描 grid 汇总 locations（含 hotspot）+ towns
	render_map()

# --- grid 统一数据源：初始化与存取辅助 ---

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
	"""是否为道路（横/纵/十字）"""
	return type in ROAD_TYPES

# --- 步骤2：地点落子（完全照原版 §3.1/§3.2）---

func generate_locations():
	"""按关卡数量表，分 5 类用「3×3 邻域全空」算法落子并写入 grid"""
	var counts = LEVEL_LOCATION_COUNTS.get(current_level, LEVEL_LOCATION_COUNTS[0])
	gas_station_count = counts["gas"]
	# 原版落子顺序：village → military → city → hospital → firestation
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

# --- 步骤3+4：道路网（完全照原版 roads_1 / roads_2）---

func generate_roads():
	"""roads_1 逐行 + roads_2 逐列：只连前两个 9/6/11/15 地点，之间填路，交叉处标十字"""
	roads.clear()

	# roads_1（横向）：每一行(y)找前两个可连地点，之间空格填 ROAD_H
	for y in range(MAP_SIZE_IN_BLOCKS):
		var pair := _first_two_connectable_in_row(y)
		if pair.x == -1 or pair.y == -1:
			continue
		for x in range(pair.x + 1, pair.y):
			if get_block(x, y) == BlockType.EMPTY:
				set_block(x, y, BlockType.ROAD_H)
		roads.append(create_straight_path(Vector2i(pair.x, y), Vector2i(pair.y, y)))

	# roads_2（纵向）：每一列(x)找前两个可连地点，之间 ROAD_H→ROAD_CROSS、EMPTY→ROAD_V
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

# --- 步骤4 尾：秘密地点（完全照原版 §4）---

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

# --- 扫描 grid 汇总地点列表（含 hotspot 世界坐标，供阶段 C 实例化）---

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

func create_straight_path(start: Vector2i, end: Vector2i) -> Array:
	"""创建两点间的直线路径"""
	var path = []
	var current = start
	path.append(current)

	if start.x == end.x:
		# 垂直移动
		var direction = 1 if end.y > start.y else -1
		while current.y != end.y:
			current.y += direction
			path.append(Vector2i(current))
	elif start.y == end.y:
		# 水平移动
		var direction = 1 if end.x > start.x else -1
		while current.x != end.x:
			current.x += direction
			path.append(Vector2i(current))

	return path

func analyze_connectivity():
	"""分析城镇连接情况"""
	var connected_towns = {}
	var isolated_towns = []

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

func render_map():
	"""Render roads and decoration on the tilemap

	城镇不在地面层渲染（建筑在阶段 C 实例化）；调试时由 WorldInspector 叠加层
	标出地点范围与类型，地面这里保持草地即可。
	"""
	# 先铺草地基底（加权随机，含花/石变体）
	render_grass_base()

	# 再渲染道路（在草地之上，覆盖其下草格并算过渡）
	for road in roads:
		render_road(road)

	# 装饰层（独立 TileMapLayer，叠在最上）
	render_decoration()

func render_decoration():
	"""按 grid 地块类型散布装饰（对标原版 ground_enviroment 的按地点散布）

	每类地点撒自己一套装饰 tile（source 按类型拆分，见 DECO_SRC_*）：
	- 道路块：照原版 3 条带——中带撒路面残骸(source 1)，两侧带撒草地(source 0)，横/纵路决定分带轴
	- 村庄/城市/军营/医院/消防：整块均匀撒对应类型装饰（建筑在阶段 C 会叠在其上）
	- 秘密地点 / 空地：撒野外植被(source 5)
	"""
	decoration_layer.clear()
	# 为每个 source 预建「按 tile probability 加权随机取 atlas 坐标」的闭包
	var picks := {}
	var ts: TileSet = decoration_layer.tile_set
	for i in range(ts.get_source_count()):
		var sid: int = ts.get_source_id(i)
		picks[sid] = create_deco_pick(sid)
	for by in range(MAP_SIZE_IN_BLOCKS):
		for bx in range(MAP_SIZE_IN_BLOCKS):
			var type: BlockType = grid[by][bx]
			var org := Vector2i(bx * DECO_BLOCK_SIZE, by * DECO_BLOCK_SIZE)
			if is_road(type):
				_scatter_road_block(type, org, picks)
			elif is_location(type):
				var sid := _location_deco_source(type)
				var count := DECO_COUNT_MILITARY if type == BlockType.MILITARY else DECO_COUNT_TOWN
				_scatter_band(org, sid, picks[sid], count, 0, DECO_BLOCK_SIZE, 0, DECO_BLOCK_SIZE)
			else:
				# 秘密地点与空地：野外植被（原版野外/wilderness 装饰集）
				_scatter_band(org, DECO_SRC_FOREST, picks[DECO_SRC_FOREST], DECO_COUNT_FOREST, 0, DECO_BLOCK_SIZE, 0, DECO_BLOCK_SIZE)

func _location_deco_source(type: BlockType) -> int:
	"""5 类地点 → 对应 decoration source（医院/消防站共用城市装饰集，照原版同属 town set）"""
	match type:
		BlockType.VILLAGE: return DECO_SRC_VILLAGE
		BlockType.CITY: return DECO_SRC_CITY
		BlockType.MILITARY: return DECO_SRC_MILITARY
		BlockType.HOSPITAL: return DECO_SRC_CITY
		BlockType.FIRESTATION: return DECO_SRC_CITY
		_: return DECO_SRC_GRASS

func _scatter_road_block(type: BlockType, org: Vector2i, picks: Dictionary):
	"""道路块按原版 3 条带散布：中带=路面残骸(source 1)，两侧=草地(source 0)；横路按 y 分带，纵路按 x 分带"""
	var third := DECO_BLOCK_SIZE / 3   # 34/3 ≈ 11，对应原版 0~11 / 11~22 / 22~33
	var grass_pick: Callable = picks[DECO_SRC_GRASS]
	var road_pick: Callable = picks[DECO_SRC_ROAD]
	if type == BlockType.ROAD_V:
		# 纵路：左带草 / 中带路 / 右带草（按 x 切）
		_scatter_band(org, DECO_SRC_GRASS, grass_pick, DECO_COUNT_BAND, 0, third, 0, DECO_BLOCK_SIZE)
		_scatter_band(org, DECO_SRC_ROAD,  road_pick,  DECO_COUNT_BAND, third, third * 2, 0, DECO_BLOCK_SIZE)
		_scatter_band(org, DECO_SRC_GRASS, grass_pick, DECO_COUNT_BAND, third * 2, DECO_BLOCK_SIZE, 0, DECO_BLOCK_SIZE)
	else:
		# 横路 / 十字：上带草 / 中带路 / 下带草（按 y 切）
		_scatter_band(org, DECO_SRC_GRASS, grass_pick, DECO_COUNT_BAND, 0, DECO_BLOCK_SIZE, 0, third)
		_scatter_band(org, DECO_SRC_ROAD,  road_pick,  DECO_COUNT_BAND, 0, DECO_BLOCK_SIZE, third, third * 2)
		_scatter_band(org, DECO_SRC_GRASS, grass_pick, DECO_COUNT_BAND, 0, DECO_BLOCK_SIZE, third * 2, DECO_BLOCK_SIZE)

func _scatter_band(org: Vector2i, source_id: int, pick: Callable, count: int, x0: int, x1: int, y0: int, y1: int):
	"""在 block 内的子矩形 [x0,x1)×[y0,y1) 里随机散布 count 个加权 tile（对标原版 Repeat(count) + SetTile(random,random,choose)）"""
	for _i in range(count):
		var coords: Vector2i = pick.call()
		if coords == Vector2i(-1, -1):
			continue
		var cell := org + Vector2i(rng.randi_range(x0, x1 - 1), rng.randi_range(y0, y1 - 1))
		decoration_layer.set_cell(cell, source_id, coords)

func render_grass_base():
	"""用加权随机铺满整张地图的草地基底（变体靠低 probability 自然冒出）"""
	var pick := create_pick_random_tile_callable(ground_layer, 0)
	for x in range(TOTAL_MAP_SIZE):
		for y in range(TOTAL_MAP_SIZE):
			ground_layer.set_cell(Vector2i(x, y), 0, pick.call())

# 针对某个 decoration source，遍历其全部 tile，按各 tile 的 probability 构建加权随机取 atlas 坐标的闭包
# （ground_decoration.tres 已按类型把装饰拆成独立 source，无需再借 pattern 间接取 tile）
func create_deco_pick(source_id: int) -> Callable:
	var source := decoration_layer.tile_set.get_source(source_id) as TileSetAtlasSource
	var coords_list: Array[Vector2i] = []
	var cumulative: Array[float] = []   # 预存累积权重，call() 内免重复求和
	var sum := 0.0
	for i in range(source.get_tiles_count()):
		var c := source.get_tile_id(i)
		sum += source.get_tile_data(c, 0).probability
		coords_list.append(c)
		cumulative.append(sum)
	return func() -> Vector2i:
		if coords_list.is_empty():
			return Vector2i(-1, -1)
		var rand := rng.randf_range(0, sum)
		for i in coords_list.size():
			if cumulative[i] >= rand:
				return coords_list[i]
		return coords_list[coords_list.size() - 1]

# 从 TileMapPattern 取候选 tile，按各 tile 的 probability 加权随机（仿 Godot 编辑器散布逻辑）
# 参考: editor/plugins/tiles/tile_map_editor.cpp
func create_pick_random_tile_callable(layer: TileMapLayer, pattern_id: int, scattering := 0.0) -> Callable:
	var pattern := layer.tile_set.get_pattern(pattern_id)
	var source := layer.tile_set.get_source(0) as TileSetAtlasSource
	var coords_list: Array[Vector2i] = []
	var cumulative: Array[float] = []   # 预存累积权重，call() 内免重复查表
	var sum := 0.0
	for cell in pattern.get_used_cells():
		var c := pattern.get_cell_atlas_coords(cell)
		sum += source.get_tile_data(c, 0).probability
		coords_list.append(c)
		cumulative.append(sum)
	return func() -> Vector2i:
		# scattering > 0 时上界超过 sum，落空返回 (-1,-1)（留洞）；草地基底用默认 0 铺满
		var rand := rng.randf_range(0, sum + sum * scattering)
		for i in coords_list.size():
			if cumulative[i] >= rand:
				return coords_list[i]
		return Vector2i(-1, -1)

func render_road(path: Array):
	"""Render a road along the given path"""
	if path.size() < 2:
		return

	var road_width = ROAD_WIDTH

	# 道路只铺在两城镇之间的空地上，端点止于城镇 block 边缘（不进入城镇内部）
	var a := Vector2i(path[0])
	var b := Vector2i(path[path.size() - 1])
	var half := BLOCK_SIZE / 2
	var start_cell: Vector2i
	var end_cell: Vector2i

	if a.y == b.y:
		# 水平路：中心线 y 取城镇行中心，x 从前一城镇右缘的下一格 到 后一城镇左缘的前一格
		var y := a.y * BLOCK_SIZE + half
		var lo: int = min(a.x, b.x)
		var hi: int = max(a.x, b.x)
		start_cell = Vector2i((lo + 1) * BLOCK_SIZE, y)
		end_cell = Vector2i(hi * BLOCK_SIZE - 1, y)
	else:
		# 垂直路：中心线 x 取城镇列中心
		var x := a.x * BLOCK_SIZE + half
		var lo: int = min(a.y, b.y)
		var hi: int = max(a.y, b.y)
		start_cell = Vector2i(x, (lo + 1) * BLOCK_SIZE)
		end_cell = Vector2i(x, hi * BLOCK_SIZE - 1)

	# Draw road using cellular approach
	draw_road_path([start_cell, end_cell], road_width)

func draw_road_path(cell_path: Array, width: int):
	"""Draw road using a cellular approach"""
	var road_cells = {}
	var half_width = width / 2

	# Process each segment of the path
	for i in range(cell_path.size() - 1):
		var start = Vector2i(cell_path[i])
		var end = Vector2i(cell_path[i + 1])

		# Get all cells along this line segment
		var line_cells = get_line_cells(start, end)

		# For each cell on the line, add surrounding cells based on width
		for cell in line_cells:
			# Determine the perpendicular direction for width
			var direction = Vector2((end - start)).normalized()
			var perpendicular: Vector2

			if abs(direction.x) > abs(direction.y):
				# Horizontal line, expand vertically
				perpendicular = Vector2(0, 1)
			else:
				# Vertical line, expand horizontally
				perpendicular = Vector2(1, 0)

			# Add cells perpendicular to the line
			for offset in range(-half_width, width - half_width):
				var road_cell = cell + Vector2i(perpendicular * offset)
				if is_valid_cell(road_cell):
					road_cells[road_cell] = true

	# 渲染道路地形（使用地形连接）
	ground_layer.set_cells_terrain_connect(road_cells.keys(), 0, 1)

func get_line_cells(start: Vector2i, end: Vector2i) -> Array:
	"""Get all cells along a line using Bresenham's algorithm"""
	var cells = []
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	var x = x0
	var y = y0

	while true:
		cells.append(Vector2i(x, y))

		if x == x1 and y == y1:
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

	return cells

func is_valid_cell(cell_pos: Vector2i) -> bool:
	"""Check if cell position is within map bounds"""
	return cell_pos.x >= 0 and cell_pos.x < TOTAL_MAP_SIZE and \
	cell_pos.y >= 0 and cell_pos.y < TOTAL_MAP_SIZE

func set_seed(seed_value: int):
	"""Set random seed for reproducible generation"""
	rng.seed = seed_value

# 重新生成整张地图（道路写入 grid，无法只重算道路，故整图重来）
func regenerate():
	"""清空并重新生成整张地图"""
	ground_layer.clear()
	generate_world()

# Debug function
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
