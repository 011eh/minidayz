extends Camera2D

# 缩放设置
@export var zoom_speed: float = 0.4          # 缩放速度
@export var min_zoom: float = 0.01            # 最小缩放值
@export var max_zoom: float = 100.0           # 最大缩放值
@export var zoom_smoothing: bool = true      # 是否启用缩放平滑
@export var zoom_smooth_speed: float = 10.0  # 缩放平滑速度

# 拖拽设置
@export var enable_drag: bool = true         # 是否启用拖拽
@export var drag_button: MouseButton = MOUSE_BUTTON_LEFT  # 拖拽鼠标按钮
@export var drag_smoothing: bool = false     # 是否启用拖拽平滑
@export var drag_smooth_speed: float = 10.0  # 拖拽平滑速度

# 边界限制设置
@export var enable_bounds: bool = false      # 是否启用移动边界
@export var bounds_rect: Rect2               # 移动边界矩形

# 键盘移动设置
@export var enable_keyboard: bool = true     # 是否启用键盘移动
@export var keyboard_speed: float = 500.0    # 键盘移动速度

# 内部变量
var target_zoom: Vector2                     # 目标缩放值
var target_position: Vector2                 # 目标位置
var is_dragging: bool = false                # 是否正在拖拽
var last_mouse_position: Vector2             # 上次鼠标位置
var drag_start_camera_position: Vector2      # 拖拽开始时相机位置

func _ready():
	# 初始化目标值
	target_zoom = zoom
	target_position = global_position

func _input(event):
	# 处理缩放输入
	handle_zoom_input(event)

	# 处理拖拽输入
	if enable_drag:
		handle_drag_input(event)

func _process(delta):
	# 处理键盘移动
	if enable_keyboard:
		handle_keyboard_input(delta)

	# 应用平滑移动和缩放
	apply_smoothing(delta)

	# 应用边界限制
	if enable_bounds:
		apply_bounds()

func handle_zoom_input(event):
	"""处理缩放输入"""
	if event is InputEventMouseButton:
		var zoom_factor = 1.0

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_factor = 1.0 + zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_factor = 1.0 - zoom_speed
		else:
			return

		if event.pressed:
			# 获取鼠标在世界坐标中的位置
			var mouse_world_pos = get_global_mouse_position()

			# 计算新的缩放值
			var new_zoom = target_zoom * zoom_factor
			new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
			new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)

			# 如果缩放值没有变化，则不处理
			if new_zoom.is_equal_approx(target_zoom):
				return

			# 以鼠标为中心进行缩放
			var zoom_center = mouse_world_pos
			var camera_pos = global_position

			# 计算缩放后相机应该移动到的位置
			var zoom_diff = new_zoom / target_zoom
			var new_camera_pos = zoom_center + (camera_pos - zoom_center) / zoom_diff

			target_zoom = new_zoom
			target_position = new_camera_pos

func handle_drag_input(event):
	"""处理拖拽输入"""
	if event is InputEventMouseButton:
		if event.button_index == drag_button:
			if event.pressed:
				# 开始拖拽
				is_dragging = true
				last_mouse_position = event.global_position
				drag_start_camera_position = global_position
			else:
				# 结束拖拽
				is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		# 拖拽移动
		var mouse_delta = event.global_position - last_mouse_position

		# 将屏幕坐标的移动转换为世界坐标的移动
		var world_delta = mouse_delta / zoom

		if drag_smoothing:
			target_position -= world_delta
		else:
			global_position -= world_delta
			target_position = global_position

		last_mouse_position = event.global_position

func handle_keyboard_input(delta):
	"""处理键盘移动输入"""
	var movement = Vector2.ZERO

	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		movement.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		movement.y += 1

	if movement != Vector2.ZERO:
		# 根据当前缩放调整移动速度
		var adjusted_speed = keyboard_speed / zoom.x
		var move_delta = movement.normalized() * adjusted_speed * delta

		target_position += move_delta

		if not drag_smoothing:
			global_position = target_position

func apply_smoothing(delta):
	"""应用平滑移动和缩放"""
	if zoom_smoothing:
		zoom = zoom.lerp(target_zoom, zoom_smooth_speed * delta)
	else:
		zoom = target_zoom

	if drag_smoothing:
		global_position = global_position.lerp(target_position, drag_smooth_speed * delta)
	else:
		global_position = target_position

