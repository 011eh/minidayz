extends ItemUI

class_name ItemCardUI


func update_item_ui(item: Item) -> void:
	var valid := is_instance_valid(item)
	item_id = item.get_instance_id() if valid else 0
	if not valid:
		change_ui_visible(false)
		return
	if item is Gear and item.resource.type == GearResource.GearType.HELMET:
		update_helmet_ui(item)
	else:
		update_general_ui(item)
	change_ui_visible(true)

func update_helmet_ui(gear: Gear) -> void:
	icon.texture.atlas = gear.get_resource().texture
	icon.texture.region = ATLAS_REGION
	number_or_durability.text = (NUMBER_FORMAT + '%%') % gear.durability

func change_ui_visible(visible: bool) -> void:
	has_data = visible
	self.visible = visible

func _can_drop_data(at_position, data):
	return false
