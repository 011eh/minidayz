extends TextureRect


func _ready():
	$Cards/ClothesCard.update_gear_ui(ItemCreator.create_item(Gear, 6))
	$Cards/PantsCard.update_gear_ui(ItemCreator.create_item(Gear, 6))
	$Cards/VestCard.update_gear_ui(ItemCreator.create_item(Gear, 6))
	$Cards/BackpackCard.update_gear_ui(ItemCreator.create_item(Gear, 55))
	$Cards/MainWeaponCard/MainWeaponIcon.update_item_ui(ItemCreator.create_item(MainWeapon, 0))
	var type := 2
	match type:
		PlayerInventory.CLOTHES:
			pass
		PlayerInventory.PANTS:
			pass
		PlayerInventory.VEST:
			pass
		PlayerInventory.BACKPACK:
			pass