func apply_bounds():
	"""应用移动边界限制"""
	if bounds_rect.size == Vector2.ZERO:
		return

	# 计算相机视野的世界坐标边界
	var viewport_size = get_viewport().get_visible_rect().size
	var world_viewport_size = viewport_size / zoom
	var half_viewport = world_viewport_size * 0.5

	# 限制相机位置
	var min_pos = bounds_rect.position + half_viewport
	var max_pos = bounds_rect.position + bounds_rect.size - half_viewport

	target_position.x = clamp(target_position.x, min_pos.x, max_pos.x)
	target_position.y = clamp(target_position.y, min_pos.y, max_pos.y)

	# 如果不使用平滑，立即应用位置
	if not drag_smoothing:
		global_position = target_position

# 公共方法：设置相机位置
func set_camera_position(pos: Vector2, smooth: bool = true):
	"""设置相机位置"""
	target_position = pos
	if not smooth:
		global_position = pos

# 公共方法：设置缩放
func set_camera_zoom(new_zoom: Vector2, smooth: bool = true):
	"""设置相机缩放"""
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	target_zoom = new_zoom

	if not smooth:
		zoom = new_zoom

# 公共方法：设置缩放（统一缩放）
func set_camera_zoom_uniform(zoom_value: float, smooth: bool = true):
	"""设置统一缩放"""
	set_camera_zoom(Vector2(zoom_value, zoom_value), smooth)

# 公共方法：重置相机
func reset_camera():
	"""重置相机到初始状态"""
	target_position = Vector2.ZERO
	target_zoom = Vector2.ONE
	global_position = Vector2.ZERO
	zoom = Vector2.ONE

# 公共方法：聚焦到指定位置
func focus_on_position(pos: Vector2, zoom_level: float = -1, smooth: bool = true):
	"""聚焦到指定位置"""
	target_position = pos

	if zoom_level > 0:
		set_camera_zoom_uniform(zoom_level, smooth)

	if not smooth:
		global_position = pos

# 公共方法：聚焦到指定区域
func focus_on_area(area: Rect2, padding: float = 50.0, smooth: bool = true):
	"""聚焦到指定区域"""
	# 计算中心位置
	var center = area.position + area.size * 0.5
	target_position = center

	# 计算合适的缩放级别
	var viewport_size = get_viewport().get_visible_rect().size
	var area_with_padding = area.size + Vector2(padding * 2, padding * 2)

	var zoom_x = viewport_size.x / area_with_padding.x
	var zoom_y = viewport_size.y / area_with_padding.y
	var fit_zoom = min(zoom_x, zoom_y)

	set_camera_zoom_uniform(fit_zoom, smooth)

	if not smooth:
		global_position = center

# 公共方法：设置移动边界
func set_bounds(new_bounds: Rect2):
	"""设置移动边界"""
	bounds_rect = new_bounds
	enable_bounds = true

# 公共方法：清除移动边界
func clear_bounds():
	"""清除移动边界"""
	enable_bounds = false

# 公共方法：获取当前可视区域
func get_visible_area() -> Rect2:
	"""获取当前相机可视的世界区域"""
	var viewport_size = get_viewport().get_visible_rect().size
	var world_size = viewport_size / zoom
	var top_left = global_position - world_size * 0.5
	return Rect2(top_left, world_size)

# 公共方法：检查点是否在可视范围内
func is_position_visible(pos: Vector2) -> bool:
	"""检查指定位置是否在当前可视范围内"""
	var visible_area = get_visible_area()
	return visible_area.has_point(pos)

# 公共方法：屏幕坐标转世界坐标
func screen_to_world(screen_pos: Vector2) -> Vector2:
	"""将屏幕坐标转换为世界坐标"""
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var viewport_center = viewport_size * 0.5

	# 屏幕坐标相对于视口中心的偏移
	var offset_from_center = screen_pos - viewport_center

	# 转换为世界坐标偏移
	var world_offset = offset_from_center / zoom

	return global_position + world_offset

# 公共方法：世界坐标转屏幕坐标
func world_to_screen(world_pos: Vector2) -> Vector2:
	"""将世界坐标转换为屏幕坐标"""
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var viewport_center = viewport_size * 0.5

	# 世界坐标相对于相机的偏移
	var world_offset = world_pos - global_position

	# 转换为屏幕坐标偏移
	var screen_offset = world_offset * zoom

	return viewport_center + screen_offset
