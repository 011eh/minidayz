@tool
class_name Obstacle
extends StaticBody2D

## 障碍/车辆/容器的共用基座。
## 节点结构：Horizontal / Vertical 两个 Node2D 分组，各含一套
##   SpriteH/ShapeH 与 SpriteV/ShapeV（Sprite2D + CollisionShape2D）。
## orientation 决定显示哪一组（编辑器即时预览）。

enum Orient { HORIZONTAL, VERTICAL }

## 朝向：HORIZONTAL 显示 SpriteH/ShapeH，VERTICAL 显示 SpriteV/ShapeV。
@export var orientation: Orient = Orient.HORIZONTAL:
	set(value):
		orientation = value
		_apply_orientation()

## 帧随机范围 [min, max]（含端点）；Vector2i.ZERO 表示不随机化（仅运行时）。
@export var random_frame: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_apply_orientation()
	if Engine.is_editor_hint():
		return

	var sprite := _active_sprite()
	if sprite and random_frame != Vector2i.ZERO:
		sprite.frame = randi_range(random_frame.x, random_frame.y)


## 按当前 orientation 切换 Horizontal/Vertical 两组的显隐；编辑器与运行时通用。
func _apply_orientation() -> void:
	var vertical := orientation == Orient.VERTICAL

	var h_root := get_node_or_null("Horizontal") as Node2D
	var v_root := get_node_or_null("Vertical") as Node2D
	if h_root:
		h_root.visible = not vertical  # 子 Sprite 随父节点隐藏
	if v_root:
		v_root.visible = vertical

	# 碰撞需单独切 disabled（Node2D.visible 不影响碰撞）。
	var shape_h := get_node_or_null("Horizontal/ShapeH") as CollisionShape2D
	var shape_v := get_node_or_null("Vertical/ShapeV") as CollisionShape2D
	if shape_h:
		shape_h.set_deferred("disabled", vertical)
	if shape_v:
		shape_v.set_deferred("disabled", not vertical)


## 当前朝向对应的 Sprite（用于 random_frame / 车辆帧计算）。
func _active_sprite() -> Sprite2D:
	var sprite_path := "Vertical/SpriteV" if orientation == Orient.VERTICAL else "Horizontal/SpriteH"
	return get_node_or_null(sprite_path) as Sprite2D
