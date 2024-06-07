extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var item := ItemCreator.create_gear_random(PlayerInventory.EquipmentType.CLOTHES)
	add_child(item)
	item = ItemCreator.create_gear_random(PlayerInventory.EquipmentType.CLOTHES)
	add_child(item)
