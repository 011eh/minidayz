@tool
class_name Obstacle
extends StaticBody2D

## 障碍/车辆/容器的共用基座。
## 子节点固定命名：SpriteH / SpriteV (Sprite2D)、ShapeH / ShapeV (CollisionShape2D)。
## 横竖朝向各一套贴图+碰撞，orientation 决定显示哪一套（编辑器即时预览）。

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


## 按当前 orientation 切换两套贴图/碰撞的显隐；编辑器与运行时通用。
func _apply_orientation() -> void:
	var vertical := orientation == Orient.VERTICAL

	var sprite_h := get_node_or_null("SpriteH") as Sprite2D
	var sprite_v := get_node_or_null("SpriteV") as Sprite2D
	if sprite_h:
		sprite_h.visible = not vertical
	if sprite_v:
		sprite_v.visible = vertical

	var shape_h := get_node_or_null("ShapeH") as CollisionShape2D
	var shape_v := get_node_or_null("ShapeV") as CollisionShape2D
	if shape_h:
		shape_h.set_deferred("disabled", vertical)
		shape_h.visible = not vertical
	if shape_v:
		shape_v.set_deferred("disabled", not vertical)
		shape_v.visible = vertical


## 当前朝向对应的 Sprite（用于 random_frame）。
func _active_sprite() -> Sprite2D:
	var sprite_name := "SpriteV" if orientation == Orient.VERTICAL else "SpriteH"
	return get_node_or_null(sprite_name) as Sprite2D
