extends Control

class_name ItemIcon


const NUMBER_FORMAT = '%d'
const ATLAS_REGION := Rect2(0, 320, 32, 32)

@onready
var icon := $Icon
@onready
var number_or_durability := $ColorRect/NumberOrDurability
@export
var atlas_texture:= preload('res://asset/images/item/gui_slot_item.png')
@export
var atlas_texture_id_offset := 0
@export
var column_number := 5
@export
var icon_size := Vector2(32, 32)

func _ready():
	var atlas := AtlasTexture.new()
	icon.texture = atlas
	atlas.atlas = atlas_texture

var update_general_ui = func update_item_ui(item: Item, offset: int = 0) -> void:
	var index := item.resource.id + offset
	icon.texture.region = Rect2(
		(index + atlas_texture_id_offset) % column_number * icon_size.x,
		(index + atlas_texture_id_offset) / column_number * icon_size.y,
		icon_size.x,
		icon_size.y)

	var label_text: String
	if item is NumberItem:
		label_text = NUMBER_FORMAT % item.number
	else:
		label_text = (NUMBER_FORMAT + '%%') % item.durability
	number_or_durability.text = label_text
	if item is RangedWeapon:
		$ColorRect/BulletNumber.text = NUMBER_FORMAT % item.get_bullet_number()

var update_helmet_ui = func update_item_ui(gear: Gear) -> void:
	icon.texture.atlas = gear.get_resource().texture
	icon.texture.region = ATLAS_REGION
	number_or_durability.text = (NUMBER_FORMAT + '%%') % gear.durability


func update_item_ui(item: Item) -> void:
	if not is_instance_valid(item):
		visible = false
		return
	
	if item is Gear and item.get_resource().type == GearResource.GearType.HELMET:
		update_helmet_ui.call(item)
	elif item is Knife:
		update_general_ui.call(item, 84)
	else:
		update_general_ui.call(item)
