extends Sprite2D

class_name Item


const SOLT_ITEM_RES_TABLE := {
	0: preload('res://item/res/slot_item/ammo_5x45.tres'),
	1: preload('res://item/res/slot_item/ammo_5x56.tres'),
	13: preload('res://item/res/state_item/edrink.tres'),
	44: preload('res://item/res/state_item/mre_1.tres'),
	72: preload('res://item/res/craft/pepper_seeds_pack.tres'),
}


var resource: ItemResource


func _ready():
	texture = resource.texture
