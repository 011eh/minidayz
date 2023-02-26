extends Node2D


var array :=[NumberItem]


func _ready():
#	$Items/ItemIcon.update_item_ui(ItemCreator.create_random(NumberItem))
#	$Items/ItemIcon2.update_item_ui(ItemCreator.create_random(NumberItem))
	ui_test()


func ui_test() -> void:
	var gear: Gear
	gear = ItemCreator.create_item(Gear, 6) as Gear
	gear.slots[1] = ItemCreator.create_item(Craft, 92)
	gear.slots[2] = ItemCreator.create_item(Knife, 11)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.PLAYER_SLOT, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.CLOTHES, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.PANTS, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.VEST, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.BACKPACK, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.HELMET, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.MAIN_WEAPON, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.PISTOL, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.MELEE_WEAPON, null)

	gear = ItemCreator.create_item(Gear, 6) as Gear
	gear.slots[1] = ItemCreator.create_random(NumberItem)
	gear.slots[2] = ItemCreator.create_random(NumberItem)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.PLAYER_SLOT, gear)
	gear = ItemCreator.create_item(Gear, 6) as Gear
	gear.slots[1] = ItemCreator.create_random(NumberItem)
	gear.slots[2] = ItemCreator.create_random(NumberItem)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.CLOTHES, gear)
	gear = ItemCreator.create_item(Gear, 6) as Gear
	gear.slots[1] = ItemCreator.create_random(NumberItem)
	gear.slots[2] = ItemCreator.create_random(NumberItem)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.PANTS, gear)
	gear = ItemCreator.create_item(Gear, 6) as Gear
	gear.slots[1] = ItemCreator.create_random(NumberItem)
	gear.slots[2] = ItemCreator.create_random(NumberItem)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.VEST, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.BACKPACK, ItemCreator.create_item(Gear, 51))
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.HELMET, ItemCreator.create_item(Gear, 25))
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.MAIN_WEAPON, ItemCreator.create_item(MainWeapon, 2))
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.PISTOL, ItemCreator.create_item(Pistol, 26))
	$InventoryUI.update_inventory_ui(PlayerInventory.EQUIPMENT_TYPE.MELEE_WEAPON, ItemCreator.create_random(Knife))
