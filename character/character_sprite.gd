extends Node2D


func set_texture(index: int,texture :Texture) -> void:
	var sprite: Sprite2D = get_child(index)
	assert(is_instance_valid(sprite),'节点不存在')
	sprite.texture = texture
