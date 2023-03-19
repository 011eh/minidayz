extends Node2D


var offset := 165

var type := Pistol

func _ready():
	var item1 := ItemCreator.create_item_from_id(13)
	var item2 := ItemCreator.create_item_from_id(17)
	item2.number = 1
	var optoins := ItemActionTable.create_crafting_options(item1, item2)
	optoins.front().action.call()
