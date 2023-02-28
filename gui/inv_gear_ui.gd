extends 'res://gui/inventory_card.gd'

class_name GearUI


const SLOT_TEXTURE := preload('res://asset/images/gui/inventory/gui_inv_slot_shadow.png')
const GEAR_ICON_REGION := Rect2(0, 320, 32, 32)
const DURABILITY_LABEL_OFFSET := 8
const ItemUISence := preload('res://gui/item_ui.tscn')


var atlas := AtlasTexture.new()
var gear: Gear
@export_range(1, 7)
var max_slot_number: int
@onready
var slots := $Slots


func _ready():
	for i in range(max_slot_number):
		var slot := TextureRect.new()
		slot.texture = SLOT_TEXTURE
		slot.visible = false
		slots.add_child(slot)
		var item_ui := ItemUISence.instantiate() as ItemUI
		item_ui.item_owner = self
		item_ui.visible = false
		item_ui.add_to_group('item_ui_group')
		item_ui.equipment_type = equipment_type
		$Items.add_child(item_ui)

func update_gear_ui(gear: Gear) -> void:
	self.gear = gear
	if not is_instance_valid(gear):
		visible = false
		return

	var resource := gear.resource as GearResource
	atlas.atlas = resource.texture
	atlas.region = GEAR_ICON_REGION
	$Icon.texture = atlas
	var name := $Name
	var durability := $Durability
	name.text = resource.item_name
	durability.text = '%.0f%%' % gear.durability
	if name.get_line_count() > 1:
		durability.offset_top += DURABILITY_LABEL_OFFSET

	for i in range(max_slot_number):
		var slot := $Slots.get_child(i)
		var item_ui := $Items.get_child(i)
		if i < resource.slot_number:
			slot.visible = true
			item_ui.visible = true
			var item := gear.slots[i] as Item
			item_ui.update_item_ui(gear.slots[i])
		else:
			item_ui.visible = false
			slot.visible = false
	visible = true
