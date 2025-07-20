extends Node2D

# 地图参数
const BLOCK_SIZE = 17  # 每个block的尺寸 (17x17 cells)
const MAP_BLOCKS = 16  # 地图由16x16个block组成
const MAP_SIZE = BLOCK_SIZE * MAP_BLOCKS  # 总地图尺寸 272x272
const ROAD_WIDTH = 2  # 道路最小宽度

# 摄像头参数
const MIN_ZOOM = 0.1
const MAX_ZOOM = 3.0
const ZOOM_SPEED = 0.1
const PAN_SPEED = 500.0

# 新增道路生成参数
@export var branch_probability: float = 0.3  # 分支道路生成概率
@export var additional_connection_probability: float = 0.4  # 额外连接概率
@export var max_additional_connections: int = 5  # 最大额外连接数量
@export var road_separation_distance: int = 2  # 平行道路间距

# Tile类型ID (需要根据你的TileSet调整)
enum TileType {
	GRASS = 0,
	ROAD = 1,
	TOWN = 2
}

@onready var grass := %Grass  # TileMapLayer
@onready var camera := Camera2D.new()  # 摄像头

# 摄像头控制变量
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var last_mouse_pos = Vector2.ZERO

# AStar网格用于寻路
var astar_grid: AStarGrid2D
var towns: Array[Vector2i] = []  # 城镇位置 (以block坐标存储)
var road_cells: Array[Vector2i] = []  # 道路cell坐标

# 新增：记录城市间的连接关系
var connected_town_pairs: Array[Array] = []  # 存储已连接的城镇对

func _ready():
	# 设置摄像头
	setup_camera()
	# 初始化地图
	initialize_map()

func setup_camera():
	"""设置摄像头"""
	add_child(camera)
	camera.enabled = true
	camera.zoom = Vector2(1.0, 1.0)
	
	# 将摄像头定位到地图中心
	var map_center = Vector2(MAP_SIZE * grass.tile_set.tile_size.x / 2, 
							MAP_SIZE * grass.tile_set.tile_size.y / 2)
	camera.global_position = map_center

func generate_map(town_count: int = 4):
	"""生成地图，包含指定数量的城镇和连接道路"""
	print("开始生成地图，城镇数量: ", town_count)
	
	# 清空现有地图
	clear_map()
	
	# 初始化AStar网格
	setup_astar_grid()
	
	# 生成城镇
	generate_towns(town_count)
	
	# 改进的道路生成系统
	generate_roads_improved()
	
	# 应用到TileMapLayer
	apply_to_tilemap()
	
	print("地图生成完成！")

func initialize_map():
	"""初始化地图基础设置"""
	# 填充草地作为基础地形
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			grass.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))  # 假设grass tile在source_id=0, atlas_coords=(0,0)

func clear_map():
	"""清空地图数据"""
	towns.clear()
	road_cells.clear()
	connected_town_pairs.clear()  # 清空连接记录
	
	# 重新填充草地
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			grass.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func setup_astar_grid():
	"""设置AStar网格"""
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, MAP_SIZE, MAP_SIZE)
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER  # 只允许4方向移动
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update()

func generate_towns(count: int):
	"""生成指定数量的城镇"""
	var attempts = 0
	var max_attempts = count * 10
	
	while towns.size() < count and attempts < max_attempts:
		var block_x = randi() % MAP_BLOCKS
		var block_y = randi() % MAP_BLOCKS
		var block_pos = Vector2i(block_x, block_y)
		
		# 确保城镇之间有最小距离
		if is_valid_town_position(block_pos):
			towns.append(block_pos)
			place_town_at_block(block_pos)
		
		attempts += 1
	
	print("生成了 ", towns.size(), " 个城镇")

func is_valid_town_position(block_pos: Vector2i) -> bool:
	"""检查城镇位置是否有效（与其他城镇保持最小距离）"""
	var min_distance = 3  # 增加城镇之间最小距离（以block为单位）
	
	for existing_town in towns:
		var distance = abs(existing_town.x - block_pos.x) + abs(existing_town.y - block_pos.y)
		if distance < min_distance:
			return false
	
	return true

