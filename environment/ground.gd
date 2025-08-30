extends Node2D

@onready var ground_layer := %GroundLayer

# Constants
const BLOCK_SIZE = 17
const MAP_SIZE_IN_BLOCKS = 16
const TOTAL_MAP_SIZE = BLOCK_SIZE * MAP_SIZE_IN_BLOCKS # 272

# Town settings
const MIN_TOWNS = 25
const MAX_TOWNS = 25

# Road settings - 道路连接概率设置
const HIGH_CONNECTION_CHANCE = 0.85  # 同行/列城镇间高概率连接
const ISOLATION_CHANCE = 0.3        # 城镇孤立的概率（1 - HIGH_CONNECTION_CHANCE）
const MIN_ROAD_WIDTH = 2
const MAX_ROAD_WIDTH = 4

# 新增：城镇分布设置
const MIN_TOWN_DISTANCE = 2  # 城镇间最小距离（以块为单位）
const GRID_SUBDIVISIONS = 5  # 将地图划分为 5x5 的网格区域
const ALLOW_EDGE_TOWNS = true  # 允许城镇出现在地图边缘

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
	"""使用网格分布和泊松圆盘采样生成均匀分布的城镇"""
	towns.clear()
	var target_towns = rng.randi_range(MIN_TOWNS, MAX_TOWNS)

	# 方法1：网格分布法（推荐用于确保均匀分布）
	towns = generate_towns_grid_distribution(target_towns)

	# 如果需要更自然的分布，可以使用方法2：泊松圆盘采样
	# towns = generate_towns_poisson_disk(target_towns)

	print("生成了 ", towns.size(), " 个城镇，位置：", towns)

func generate_row_column_roads():
	"""生成同行/同列城镇间的道路连接，大概率相连，小概率孤立"""
	roads.clear()

	if towns.size() < 2:
		return

	# 按行分组城镇
	var towns_by_row = {}
	for town in towns:
		if not towns_by_row.has(town.y):
			towns_by_row[town.y] = []
		towns_by_row[town.y].append(town)

	# 按列分组城镇
	var towns_by_column = {}
	for town in towns:
		if not towns_by_column.has(town.x):
			towns_by_column[town.x] = []
		towns_by_column[town.x].append(town)

	# 连接同行的城镇
	for row in towns_by_row.keys():
		var row_towns = towns_by_row[row]
		if row_towns.size() > 1:
			connect_towns_in_line(row_towns, true)  # true表示水平连接

	# 连接同列的城镇
	for column in towns_by_column.keys():
		var column_towns = towns_by_column[column]
		if column_towns.size() > 1:
			connect_towns_in_line(column_towns, false)  # false表示垂直连接

	print("生成了 ", roads.size(), " 条道路连接")
	analyze_connectivity()

func connect_towns_in_line(line_towns: Array, is_horizontal: bool):
	"""连接一条线上的城镇（同行或同列）"""
	if line_towns.size() < 2:
		return

	# 排序城镇（水平按x坐标，垂直按y坐标）
	if is_horizontal:
		line_towns.sort_custom(func(a, b): return a.x < b.x)
	else:
		line_towns.sort_custom(func(a, b): return a.y < b.y)

	# 逐一连接相邻城镇，但有一定概率跳过连接（创造孤立城镇）
	for i in range(line_towns.size() - 1):
		var town_a = line_towns[i]
		var town_b = line_towns[i + 1]

		# 大概率连接，小概率跳过（创建孤立城镇的机会）
		if rng.randf() < HIGH_CONNECTION_CHANCE:
			# 检查路径是否畅通
			if is_path_clear_between_towns(town_a, town_b):
				var path = create_straight_path(town_a, town_b)
				if path.size() > 0:
					roads.append(path)
		else:
			print("跳过连接 ", town_a, " 和 ", town_b, " (创建孤立机会)")

func is_path_clear_between_towns(start: Vector2i, end: Vector2i) -> bool:
	"""检查两个城镇间的路径是否被其他城镇阻挡"""
	# 获取路径上的所有中间点
	var path_blocks = get_path_blocks(start, end)

	# 检查中间路径上是否有其他城镇
	for block in path_blocks:
		if block != start and block != end:
			if block in towns:
				return false

	return true

