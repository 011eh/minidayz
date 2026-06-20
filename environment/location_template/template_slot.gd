@tool
class_name TemplateSlot
extends Marker2D
## 地块模板中的一个对象槽位（纯数据 + 编辑器预览）。
##
## 自身不含运行逻辑，仅在编辑器里携带「放什么、随机池、抖动范围」。
## 由 [LocationTemplate].build() 在生成时读取：choose 一个候选场景实例化，叠加位置抖动。

enum Kind { BUILDING, VEHICLE, TREE, PROP, CONTAINER }

## 元素种类，仅用于编辑器分类与预览着色（生成逻辑只认 choices）。
@export var kind: Kind = Kind.BUILDING:
	set(value):
		kind = value
		queue_redraw()

## 候选场景：1 个 = 固定，多个 = 随机 choose。
@export var choices: Array[PackedScene] = []:
	set(value):
		choices = value
		update_configuration_warnings()
		queue_redraw()

## 位置抖动半径（像素，逐轴对称 ±）。Vector2.ZERO 表示位置固定。
@export var position_jitter: Vector2 = Vector2.ZERO:
	set(value):
		position_jitter = value
		queue_redraw()


## 随机选一个候选场景；choices 为空则返回 null。
func pick(rng: RandomNumberGenerator) -> PackedScene:
	if choices.is_empty():
		return null
	return choices[rng.randi() % choices.size()]


## 该槽位的最终落点（节点位置 + 抖动），相对槽位父节点坐标系。
func spawn_position(rng: RandomNumberGenerator) -> Vector2:
	if position_jitter == Vector2.ZERO:
		return position
	return position + Vector2(
		rng.randf_range(-position_jitter.x, position_jitter.x),
		rng.randf_range(-position_jitter.y, position_jitter.y),
	)


func _get_configuration_warnings() -> PackedStringArray:
	if choices.is_empty():
		return ["choices 为空：此槽位不会生成任何东西。"]
	return []


# --- 编辑器预览 ---

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# 抖动范围：半透明矩形，便于直观看到散布区域
	if position_jitter != Vector2.ZERO:
		var rect := Rect2(-position_jitter, position_jitter * 2.0)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.06))
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.25), false, 1.0)
	# 槽位本体：按 kind 着色的圆点
	draw_circle(Vector2.ZERO, 10.0, _kind_color())
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color.BLACK, 1.5)


func _kind_color() -> Color:
	match kind:
		Kind.BUILDING: return Color(0.90, 0.55, 0.20)
		Kind.VEHICLE: return Color(0.30, 0.55, 0.95)
		Kind.TREE: return Color(0.30, 0.75, 0.35)
		Kind.PROP: return Color(0.85, 0.80, 0.30)
		Kind.CONTAINER: return Color(0.70, 0.40, 0.80)
		_: return Color.WHITE
