class_name ChopInteraction
extends InteractionArea


func _on_interact() -> void:
	var tree := owner as ChoppableTree
	if not tree:
		return
	tree.chop()
	if tree.is_felled():
		enabled = false
