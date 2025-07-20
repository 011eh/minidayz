extends Node2D

var astar_grids = {}
var paths = {}
var grid_size = Vector2i(15, 10)
var cell_size = 40
var start_pos = Vector2i(1, 1)
var end_pos = Vector2i(13, 8)

# 摄像机控制
var camera: Camera2D
var is_dragging = false
var drag_start_position: Vector2
var camera_start_position: Vector2
var zoom_speed = 0.1
var min_zoom = 0.3
var max_zoom = 3.0

# 障碍物
var obstacles = [
	Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5),
	Vector2i(8, 1), Vector2i(8, 2), Vector2i(8, 3),
	Vector2i(10, 5), Vector2i(10, 6), Vector2i(10, 7),
]

func _ready():
	setup_camera()
	setup_grids()
	calculate_all_paths()

func setup_camera():
	# 创建摄像机
	camera = Camera2D.new()
	add_child(camera)
	
	# 设置初始位置和缩放
	var total_height = (grid_size.y + 2) * cell_size * 4  # 4个网格的总高度
	camera.position = Vector2(grid_size.x * cell_size / 2, total_height / 2)
	camera.zoom = Vector2(0.6, 0.6)  # 初始缩放，让内容可见
	
	# 让摄像机生效
	camera.make_current()

func setup_grids():
	# 创建使用不同启发式的网格
	var heuristics = {
		"Euclidean": AStarGrid2D.HEURISTIC_EUCLIDEAN,
		"Manhattan": AStarGrid2D.HEURISTIC_MANHATTAN,
		"Octile": AStarGrid2D.HEURISTIC_OCTILE,
		"Chebyshev": AStarGrid2D.HEURISTIC_CHEBYSHEV
	}
	
	for heuristic_name in heuristics:
		var grid = AStarGrid2D.new()
		grid.size = grid_size
		
		# 设置不同的启发式函数
		var heuristic_value = heuristics[heuristic_name]
		grid.default_compute_heuristic = heuristic_value
		grid.default_estimate_heuristic = heuristic_value
		
		grid.update()
		
		# 添加障碍物
		for obstacle in obstacles:
			grid.set_point_solid(obstacle, true)
		
		astar_grids[heuristic_name] = grid

func calculate_all_paths():
	for heuristic_name in astar_grids:
		var grid = astar_grids[heuristic_name]
		var path = grid.get_point_path(start_pos, end_pos)
		paths[heuristic_name] = path
		
		print(heuristic_name, " 路径长度: ", path.size())
		print("  路径距离: %.2f" % calculate_path_distance(path))

func calculate_path_distance(path: PackedVector2Array) -> float:
	if path.size() < 2:
		return 0.0
	
	var distance = 0.0
	for i in range(path.size() - 1):
		distance += path[i].distance_to(path[i + 1])
	return distance

func _draw():
	var colors = {
		"Euclidean": Color.BLUE,
		"Manhattan": Color.RED,
		"Octile": Color.GREEN,
		"Chebyshev": Color.PURPLE
	}
	
	var y_offset = 0
	
	for heuristic_name in ["Euclidean", "Manhattan", "Octile", "Chebyshev"]:
		draw_grid_section(heuristic_name, Vector2(0, y_offset), colors[heuristic_name])
		y_offset += (grid_size.y + 2) * cell_size

func draw_grid_section(heuristic_name: String, offset: Vector2, path_color: Color):
	# 绘制标题
	var font = ThemeDB.fallback_font
	var font_size = 16
	draw_string(font, offset + Vector2(0, -5), heuristic_name + " Heuristic", 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# 绘制网格
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = offset + Vector2(x * cell_size, y * cell_size)
			var rect = Rect2(pos, Vector2(cell_size, cell_size))
			
			# 绘制网格线
			draw_rect(rect, Color.GRAY, false, 1)
			
			# 绘制障碍物
			if Vector2i(x, y) in obstacles:
				draw_rect(rect, Color.DARK_GRAY, true)
	
	# 绘制路径
	if heuristic_name in paths and paths[heuristic_name].size() > 0:
		var path = paths[heuristic_name]
		
		# 绘制路径线
		for i in range(path.size() - 1):
			var start_world = path[i] * cell_size + Vector2(cell_size/2, cell_size/2) + offset
			var end_world = path[i + 1] * cell_size + Vector2(cell_size/2, cell_size/2) + offset
			draw_line(start_world, end_world, path_color, 3)
		
		# 绘制路径点
		for point in path:
			var world_pos = point * cell_size + Vector2(cell_size/2, cell_size/2) + offset
			draw_circle(world_pos, 4, path_color)
	
	# 绘制起点和终点
	var start_rect = Rect2(offset + Vector2(start_pos) * cell_size + Vector2(5, 5), 
						  Vector2(cell_size-10, cell_size-10))
	var end_rect = Rect2(offset + Vector2(end_pos) * cell_size + Vector2(5, 5), 
						Vector2(cell_size-10, cell_size-10))
	draw_rect(start_rect, Color.YELLOW, true)
	draw_rect(end_rect, Color.ORANGE, true)
	
	# 显示路径信息
	if heuristic_name in paths:
		var path = paths[heuristic_name]
		var info_text = "路径长度: %d, 距离: %.1f" % [path.size(), calculate_path_distance(path)]
		draw_string(font, offset + Vector2(0, grid_size.y * cell_size + 20), info_text,
				   HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	
	# 绘制控制提示（只在第一个网格显示）
	if heuristic_name == "Euclidean":
		var help_text = [
			"控制说明:",
			"• 鼠标拖拽 - 移动视图",
			"• 滚轮 - 缩放",
			"• H键 - 重置视图",
			"• R键 - 重新计算路径"
		]
		
		var help_offset = offset + Vector2(grid_size.x * cell_size + 20, 0)
		for i in range(help_text.size()):
			draw_string(font, help_offset + Vector2(0, i * 20), help_text[i],
					   HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _input(event):
	# 摄像机控制
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖拽
				is_dragging = true
				drag_start_position = event.position
				camera_start_position = camera.position
			else:
				# 停止拖拽
				is_dragging = false
		
		# 鼠标滚轮缩放
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0 - zoom_speed)
	
	elif event is InputEventMouseMotion and is_dragging:
		# 拖拽移动摄像机
		var drag_delta = drag_start_position - event.position
		camera.position = camera_start_position + drag_delta / camera.zoom
	
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			# 重新计算路径
			calculate_all_paths()
			queue_redraw()
		elif event.keycode == KEY_HOME or event.keycode == KEY_H:
			# 重置摄像机位置
			reset_camera()

func zoom_camera(zoom_factor: float):
	var new_zoom = camera.zoom * zoom_factor
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	camera.zoom = new_zoom

func reset_camera():
	var total_height = (grid_size.y + 2) * cell_size * 4
	camera.position = Vector2(grid_size.x * cell_size / 2, total_height / 2)
	camera.zoom = Vector2(0.6, 0.6)
