extends Node2D

func _ready():
	var inventory_ui := $CanvasLayer/InventoryUI
	$Player/Inventory.slot_item_changed.connect(inventory_ui.update_inventory_ui)
	stack_test()
	pass

func stack_test():
	var item: Item
	item = ItemCreator.create_item(NumberItem, 0)
	item.number = 60
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(NumberItem, 0)
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(NumberItem, 0)
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
	$ItemPosition.position.x += 200
	item.position = $EquipmentPosition.position
	add_child(item)
	
	item = ItemCreator.create_item(Gear, 1)
	$EquipmentPosition.position.x += 200
	item.position = $EquipmentPosition.position
	add_child(item)
	

func inventory_test():
	var item: Item
	for i in range(8):
		item = ItemCreator.create_item(NumberItem, i)
		$ItemPosition.position.x += 20
		item.position = $ItemPosition.position
		add_child(item)
	
	item = ItemCreator.create_item(NumberItem, 0)
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
