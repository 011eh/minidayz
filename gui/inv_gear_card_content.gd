extends TextureRect


const ItemIcon := preload('res://gui/item_ui_content.tscn')
const SlotTexture := preload('res://asset/images/gui/inventory/gui_inv_slot_shadow.png')
const GEAR_ICON_REGION := Rect2(0, 320, 32, 32)
const DURABILITY_LABEL_OFFSET := 8


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
	for i in range(resource.slot_number):
		var icon := TextureRect.new()
		icon.texture = SlotTexture
		$Slots.add_child(icon)
	visible = true