func place_town_at_block(block_pos: Vector2i):
	"""在指定block位置放置城镇"""
	var start_x = block_pos.x * BLOCK_SIZE
	var start_y = block_pos.y * BLOCK_SIZE
	
	# 城镇占用整个block (17x17)，但在AStar中只标记边缘为不可通行
	# 保留中心区域可通行，以便道路可以连接
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var cell_pos = Vector2i(start_x + x, start_y + y)
			
			# 在AStar网格中，只将城镇边缘设置为不可通行，保留中心可通行
			if astar_grid.is_in_bounds(cell_pos.x, cell_pos.y):
				# 如果是边缘区域，设置为不可通行
				var is_edge = (x == 0 or x == BLOCK_SIZE - 1 or y == 0 or y == BLOCK_SIZE - 1)
				if is_edge:
					astar_grid.set_point_solid(cell_pos, true)
				else:
					astar_grid.set_point_solid(cell_pos, false)

# ========== 改进的道路生成系统 ==========

func generate_roads_improved():
	"""改进的道路生成系统"""
	road_cells.clear()
	connected_town_pairs.clear()
	
	if towns.size() < 2:
		return
	
	# 第一阶段：使用最小生成树算法确保所有城镇连通
	build_minimum_spanning_tree()
	
	# 第二阶段：添加额外的城镇间连接
	add_additional_connections()
	
	# 第三阶段：添加分支道路
	add_random_branches()

func build_minimum_spanning_tree():
	"""建立最小生成树确保所有城镇连通"""
	var connected_towns = [towns[0]]
	var unconnected_towns = towns.slice(1)
	
	while unconnected_towns.size() > 0:
		var best_start = Vector2i.ZERO
		var best_end = Vector2i.ZERO
		var shortest_distance = INF
		
		# 找到最短连接
		for connected in connected_towns:
			for unconnected in unconnected_towns:
				var distance = get_manhattan_distance(connected, unconnected)
				if distance < shortest_distance:
					shortest_distance = distance
					best_start = connected
					best_end = unconnected
		
		# 创建道路连接
		create_road_between_towns_improved(best_start, best_end)
		
		# 记录这对城镇已经连接
		add_town_pair_connection(best_start, best_end)
		
		# 移动城镇到已连接列表
		connected_towns.append(best_end)
		unconnected_towns.erase(best_end)

func add_additional_connections():
	"""添加额外的城镇间连接（只连接未直接相连的城镇对）"""
	var possible_connections = get_unconnected_town_pairs()
	var connections_added = 0
	
	# 按距离排序，优先连接较近的城镇
	possible_connections.sort_custom(func(a, b): 
		var dist_a = get_manhattan_distance(a[0], a[1])
		var dist_b = get_manhattan_distance(b[0], b[1])
		return dist_a < dist_b
	)
	
	# 根据概率和最大连接数添加额外连接
	for connection in possible_connections:
		if connections_added >= max_additional_connections:
			break
			
		var town_a = connection[0] as Vector2i
		var town_b = connection[1] as Vector2i
		var distance = get_manhattan_distance(town_a, town_b)
		
		# 距离因子：距离越近，连接概率越高
		var distance_factor = max(0.1, 1.0 - (distance / 30.0))
		var adjusted_probability = additional_connection_probability * distance_factor
		
		if randf() < adjusted_probability:
			create_road_between_towns_improved(town_a, town_b)
			add_town_pair_connection(town_a, town_b)
			connections_added += 1
	
	print("添加了 ", connections_added, " 个额外连接")

func get_unconnected_town_pairs() -> Array[Array]:
	"""获取所有未直接连接的城镇对"""
	var unconnected_pairs: Array[Array] = []
	
	# 遍历所有可能的城镇对
	for i in range(towns.size()):
		for j in range(i + 1, towns.size()):
			var town_a = towns[i]
			var town_b = towns[j]
			
			# 检查这对城镇是否已经直接连接
			if not are_towns_connected(town_a, town_b):
				unconnected_pairs.append([town_a, town_b])
	
	return unconnected_pairs

func are_towns_connected(town_a: Vector2i, town_b: Vector2i) -> bool:
	"""检查两个城镇是否已经直接连接"""
	for pair in connected_town_pairs:
		var pair_town_a = pair[0] as Vector2i
		var pair_town_b = pair[1] as Vector2i
		
		if (pair_town_a == town_a and pair_town_b == town_b) or \
		   (pair_town_a == town_b and pair_town_b == town_a):
			return true
	
	return false

