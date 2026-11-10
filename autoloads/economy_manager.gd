extends Node

var money: int = 45000
var reputation: int = 15
var candy_jar: int = 12

# Danh mục mặt hàng tạp hóa (ItemId -> ItemData)
var item_catalog: Dictionary = {}
# Số lượng hàng đang có trong Kho (ItemId -> int)
var warehouse_stock: Dictionary = {}
# Danh mục nội thất/kệ hàng (FurnitureId -> FurnitureData)
var furniture_catalog: Dictionary = {}
# Sổ ghi nợ hàng xóm (Array[DebtRecord])
var debt_records: Array[DebtRecord] = []
var _next_debt_id: int = 1

func _ready() -> void:
	_setup_catalogs()
	_setup_initial_debts()
	call_deferred("_emit_initial")

func reset_for_new_game() -> void:
	money = 45000
	reputation = 15
	candy_jar = 12
	for k in item_catalog:
		var it: ItemData = item_catalog[k]
		var raw_base: Variant = it.get("base_price")
		it.retail_price = int(raw_base) if raw_base != null and int(raw_base) > 0 else (it.wholesale_cost * 2)
		warehouse_stock[k] = 10
	debt_records.clear()
	_next_debt_id = 1
	_setup_initial_debts()
	_emit_initial()

func get_effective_wholesale_cost(item_id: String) -> int:
	if not item_catalog.has(item_id):
		return 1000
	var item: ItemData = item_catalog[item_id]
	if GameManager.daily_discount_item_id == item_id:
		return int(round(float(item.wholesale_cost) * 0.75 / 100.0)) * 100
	return item.wholesale_cost

func _emit_initial() -> void:
	EventBus.money_changed.emit(money, 0)
	EventBus.reputation_changed.emit(reputation, 0)
	EventBus.candy_jar_changed.emit(candy_jar)
	EventBus.inventory_updated.emit()
	EventBus.debt_ledger_updated.emit()

func _setup_catalogs() -> void:
	var items: Array[ItemData] = [
		ItemData.new(
			"mi_tre_em",
			"Mì Trẻ Em Giòn Rụm",
			"Snack",
			1000,
			2500,
			"SchoolRush",
			Color("#E5A93C"),
			"Món quà vặt huyền thoại mỗi giờ trống trường tan học.",
			load("res://assets/sprites/items/item_mi_tre_em.png")
		),
		ItemData.new(
			"kem_mut",
			"Kem Mút Đậu Xanh",
			"Drink",
			1500,
			3500,
			"Sunny",
			Color("#77A88D"),
			"Giải nhiệt cực đỉnh những buổi trưa nắng vàng.",
			load("res://assets/sprites/items/item_kem_mut.png")
		),
		ItemData.new(
			"nuoc_ngot_bich",
			"Nước Ngọt Đóng Bịch",
			"Drink",
			1200,
			3000,
			"Sunny",
			Color("#D96B43"),
			"Buộc dây thun kèm ống hút nhựa, hút khách trẻ con lẫn người lớn.",
			load("res://assets/sprites/items/item_nuoc_ngot_bich.png")
		),
		ItemData.new(
			"keo_keo",
			"Kẹo Kéo Đậu Phộng",
			"Snack",
			800,
			2000,
			"SchoolRush",
			Color("#D49B6A"),
			"Ngọt bùi giòn tan, cũng có thể bổ sung vào hũ kẹo thối tiền lẻ.",
			load("res://assets/sprites/items/item_keo_keo.png")
		),
		ItemData.new(
			"ao_mua",
			"Áo Mưa Giấy Tiện Lợi",
			"Weather",
			2500,
			6000,
			"Rainy",
			Color("#5B84B1"),
			"Mặt hàng cháy kệ mỗi khi cơn mưa chiều ập xuống đầu ngõ.",
			load("res://assets/sprites/items/item_ao_mua.png")
		),
		ItemData.new(
			"ca_phe_goi",
			"Cà Phê Hòa Tan & Mì Ly",
			"Specialty",
			3000,
			6500,
			"Any",
			Color("#7A5C48"),
			"Cứu cánh cho anh sinh viên kiến trúc thức khuya vẽ đồ án.",
			load("res://assets/sprites/items/item_ca_phe_goi.png")
		)
	]

	for item in items:
		item_catalog[item.id] = item
		warehouse_stock[item.id] = 10

	var furns: Array[FurnitureData] = [
		FurnitureData.new(
			"wooden_shelf",
			"Kệ Gỗ Mộc (Mì & Bánh Kẹo)",
			8000,
			12,
			1,
			Color("#D49B62"),
			"mi_tre_em"
		),
		FurnitureData.new(
			"ice_box",
			"Thùng Đá & Tủ Kem Mút",
			12000,
			14,
			1,
			Color("#6D9DC5"),
			"kem_mut"
		),
		FurnitureData.new(
			"rain_rack",
			"Giá Treo Đồ Mưa & Tạp Phẩm",
			10000,
			10,
			1,
			Color("#6B8E78"),
			"ao_mua"
		)
	]
	for f in furns:
		furniture_catalog[f.id] = f

