extends 'durability_item.gd'

class_name Craft


static func create_item(id: int) -> Craft:
	var item := Craft.new()
	item.resource = SOLT_ITEM_RES_TABLE.get(id)
	return item
