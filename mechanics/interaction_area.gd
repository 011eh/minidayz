extends Area2D

class_name InteractionArea


signal interaction_inputted


enum OwnerType {
	ITEM,
	OTHER
}


@export
var owner_type := OwnerType.OTHER
