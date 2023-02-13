extends Control

class_name ItemIcon


const NUMBER_FORMAT = '%d'


@onready
var icon := $Icon
@export
var atlas_texture:= preload('res://asset/images/item/gui_slot_item.png')
@export
var atlas_texture_id_offset := 0
@export
var column_number := 5
@export
var icon_size := Vector2(32, 32)

var general_update_ui = func update_item_ui(item: Item) -> void:
	var atlas := AtlasTexture.new()
	$Icon.texture = atlas
	var id := item.resource.id
	atlas.atlas = atlas_texture
	atlas.region = Rect2(
		(id + atlas_texture_id_offset) % column_number * icon_size.x,
		(id + atlas_texture_id_offset) / column_number * icon_size.y,
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

var update_helmet_ui = func update_item_ui(gear: Gear) -> void:
	icon.texture.atlas = gear.get_resource().texture

func update_item_ui(item: Item) -> void:
	if item is Gear and item.get_resource().type == GearResource.GearType.HELMET:
		update_helmet_ui.call(item)
	else:
		general_update_ui.call(item)
