extends 'number_item.gd'

class_name SlotItem


static func create_item(id: int) -> SlotItem:
	var item := SlotItem.new()
	item.resource = SOLT_ITEM_RES_TABLE.get(id)
	return item
