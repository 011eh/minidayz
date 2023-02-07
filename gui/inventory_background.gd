extends TextureRect


func _ready():
	$Cards/ClothesCard.update(ItemCreator.create_item(Gear, 6))
	$Cards/PantsCard.update(ItemCreator.create_item(Gear, 6))
	$Cards/VestCard.update(ItemCreator.create_item(Gear, 6))
	$Cards/BackpackCard.update(ItemCreator.create_item(Gear, 55))
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
