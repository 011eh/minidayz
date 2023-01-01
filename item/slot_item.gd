extends 'number_item.gd'

class_name SlotItem


func _ready():
	super._ready()
	if resource.id == 16:
		hframes = 3
		vframes = 2
		frame = 5

static func create_item(id: int) -> SlotItem:
	var item := SlotItem.new()
	item.resource = SOLT_ITEM_RES_TABLE.get(id)
	return item
