extends Area2D

class_name InteractionArea


signal interaction_inputted


enum OwnerType {
	ITEM,
	OTHER
}


@export
var owner_type := OwnerType.OTHER
@export
var enabled: bool = true
@export
var one_shot: bool = false

var _used: bool = false


func can_interact() -> bool:
	return enabled and not (one_shot and _used)


func interact() -> void:
	if not can_interact():
		return
	_used = true
	interaction_inputted.emit()
	_on_interact()


func _on_interact() -> void:
	pass
