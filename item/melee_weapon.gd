extends DurabilityItem

class_name MeleeWeapon


const RES_TABLE = {
	151: preload('res://item/res/melee_weapon/hatchet.tres'),
	152: preload('res://item/res/melee_weapon/baseball_bat.tres'),
	153: preload('res://item/res/melee_weapon/crowbar.tres'),
	154: preload('res://item/res/melee_weapon/fire_axe.tres'),
	156: preload('res://item/res/melee_weapon/pickaxe.tres'),
	157: preload('res://item/res/melee_weapon/pipe_wrench.tres'),
	158: preload('res://item/res/melee_weapon/pitchfork.tres'),
	159: preload('res://item/res/melee_weapon/shovel.tres'),
	160: preload('res://item/res/melee_weapon/sledgehammer.tres'),
	161: preload('res://item/res/melee_weapon/sword.tres'),
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
