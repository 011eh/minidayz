extends Node2D


func _ready():
	var inventory := $Player/Inventory as PlayerInventory
	var inventory_ui := $CanvasLayer/InventoryUI
	inventory_ui.setup(inventory)

	for item in ItemCreator.create_all(NumberItem):
		$NumberItem.position.x += 25
		item.position = $NumberItem.position
		add_child(item)

	for item in ItemCreator.create_all(Craft):
		$Craft.position.x += 25
		item.position = $Craft.position
		add_child(item)

	for item in ItemCreator.create_all(Gear):
		$Gear.position.x += 25
		item.position = $Gear.position
		add_child(item)

	for item in ItemCreator.create_all(Knife):
		$Knife.position.x += 25
		item.position = $Knife.position
		add_child(item)

	for item in ItemCreator.create_all(MeleeWeapon):
		$MeleeWeapon.position.x += 25
		item.position = $MeleeWeapon.position
		add_child(item)

	for item in ItemCreator.create_all(Pistol):
		$Pistol.position.x += 25
		item.position = $Pistol.position
		add_child(item)

	for item in ItemCreator.create_all(MainWeapon):
		$MainWeapon.position.x += 25
		item.position = $MainWeapon.position
		add_child(item)

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
