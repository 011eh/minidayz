extends ItemResource

class_name GearResource

enum GearType {
	CLOTHES,
	PANTS,
	HELMET,
	VEST,
	BACKPACK
}

@export
var type: GearType
@export
var slot_number: int
@export
var heat: float
@export
var armor: float
