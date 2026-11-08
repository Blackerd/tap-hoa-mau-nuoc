extends Node

enum StorePhase {
	STORY_INTRO,
	OWNER_SETUP,
	MORNING_PREP,
	OPEN_FOR_BUSINESS,
	NIGHT_SUMMARY
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
var is_rush_hour: bool = false
var time_speed_multiplier: float = 1.0
var auto_cashier_enabled: bool = false

# Thống kê trong ngày cho Màn hình Đóng Tiệm Về Nhà (Scene 5)
var daily_revenue: int = 0
var daily_spent: int = 0
var daily_customers_served: int = 0
var daily_customers_left: int = 0

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
	_roll_daily_weather()
	call_deferred("_broadcast_initial_state")

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

func begin_owner_setup() -> void:
	current_phase = StorePhase.OWNER_SETUP
	EventBus.store_phase_changed.emit("OWNER_SETUP")
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())

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
			EconomyManager.add_money(15000)
		"stock":
			for item_id in EconomyManager.warehouse_stock:
				EconomyManager.warehouse_stock[item_id] += 6
			EventBus.inventory_updated.emit()

	_reset_daily_stats()
	current_phase = StorePhase.MORNING_PREP
	EventBus.store_phase_changed.emit("MORNING_PREP")
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())
	EventBus.toast_requested.emit("🎉 Chào mừng %s khai trương %s! Hãy nhập hàng sáng sớm trước khi mở cửa." % [player_name, store_name], Color("#6B8E78"))

func skip_to_daytime_store() -> void:
	has_completed_onboarding = true
	open_store_for_day()

func open_store_for_day() -> void:
	current_hour = 7
	current_minute = 0
	is_rush_hour = false
	current_phase = StorePhase.OPEN_FOR_BUSINESS
	EventBus.store_phase_changed.emit("OPEN_FOR_BUSINESS")
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())
	EventBus.toast_requested.emit("🔓 %s đã mở cửa đón khách ngày thứ %d!" % [store_name, current_day], Color("#6B8E78"))

func close_store_for_night() -> void:
	current_hour = 21
	current_minute = 0
	is_rush_hour = false
	current_phase = StorePhase.NIGHT_SUMMARY
	EventBus.rush_hour_changed.emit(false, "")
	EventBus.store_phase_changed.emit("NIGHT_SUMMARY")
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())

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
			EventBus.rush_hour_changed.emit(true, "🔔 Trống trường tan học! Học sinh ùa vào mua quà vặt!")
			EventBus.toast_requested.emit("🔔 Tan trường! Mì trẻ em, kẹo kéo, kem mút bán cực chạy!", Color("#C84B31"))
		else:
			EventBus.rush_hour_changed.emit(false, "")

	# Đổi thời tiết bất chợt buổi chiều
	if current_hour == 14 and current_minute == 30 and randf() < 0.35:
		if current_weather != "Rainy":
			current_weather = "Rainy"
			weather_label = "Chiều mưa rào bất chợt"
			EventBus.weather_changed.emit(current_weather, weather_label)
			EventBus.toast_requested.emit("🌧️ Cơn mưa chiều ập tới! Khách tìm mua Áo mưa & Mì gói!", Color("#4A749C"))

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
	current_phase = StorePhase.MORNING_PREP
	EventBus.weather_changed.emit(current_weather, weather_label)
	EventBus.store_phase_changed.emit("MORNING_PREP")
	EventBus.time_updated.emit(current_day, current_hour, current_minute, get_phase_label())

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
		EventBus.toast_requested.emit("Cần thêm điểm Tình Làng Nghĩa Xóm (%d/%d ♥)!" % [EconomyManager.reputation, req_rep], Color("#C84B31"))
		return false

	EconomyManager.spend_money(cost)
	store_level += 1
	var next_cfg: Dictionary = level_configs[store_level]
	EventBus.store_level_changed.emit(store_level, next_cfg["title"], next_cfg["reveal_radius"])
	EventBus.stamp_effect_requested.emit("MỞ RỘNG CẤP %d" % store_level, Vector2(800, 420))
	EventBus.toast_requested.emit("🎨 Màu nước đã loang rộng ra khu phố! Đạt %s!" % next_cfg["title"], Color("#6B8E78"))
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
	match current_weather:
		"Sunny":
			return "☀️ Dự báo hôm nay: TRƯA NẮNG VÀNG RỰC — Học sinh và người qua đường sẽ hỏi mua Kem Mút Đậu Xanh & Nước Ngọt Bịch rất nhiều! Hãy nhớ nhập đủ kho và châm đầy tủ kem nhé."
		"Rainy":
			return "🌧️ Dự báo hôm nay: MƯA PHÙN ĐẦU NGÕ — Người đi đường rất cần Áo Mưa Giấy Tiện Lợi và Cà Phê / Mì Ly ấm bụng! Hãy ưu tiên nhập sỉ Áo Mưa."
		_:
			return "🍃 Dự báo hôm nay: GIÓ MÁT HIÊN NHÀ — Thời tiết dễ chịu, hàng xóm thích ngồi bàn trà đá gốc đa và mua đều các mặt hàng quà vặt, mì trẻ em, kẹo kéo."

func get_daily_story_vignette() -> String:
	var stories: Array[String] = [
		"📖 Nhật ký Đêm Ngày 1: Hôm nay %s chính thức kéo cánh cửa gỗ mở lại '%s'. Mùi gỗ thông cũ hòa cùng tiếng trẻ con ríu rít giờ tan tầm làm con ngõ nhỏ như sống lại những năm tháng tuổi thơ...",
		"📖 Nhật ký Đêm Ngày 2: Sáng nay Bác Tư ghé uống chén trà đá dưới gốc đa, kể chuyện ngày xưa bà ngoại cũng hay để dành kẹo kéo thối tiền lẻ cho lũ trẻ trong xóm. Tiệm nhỏ của %s đã bắt đầu trở thành điểm hẹn quen thuộc.",
		"📖 Nhật ký Đêm Ngày 3: Anh Tuấn sinh viên phòng trọ cuối ngõ ghé mua vội gói cà phê hòa tan để thức vẽ đồ án. Nhìn ánh đèn vàng hắt ra từ hiên quán '%s', ai đi làm về muộn cũng thấy lòng ấm lại.",
		"📖 Nhật ký Đêm Ngày %d: Từng nét cọ màu nước đang dần tô thắm lại cả khu phố. '%s' của %s không chỉ bán những món hàng lặt vặt, mà còn giữ giùm cả xóm nhỏ một khoảng ký ức bình yên..."
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
