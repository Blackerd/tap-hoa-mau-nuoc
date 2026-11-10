extends Node

const SAVE_FILE_PATH: String = "user://tap_hoa_save.json"

enum StorePhase {
	STORY_INTRO,
	OWNER_SETUP,
	MORNING_PREP,
	OPEN_FOR_BUSINESS,
	NIGHT_SUMMARY
}

const SCENE_PATHS: Dictionary = {
	StorePhase.STORY_INTRO: "res://scenes/story_intro_scene.tscn",
	StorePhase.OWNER_SETUP: "res://scenes/owner_setup_scene.tscn",
	StorePhase.MORNING_PREP: "res://scenes/morning_market_scene.tscn",
	StorePhase.OPEN_FOR_BUSINESS: "res://scenes/main/main_game.tscn",
	StorePhase.NIGHT_SUMMARY: "res://scenes/night_home_scene.tscn"
}

var player_name: String = "Bà Ba"
var store_name: String = "TẠP HÓA MÀU NƯỚC"
var has_completed_onboarding: bool = false

var current_day: int = 1
var current_hour: int = 7
var current_minute: int = 0
var current_phase: StorePhase = StorePhase.STORY_INTRO

var current_weather: String = "Sunny" # "Sunny", "Rainy", "Breezy"
var weather_label: String = "Trưa nắng vàng rực"
var daily_discount_item_id: String = "mi_tre_em"
var is_rush_hour: bool = false
var time_speed_multiplier: float = 1.0
var auto_cashier_enabled: bool = false

# Thống kê trong ngày cho Màn hình Đóng Tiệm Về Nhà (Scene 5)
var daily_revenue: int = 0
var daily_spent: int = 0
var daily_customers_served: int = 0
var daily_customers_left: int = 0

# Lưu trữ danh sách các kệ hàng trong quán xuyên suốt các Scene & Save/Load
var saved_shelves: Array[Dictionary] = []

# Hệ thống Level "Tô màu khu phố" (Style 8)
var store_level: int = 1
var level_configs: Dictionary = {
	1: {
		"title": "Cấp 1: Quầy Nhỏ Hiên Nhà",
		"reveal_radius": 0.48,
		"upgrade_cost": 35000,
		"rep_required": 20,
		"unlock_desc": "Mở rộng màu nước ra Sân Cây Đa & bàn trà đá!"
	},
	2: {
		"title": "Cấp 2: Tạp Hóa Gốc Đa",
		"reveal_radius": 0.68,
		"upgrade_cost": 75000,
		"rep_required": 45,
		"unlock_desc": "Tô màu Vỉa Hè Trà Đá & tăng lượng khách dạo phố!"
	},
	3: {
		"title": "Cấp 3: Tạp Hóa Đầu Ngõ",
		"reveal_radius": 0.86,
		"upgrade_cost": 140000,
		"rep_required": 80,
		"unlock_desc": "Hoàn thiện toàn bộ bức tranh Bách Hóa Khu Phố!"
	},
	4: {
		"title": "Cấp 4: Bách Hóa Ký Ức (Tối đa)",
		"reveal_radius": 1.15,
		"upgrade_cost": 0,
		"rep_required": 999,
		"unlock_desc": "Bức tranh màu nước khu phố đã rực rỡ trọn vẹn!"
	}
}

var _minute_accumulator: float = 0.0
const SECONDS_PER_TEN_MINUTES: float = 2.8

func _ready() -> void:
	_init_default_shelves()
	_roll_daily_weather()
	call_deferred("_broadcast_initial_state")

func _init_default_shelves() -> void:
	saved_shelves = [
		{"x": 1, "y": 1, "furn_id": "wooden_shelf", "item_id": "mi_tre_em", "stock": 10},
		{"x": 4, "y": 1, "furn_id": "ice_box", "item_id": "kem_mut", "stock": 10},
		{"x": 7, "y": 1, "furn_id": "wooden_shelf", "item_id": "nuoc_ngot_bich", "stock": 9},
		{"x": 5, "y": 3, "furn_id": "rain_rack", "item_id": "keo_keo", "stock": 10}
	]

