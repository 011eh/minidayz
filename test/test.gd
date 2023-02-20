extends Node2D


func _ready():
	var gear := ItemCreator.create_item(Gear, 6) as Gear
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	$InventoryUI.update_inventory_ui(1,gear)
