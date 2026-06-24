extends Node2D


func _ready() -> void:
	for area in _collect_interaction_areas(self):
		area.interaction_inputted.connect(func() -> void:
			print("[interact] %s  one_shot=%s can_interact_after=%s"
				% [area.owner.name, area.one_shot, area.can_interact()])
		)


func _collect_interaction_areas(node: Node) -> Array[InteractionArea]:
	var result: Array[InteractionArea] = []
	for child in node.get_children():
		if child is InteractionArea:
			result.append(child)
		result.append_array(_collect_interaction_areas(child))
	return result
