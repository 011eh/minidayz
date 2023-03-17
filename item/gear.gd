extends DurabilityItem

class_name Gear

const RES_TABLE := {
	95: preload('res://item/res/gear/cloak_brown.tres'),
	96: preload('res://item/res/gear/down_jacket.tres'),
	97: preload('res://item/res/gear/dress.tres'),
	98: preload('res://item/res/gear/gorka_jacket.tres'),
	99: preload('res://item/res/gear/hoodie_gray.tres'),
	100: preload('res://item/res/gear/hoodie_red.tres'),
	101: preload('res://item/res/gear/hunter_jacket.tres'),
	102: preload('res://item/res/gear/jacket.tres'),
	103: preload('res://item/res/gear/orel_jacket.tres'),
	104: preload('res://item/res/gear/paramedic_jacket.tres'),
	105: preload('res://item/res/gear/raider_jacket.tres'),
	106: preload('res://item/res/gear/raincoat_blue.tres'),
	107: preload('res://item/res/gear/shirt_gray.tres'),
	108: preload('res://item/res/gear/shirt_green.tres'),
	109: preload('res://item/res/gear/sweater.tres'),
	110: preload('res://item/res/gear/tracksuit_jacket.tres'),
	111: preload('res://item/res/gear/tshirt.tres'),
	
	112: preload('res://item/res/gear/gorka_pants.tres'),
	113: preload('res://item/res/gear/hunter_pants.tres'),
	114: preload('res://item/res/gear/jeans.tres'),
	115: preload('res://item/res/gear/orel_pants.tres'),
	116: preload('res://item/res/gear/paramedic_pants.tres'),
	117: preload('res://item/res/gear/tracksuit_pants.tres'),
	118: preload('res://item/res/gear/worker_pants.tres'),
	
	119: preload('res://item/res/gear/army_helmet.tres'),
	120: preload('res://item/res/gear/balaklava.tres'),
	121: preload('res://item/res/gear/bandana.tres'),
	122: preload('res://item/res/gear/baseball_cap.tres'),
	123: preload('res://item/res/gear/beret.tres'),
	124: preload('res://item/res/gear/cowboy_hat.tres'),
	125: preload('res://item/res/gear/crusader_helmet.tres'),
	126: preload('res://item/res/gear/gasmask.tres'),
	127: preload('res://item/res/gear/gorka_helmet.tres'),
	128: preload('res://item/res/gear/hard_helmet.tres'),
	129: preload('res://item/res/gear/headlamp.tres'),
	130: preload('res://item/res/gear/moto_helmet.tres'),
	131: preload('res://item/res/gear/moto_helmet_red.tres'),
	132: preload('res://item/res/gear/nvg.tres'),
	133: preload('res://item/res/gear/police_hat.tres'),
	134: preload('res://item/res/gear/ushanka.tres'),
	135: preload('res://item/res/gear/warm_hat.tres'),
	136: preload('res://item/res/gear/welding_mask.tres'),
	
	137: preload('res://item/res/gear/assault_vest.tres'),
	138: preload('res://item/res/gear/bulletproof_vest.tres'),
	139: preload('res://item/res/gear/high_capacity_vest.tres'),
	140: preload('res://item/res/gear/kevlar_vest.tres'),
	141: preload('res://item/res/gear/press_vest.tres'),
	142: preload('res://item/res/gear/soviet_vest.tres'),
	
	143: preload('res://item/res/gear/bag.tres'),
	144: preload('res://item/res/gear/civilian_tent.tres'),
	145: preload('res://item/res/gear/hunter_backpack.tres'),
	146: preload('res://item/res/gear/improvised_bag.tres'),
	147: preload('res://item/res/gear/mountain_backpack.tres'),
	148: preload('res://item/res/gear/school_backpack.tres'),
	149: preload('res://item/res/gear/taloon_backpack.tres'),
	150: preload('res://item/res/gear/tortilla_backpack.tres'),
}
const GEAR_VFRAMES = 11


var slots: Array[Item]


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = GEAR_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

func add_to_slot(item: Item) -> void:
	var index := slots.find(null)
	if index != -1:
		slots[index] = item

func has_empty_slot() -> bool:
	return slots.find(null) != -1

func is_equipment() -> bool:
	return true

func get_resource() -> GearResource:
	return resource

func set_resource(resource: ItemResource) -> void:
	super.set_resource(resource)
	slots.resize(resource.slot_number)

static func get_item_resource(id: int) -> GearResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)

static func create_player_slot() -> Gear:
	var res := GearResource.new()
	res.slot_number = 1
	var gear := Gear.new() as Gear
	gear.resource = res
	gear.durability = 100
	return gear
