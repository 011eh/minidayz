extends Node2D


func _ready():
	$Items/ItemIcon.update_item_ui(ItemCreator.create_random(NumberItem))
	$Items/ItemIcon2.update_item_ui(ItemCreator.create_random(NumberItem))


func ui_test() -> void:
	var gear := ItemCreator.create_item(Gear, 6) as Gear
	
	$InventoryUI.update_inventory_ui(PlayerInventory.PLAYER_SLOT, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.CLOTHES, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.PANTS, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.VEST, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.BACKPACK, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.HELMET, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.MAIN_WEAPON, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.PISTOL, null)
	$InventoryUI.update_inventory_ui(PlayerInventory.MELEE_WEAPON, null)
	
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	$InventoryUI.update_inventory_ui(PlayerInventory.PLAYER_SLOT, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.CLOTHES, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.PANTS, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.VEST, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.BACKPACK, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.HELMET, ItemCreator.create_item(Gear, 25))
	$InventoryUI.update_inventory_ui(PlayerInventory.MAIN_WEAPON, ItemCreator.create_item(MainWeapon, 2))
	$InventoryUI.update_inventory_ui(PlayerInventory.PISTOL, ItemCreator.create_item(Pistol, 26))
	$InventoryUI.update_inventory_ui(PlayerInventory.MELEE_WEAPON, ItemCreator.create_item(MeleeWeapon, 2))
