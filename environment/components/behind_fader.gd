class_name BehindFader
extends VisibleOnScreenNotifier2D

## 当玩家走到目标 Sprite 之后（更靠上方）时，把这些 Sprite 变半透明的可复用组件。
##
## 利用 VisibleOnScreenNotifier2D 自带的离屏门控：离屏时关闭 _process，实现零开销。
## 目标物体被视为静态，所有几何信息在 _ready 中一次性计算。

## 要淡出的 Sprite2D 列表；留空时默认为 [get_parent()]。
@export var targets: Array[NodePath] = []
## 淡出时的不透明度。
@export var faded_alpha: float = 0.4
## 前后判定线相对父节点 global_position.y 的偏移（全局 y）。
@export var threshold_offset: float = 0.0
## 水平范围的额外外扩（全局 x）。
@export var margin: float = 0.0

var _sprites: Array[CanvasItem] = []
var _player: Node2D
var _left: float
var _right: float
var _threshold_y: float
var _is_faded: bool = false


func _ready() -> void:
	# 1. 解析 targets。
	var node_paths := targets
	if node_paths.is_empty():
		_sprites = [get_parent() as CanvasItem]
	else:
		for path in node_paths:
			_sprites.append(get_node(path) as CanvasItem)

	# 2. 计算所有 target 的全局并集 AABB。
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for sprite in _sprites:
		var local_rect := (sprite as Sprite2D).get_rect()
		var xform := sprite.get_global_transform()
		var corners := [
			local_rect.position,
			local_rect.position + Vector2(local_rect.size.x, 0),
			local_rect.position + Vector2(0, local_rect.size.y),
			local_rect.position + local_rect.size,
		]
		for corner in corners:
			var g: Vector2 = xform * corner
			min_x = minf(min_x, g.x)
			min_y = minf(min_y, g.y)
			max_x = maxf(max_x, g.x)
			max_y = maxf(max_y, g.y)

	# 3. 水平范围（全局 x）。
	_left = min_x - margin
	_right = max_x + margin

	# 4. 前后判定线（全局 y，与 Y-Sort 排序依据一致）。
	_threshold_y = get_parent().global_position.y + threshold_offset

	# 5. 设置离屏检测的 rect：把全局并集 AABB 转回本节点局部坐标。
	var top_left := to_local(Vector2(min_x, min_y))
	var bottom_right := to_local(Vector2(max_x, max_y))
	rect = Rect2(top_left, bottom_right - top_left)

	# 6. 缓存玩家。
	_player = get_tree().get_first_node_in_group('player')

	# 7. 离屏门控：默认关闭 _process，进出屏幕时切换。
	set_process(false)
	screen_entered.connect(func() -> void:
		set_process(true)
	)
	screen_exited.connect(func() -> void:
		set_process(false)
	)
	# 兼容出生即在屏的情况（is_on_screen 需要一帧才能确定）。
	await get_tree().process_frame
	if is_on_screen():
		set_process(true)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var p := _player.global_position
	var want := p.x >= _left and p.x <= _right and p.y < _threshold_y
	if want == _is_faded:
		return
	_is_faded = want
	var a := faded_alpha if want else 1.0
	for s in _sprites:
		s.self_modulate.a = a