func add_town_pair_connection(town_a: Vector2i, town_b: Vector2i):
	"""添加城镇对连接记录"""
	if town_a != town_b:  # 避免自连接
		connected_town_pairs.append([town_a, town_b])

func create_road_between_towns_improved(town1: Vector2i, town2: Vector2i):
	"""改进的城镇间道路创建"""
	var start_pos = get_town_center_cell(town1)
	var end_pos = get_town_center_cell(town2)
	
	print("连接城镇: ", town1, " -> ", town2)
	
	# 使用AStar寻找路径
	var path = astar_grid.get_id_path(start_pos, end_pos)
	
	if path.size() > 0:
		# 将路径转换为PackedVector2Array以便添加宽度
		var packed_path = PackedVector2Array()
		for point_id in path:
			var cell_pos = astar_grid.get_point_position(point_id)
			packed_path.append(Vector2(cell_pos.x, cell_pos.y))
		
		# 添加带宽度的道路
		add_road_width(packed_path, ROAD_WIDTH)
		print("成功创建道路，路径长度: ", path.size())
	else:
		# 如果AStar失败，使用简单的直线连接
		print("AStar路径查找失败，使用直线连接")
		create_simple_road_between_towns(town1, town2)

func add_road_width(path: PackedVector2Array, width: int):
	"""为路径添加宽度"""
	var half_width = width / 2
	
	for point in path:
		var grid_pos = Vector2i(point.x, point.y)
		
		# 在路径点周围添加宽度
		for x in range(-half_width, half_width + 1):
			for y in range(-half_width, half_width + 1):
				var road_pos = grid_pos + Vector2i(x, y)
				if is_valid_road_position(road_pos) and not road_cells.has(road_pos):
					road_cells.append(road_pos)
					
					# 在AStar网格中设置为可通行
					if astar_grid.is_in_bounds(road_pos.x, road_pos.y):
						astar_grid.set_point_solid(road_pos, false)

func add_random_branches():
	"""添加随机分支道路"""
	var original_roads = road_cells.duplicate()
	var branches_added = 0
	
	for road_pos in original_roads:
		if randf() < branch_probability:
			# 随机选择分支方向
			var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
			var direction = directions[randi() % directions.size()]
			
			# 生成分支长度
			var branch_length = randi_range(3, 8)
			var current_pos = road_pos
			
			# 创建分支
			var branch_cells = []
			for i in range(branch_length):
				current_pos += direction
				if not is_valid_road_position(current_pos):
					break
				
				if not road_cells.has(current_pos):
					branch_cells.append(current_pos)
					road_cells.append(current_pos)
					
					# 在AStar网格中设置为可通行
					if astar_grid.is_in_bounds(current_pos.x, current_pos.y):
						astar_grid.set_point_solid(current_pos, false)
				
				# 随机改变方向
				if randf() < 0.3:
					directions.erase(direction)
					if directions.size() > 0:
						direction = directions[randi() % directions.size()]
			
			if branch_cells.size() > 0:
				branches_added += 1
	
	print("添加了 ", branches_added, " 个分支道路")

func is_valid_road_position(pos: Vector2i) -> bool:
	"""检查道路位置是否有效"""
	return pos.x >= 0 and pos.x < MAP_SIZE and pos.y >= 0 and pos.y < MAP_SIZE

# ========== 保留原有的辅助函数 ==========

func get_manhattan_distance(town1: Vector2i, town2: Vector2i) -> int:
	"""计算两个城镇之间的曼哈顿距离"""
	return abs(town1.x - town2.x) + abs(town1.y - town2.y)

func create_simple_road_between_towns(town1: Vector2i, town2: Vector2i):
	"""使用简单直线方式连接两个城镇"""
	var start_pos = get_town_center_cell(town1)
	var end_pos = get_town_center_cell(town2)
	
	# 先水平移动，再垂直移动（L形路径）
	var current_pos = start_pos
	var path_cells = []
	
	# 水平移动
	var dx = 1 if end_pos.x > start_pos.x else -1
	while current_pos.x != end_pos.x:
		path_cells.append(Vector2(current_pos.x, current_pos.y))
		current_pos.x += dx
	
	# 垂直移动
	var dy = 1 if end_pos.y > start_pos.y else -1
	while current_pos.y != end_pos.y:
		path_cells.append(Vector2(current_pos.x, current_pos.y))
		current_pos.y += dy
	
	# 终点
	path_cells.append(Vector2(end_pos.x, end_pos.y))
	
	# 转换为PackedVector2Array并添加宽度
	var packed_path = PackedVector2Array(path_cells)
	add_road_width(packed_path, ROAD_WIDTH)