func get_path_blocks(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	"""获取两点间直线路径上的所有块坐标"""
	var blocks: Array[Vector2i] = []

	if start.x == end.x:
		# 垂直路径
		var min_y = min(start.y, end.y)
		var max_y = max(start.y, end.y)
		for y in range(min_y, max_y + 1):
			blocks.append(Vector2i(start.x, y))
	elif start.y == end.y:
		# 水平路径
		var min_x = min(start.x, end.x)
		var max_x = max(start.x, end.x)
		for x in range(min_x, max_x + 1):
			blocks.append(Vector2i(x, start.y))

	return blocks

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

func generate_towns_grid_distribution(target_count: int) -> Array[Vector2i]:
	"""网格分布法：将地图划分为网格，每个网格区域放置一个城镇"""
	var result_towns: Array[Vector2i] = []

	# 计算每个网格单元的大小
	var grid_cell_size = MAP_SIZE_IN_BLOCKS / GRID_SUBDIVISIONS
	var towns_per_cell = max(1, target_count / (GRID_SUBDIVISIONS * GRID_SUBDIVISIONS))

	# 根据设置决定边界范围
	var border_offset = 0 if ALLOW_EDGE_TOWNS else 1
	var max_coord = MAP_SIZE_IN_BLOCKS - 1 if ALLOW_EDGE_TOWNS else MAP_SIZE_IN_BLOCKS - 2

	# 为每个网格单元生成城镇
	for grid_x in range(GRID_SUBDIVISIONS):
		for grid_y in range(GRID_SUBDIVISIONS):
			# 计算当前网格单元的边界
			var cell_min_x = max(border_offset, grid_x * grid_cell_size)
			var cell_max_x = min(max_coord, (grid_x + 1) * grid_cell_size - 1)
			var cell_min_y = max(border_offset, grid_y * grid_cell_size)
			var cell_max_y = min(max_coord, (grid_y + 1) * grid_cell_size - 1)

			# 在当前网格单元中放置城镇
			var attempts = 0
			var towns_in_cell = 0
			while towns_in_cell < towns_per_cell and attempts < 50:
				var town_pos = Vector2i(
								   rng.randi_range(cell_min_x, cell_max_x),
								   rng.randi_range(cell_min_y, cell_max_y)
							   )

				if is_position_suitable_for_town(town_pos, result_towns):
					result_towns.append(town_pos)
					towns_in_cell += 1

				attempts += 1

			# 如果已经达到目标数量就停止
			if result_towns.size() >= target_count:
				break

		if result_towns.size() >= target_count:
			break

	# 如果还没达到目标数量，用随机填充的方式补充
	fill_remaining_towns_randomly(result_towns, target_count)

	return result_towns

func generate_towns_poisson_disk(target_count: int) -> Array[Vector2i]:
	"""泊松圆盘采样法：确保城镇间有最小距离，同时分布相对均匀"""
	var result_towns: Array[Vector2i] = []
	var attempts = 0
	var max_attempts = target_count * 50

	# 根据设置决定边界范围
	var min_coord = 0 if ALLOW_EDGE_TOWNS else 1
	var max_coord = MAP_SIZE_IN_BLOCKS - 1 if ALLOW_EDGE_TOWNS else MAP_SIZE_IN_BLOCKS - 2

	while result_towns.size() < target_count and attempts < max_attempts:
		var candidate = Vector2i(
							rng.randi_range(min_coord, max_coord),
							rng.randi_range(min_coord, max_coord)
						)

		if is_position_suitable_for_town(candidate, result_towns):
			result_towns.append(candidate)

		attempts += 1

	return result_towns

func is_position_suitable_for_town(pos: Vector2i, existing_towns: Array[Vector2i]) -> bool:
	"""检查位置是否适合放置城镇（距离其他城镇足够远）"""
	for existing_town in existing_towns:
		var distance = pos.distance_to(existing_town)
		if distance < MIN_TOWN_DISTANCE:
			return false
	return true

func fill_remaining_towns_randomly(current_towns: Array[Vector2i], target_count: int):
	"""用随机方式填充剩余的城镇位置"""
	var attempts = 0
	var max_attempts = (target_count - current_towns.size()) * 50

	# 根据设置决定边界范围
	var min_coord = 0 if ALLOW_EDGE_TOWNS else 1
	var max_coord = MAP_SIZE_IN_BLOCKS - 1 if ALLOW_EDGE_TOWNS else MAP_SIZE_IN_BLOCKS - 2

	while current_towns.size() < target_count and attempts < max_attempts:
		var candidate = Vector2i(
							rng.randi_range(min_coord, max_coord),
							rng.randi_range(min_coord, max_coord)
						)

		if is_position_suitable_for_town(candidate, current_towns):
			current_towns.append(candidate)

		attempts += 1

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

# 新增：设置道路连接概率
func set_connection_probability(high_chance: float, isolation_chance: float = 0.0):
	"""设置道路连接概率"""
	if isolation_chance == 0.0:
		isolation_chance = 1.0 - high_chance

	# 确保概率在合理范围内
	high_chance = clamp(high_chance, 0.0, 1.0)
	isolation_chance = clamp(isolation_chance, 0.0, 1.0)

	print("设置连接概率: ", high_chance, ", 孤立概率: ", isolation_chance)

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
