class_name ShelfEntity
extends Node2D

var grid_cell: Vector2i = Vector2i.ZERO
var furniture_id: String = "wooden_shelf"
var item_id: String = "mi_tre_em"
var current_stock: int = 8
var max_capacity: int = 12
var tint_color: Color = Color("#D49B62")
var is_hovered: bool = false

const INK_COLOR := Color("#2C221E")
const PAPER_CREAM := Color("#FBF8F1")

static var tex_shelf_noodles: Texture2D
static var tex_shelf_icebox: Texture2D
static var tex_shelf_raincoat: Texture2D
static var tex_shelf_soda_coffee: Texture2D
static var tex_shelf_empty_cat: Texture2D
static var tex_ui_bubble: Texture2D

func _ready() -> void:
	if tex_shelf_noodles == null:
		tex_shelf_noodles = load("res://assets/sprites/furniture/shelf_noodles.png")
		tex_shelf_icebox = load("res://assets/sprites/furniture/shelf_icebox.png")
		tex_shelf_raincoat = load("res://assets/sprites/furniture/shelf_raincoat.png")
		tex_shelf_soda_coffee = load("res://assets/sprites/furniture/shelf_soda_coffee.png")
		tex_shelf_empty_cat = load("res://assets/sprites/furniture/shelf_empty_cat.png")
		tex_ui_bubble = load("res://assets/sprites/ui/ui_bubble.png")

func setup(cell: Vector2i, furn_data: FurnitureData, assigned_item: String, initial_stock: int) -> void:
	grid_cell = cell
	furniture_id = furn_data.id
	max_capacity = furn_data.max_capacity
	tint_color = furn_data.tint_color
	item_id = assigned_item
	current_stock = clampi(initial_stock, 0, max_capacity)
	queue_redraw()

func take_one_item() -> bool:
	if current_stock <= 0:
		return false
	current_stock -= 1
	play_bounce()
	queue_redraw()
	return true

func restock_from_warehouse() -> int:
	var space_left: int = max_capacity - current_stock
	if space_left <= 0:
		EventBus.toast_requested.emit("Kệ này đã đầy ắp hàng!", Color("#6B8E78"))
		return 0
	var added: int = EconomyManager.take_from_warehouse(item_id, space_left)
	if added > 0:
		current_stock += added
		play_bounce()
		queue_redraw()
		var item: ItemData = EconomyManager.item_catalog.get(item_id)
		var item_name: String = item.display_name if item else item_id
		EventBus.toast_requested.emit("✨ Đã xếp +%d %s lên kệ!" % [added, item_name], Color("#6B8E78"))
	else:
		var item: ItemData = EconomyManager.item_catalog.get(item_id)
		var item_name: String = item.display_name if item else item_id
		EventBus.toast_requested.emit("Kho đã hết %s! Hãy mở Sổ Cái để nhập sỉ." % item_name, Color("#C84B31"))
	return added

func cycle_assigned_item() -> void:
	if current_stock > 0:
		EconomyManager.warehouse_stock[item_id] = EconomyManager.warehouse_stock.get(item_id, 0) + current_stock
		current_stock = 0
	var keys: Array = EconomyManager.item_catalog.keys()
	var idx: int = keys.find(item_id)
	var next_idx: int = (idx + 1) % keys.size()
	item_id = keys[next_idx]
	restock_from_warehouse()
	EventBus.inventory_updated.emit()
	queue_redraw()

func play_bounce() -> void:
	var tw: Tween = create_tween()
	scale = Vector2(1.10, 0.90)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _get_shelf_texture() -> Texture2D:
	if current_stock <= 0 and tex_shelf_empty_cat != null:
		return tex_shelf_empty_cat
	match item_id:
		"kem_mut":
			return tex_shelf_icebox
		"ao_mua", "keo_keo":
			return tex_shelf_raincoat
		"nuoc_ngot_bich", "ca_phe_goi":
			return tex_shelf_soda_coffee
		_:
			return tex_shelf_noodles

func _draw() -> void:
	var item: ItemData = EconomyManager.item_catalog.get(item_id)
	var item_tex: Texture2D = item.icon if item else null

	# 1. Soft watercolor ground shadow
	draw_rect(Rect2(-48, -6, 96, 16), Color(0.18, 0.14, 0.11, 0.16), true)

	# 2. Draw high-res Watercolor Shelf Sprite
	var shelf_tex: Texture2D = _get_shelf_texture()
	var shelf_rect := Rect2(-48, -88, 96, 92)
	if shelf_tex != null:
		draw_texture_rect(shelf_tex, shelf_rect, false)

	# 3. Compact stock tag + Item Icon at top of shelf
	var font: Font = ThemeDB.fallback_font
	var stock_str: String = "%d/%d" % [current_stock, max_capacity] if current_stock > 0 else "HẾT!"
	var tag_rect := Rect2(-34, -112, 68, 22)
	var tag_bg: Color = PAPER_CREAM if current_stock > 0 else Color("#FADBD8")
	draw_rect(tag_rect, tag_bg, true)
	draw_rect(tag_rect, Color("#C84B31") if is_hovered or current_stock == 0 else INK_COLOR, false, 1.6)

	if item_tex != null:
		draw_texture_rect(item_tex, Rect2(tag_rect.position.x + 3, tag_rect.position.y + 2, 18, 18), false)
		draw_string(
			font,
			Vector2(tag_rect.position.x + 24, tag_rect.position.y + 15),
			stock_str,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			11,
			INK_COLOR if current_stock > 0 else Color("#C84B31")
		)
	else:
		draw_string(font, Vector2(tag_rect.position.x + 8, tag_rect.position.y + 15), stock_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK_COLOR)

	if is_hovered:
		draw_rect(Rect2(-52, -92, 104, 98), Color(0.78, 0.29, 0.19, 0.55), false, 2.2)
