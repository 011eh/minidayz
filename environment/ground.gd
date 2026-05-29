extends Node2D

@onready var ground_layer := %GroundLayer

# Constants
const BLOCK_SIZE = 17
const MAP_SIZE_IN_BLOCKS = 16
const TOTAL_MAP_SIZE = BLOCK_SIZE * MAP_SIZE_IN_BLOCKS # 272

# Town settings
const MIN_TOWNS = 25
const MAX_TOWNS = 25

# Road settings
const MIN_ROAD_WIDTH = 2
const MAX_ROAD_WIDTH = 4

# Data structures
var towns: Array[Vector2i] = []  # Block coordinates
var roads: Array[Array] = []     # Road segments
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	generate_world()

func generate_world():
	"""Main generation function"""
	generate_towns_uniform()
	generate_row_column_roads()
	render_map()

func generate_towns_uniform():
	"""原版落子算法：随机抽格，要求目标格 3×3 邻域全空才落子，否则重抽"""
	towns.clear()
	var target_towns = rng.randi_range(MIN_TOWNS, MAX_TOWNS)

	var attempts = 0
	var max_attempts = target_towns * 200
	while towns.size() < target_towns and attempts < max_attempts:
		var pos = Vector2i(
			rng.randi_range(0, MAP_SIZE_IN_BLOCKS - 1),
			rng.randi_range(0, MAP_SIZE_IN_BLOCKS - 1)
		)
		if is_3x3_clear(pos):
			towns.append(pos)
		attempts += 1

	print("生成了 ", towns.size(), " 个城镇，位置：", towns)

func is_3x3_clear(center: Vector2i) -> bool:
	"""要求 center 周围 3×3 共 9 格内没有其它城镇（保证间距 ≥2 格）"""
	for town in towns:
		if abs(town.x - center.x) <= 1 and abs(town.y - center.y) <= 1:
			return false
	return true

func generate_row_column_roads():
	"""还原原版 roads_1 / roads_2：逐行/逐列只连接最先出现的前两个地点，确定性连接"""
	roads.clear()

	if towns.size() < 2:
		return

	# 按行分组城镇（roads_1 横向）
	var towns_by_row = {}
	for town in towns:
		if not towns_by_row.has(town.y):
			towns_by_row[town.y] = []
		towns_by_row[town.y].append(town)

	# 按列分组城镇（roads_2 纵向）
	var towns_by_column = {}
	for town in towns:
		if not towns_by_column.has(town.x):
			towns_by_column[town.x] = []
		towns_by_column[town.x].append(town)

	# roads_1：每行按 x 升序，连接最先出现的前两个地点
	for row in towns_by_row.keys():
		var row_towns = towns_by_row[row]
		if row_towns.size() >= 2:
			row_towns.sort_custom(func(a, b): return a.x < b.x)
			roads.append(create_straight_path(row_towns[0], row_towns[1]))

	# roads_2：每列按 y 升序，连接最先出现的前两个地点（与横向路交叉处由地形连接自动合并为十字）
	for column in towns_by_column.keys():
		var column_towns = towns_by_column[column]
		if column_towns.size() >= 2:
			column_towns.sort_custom(func(a, b): return a.y < b.y)
			roads.append(create_straight_path(column_towns[0], column_towns[1]))

	print("生成了 ", roads.size(), " 条道路连接")
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
	"""Render towns and roads on the tilemap"""
	# 先渲染道路（在底层）
	for road in roads:
		render_road(road)

	# 再渲染城镇（在上层）
	for town_block in towns:
		render_town(town_block)

func render_town(block_pos: Vector2i):
	"""Render a town in the specified block"""
	var start_cell = block_pos * BLOCK_SIZE

	# Fill the entire block with town tiles
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var cell_pos = start_cell + Vector2i(x, y)
			ground_layer.set_cell(cell_pos, 0, Vector2i(11, 1))

func render_road(path: Array):
	"""Render a road along the given path"""
	if path.size() < 2:
		return

	var road_width = rng.randi_range(MIN_ROAD_WIDTH, MAX_ROAD_WIDTH)

	# Convert block path to cell path
	var cell_path = []
	for block_pos in path:
		var block_center = Vector2i(block_pos) * BLOCK_SIZE + Vector2i(BLOCK_SIZE / 2, BLOCK_SIZE / 2)
		cell_path.append(block_center)

	# Draw road using cellular approach
	draw_road_path(cell_path, road_width)

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

# 新增：重新生成道路（保持城镇不变）
func regenerate_roads_only():
	"""只重新生成道路，保持城镇位置不变"""
	generate_row_column_roads()
	# 清除之前的渲染，重新渲染
	ground_layer.clear()
	render_map()

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
	var connected_towns = {}
	var isolated_count = 0

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

	var distances = []
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
