@tool
class_name TemplateSlot
extends Marker2D


enum Type { BUILDING, VEHICLE, TREE, PROP, CONTAINER }

@export
var type: Type = Type.BUILDING:
	set(value):
		type = value
		queue_redraw()

@export
var choices: Array[PackedScene] = []:
	set(value):
		choices = value
		update_configuration_warnings()
		queue_redraw()

@export
var position_jitter: Vector2 = Vector2.ZERO:
	set(value):
		position_jitter = value
		queue_redraw()


func pick(rng: RandomNumberGenerator) -> PackedScene:
	if choices.is_empty():
		return null
	return choices[rng.randi() % choices.size()]

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

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if position_jitter != Vector2.ZERO:
		var rect := Rect2(-position_jitter, position_jitter * 2.0)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.06))
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.25), false, 1.0)
	draw_circle(Vector2.ZERO, 10.0, _type_color())
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color.BLACK, 1.5)


func _type_color() -> Color:
	match type:
		Type.BUILDING: return Color(0.90, 0.55, 0.20)
		Type.VEHICLE: return Color(0.30, 0.55, 0.95)
		Type.TREE: return Color(0.30, 0.75, 0.35)
		Type.PROP: return Color(0.85, 0.80, 0.30)
		Type.CONTAINER: return Color(0.70, 0.40, 0.80)
		_: return Color.WHITE
