extends Node2D


func set_texture(index: int, item: Item) -> void:
	var sprite: Sprite2D = get_child(index)
	assert(is_instance_valid(sprite),'节点不存在')
	if is_instance_valid(item):
		sprite.texture = item.resource.texture
	else:
		sprite.texture = null
