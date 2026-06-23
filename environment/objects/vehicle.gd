@tool
class_name Vehicle
extends StaticBody2D


@export
var color_count: int = 1
@export
var has_open_state: bool = false
var _color_row: int = 0
var _opened: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if color_count > 1:
		_color_row = randi() % color_count
	_update_frame()

func open() -> void:
	if not has_open_state or _opened:
		return
	_opened = true
	_update_frame()

func is_opened() -> bool:
	return _opened

func _update_frame() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if not sprite:
		return
	var state_col := 1 if (_opened and has_open_state) else 0
	sprite.frame = _color_row * sprite.hframes + state_col
