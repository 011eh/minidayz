extends Sprite2D

class_name Item


var resource: ItemResource


func _ready():
	texture = resource.texture

static func assert_id_exists(id: int, table: Dictionary) -> void:
	assert(table.has(id), '不存在物品资源ID %s' % id)