func get_town_center_cell(town_block: Vector2i) -> Vector2i:
	"""获取城镇中心的cell坐标"""
	var center_x = town_block.x * BLOCK_SIZE + BLOCK_SIZE / 2
	var center_y = town_block.y * BLOCK_SIZE + BLOCK_SIZE / 2
	return Vector2i(center_x, center_y)

func apply_to_tilemap():
	"""将生成的地图应用到TileMapLayer"""
	# 放置城镇tiles
	for town_pos in towns:
		place_town_tiles(town_pos)
	
	# 放置道路tiles
	for road_pos in road_cells:
		grass.set_cell(road_pos, 0, Vector2i(1, 0))  # 假设road tile在atlas_coords=(1,0)

func place_town_tiles(town_block: Vector2i):
	"""在TileMapLayer上放置城镇tiles"""
	var start_x = town_block.x * BLOCK_SIZE
	var start_y = town_block.y * BLOCK_SIZE
	
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var cell_pos = Vector2i(start_x + x, start_y + y)
			grass.set_cell(cell_pos, 0, Vector2i(2, 0))  # 假设town tile在atlas_coords=(2,0)

# 公共接口函数
func generate_random_map():
	"""生成随机城镇数量的地图"""
	var town_count = randi_range(3, 8)
	generate_map(town_count)

func get_town_positions() -> Array[Vector2i]:
	"""获取所有城镇位置"""
	return towns.duplicate()

func get_road_cells() -> Array[Vector2i]:
	"""获取所有道路cell位置"""
	return road_cells.duplicate()

func get_connection_info() -> Dictionary:
	"""获取连接信息"""
	return {
		"total_connections": connected_town_pairs.size(),
		"minimum_connections": towns.size() - 1 if towns.size() > 0 else 0,
		"additional_connections": max(0, connected_town_pairs.size() - (towns.size() - 1)),
		"connected_pairs": connected_town_pairs.duplicate()
	}

func is_position_town(world_pos: Vector2) -> bool:
	"""检查世界坐标是否在城镇内"""
	var cell_pos = grass.local_to_map(world_pos)
	var block_x = cell_pos.x / BLOCK_SIZE
	var block_y = cell_pos.y / BLOCK_SIZE
	var block_pos = Vector2i(block_x, block_y)
	
	return towns.has(block_pos)

func is_position_road(world_pos: Vector2) -> bool:
	"""检查世界坐标是否在道路上"""
	var cell_pos = grass.local_to_map(world_pos)
	return road_cells.has(cell_pos)

# 调试函数
func _input(event):
	# 处理摄像头控制
	handle_camera_input(event)
	
	# 地图生成快捷键
	if event.is_action_pressed("ui_accept"):  # 空格键
		generate_random_map()
	elif event.is_action_pressed("ui_select"):  # Enter键
		generate_map(6)  # 生成6个城镇的地图
	
	# 新增调试快捷键
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				additional_connection_probability = max(0.0, additional_connection_probability - 0.1)
				print("额外连接概率: ", additional_connection_probability)
				generate_random_map()
			KEY_2:
				additional_connection_probability = min(1.0, additional_connection_probability + 0.1)
				print("额外连接概率: ", additional_connection_probability)
				generate_random_map()
			KEY_3:
				branch_probability = max(0.0, branch_probability - 0.1)
				print("分支概率: ", branch_probability)
				generate_random_map()
			KEY_4:
				branch_probability = min(1.0, branch_probability + 0.1)
				print("分支概率: ", branch_probability)
				generate_random_map()
			KEY_5:
				max_additional_connections = max(0, max_additional_connections - 1)
				print("最大额外连接数: ", max_additional_connections)
				generate_random_map()
			KEY_6:
				max_additional_connections = min(15, max_additional_connections + 1)
				print("最大额外连接数: ", max_additional_connections)
				generate_random_map()
			KEY_I:
				print_connection_info()

