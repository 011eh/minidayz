extends Node2D

class_name Test


var slots: Array[Gear]


func _ready():
	var item: Item
	for i in range(100):
		item = ItemCreator.create_item(SlotItem, 0)
		add_child(item)
	
	item = ItemCreator.create_item(SlotItem, 49)
	add_child(item)
	item = ItemCreator.create_item(MeleeWeapon, 0)
	add_child(item)
	item = ItemCreator.create_item(MainWeapon, 0)
	add_child(item)
	item = ItemCreator.create_item(Gear, 0)
	add_child(item)
	item = ItemCreator.create_item(Gear, 17)
	add_child(item)
	item = ItemCreator.create_item(Gear, 24)
	add_child(item)
	item = ItemCreator.create_item(Gear, 42)
	add_child(item)
	item = ItemCreator.create_item(Gear, 48)
	add_child(item)
	item = ItemCreator.create_item(Pistol, 25)
	add_child(item)
