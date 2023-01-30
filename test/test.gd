extends Node2D

class_name Test


var slots: Array[Gear]

var n:int: get= ggg
var s:int
func ggg():
	return s+10

func _ready():
	stack_test()
	pass

func stack_test():
	
	
	var item: Item
	item = ItemCreator.create_item(SlotItem, 0)
	item.number = 60
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(SlotItem, 0)
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(SlotItem, 0)
	item.number = 30
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(Craft, 85)
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(Knife, 11)
	$ItemPosition.position.x += 200
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(Gear, 0)
	item.position = $EquipmentPosition.position
	add_child(item)

func inventory_test():
	var item: Item
	for i in range(8):
		item = ItemCreator.create_item(SlotItem, i)
		$ItemPosition.position.x += 20
		item.position = $ItemPosition.position
		add_child(item)
	
	item = ItemCreator.create_item(SlotItem, 0)
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(Gear, 0)
	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(Gear, 17)

	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(Gear, 24)

	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(Gear, 42)

	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(Gear, 48)

	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(MainWeapon, 0)

	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(Pistol, 25)

	item.position = $EquipmentPosition.position 
	add_child(item)
	item = ItemCreator.create_item(MeleeWeapon, 0)

	item.position = $EquipmentPosition.position 
	add_child(item)
