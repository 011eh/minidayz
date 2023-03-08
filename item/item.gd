extends Sprite2D

class_name Item


@export
var resource: ItemResource: get = get_resource, set = set_resource


func _ready():
	texture = resource.texture

func get_resource():
	return resource

func set_resource(res: ItemResource):
	resource = res

func is_equipment() -> bool:
	return false

func get_item_id() -> int:
	return resource.id

func get_item_name() -> StringName:
	return resource.item_name

static func assert_id_exists(id: int, table: Dictionary) -> void:
	assert(table.has(id), '不存在物品资源ID %s' % id)
