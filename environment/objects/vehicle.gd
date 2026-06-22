@tool
class_name Vehicle
extends Obstacle

## 车辆残骸：在 Obstacle（朝向/碰撞/显隐）之上，处理“颜色行 × 搜刮状态列”的二维帧网格。
##
## 当前朝向的 Sprite 用 vframes=颜色数、hframes=状态列数：
## - 颜色（垂直轴）：spawn 时在 [0, color_count) 随机取一行（替代基类 random_frame 的一维区间）。
## - 搜刮状态（水平轴）：列 0=关，列 1=开。搜刮成功后调 open() 切到开箱帧。
## van/truck 这类有后备箱的 has_open_state=true（hframes=2）；
## 轿车无开关帧时 has_open_state=false（hframes=1），退化为纯颜色随机。

## 颜色行数（= 当前 Sprite 的 vframes）；>1 时 spawn 随机选一行。
@export var color_count: int = 1

## 是否有“关/开”两列搜刮帧（hframes=2）。false 时只有关闭列。
@export var has_open_state: bool = false

var _color_row: int = 0
var _opened: bool = false


func _ready() -> void:
	super()  # 应用朝向；车辆不用基类 random_frame（保持 ZERO）
	if Engine.is_editor_hint():
		return

	if color_count > 1:
		_color_row = randi() % color_count
	_update_frame()


## 搜刮成功后切到“开后备箱”帧；无开关帧或已开则忽略。
func open() -> void:
	if not has_open_state or _opened:
		return
	_opened = true
	_update_frame()


func is_opened() -> bool:
	return _opened


## 按 颜色行 × 状态列 计算并设置当前朝向 Sprite 的帧号（行优先）。
func _update_frame() -> void:
	var sprite := _active_sprite()
	if not sprite:
		return
	var state_col := 1 if (_opened and has_open_state) else 0
	sprite.frame = _color_row * sprite.hframes + state_col
