extends Sprite2D

class_name Item


@export
var resource: ItemResource


func _ready():
	texture = resource.texture

func is_equipment() -> bool:
	return self is Gear \
	or self is MainWeapon \
	or self is  Pistol \
	or self is MeleeWeapon

static func assert_id_exists(id: int, table: Dictionary) -> void:
	assert(table.has(id), '不存在物品资源ID %s' % id)
