class_name SearchableInteraction
extends InteractionArea


func _on_interact() -> void:
	var vehicle := owner as Vehicle
	if vehicle:
		vehicle.open()
	# TODO(P1): 触发 LootAnchors 下的战利品刷新
