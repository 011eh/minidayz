extends TextureRect


@onready
var clothes_card := $Cards/ClothesCard
@onready
var pants_card := $Cards/PantsCard
@onready
var vest_card := $Cards/VestCard
@onready
var backpack_card := $Cards/BackpackCard
@onready
var helmet_card_content := $Cards/HelmetCard/HelmetContent
@onready
var main_wepaon_content := $Cards/MainWeaponCard/MainWeaponContent
@onready
var melee_weapon_content := $Cards/MeleeWeaponCard/MeleeWeaponContent

func _ready():
	helmet_card_content.update_item_ui(ItemCreator.create_item(Gear, 35))
	var type := 2
	match type:
		PlayerInventory.CLOTHES:
			pass
		PlayerInventory.PANTS:
			pass
		PlayerInventory.HELMET:
			pass
		PlayerInventory.VEST:
			pass
		PlayerInventory.BACKPACK:
			pass
		PlayerInventory.MAIN_WEAPON:
			pass
		PlayerInventory.MELEE_WEAPON:
			pass
