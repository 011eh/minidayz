extends Node2D


func _ready():
	ui_test()


func ui_test() -> void:
	var gear := ItemCreator.create_item(Gear, 6) as Gear
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	$InventoryUI.update_inventory_ui(PlayerInventory.PLAYER_SLOT, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.CLOTHES, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.PANTS, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.VEST, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.BACKPACK, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.HELMET, ItemCreator.create_item(Gear, 25))
	$InventoryUI.update_inventory_ui(PlayerInventory.MAIN_WEAPON, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.PISTOL, ItemCreator.create_item(Pistol, 26))
	$InventoryUI.update_inventory_ui(PlayerInventory.MELEE_WEAPON, ItemCreator.create_item(MeleeWeapon, 2))
