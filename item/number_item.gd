extends SlotItem

class_name NumberItem


const RES_TABLE := {
	0: preload('res://item/res/number_item/5.45x39_ammo.tres'),
	1: preload('res://item/res/number_item/5.56x45_ammo.tres'),
	2: preload('res://item/res/number_item/7.62_ammo.tres'),
	3: preload('res://item/res/number_item/7.62x39_ammo.tres'),
	4: preload('res://item/res/number_item/9mm_ammo.tres'),
	5: preload('res://item/res/number_item/9x18_ammo.tres'),
	6: preload('res://item/res/number_item/9x39_ammo.tres'),
	7: preload('res://item/res/number_item/12cal_ammo.tres'),
	8: preload('res://item/res/number_item/.22lr_ammo.tres'),
	9: preload('res://item/res/number_item/.45_acp_ammo.tres'),
	10: preload('res://item/res/number_item/.357_ammo.tres'),
	11: preload('res://item/res/number_item/crafted_arrow.tres'),
	12: preload('res://item/res/number_item/composite_arrow.tres'),
	13: preload('res://item/res/number_item/ashwood_stick.tres'),
	14: preload('res://item/res/number_item/wood_sticks.tres'),
	15: preload('res://item/res/number_item/wood_piles.tres'),
	16: preload('res://item/res/number_item/campfire_kit.tres'),
	17: preload('res://item/res/number_item/rope.tres'),
	18: preload('res://item/res/number_item/papers.tres'),
	19: preload('res://item/res/number_item/burlap_sack.tres'),
	20: preload('res://item/res/number_item/matches.tres'),
	21: preload('res://item/res/number_item/protective_case.tres'),
	22: preload('res://item/res/number_item/rag.tres'),
	23: preload('res://item/res/number_item/bandage.tres'),
	24: preload('res://item/res/number_item/vitamins.tres'),
	25: preload('res://item/res/number_item/tetracycline.tres'),
	26: preload('res://item/res/number_item/morphine.tres'),
	27: preload('res://item/res/number_item/flare.tres'),
	28: preload('res://item/res/number_item/f1_grenade.tres'),
	29: preload('res://item/res/number_item/molotov.tres'),
	30: preload('res://item/res/number_item/duct_tape.tres'),
	31: preload('res://item/res/number_item/gasoline.tres'),
	32: preload('res://item/res/number_item/car_toolbox.tres'),
	33: preload('res://item/res/number_item/bandolier.tres'),
	34: preload('res://item/res/number_item/magpul.tres'),
	35: preload('res://item/res/number_item/choke.tres'),
	36: preload('res://item/res/number_item/acog_scope.tres'),
	37: preload('res://item/res/number_item/long_range_scope.tres'),
	38: preload('res://item/res/number_item/pso-1_scope.tres'),
	39: preload('res://item/res/number_item/pu_scope.tres'),
	40: preload('res://item/res/number_item/rds_scope.tres'),
	41: preload('res://item/res/number_item/silencer_5.45.tres'),
	42: preload('res://item/res/number_item/silencer_5.56.tres'),
	43: preload('res://item/res/number_item/barbed_wire.tres'),
	44: preload('res://item/res/number_item/bear_trap.tres'),
	45: preload('res://item/res/number_item/landmine.tres'),
	46: preload('res://item/res/number_item/claymore.tres'),

	47: preload('res://item/res/status_item/energy_drink.tres'),
	48: preload('res://item/res/status_item/kvas.tres'),
	49: preload('res://item/res/status_item/nota_cola.tres'),
	50: preload('res://item/res/status_item/nuko_cola.tres'),
	51: preload('res://item/res/status_item/pipsi.tres'),
	52: preload('res://item/res/status_item/spite.tres'),
	53: preload('res://item/res/status_item/whiskey.tres'),
	54: preload('res://item/res/status_item/canned_bean.tres'),
	55: preload('res://item/res/status_item/canned_tuna.tres'),
	56: preload('res://item/res/status_item/rice.tres'),
	57: preload('res://item/res/status_item/tactical_bacon.tres'),
	58: preload('res://item/res/status_item/apple.tres'),
	59: preload('res://item/res/status_item/banana.tres'),
	60: preload('res://item/res/status_item/orange.tres'),
	61: preload('res://item/res/status_item/bell_pepper.tres'),
	62: preload('res://item/res/status_item/zucchini.tres'),
	63: preload('res://item/res/status_item/tomato.tres'),
	64: preload('res://item/res/status_item/bilberry.tres'),
	65: preload('res://item/res/status_item/cranberry.tres'),
	66: preload('res://item/res/status_item/cloudberry.tres'),
	67: preload('res://item/res/status_item/mushroom.tres'),
	68: preload('res://item/res/status_item/rabbit_meat.tres'),
	69: preload('res://item/res/status_item/cooked_rabbit_meat.tres'),
	70: preload('res://item/res/status_item/raw_steak.tres'),
	71: preload('res://item/res/status_item/cooked_steak.tres'),
	72: preload('res://item/res/status_item/herring.tres'),
	73: preload('res://item/res/status_item/perch.tres'),
	74: preload('res://item/res/status_item/ruffe.tres'),
	75: preload('res://item/res/status_item/salmon.tres'),
	76: preload('res://item/res/status_item/small_fish_fillet.tres'),
	77: preload('res://item/res/status_item/big_fish_fillet.tres'),
	78: preload('res://item/res/status_item/mre_ration_1.tres'),
	79: preload('res://item/res/status_item/mre_ration_2.tres'),
	80: preload('res://item/res/status_item/saline_bag.tres'),
	81: preload('res://item/res/status_item/blood_bag.tres'),
	82: preload('res://item/res/status_item/water_bottle.tres'),
	83: preload('res://item/res/status_item/canteen.tres'),
	84: preload('res://item/res/status_item/heat_pack.tres'),
}


var number := 1: set = set_number


func get_resource() -> NumberItemResource:
	return resource

func set_number(n: int) -> void:
		number = n
		if n == 0:
			queue_free()

static func get_item_resource(id: int) -> ItemResource:
	assert_id_exists(id, RES_TABLE)
	return RES_TABLE.get(id)