func print_connection_info():
	"""打印连接信息"""
	var info = get_connection_info()
	print("=== 连接信息 ===")
	print("城镇数量: ", towns.size())
	print("最小连接数: ", info.minimum_connections)
	print("额外连接数: ", info.additional_connections)
	print("总连接数: ", info.total_connections)
	print("分支概率: ", branch_probability)
	print("额外连接概率: ", additional_connection_probability)
	print("最大额外连接数: ", max_additional_connections)

# ========== 摄像头控制保持不变 ==========

func handle_camera_input(event):
	"""处理摄像头输入"""
	# 缩放控制
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.0 + ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0 - ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.position)
			else:
				stop_drag()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				# 中键点击重置摄像头到地图中心
				reset_camera_to_center()
	
	# 拖拽控制
	elif event is InputEventMouseMotion:
		if is_dragging:
			drag_camera(event.position)
	
	# 键盘控制
	elif event is InputEventKey and event.pressed:
		var pan_vector = Vector2.ZERO
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			pan_vector.y -= 1
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			pan_vector.y += 1
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			pan_vector.x -= 1
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			pan_vector.x += 1
		elif event.keycode == KEY_R:
			reset_camera_to_center()
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS:
			zoom_camera(1.0 + ZOOM_SPEED)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			zoom_camera(1.0 - ZOOM_SPEED)
		
		if pan_vector != Vector2.ZERO:
			pan_camera_by_vector(pan_vector)

func start_drag(mouse_pos: Vector2):
	"""开始拖拽"""
	is_dragging = true
	last_mouse_pos = mouse_pos
	drag_start_pos = camera.global_position

func stop_drag():
	"""停止拖拽"""
	is_dragging = false

func drag_camera(mouse_pos: Vector2):
	"""拖拽摄像头"""
	if not is_dragging:
		return
	
	var delta = (last_mouse_pos - mouse_pos) / camera.zoom
	camera.global_position += delta
	last_mouse_pos = mouse_pos
	
	# 限制摄像头在地图范围内
	clamp_camera_position()

func zoom_camera(zoom_factor: float):
	"""缩放摄像头"""
	var new_zoom = camera.zoom * zoom_factor
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = new_zoom

func pan_camera_by_vector(direction: Vector2):
	"""通过方向向量平移摄像头"""
	var pan_amount = direction * PAN_SPEED / camera.zoom.x
	camera.global_position += pan_amount
	clamp_camera_position()

func reset_camera_to_center():
	"""重置摄像头到地图中心"""
	var map_center = Vector2(MAP_SIZE * grass.tile_set.tile_size.x / 2, 
							MAP_SIZE * grass.tile_set.tile_size.y / 2)
	camera.global_position = map_center
	camera.zoom = Vector2(1.0, 1.0)

func clamp_camera_position():
	"""限制摄像头位置在地图范围内"""
	var tile_size = grass.tile_set.tile_size if grass.tile_set else Vector2i(16, 16)
	var map_pixel_size = Vector2(MAP_SIZE * tile_size.x, MAP_SIZE * tile_size.y)
	
	# 获取视口大小
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_bounds = viewport_size / camera.zoom
	
	# 计算摄像头边界
	var min_pos = camera_bounds / 2
	var max_pos = map_pixel_size - camera_bounds / 2
	
	# 如果地图比视口小，允许摄像头居中
	if max_pos.x < min_pos.x:
		var center_x = map_pixel_size.x / 2
		min_pos.x = center_x
		max_pos.x = center_x
	if max_pos.y < min_pos.y:
		var center_y = map_pixel_size.y / 2
		min_pos.y = center_y
		max_pos.y = center_y
	
	camera.global_position.x = clamp(camera.global_position.x, min_pos.x, max_pos.x)
	camera.global_position.y = clamp(camera.global_position.y, min_pos.y, max_pos.y)

func focus_camera_on_town(town_index: int):
	"""将摄像头聚焦到指定城镇"""
	if town_index >= 0 and town_index < towns.size():
		var town_block = towns[town_index]
		var town_center_cell = get_town_center_cell(town_block)
		var tile_size = grass.tile_set.tile_size if grass.tile_set else Vector2i(16, 16)
		var town_world_pos = Vector2(town_center_cell.x * tile_size.x, town_center_cell.y * tile_size.y)
		
		camera.global_position = town_world_pos

func get_camera_world_position() -> Vector2:
	"""获取摄像头世界坐标"""
	return camera.global_position

func get_camera_zoom() -> Vector2:
	"""获取摄像头缩放级别"""
	return camera.zoom
