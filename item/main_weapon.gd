extends 'ranged_weapon.gd'

class_name MainWeapon


const MAIN_WEAPON_VFRAMES = 16
const RES_TABLE := {
	0: preload('res://item/res/ranged_weapon/ak-74.tres'),
	1: preload('res://item/res/ranged_weapon/akm.tres'),
	2: preload('res://item/res/ranged_weapon/aks74u.tres'),
	3: preload('res://item/res/ranged_weapon/aug.tres'),
	4: preload('res://item/res/ranged_weapon/bizon.tres'),
	5: preload('res://item/res/ranged_weapon/izh-43.tres'),
	6: preload('res://item/res/ranged_weapon/crossbow.tres'),
	7: preload('res://item/res/ranged_weapon/fn_cal.tres'),
	8: preload('res://item/res/ranged_weapon/groza.tres'),
	9: preload('res://item/res/ranged_weapon/improvised_bow.tres'),
	10: preload('res://item/res/ranged_weapon/l85.tres'),
	11: preload('res://item/res/ranged_weapon/m4_carbine.tres'),
	12: preload('res://item/res/ranged_weapon/madsen.tres'),
	13: preload('res://item/res/ranged_weapon/mosin.tres'),
	14: preload('res://item/res/ranged_weapon/mp5k.tres'),
	15: preload('res://item/res/ranged_weapon/remington_870.tres'),
	16: preload('res://item/res/ranged_weapon/repeater.tres'),
	17: preload('res://item/res/ranged_weapon/rpk.tres'),
	18: preload('res://item/res/ranged_weapon/saiga-12.tres'),
	19: preload('res://item/res/ranged_weapon/sks.tres'),
	20: preload('res://item/res/ranged_weapon/sporter_22.tres'),
	21: preload('res://item/res/ranged_weapon/sv-98.tres'),
	22: preload('res://item/res/ranged_weapon/svd.tres'),
	23: preload('res://item/res/ranged_weapon/ump-45.tres'),
	24: preload('res://item/res/ranged_weapon/vss.tres'),
}


func _ready():
	super._ready()
	vframes = MAIN_WEAPON_VFRAMES
	frame = SPRITE_INIT_FRAME

static func create_item(id: int) -> MainWeapon:
	assert_id_exists(id, RES_TABLE)
	var weapon := MainWeapon.new()
	weapon.resource = RES_TABLE.get(id) as RangedWeaponResource
	return weapon
