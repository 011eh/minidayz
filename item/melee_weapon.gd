extends DurabilityItem

class_name MeleeWeapon


const RES_TABLE := {
	0: preload('res://item/res/melee_weapon/hatchet.tres'),
	1: preload('res://item/res/melee_weapon/baseball_bat.tres'),
	2: preload('res://item/res/melee_weapon/crowbar.tres'),
	3: preload('res://item/res/melee_weapon/fire_axe.tres'),
	5: preload('res://item/res/melee_weapon/pickaxe.tres'),
	6: preload('res://item/res/melee_weapon/pipe_wrench.tres'),
	7: preload('res://item/res/melee_weapon/pitchfork.tres'),
	8: preload('res://item/res/melee_weapon/shovel.tres'),
	9: preload('res://item/res/melee_weapon/sledgehammer.tres'),
	10: preload('res://item/res/melee_weapon/sword.tres'),
}


func _ready():
	hframes = SPRITE_HFRAMES
	vframes = MELEE_WEAPON_VFRAMES
	frame = SPRITE_INIT_FRAME
	texture = resource.texture

func is_equipment() -> bool:
	return true

static func get_item_resource(id: int) -> MeleeWeaponResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)
