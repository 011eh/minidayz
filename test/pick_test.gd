extends Node2D

func _ready():
	var inventory_ui := $CanvasLayer/InventoryUI
	$Player/Inventory.slot_item_changed.connect(inventory_ui.update_inventory_ui)
	
	var item: Item
	for i in range(200):
		item = ItemCreator.create_random(NumberItem)
		$ItemPosition.position.x += 20
		item.position = $ItemPosition.position
		add_child(item)
	
	var equip: Item
	for i in range(20):
		equip = ItemCreator.create_random(Gear)
		$EquipmentPosition.position.x += 20
		equip.position = $EquipmentPosition.position
		add_child(equip)
	
	for i in range(20):
		equip = ItemCreator.create_random(Pistol)
		$Pistol.position.x += 20
		equip.position = $Pistol.position
		add_child(equip)
	
	for i in range(20):
		equip = ItemCreator.create_random(MainWeapon)
		$MainWeapon.position.x += 20
		equip.position = $MainWeapon.position
		add_child(equip)
	
	for i in range(20):
		equip = ItemCreator.create_random(MeleeWeapon)
		$MeleeWeapon.position.x += 20
		equip.position = $MeleeWeapon.position
		add_child(equip)

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
