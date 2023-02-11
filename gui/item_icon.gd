extends Control

class_name ItemIcon


const NUMBER_FORMAT = '%d'


@export
var atlas_texture:= preload('res://asset/images/item/gui_slot_item.png')
@export
var column_number := 5
@export
var icon_size := Vector2(32, 32)


func update_item_ui(item: Item):
	var atlas := AtlasTexture.new()
	$Icon.texture = atlas
	var id := item.resource.id
	atlas.atlas = atlas_texture
	atlas.region = Rect2(
		id % column_number * icon_size.x,
		id / column_number * icon_size.y,
		icon_size.x,
		icon_size.y)
	
	var label_text: String
	if item is NumberItem:
		label_text = NUMBER_FORMAT % item.number
	else:
		label_text = (NUMBER_FORMAT + '%%') % item.durability
	$ColorRect/NumberOrDuability.text = label_text
	
	if item is RangedWeapon:
		$ColorRect/BulletNumber.text = NUMBER_FORMAT % item.get_bullet_number()
