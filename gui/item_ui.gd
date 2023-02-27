extends 'res://gui/inventory_card.gd'

class_name ItemUI


signal item_ui_dropped


const NUMBER_FORMAT = '%d'
const ATLAS_REGION := Rect2(0, 320, 32, 32)


var item_id: int
var has_data := true
var item_owner: GearUI
@export
var atlas_texture:= preload('res://asset/images/item/gui_slot_item.png')
@export
var atlas_texture_id_offset := 0
@export
var column_number := 5
@export
var icon_size := Vector2(32, 32)
@export
var can_drop_item_list:Array[GDScript] = [NumberItem, Craft, Knife]
@onready
var icon := $Icon
@onready
var number_or_durability := $Info/NumberOrDurability


var update_general_ui = func(item: Item, offset: int = 0) -> void:
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
		$Info/BulletNumber.text = NUMBER_FORMAT % item.get_bullet_number()


func _ready():
	var atlas := AtlasTexture.new()
	icon.texture = atlas
	atlas.atlas = atlas_texture

func update_item_ui(item: Item) -> void:
	var valid := is_instance_valid(item)
	item_id = item.get_instance_id() if valid else 0
	if not valid:
		change_ui_visible(false)
		return
	if item is Knife:
		update_general_ui.call(item, 84)
	else:
		update_general_ui.call(item)
	change_ui_visible(true)

func change_ui_visible(visible: bool) -> void:
	has_data = visible
	icon.visible = visible
	$Info.visible = visible

func _get_drag_data(at_position):
	if has_data:
		var rect := TextureRect.new()
		rect.texture = icon.texture
		set_drag_preview(rect)
		icon.visible = false
		$Info.visible = false
		return self

func _can_drop_data(at_position, data):
	var id := data.item_id as int
	return is_instance_id_valid(id)\
		and instance_from_id(id).get_script() in can_drop_item_list

func _drop_data(at_position, drop_ui):
	var temp := instance_from_id(item_id) as Item
	sync_to_slot(instance_from_id(drop_ui.item_id))
	drop_ui.sync_to_slot(temp)

func sync_to_slot(item: Item) -> void:
	item_owner.gear.slots[get_index()] = item
	update_item_ui(item)
