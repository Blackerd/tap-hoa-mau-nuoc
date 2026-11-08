class_name ItemData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var category: String = "Snack"
@export var wholesale_cost: int = 1000
@export var retail_price: int = 2000
@export var base_price: int = 2000
@export var weather_boost: String = "Any"
@export var accent_color: Color = Color("#E5A93C")
@export var description: String = ""
@export var icon: Texture2D = null

func _init(
	p_id: String = "",
	p_name: String = "",
	p_cat: String = "Snack",
	p_cost: int = 1000,
	p_price: int = 2000,
	p_weather: String = "Any",
	p_color: Color = Color("#E5A93C"),
	p_desc: String = "",
	p_icon: Texture2D = null
) -> void:
	id = p_id
	display_name = p_name
	category = p_cat
	wholesale_cost = p_cost
	retail_price = p_price
	base_price = p_price
	weather_boost = p_weather
	accent_color = p_color
	description = p_desc
	icon = p_icon
