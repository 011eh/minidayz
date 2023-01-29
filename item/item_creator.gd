extends Node

class_name ItemCreator


const ItemScene := preload('res://item/item.tscn')


static func create_item(item_script: GDScript, item_id: int) -> Item:
	var item := ItemScene.instantiate()
	item.set_script(item_script)
	item.resource = item_script.get_item_resource(item_id)
	var res := item.resource as ItemResource
	return item
