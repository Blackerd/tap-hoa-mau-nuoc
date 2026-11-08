class_name FurnitureData
extends Resource

@export var id: String = "wooden_shelf"
@export var display_name: String = "Kệ Gỗ Tạp Hóa"
@export var cost: int = 8000
@export var max_capacity: int = 12
@export var unlock_level: int = 1
@export var tint_color: Color = Color("#D8A46B")
@export var default_item_id: String = "mi_tre_em"

func _init(
	p_id: String = "wooden_shelf",
	p_name: String = "Kệ Gỗ Tạp Hóa",
	p_cost: int = 8000,
	p_cap: int = 12,
	p_level: int = 1,
	p_color: Color = Color("#D8A46B"),
	p_default_item: String = "mi_tre_em"
) -> void:
	id = p_id
	display_name = p_name
	cost = p_cost
	max_capacity = p_cap
	unlock_level = p_level
	tint_color = p_color
	default_item_id = p_default_item

