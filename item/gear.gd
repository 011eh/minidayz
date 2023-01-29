extends 'durability_item.gd'

class_name Gear

const RES_TABLE := {
	0: preload('res://item/res/gear/cloak_brown.tres'),
	1: preload('res://item/res/gear/down_jacket.tres'),
	2: preload('res://item/res/gear/dress.tres'),
	3: preload('res://item/res/gear/gorka_jacket.tres'),
	4: preload('res://item/res/gear/hoodie_gray.tres'),
	5: preload('res://item/res/gear/hoodie_red.tres'),
	6: preload('res://item/res/gear/hunter_jacket.tres'),
	7: preload('res://item/res/gear/jacket.tres'),
	8: preload('res://item/res/gear/orel_jacket.tres'),
	9: preload('res://item/res/gear/paramedic_jacket.tres'),
	10: preload('res://item/res/gear/raider_jacket.tres'),
	11: preload('res://item/res/gear/raincoat_blue.tres'),
	12: preload('res://item/res/gear/shirt_gray.tres'),
	13: preload('res://item/res/gear/shirt_green.tres'),
	14: preload('res://item/res/gear/sweater.tres'),
	15: preload('res://item/res/gear/tracksuit_jacket.tres'),
	16: preload('res://item/res/gear/tshirt.tres'),

	17: preload('res://item/res/gear/gorka_pants.tres'),
	18: preload('res://item/res/gear/hunter_pants.tres'),
	19: preload('res://item/res/gear/jeans.tres'),
	20: preload('res://item/res/gear/orel_pants.tres'),
	21: preload('res://item/res/gear/paramedic_pants.tres'),
	22: preload('res://item/res/gear/tracksuit_pants.tres'),
	23: preload('res://item/res/gear/worker_pants.tres'),

	24: preload('res://item/res/gear/army_helmet.tres'),
	25: preload('res://item/res/gear/balaklava.tres'),
	26: preload('res://item/res/gear/bandana.tres'),
	27: preload('res://item/res/gear/baseball_cap.tres'),
	28: preload('res://item/res/gear/beret.tres'),
	29: preload('res://item/res/gear/cowboy_hat.tres'),
	30: preload('res://item/res/gear/crusader_helmet.tres'),
	31: preload('res://item/res/gear/gasmask.tres'),
	32: preload('res://item/res/gear/gorka_helmet.tres'),
	33: preload('res://item/res/gear/hard_helmet.tres'),
	34: preload('res://item/res/gear/headlamp.tres'),
	35: preload('res://item/res/gear/moto_helmet.tres'),
	36: preload('res://item/res/gear/moto_helmet_red.tres'),
	37: preload('res://item/res/gear/nvg.tres'),
	38: preload('res://item/res/gear/police_hat.tres'),
	39: preload('res://item/res/gear/ushanka.tres'),
	40: preload('res://item/res/gear/warm_hat.tres'),
	41: preload('res://item/res/gear/welding_mask.tres'),

	42: preload('res://item/res/gear/assault_vest.tres'),
	43: preload('res://item/res/gear/bulletproof_vest.tres'),
	44: preload('res://item/res/gear/high_capacity_vest.tres'),
	45: preload('res://item/res/gear/kevlar_vest.tres'),
	46: preload('res://item/res/gear/press_vest.tres'),
	47: preload('res://item/res/gear/soviet_vest.tres'),

	48: preload('res://item/res/gear/bag.tres'),
	49: preload('res://item/res/gear/civilian_tent.tres'),
	50: preload('res://item/res/gear/hunter_backpack.tres'),
	51: preload('res://item/res/gear/improvised_bag.tres'),
	52: preload('res://item/res/gear/mountain_backpack.tres'),
	53: preload('res://item/res/gear/school_backpack.tres'),
	54: preload('res://item/res/gear/taloon_backpack.tres'),
	55: preload('res://item/res/gear/tortilla_backpack.tres'),
}
const GEAR_VFRAMES = 11

var slots: Array[Item]


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = GEAR_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

func add_to_slot(item: NumberItem) -> bool:
	var item_in_slot := get_item_to_stack(item.get_item_id()) as NumberItem
	if is_instance_valid(item_in_slot):
		var capacity := item_in_slot.resource.stack_limit - item_in_slot.number as int
		if capacity >= item.number:
			item_in_slot.number += item.number
			# todo，释放对应的 Item 实例
		else:
			item_in_slot.number += capacity
			item.number -= capacity
			return false
	else:
		slots.append(item)
	return true

func get_item_to_stack(item_id: int) -> Item:
	var stackable_item_in_slot := func (item_in_slot) -> bool:
		var res := item_in_slot.resource as SlotItemResource
		return item_id == res.id and res.stackable and item_in_slot.number < res.stack_limit
	return slots.filter(stackable_item_in_slot).front()

func has_empty_slot() -> bool:
	return resource.slot_number > 0 and slots.size() < resource.slot_number

func is_equipment() -> bool:
	return true

static func get_item_resource(id: int) -> GearResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)

static func create_character_slot() -> Gear:
	var res := GearResource.new()
	res.slot_number = 1
	var gear := Gear.new() as Gear
	gear.resource = res
	gear.durability = 100
	return gear