func _broadcast_initial_state() -> void:
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())
	EventBus.weather_changed.emit(current_weather, weather_label)
	var cfg: Dictionary = level_configs[store_level]
	EventBus.store_level_changed.emit(store_level, cfg["title"], cfg["reveal_radius"])
	EventBus.store_phase_changed.emit(get_phase_id())

func get_phase_id() -> String:
	match current_phase:
		StorePhase.STORY_INTRO:
			return "STORY_INTRO"
		StorePhase.OWNER_SETUP:
			return "OWNER_SETUP"
		StorePhase.MORNING_PREP:
			return "MORNING_PREP"
		StorePhase.OPEN_FOR_BUSINESS:
			return "OPEN_FOR_BUSINESS"
		StorePhase.NIGHT_SUMMARY:
			return "NIGHT_SUMMARY"
	return "OPEN_FOR_BUSINESS"

func change_to_phase_scene(target_phase: StorePhase) -> void:
	current_phase = target_phase
	var path: String = SCENE_PATHS.get(target_phase, "res://scenes/main/main_game.tscn")
	EventBus.store_phase_changed.emit(get_phase_id())
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())
	if get_tree() and get_tree().current_scene and get_tree().current_scene.scene_file_path != path:
		get_tree().change_scene_to_file(path)

func begin_new_game_onboarding() -> void:
	current_day = 1
	store_level = 1
	EconomyManager.reset_for_new_game()
	_init_default_shelves()
	_reset_daily_stats()
	_roll_daily_weather()
	change_to_phase_scene(StorePhase.OWNER_SETUP)

func begin_owner_setup() -> void:
	begin_new_game_onboarding()

func continue_saved_game() -> void:
	if load_game():
		change_to_phase_scene(StorePhase.MORNING_PREP)
	else:
		begin_new_game_onboarding()

func complete_owner_setup(p_owner: String, p_store: String, perk_id: String) -> void:
	var clean_owner: String = p_owner.strip_edges()
	var clean_store: String = p_store.strip_edges().to_upper()
	player_name = clean_owner if clean_owner != "" else "Bà Ba"
	store_name = clean_store if clean_store != "" else "TẠP HÓA MÀU NƯỚC"
	has_completed_onboarding = true

	match perk_id:
		"neighbor":
			EconomyManager.add_reputation(10)
			EconomyManager.candy_jar += 10
			EventBus.candy_jar_changed.emit(EconomyManager.candy_jar)
		"capital":
			EconomyManager.money += 15000
			EventBus.money_changed.emit(EconomyManager.money, 15000)
		"stock":
			for item_id in EconomyManager.warehouse_stock:
				EconomyManager.warehouse_stock[item_id] += 6
			EventBus.inventory_updated.emit()

	_reset_daily_stats()
	save_game()
	change_to_phase_scene(StorePhase.MORNING_PREP)

func skip_to_daytime_store() -> void:
	has_completed_onboarding = true
	open_store_for_day()

func open_store_for_day() -> void:
	current_hour = 7
	current_minute = 0
	is_rush_hour = false
	save_game()
	change_to_phase_scene(StorePhase.OPEN_FOR_BUSINESS)

func close_store_for_night() -> void:
	current_hour = 21
	current_minute = 0
	is_rush_hour = false
	EventBus.rush_hour_changed.emit(false, "")
	save_game()
	change_to_phase_scene(StorePhase.NIGHT_SUMMARY)

func _reset_daily_stats() -> void:
	daily_revenue = 0
	daily_spent = 0
	daily_customers_served = 0
	daily_customers_left = 0

func _process(delta: float) -> void:
	if current_phase != StorePhase.OPEN_FOR_BUSINESS:
		return

	_minute_accumulator += delta * time_speed_multiplier
	if _minute_accumulator >= SECONDS_PER_TEN_MINUTES:
		_minute_accumulator -= SECONDS_PER_TEN_MINUTES
		_advance_ten_minutes()