func _setup_initial_debts() -> void:
	add_debt_record(
		"Cậu bé Nam (Lớp 5A)",
		"Học trò đầu ngõ",
		5000,
		"Mua 2 gói mì trẻ em, hẹn cuối tuần đập heo đất trả.",
		Color("#E5A93C")
	)
	add_debt_record(
		"Anh Tuấn Kiến Trúc",
		"Sinh viên thuê trọ",
		13000,
		"Mua cà phê gói & mì ly chạy đồ án đêm mưa.",
		Color("#5B84B1")
	)
	add_debt_record(
		"Bác Tư Hàng Xóm",
		"Khách quen lâu năm",
		9000,
		"Quên mang ví lẻ khi sang mua nước ngọt đãi khách.",
		Color("#6B8E78")
	)

func add_money(amount: int) -> void:
	money += amount
	if amount > 0:
		GameManager.daily_revenue += amount
	EventBus.money_changed.emit(money, amount)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	if amount > 0:
		GameManager.daily_spent += amount
	EventBus.money_changed.emit(money, -amount)
	return true

func add_reputation(delta: int) -> void:
	reputation = maxi(0, reputation + delta)
	EventBus.reputation_changed.emit(reputation, delta)

func buy_wholesale_pack(item_id: String, pack_size: int = 8) -> bool:
	if not item_catalog.has(item_id):
		return false
	var item: ItemData = item_catalog[item_id]
	var unit_cost: int = get_effective_wholesale_cost(item_id)
	var total_cost: int = unit_cost * pack_size
	if not spend_money(total_cost):
		EventBus.toast_requested.emit("Không đủ vốn nhập sỉ (Cần %s đ)!" % format_vnd(total_cost), Color("#C84B31"))
		return false

	warehouse_stock[item_id] = warehouse_stock.get(item_id, 0) + pack_size
	EventBus.inventory_updated.emit()
	EventBus.toast_requested.emit("Đã nhập +%d %s vào kho (-%s đ)!" % [pack_size, item.display_name, format_vnd(total_cost)], Color("#6B8E78"))
	return true

func refill_candy_jar() -> bool:
	var cost: int = 3000
	if not spend_money(cost):
		EventBus.toast_requested.emit("Cần 3.000đ để mua thêm kẹo lẻ!", Color("#C84B31"))
		return false
	candy_jar += 10
	EventBus.candy_jar_changed.emit(candy_jar)
	EventBus.toast_requested.emit("Đã đổ thêm +10 viên kẹo vào hũ thu ngân!", Color("#E5A93C"))
	return true

func use_candy_for_change() -> bool:
	if candy_jar <= 0:
		return false
	candy_jar -= 1
	EventBus.candy_jar_changed.emit(candy_jar)
	return true

func take_from_warehouse(item_id: String, max_needed: int) -> int:
	var available: int = warehouse_stock.get(item_id, 0)
	var taken: int = mini(available, max_needed)
	if taken > 0:
		warehouse_stock[item_id] = available - taken
		EventBus.inventory_updated.emit()
	return taken

func adjust_item_price(item_id: String, delta: int) -> void:
	if not item_catalog.has(item_id):
		return
	var item: ItemData = item_catalog[item_id]
	item.retail_price = clampi(item.retail_price + delta, item.wholesale_cost, item.wholesale_cost * 4)
	EventBus.inventory_updated.emit()

func add_debt_record(c_name: String, c_role: String, amount: int, note: String, color: Color = Color("#6B8E78")) -> DebtRecord:
	var rec := DebtRecord.new(_next_debt_id, c_name, c_role, amount, note, GameManager.current_day, color)
	_next_debt_id += 1
	debt_records.push_front(rec)
	EventBus.debt_ledger_updated.emit()
	return rec

func collect_debt(record_id: int) -> bool:
	for rec in debt_records:
		if rec.record_id == record_id and not rec.is_paid:
			rec.is_paid = true
			add_money(rec.amount)
			add_reputation(2)
			EventBus.debt_ledger_updated.emit()
			EventBus.toast_requested.emit("Đã thu nợ %s (%s đ) +2 Tình làng nghĩa xóm!" % [rec.customer_name, format_vnd(rec.amount)], Color("#6B8E78"))
			return true
	return false

func get_unpaid_debt_total() -> int:
	var total: int = 0
	for rec in debt_records:
		if not rec.is_paid:
			total += rec.amount
	return total

func format_vnd(val: int) -> String:
	var s: String = str(abs(val))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "." + res
	if val < 0:
		res = "-" + res
	return res

