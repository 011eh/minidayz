extends TextureRect


func _ready():
	var type := 1
	match type:
		PlayerInventory.CLOTHES:
			$Cards/ClothesCard.update(ItemCreator.create_item(Gear, 6))
			pass
		PlayerInventory.PANTS:
			pass
		PlayerInventory.VEST:
			pass
		PlayerInventory.BACKPACK:
			pass