func _advance_ten_minutes() -> void:
	current_minute += 10
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1

	# Kiểm tra khung giờ cao điểm Tan Trường (11:20-12:10 hoặc 16:50-17:40)
	var should_rush: bool = (
		(current_hour == 11 and current_minute >= 20) or
		(current_hour == 12 and current_minute == 0) or
		(current_hour == 16 and current_minute >= 50) or
		(current_hour == 17 and current_minute <= 30)
	)
	if should_rush != is_rush_hour:
		is_rush_hour = should_rush
		if is_rush_hour:
			EventBus.rush_hour_changed.emit(true, "[Tan trường] Trống trường điểm! Học sinh ùa vào mua quà vặt!")
			EventBus.toast_requested.emit("[Tan trường] Mì trẻ em, kẹo kéo, kem mút bán cực chạy!", Color("#C84B31"))
		else:
			EventBus.rush_hour_changed.emit(false, "")

	# Đổi thời tiết bất chợt buổi chiều
	if current_hour == 14 and current_minute == 30 and randf() < 0.35:
		if current_weather != "Rainy":
			current_weather = "Rainy"
			weather_label = "Chiều mưa rào bất chợt"
			EventBus.weather_changed.emit(current_weather, weather_label)
			EventBus.toast_requested.emit("[Mưa chiều] Cơn mưa rào ập tới! Khách tìm mua Áo mưa & Mì gói!", Color("#4A749C"))

	if current_hour >= 21:
		close_store_for_night()
		return

	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())

func start_next_day() -> void:
	current_day += 1
	current_hour = 6
	current_minute = 30
	is_rush_hour = false
	_reset_daily_stats()
	_roll_daily_weather()
	save_game()
	EventBus.weather_changed.emit(current_weather, weather_label)
	change_to_phase_scene(StorePhase.MORNING_PREP)

func restock_all_saved_shelves_from_warehouse() -> int:
	var total_added: int = 0
	for s_dict in saved_shelves:
		var f_id: String = s_dict.get("furn_id", "wooden_shelf")
		var i_id: String = s_dict.get("item_id", "mi_tre_em")
		var cur_stock: int = int(s_dict.get("stock", 0))
		var furn: FurnitureData = EconomyManager.furniture_catalog.get(f_id)
		var max_cap: int = furn.max_capacity if furn else 12
		var space: int = max_cap - cur_stock
		if space > 0:
			var taken: int = EconomyManager.take_from_warehouse(i_id, space)
			if taken > 0:
				s_dict["stock"] = cur_stock + taken
				total_added += taken
	if total_added > 0:
		save_game()
	return total_added

func toggle_time_speed() -> float:
	if time_speed_multiplier == 1.0:
		time_speed_multiplier = 2.0
	elif time_speed_multiplier == 2.0:
		time_speed_multiplier = 3.0
	else:
		time_speed_multiplier = 1.0
	return time_speed_multiplier

func try_upgrade_store_level() -> bool:
	if store_level >= 4:
		EventBus.toast_requested.emit("Quán đã đạt cấp độ tối đa!", Color("#6B8E78"))
		return false
	var cfg: Dictionary = level_configs[store_level]
	var cost: int = cfg["upgrade_cost"]
	var req_rep: int = cfg["rep_required"]
	if EconomyManager.money < cost:
		EventBus.toast_requested.emit("Chưa đủ tiền để tô màu mở rộng quán (Cần %s đ)!" % EconomyManager.format_vnd(cost), Color("#C84B31"))
		return false
	if EconomyManager.reputation < req_rep:
		EventBus.toast_requested.emit("Cần thêm điểm Tình Làng Nghĩa Xóm (%d/%d)!" % [EconomyManager.reputation, req_rep], Color("#C84B31"))
		return false

	EconomyManager.spend_money(cost)
	store_level += 1
	var next_cfg: Dictionary = level_configs[store_level]
	save_game()
	EventBus.store_level_changed.emit(store_level, next_cfg["title"], next_cfg["reveal_radius"])
	EventBus.stamp_effect_requested.emit("MỞ RỘNG CẤP %d" % store_level, Vector2(800, 420))
	EventBus.toast_requested.emit("Màu nước đã loang rộng ra khu phố! Đạt %s!" % next_cfg["title"], Color("#6B8E78"))
	return true

