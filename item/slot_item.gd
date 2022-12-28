extends 'number_item.gd'

class_name SlotItem

const RES_TABLE := {
	0: preload('res://item/res/slot_item/ammo_5x45.tres'),
	1: preload('res://item/res/slot_item/ammo_5x56.tres'),
}

static func get_item(id: int) -> SlotItem:
	var item := SlotItem.new()
	item.resource = RES_TABLE.get(id)
	return item
