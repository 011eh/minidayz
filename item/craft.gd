extends 'durability_item.gd'

class_name Craft


const RES_TABLE := {
	85: preload('res://item/res/craft/battery.tres'),
	86: preload('res://item/res/craft/tomato_seeds_pack.tres'),
	87: preload('res://item/res/craft/pepper_seeds_pack.tres'),
	88: preload('res://item/res/craft/zucchini_seeds_pack.tres'),
	89: preload('res://item/res/craft/radio.tres'),
	90: preload('res://item/res/craft/hacksaw.tres'),
	91: preload('res://item/res/craft/cleaning_kit.tres'),
	92: preload('res://item/res/craft/sewing_kit.tres'),
	93: preload('res://item/res/craft/basic_fishing_rod.tres'),
	94: preload('res://item/res/craft/spinning_fishing_rod.tres'),
}


static func create_item(id: int) -> Craft:
	assert_id_exists(id, RES_TABLE)
	var item := Craft.new()
	item.resource = RES_TABLE.get(id) as CraftResource
	return item
