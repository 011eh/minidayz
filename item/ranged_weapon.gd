extends DurabilityItem

class_name RangedWeapon


var spread: int
var round: NumberItem


func _ready():
	hframes = SPRITE_HFRAMES
	texture = resource.texture

func is_equipment() -> bool:
	return true

func get_resource() -> RangedWeaponResource:
	return resource

func get_round_count() -> int:
	return round.number if is_instance_valid(round) else 0

func reload(ammo: NumberItem) -> void:
	var number_can_reload := min(ammo.number, get_resource().mag_size - get_round_count()) as int
	if is_instance_valid(round):
		round.number += number_can_reload
	else:
		round = ammo.duplicate()
		round.number = number_can_reload
	ammo.number -= number_can_reload

func eject() -> NumberItem:
	var ammo = round
	round = null
	return ammo