func get_phase_label() -> String:
	match current_phase:
		StorePhase.STORY_INTRO:
			return "Mở đầu ký ức"
		StorePhase.OWNER_SETUP:
			return "Đăng ký khai trương"
		StorePhase.MORNING_PREP:
			return "Đi chợ sỉ sáng sớm"
		StorePhase.OPEN_FOR_BUSINESS:
			return "Đang mở cửa"
		StorePhase.NIGHT_SUMMARY:
			return "Đóng tiệm về nhà"
	return "Đang mở cửa"

func get_weather_forecast_advice() -> String:
	var disc_item: ItemData = EconomyManager.item_catalog.get(daily_discount_item_id)
	var disc_str: String = "  |  Chợ sỉ hôm nay giảm giá 25%%: %s!" % disc_item.display_name if disc_item else ""
	match current_weather:
		"Sunny":
			return "Dự báo hôm nay: TRƯA NẮNG VÀNG RỰC — Khách hỏi mua Kem Mút Đậu Xanh & Nước Ngọt Bịch rất nhiều!" + disc_str
		"Rainy":
			return "Dự báo hôm nay: MƯA PHÙN ĐẦU NGÕ — Người đi đường rất cần Áo Mưa Giấy Tiện Lợi và Cà Phê / Mì Ly!" + disc_str
		_:
			return "Dự báo hôm nay: GIÓ MÁT HIÊN NHÀ — Hàng xóm thích ngồi bàn trà đá gốc đa và mua quà vặt đều đặn." + disc_str

func get_daily_story_vignette() -> String:
	var stories: Array[String] = [
		"Nhật ký Đêm Ngày 1: Hôm nay %s chính thức kéo cánh cửa gỗ mở lại '%s'. Mùi gỗ thông cũ hòa cùng tiếng trẻ con ríu rít giờ tan tầm làm con ngõ nhỏ như sống lại những năm tháng tuổi thơ...",
		"Nhật ký Đêm Ngày 2: Sáng nay Bác Tư ghé uống chén trà đá dưới gốc đa, kể chuyện ngày xưa bà ngoại cũng hay để dành kẹo kéo thối tiền lẻ cho lũ trẻ trong xóm. Tiệm nhỏ của %s đã bắt đầu trở thành điểm hẹn quen thuộc.",
		"Nhật ký Đêm Ngày 3: Anh Tuấn sinh viên phòng trọ cuối ngõ ghé mua vội gói cà phê hòa tan để thức vẽ đồ án. Nhìn ánh đèn vàng hắt ra từ hiên quán '%s', ai đi làm về muộn cũng thấy lòng ấm lại.",
		"Nhật ký Đêm Ngày %d: Từng nét cọ màu nước đang dần tô thắm lại cả khu phố. '%s' của %s không chỉ bán những món hàng lặt vặt, mà còn giữ giùm cả xóm nhỏ một khoảng ký ức bình yên..."
	]
	if current_day <= 3:
		return stories[current_day - 1] % [player_name, store_name]
	return stories[3] % [current_day, store_name, player_name]

func get_reveal_radius() -> float:
	return level_configs[store_level]["reveal_radius"]

func _roll_daily_weather() -> void:
	var roll: float = randf()
	if roll < 0.50:
		current_weather = "Sunny"
		weather_label = "Trưa nắng vàng rực"
	elif roll < 0.80:
		current_weather = "Breezy"
		weather_label = "Gió mát hiên nhà"
	else:
		current_weather = "Rainy"
		weather_label = "Mưa phùn đầu ngõ"

	var item_keys: Array = ["mi_tre_em", "kem_mut", "nuoc_ngot_bich", "keo_keo", "ao_mua", "ca_phe_goi"]
	daily_discount_item_id = item_keys.pick_random()

