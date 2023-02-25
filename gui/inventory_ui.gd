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
var pistol_content := $Cards/PistolCard/PistolContent
@onready
var melee_weapon_content := $Cards/MeleeWeaponCard/MeleeWeaponContent
@onready
var player_slot := $Cards/PlayerSlot


func _unhandled_input(event):
	if event.is_action_pressed('open_inventory'):
		visible = not visible

func update_inventory_ui(equipment_type: int, item: Item) -> void:
	match equipment_type:
		PlayerInventory.EQUIPMENT_TYPE.PLAYER_SLOT:
			player_slot.update_item_ui(item.slots[0])
		PlayerInventory.EQUIPMENT_TYPE.CLOTHES:
			clothes_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.PANTS:
			pants_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.VEST:
			vest_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.BACKPACK:
			backpack_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.HELMET:
			helmet_card_content.update_item_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.MAIN_WEAPON:
			main_wepaon_content.update_item_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.PISTOL:
			pistol_content.update_item_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.MELEE_WEAPON:
			melee_weapon_content.update_item_ui(item)
