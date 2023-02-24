extends Node2D


var array :=[NumberItem]

func _ready():
	print(NumberItem)
	print(array[0])
	
#	$Items/ItemIcon.update_item_ui(ItemCreator.create_random(NumberItem))
#	$Items/ItemIcon2.update_item_ui(ItemCreator.create_random(NumberItem))
	ui_test()


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
	
	gear.slots[1] = ItemCreator.create_item(Craft, 92) 
	gear.slots[2] = ItemCreator.create_item(Knife, 11) 
	$InventoryUI.update_inventory_ui(PlayerInventory.PLAYER_SLOT, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.CLOTHES, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.PANTS, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.VEST, gear)
	$InventoryUI.update_inventory_ui(PlayerInventory.BACKPACK, ItemCreator.create_item(Gear, 51))
	$InventoryUI.update_inventory_ui(PlayerInventory.HELMET, ItemCreator.create_item(Gear, 25))
	$InventoryUI.update_inventory_ui(PlayerInventory.MAIN_WEAPON, ItemCreator.create_item(MainWeapon, 2))
	$InventoryUI.update_inventory_ui(PlayerInventory.PISTOL, ItemCreator.create_item(Pistol, 26))
	$InventoryUI.update_inventory_ui(PlayerInventory.MELEE_WEAPON, null)