# ==============================================================================
# HỆ THỐNG LƯU & TẢI GAME (SAVE / LOAD PERSISTENCE)
# ==============================================================================
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func get_save_summary() -> Dictionary:
	if not has_save_file():
		return {}
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}

func save_game() -> void:
	var prices_dict: Dictionary = {}
	for k in EconomyManager.item_catalog:
		var it: ItemData = EconomyManager.item_catalog[k]
		prices_dict[k] = it.retail_price

	var debts_arr: Array[Dictionary] = []
	for rec: DebtRecord in EconomyManager.debt_records:
		debts_arr.append({
			"id": rec.record_id,
			"name": rec.customer_name,
			"role": rec.customer_role,
			"amount": rec.amount,
			"note": rec.note,
			"day": rec.day_borrowed,
			"paid": rec.is_paid
		})

	var data: Dictionary = {
		"player_name": player_name,
		"store_name": store_name,
		"has_completed_onboarding": has_completed_onboarding,
		"current_day": current_day,
		"store_level": store_level,
		"money": EconomyManager.money,
		"reputation": EconomyManager.reputation,
		"candy_jar": EconomyManager.candy_jar,
		"warehouse_stock": EconomyManager.warehouse_stock.duplicate(),
		"item_prices": prices_dict,
		"saved_shelves": saved_shelves.duplicate(true),
		"debts": debts_arr
	}
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> bool:
	var data: Dictionary = get_save_summary()
	if data.is_empty():
		return false

	player_name = str(data.get("player_name", "Bà Ba"))
	store_name = str(data.get("store_name", "TẠP HÓA MÀU NƯỚC"))
	has_completed_onboarding = bool(data.get("has_completed_onboarding", true))
	current_day = maxi(1, int(data.get("current_day", 1)))
	store_level = clampi(int(data.get("store_level", 1)), 1, 4)

	EconomyManager.money = int(data.get("money", 45000))
	EconomyManager.reputation = int(data.get("reputation", 15))
	EconomyManager.candy_jar = int(data.get("candy_jar", 12))

	if data.has("warehouse_stock") and data["warehouse_stock"] is Dictionary:
		var ws: Dictionary = data["warehouse_stock"]
		for k in ws:
			EconomyManager.warehouse_stock[str(k)] = int(ws[k])

	if data.has("item_prices") and data["item_prices"] is Dictionary:
		var ip: Dictionary = data["item_prices"]
		for k in ip:
			if EconomyManager.item_catalog.has(str(k)):
				EconomyManager.item_catalog[str(k)].retail_price = int(ip[k])

	if data.has("saved_shelves") and data["saved_shelves"] is Array:
		saved_shelves.clear()
		for entry in data["saved_shelves"]:
			if entry is Dictionary:
				saved_shelves.append({
					"x": int(entry.get("x", 1)),
					"y": int(entry.get("y", 1)),
					"furn_id": str(entry.get("furn_id", "wooden_shelf")),
					"item_id": str(entry.get("item_id", "mi_tre_em")),
					"stock": int(entry.get("stock", 8))
				})

	if data.has("debts") and data["debts"] is Array:
		EconomyManager.debt_records.clear()
		var max_id: int = 1
		for d in data["debts"]:
			if d is Dictionary:
				var rid: int = int(d.get("id", max_id))
				max_id = maxi(max_id, rid + 1)
				var rec := DebtRecord.new(
					rid,
					str(d.get("name", "Hàng xóm")),
					str(d.get("role", "Khách quen")),
					int(d.get("amount", 5000)),
					str(d.get("note", "")),
					int(d.get("day", 1)),
					Color("#6B8E78")
				)
				rec.is_paid = bool(d.get("paid", false))
				EconomyManager.debt_records.append(rec)
		EconomyManager._next_debt_id = max_id

	_reset_daily_stats()
	_roll_daily_weather()
	return true
