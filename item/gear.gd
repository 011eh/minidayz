extends 'durability_item.gd'

class_name Gear


const GEAR_VFRAMES = 11
const GENAR_RES_TABLE := {
}

func _ready():
	hframes = SPRITE_HFRAMES
	vframes = GEAR_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

static func create_item(id: int) -> Gear:
	var gear := Gear.new()
	gear.resource = GENAR_RES_TABLE.get(id)
	return gear
