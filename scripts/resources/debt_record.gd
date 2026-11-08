class_name DebtRecord
extends RefCounted

var record_id: int = 0
var customer_name: String = ""
var customer_role: String = ""
var amount: int = 0
var note: String = ""
var day_borrowed: int = 1
var is_paid: bool = false
var portrait_color: Color = Color("#6B8E78")

func _init(
	p_id: int,
	p_name: String,
	p_role: String,
	p_amount: int,
	p_note: String,
	p_day: int,
	p_color: Color = Color("#6B8E78")
) -> void:
	record_id = p_id
	customer_name = p_name
	customer_role = p_role
	amount = p_amount
	note = p_note
	day_borrowed = p_day
	portrait_color = p_color

