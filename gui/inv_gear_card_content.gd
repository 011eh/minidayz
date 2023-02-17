extends TextureRect


const ItemIcon := preload('res://gui/item_ui_content.tscn')
const SlotTexture := preload('res://asset/images/gui/inventory/gui_inv_slot_shadow.png')
const ItemUIContent := preload('res://gui/item_ui_content.tscn')
const GEAR_ICON_REGION := Rect2(0, 320, 32, 32)
const DURABILITY_LABEL_OFFSET := 8

@export_range(1, 7)
var max_slot_number: int
@onready
var slots := $Slots

func _ready():
	for i in range(max_slot_number):
		var slot := TextureRect.new()
		slot.texture = SlotTexture
		slot.visible = false
		slots.add_child(slot)
		var item_ui := ItemUIContent.instantiate()
		item_ui.visible = false
		$Items.add_child(item_ui)

func update_gear_ui(gear: Gear) -> void:
	var resource := gear.resource as GearResource
	var atlas := AtlasTexture.new()
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
			var item := gear.slots[i] as Item
			if is_instance_valid(item):
				item_ui.update_item_ui(gear.slots[i])
				item_ui.visible = true
		else:
			item_ui.visible = false
			slot.visible = false
