extends Node2D


func _ready():
	var gear := ItemCreator.create_item(Gear, 18) as Gear
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	gear.add_to_slot(ItemCreator.create_item(Craft, 92))
	$InventoryUI/Cards/ClothesCard.update_gear_ui(gear)
	
	gear = ItemCreator.create_item(Gear, 18) as Gear
	gear.add_to_slot(ItemCreator.create_item(NumberItem, 31))
	gear.add_to_slot(ItemCreator.create_item(NumberItem, 31))
	gear.add_to_slot(ItemCreator.create_item(NumberItem, 31))
	$InventoryUI/Cards/PantsCard.update_gear_ui(gear)
