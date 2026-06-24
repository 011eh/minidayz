@tool
class_name ChoppableTree
extends Node2D


@export
var chops_to_fell: int = 5

var _felled: bool = false
var _hp: int


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_hp = chops_to_fell
	_update_frame()


func chop() -> void:
	if _felled:
		return
	_hp = maxi(_hp - 1, 0)
	if _hp == 0:
		_fell()


func is_felled() -> bool:
	return _felled


func _fell() -> void:
	_felled = true
	_update_frame()

	var sound := get_node_or_null("FallSound") as AudioStreamPlayer2D
	if sound:
		sound.play()

	# 砍倒后躯干变为可穿行，玩家可越过倒木
	var shape := get_node_or_null("Trunk/TrunkShape") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	# TODO(P1): 砍倒时掉落木材战利品（木堆/木棍）


func _update_frame() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite:
		sprite.frame = 1 if _felled else 0
