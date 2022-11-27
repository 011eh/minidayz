extends Node2D


func set_texture(node_name: String,texture :Texture) -> void:
	assert(has_node(node_name),'没有 %s 节点！')
	var sprite = get_node(node_name) as Sprite2D
	sprite.texture = texture 
