extends Control

class_name ItemUI


enum ItemUiType {SLOT_ITEM_UI, INVENTORY_CARD_UI}


const NUMBER_FORMAT = '%d'
const ATLAS_REGION := Rect2(0, 320, 32, 32)


var has_data := true
var item_instance_id: int
@export
var atlas_texture:= preload('res://asset/images/item/gui_slot_item.png')
@export
var atlas_texture_id_offset := 0
@export
var column_number := 5
@export
var icon_size := Vector2(32, 32)
@export
var can_drop_item_list: Array[GDScript] = [NumberItem, Craft, Knife]
@export
var item_ui_type := ItemUiType.SLOT_ITEM_UI
@onready
var icon := $Icon
@onready
var number_or_durability := $ColorRect/NumberOrDurability


func _ready():
	var atlas := AtlasTexture.new()
	icon.texture = atlas
	atlas.atlas = atlas_texture

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
		$ColorRect/BulletNumber.text = NUMBER_FORMAT % item.get_bullet_number()

var update_helmet_ui = func(gear: Gear) -> void:
	icon.texture.atlas = gear.get_resource().texture
	icon.texture.region = ATLAS_REGION
	number_or_durability.text = (NUMBER_FORMAT + '%%') % gear.durability

var change_slot_item_ui_visible = func(visible: bool):
		icon.visible = visible
		$ColorRect.visible = visible

var change_inv_item_ui_visible = func(visible: bool):
	get_parent().visible = visible


func update_item_ui(item: Item) -> void:
	item_instance_id = item.get_instance_id() if is_instance_valid(item) else 0
	if not is_instance_valid(item):
		change_ui_visible(false)
		return
	if item is Gear and item.get_resource().type == GearResource.GearType.HELMET:
		update_helmet_ui.call(item)
	elif item is Knife:
		update_general_ui.call(item, 84)
	else:
		update_general_ui.call(item)
	change_ui_visible(true)

func _get_drag_data(at_position):
	if has_data:
		var rect := TextureRect.new()
		rect.texture = icon.texture
		set_drag_preview(rect)
		return self

func _can_drop_data(at_position, data):
	var item := instance_from_id(data.item_instance_id)
	return instance_from_id(data.item_instance_id).get_script() in can_drop_item_list and (item is Gear and item.type)

func _drop_data(at_position, data):
	var drop_item_id := data.item_instance_id as int
	if data.item_instance_id != 0:
		data.update_item_ui(instance_from_id(item_instance_id))
		update_item_ui(instance_from_id(drop_item_id))

func change_ui_visible(visible: bool) -> void:
	has_data = visible
	if item_ui_type == ItemUiType.SLOT_ITEM_UI:
		change_slot_item_ui_visible.call(visible)
	else:
		change_inv_item_ui_visible.call(visible)
