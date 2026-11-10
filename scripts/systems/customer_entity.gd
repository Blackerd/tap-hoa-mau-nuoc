class_name CustomerEntity
extends Node2D

enum State {
	STROLLING_SIDEWALK,
	SITTING_AT_TEA_TABLE,
	WALKING_TO_SHELF,
	BROWSING_AT_SHELF,
	WALKING_TO_CASHIER,
	WAITING_AT_CASHIER,
	LEAVING
}

var customer_name: String = "Khách hàng"
var customer_role: String = "Hàng xóm"
var shirt_color: Color = Color("#6B8E78")
var sprite_key: String = "schoolboy"
var wanted_item_id: String = "mi_tre_em"
var wanted_qty: int = 1
var asks_for_credit: bool = false
var target_shelf: ShelfEntity = null

# Hồ sơ tâm lý & hành vi đời thường
var initial_intent: String = "shop" # "shop", "window_shop", "tea_break", "passerby"
var price_sensitivity: float = 1.0  # Độ nhạy cảm với giá đắt (0.7 -> 1.5)
var browse_timer: float = 1.8
var tea_timer: float = 5.5
var patience_max: float = 20.0
var patience_left: float = 20.0
var is_greeted: bool = false
var queue_index: int = 0

var state: State = State.WALKING_TO_SHELF
var waypoints: Array[Vector2] = []
var move_speed: float = 95.0
var walk_bob_time: float = 0.0
var mood_text: String = ""
var mood_color: Color = Color("#2C221E")
var exit_point: Vector2 = Vector2.ZERO
var cashier_point: Vector2 = Vector2.ZERO
var shelf_waypoints: Array[Vector2] = []

const INK_COLOR := Color("#2C221E")
const PAPER_CREAM := Color("#FBF8F1")
const STAMP_RED := Color("#C84B31")
const SAGE_GREEN := Color("#6B8E78")

static var char_textures: Dictionary = {}
static var tex_bubble: Texture2D
static var tex_money: Texture2D
static var tex_heart: Texture2D

func _ready() -> void:
	if char_textures.is_empty():
		char_textures["schoolboy"] = load("res://assets/sprites/characters/char_schoolboy.png")
		char_textures["schoolgirl"] = load("res://assets/sprites/characters/char_schoolgirl.png")
		char_textures["student"] = load("res://assets/sprites/characters/char_student.png")
		char_textures["uncle"] = load("res://assets/sprites/characters/char_uncle.png")
		char_textures["auntie"] = load("res://assets/sprites/characters/char_auntie.png")
		tex_bubble = load("res://assets/sprites/ui/ui_bubble.png")
		tex_money = load("res://assets/sprites/items/icon_money.png")
		tex_heart = load("res://assets/sprites/items/icon_heart.png")

func setup_customer(
	p_name: String,
	p_role: String,
	p_color: Color,
	p_item_id: String,
	p_shelf: ShelfEntity,
	p_path_to_shelf: Array[Vector2],
	p_cashier_pos: Vector2,
	p_exit_pos: Vector2,
	p_sprite_key: String = "schoolboy",
	p_intent: String = "shop",
	p_price_sens: float = 1.0,
	p_patience: float = 20.0
) -> void:
	customer_name = p_name
	customer_role = p_role
	shirt_color = p_color
	wanted_item_id = p_item_id
	target_shelf = p_shelf
	shelf_waypoints = p_path_to_shelf.duplicate()
	cashier_point = p_cashier_pos
	exit_point = p_exit_pos
	sprite_key = p_sprite_key
	initial_intent = p_intent
	price_sensitivity = p_price_sens
	patience_max = p_patience
	patience_left = p_patience
	wanted_qty = 1 if randf() < 0.70 else 2
	asks_for_credit = (randf() < 0.22)

	match initial_intent:
		"passerby":
			state = State.STROLLING_SIDEWALK
			move_speed = 78.0
			mood_text = "Đi dạo ngang ngõ..."
			waypoints = [Vector2(620.0, 646.0), exit_point]
		"tea_break":
			state = State.SITTING_AT_TEA_TABLE
			move_speed = 85.0
			tea_timer = randf_range(5.0, 7.5)
			mood_text = "Ghé uống trà đá..."
			var seat_pos := Vector2(280.0, 548.0) if randf() < 0.5 else Vector2(395.0, 548.0)
			waypoints = [ Vector2(335.0, 646.0), seat_pos ]
		_:
			state = State.WALKING_TO_SHELF
			move_speed = 102.0 if GameManager.is_rush_hour else 88.0
			waypoints = shelf_waypoints.duplicate()
	queue_redraw()

func _process(delta: float) -> void:
	var sim_delta: float = delta * GameManager.time_speed_multiplier
	walk_bob_time += sim_delta * 8.5

	match state:
		State.STROLLING_SIDEWALK:
			if _move_along_waypoints(sim_delta):
				queue_free()
			elif waypoints.size() == 1 and position.x >= 560.0 and position.x <= 640.0:
				# Cơ hội tự nhiên tạt vào quán nếu danh tiếng cao
				var rep_bonus: float = clampf(float(EconomyManager.reputation) * 0.005, 0.0, 0.35)
				if is_greeted or randf() < (0.15 + rep_bonus) * sim_delta:
					_decide_to_enter_store_from_sidewalk()

		State.SITTING_AT_TEA_TABLE:
			if not waypoints.is_empty():
				_move_along_waypoints(sim_delta)
			else:
				mood_text = "Trà đá mát ruột!"
				tea_timer -= sim_delta
				if tea_timer <= 0.0:
					EconomyManager.add_money(2000)
					EconomyManager.add_reputation(1)
					EventBus.toast_requested.emit("%s trả 2.000đ tiền trà đá gốc đa (+1 Tình làng)!" % customer_name, SAGE_GREEN)
					if is_instance_valid(target_shelf) and (is_greeted or randf() < 0.65):
						mood_text = "Tiện ghé mua đồ!"
						state = State.WALKING_TO_SHELF
						waypoints = [Vector2(335.0, 646.0)] + shelf_waypoints.duplicate()
					else:
						mood_text = "+2.000đ Trà đá"
						_start_leaving()

		State.WALKING_TO_SHELF:
			if _move_along_waypoints(sim_delta):
				state = State.BROWSING_AT_SHELF
				browse_timer = randf_range(1.4, 2.3)
				mood_text = "Đang ngắm giá..."

		State.BROWSING_AT_SHELF:
			browse_timer -= sim_delta
			if browse_timer <= 0.0:
				_evaluate_psychology_at_shelf()

		State.WALKING_TO_CASHIER:
			_update_cashier_slot_waypoint()
			if _move_along_waypoints(sim_delta):
				_on_reached_cashier()

		State.WAITING_AT_CASHIER:
			_update_cashier_slot_waypoint()
			if not waypoints.is_empty():
				_move_along_waypoints(sim_delta)
			if GameManager.auto_cashier_enabled:
				complete_checkout("exact")
			else:
				patience_left -= sim_delta
				if patience_left <= 0.0:
					_abandon_queue_and_leave()

		State.LEAVING:
			if _move_along_waypoints(sim_delta):
				queue_free()
	queue_redraw()

func _move_along_waypoints(delta: float) -> bool:
	if waypoints.is_empty():
		return true
	var next_pt: Vector2 = waypoints[0]
	var dist: float = position.distance_to(next_pt)
	if dist <= move_speed * delta:
		position = next_pt
		waypoints.remove_at(0)
		return waypoints.is_empty()
	else:
		position = position.move_toward(next_pt, move_speed * delta)
		return false

func _start_leaving() -> void:
	state = State.LEAVING
	# Luôn bước xuống vỉa hè (y = 646) ở phía bên phải Quầy Thu Ngân (x >= 640) rồi mới đi bộ ra khỏi ngõ
	var sidewalk_step := Vector2(maxf(position.x, 650.0), 646.0)
	waypoints = [sidewalk_step, exit_point]

func _decide_to_enter_store_from_sidewalk() -> void:
	if not is_instance_valid(target_shelf):
		return
	mood_text = "Ghé vào xem thử!"
	state = State.WALKING_TO_SHELF
	waypoints = shelf_waypoints.duplicate()

func encourage_by_player() -> void:
	if is_greeted:
		return
	is_greeted = true
	patience_left = min(patience_max, patience_left + 8.0)
	if state == State.STROLLING_SIDEWALK:
		_decide_to_enter_store_from_sidewalk()
		EventBus.toast_requested.emit("Bạn tươi cười chào hỏi — %s liền rẽ vào tiệm xem hàng!" % customer_name, SAGE_GREEN)
	elif state == State.BROWSING_AT_SHELF:
		mood_text = "Bà chủ niềm nở quá!"
		EventBus.toast_requested.emit("Bạn tư vấn nhiệt tình khiến %s rất ưng ý!" % customer_name, SAGE_GREEN)
	elif state == State.WAITING_AT_CASHIER:
		EventBus.toast_requested.emit("Bạn xin lỗi khách chờ một lát — %s kiên nhẫn đứng đợi thêm!" % customer_name, SAGE_GREEN)
	queue_redraw()

func _evaluate_psychology_at_shelf() -> void:
	# 1. Kiểm tra kệ còn hàng không
	if not is_instance_valid(target_shelf) or target_shelf.current_stock <= 0:
		mood_text = "Ủa hết hàng rồi..."
		mood_color = STAMP_RED
		EconomyManager.add_reputation(-1)
		GameManager.daily_customers_left += 1
		EventBus.toast_requested.emit("%s lắc đầu bỏ về vì kệ đã hết sạch hàng (-1 Tình làng)!" % customer_name, STAMP_RED)
		_start_leaving()
		return

	var item: ItemData = EconomyManager.item_catalog.get(wanted_item_id)
	if item == null:
		_start_leaving()
		return

	# 2. Tính toán Tâm Lý Giá Cả (Price Shock vs Bargain)
	var raw_base: Variant = item.get("base_price")
	var safe_base_price: int = int(raw_base) if raw_base != null and int(raw_base) > 0 else (item.wholesale_cost * 2)
	var price_ratio: float = float(item.retail_price) / float(maxi(500, safe_base_price))
	var weather_match: bool = (
		(GameManager.current_weather == "Sunny" and item.weather_boost == "Sunny")
		or (GameManager.current_weather == "Rainy" and item.weather_boost == "Rainy")
		or (GameManager.is_rush_hour and item.weather_boost == "SchoolRush")
	)

	# Khả năng chê đắt bỏ đi khi giá bán lẻ cao hơn giá chuẩn
	if price_ratio > 1.05 and not is_greeted:
		var overprice_chance: float = (price_ratio - 1.0) * 0.85 * price_sensitivity
		if weather_match:
			overprice_chance *= 0.65 # Cần gấp theo thời tiết nên đỡ kén giá hơn
		if randf() < overprice_chance:
			mood_text = "Đắt quá! Khỏi mua!"
			mood_color = STAMP_RED
			GameManager.daily_customers_left += 1
			if price_ratio >= 1.4:
				EconomyManager.add_reputation(-1)
				EventBus.toast_requested.emit("%s chê %s bán giá quá đắt (%sđ) nên bỏ về (-1 Tình làng)!" % [
					customer_name, item.display_name, EconomyManager.format_vnd(item.retail_price)
				], STAMP_RED)
			else:
				EventBus.toast_requested.emit("%s thấy %s hơi đắt (%sđ) nên đặt xuống không mua." % [
					customer_name, item.display_name, EconomyManager.format_vnd(item.retail_price)
				], Color("#D96B43"))
			_start_leaving()
			return

	# 3. Tâm lý "Chỉ xem chơi / Đắn đo túi tiền rồi đổi ý không mua" (Window Shopper)
	var hesitate_chance: float = 0.42 if initial_intent == "window_shop" else 0.14
	if price_ratio < 0.95:
		hesitate_chance *= 0.25 # Đang giảm giá rẻ nên rất ít ai bỏ qua
	if weather_match:
		hesitate_chance *= 0.40
	if is_greeted:
		hesitate_chance = 0.0 # Đã được chủ quán tư vấn niềm nở thì chốt mua luôn!

	if randf() < hesitate_chance:
		var excuses: Array[String] = [
			"Thôi để dành tiền mai mua...",
			"Ngắm tí thôi chứ chưa cần!",
			"Nay quên mang đủ tiền lẻ rồi..."
		]
		mood_text = excuses.pick_random()
		mood_color = Color("#7A5C48")
		EventBus.toast_requested.emit("%s đứng ngắm %s một hồi rồi đổi ý chưa mua hôm nay." % [customer_name, item.display_name], Color("#7A5C48"))
		_start_leaving()
		return

	# 4. Tâm lý Mua Ngẫu Hứng / Mua Thêm (Impulse Buy khi giá tốt hoặc đúng thời tiết)
	if (weather_match or price_ratio <= 0.90 or is_greeted) and randf() < 0.35:
		wanted_qty = mini(3, wanted_qty + 1)
		mood_text = "Ưng quá lấy %d món!" % wanted_qty

	# 5. Lấy hàng khỏi kệ và ra xếp hàng thu ngân
	var taken: int = 0
	for i in range(wanted_qty):
		if target_shelf.take_one_item():
			taken += 1
	wanted_qty = maxi(1, taken)
	state = State.WALKING_TO_CASHIER
	_update_cashier_slot_waypoint()

func _update_cashier_slot_waypoint() -> void:
	# Tính vị trí đứng xếp hàng ngăn nắp theo thứ tự, không bao giờ chồng đè lên nhau
	var my_idx: int = 0
	if get_parent():
		for sibling in get_parent().get_children():
			if sibling == self:
				break
			if sibling is CustomerEntity:
				var sc: CustomerEntity = sibling as CustomerEntity
				if sc.state in [State.WALKING_TO_CASHIER, State.WAITING_AT_CASHIER]:
					my_idx += 1
	queue_index = my_idx
	var target_slot := cashier_point + Vector2(my_idx * 64.0, (my_idx % 2) * 10.0)
	if state == State.WALKING_TO_CASHIER:
		waypoints = [target_slot]
	elif state == State.WAITING_AT_CASHIER and position.distance_to(target_slot) > 6.0:
		waypoints = [target_slot]

func _on_reached_cashier() -> void:
	state = State.WAITING_AT_CASHIER
	if GameManager.auto_cashier_enabled:
		complete_checkout("exact")
	else:
		EventBus.customer_waiting_at_checkout.emit(self)

func _abandon_queue_and_leave() -> void:
	# Khách hết kiên nhẫn vì chờ thu ngân quá lâu -> Trả lại hàng vào kệ và bỏ về!
	if is_instance_valid(target_shelf):
		target_shelf.current_stock = mini(target_shelf.max_capacity, target_shelf.current_stock + wanted_qty)
		target_shelf.queue_redraw()
	mood_text = "Đợi lâu quá, thôi khỏi mua!"
	mood_color = STAMP_RED
	EconomyManager.add_reputation(-2)
	GameManager.daily_customers_left += 1
	EventBus.toast_requested.emit("%s đợi tính tiền quá lâu nên đã trả lại hàng và bỏ về (-2 Tình làng)!" % customer_name, STAMP_RED)
	_start_leaving()
	EventBus.checkout_resolved.emit(self, "abandoned")

func complete_checkout(method: String) -> void:
	if state != State.WAITING_AT_CASHIER:
		return
	var item: ItemData = EconomyManager.item_catalog.get(wanted_item_id)
	var unit_price: int = item.retail_price if item else 2000
	var total_bill: int = unit_price * wanted_qty

	match method:
		"exact":
			GameManager.play_sfx("cash_coin")
			EconomyManager.add_money(total_bill)
			EconomyManager.add_reputation(1)
			mood_text = "+%sđ" % EconomyManager.format_vnd(total_bill)
			mood_color = SAGE_GREEN
		"candy":
			GameManager.play_sfx("candy_jar")
			if EconomyManager.use_candy_for_change():
				EconomyManager.add_money(total_bill)
				EconomyManager.add_reputation(2)
				mood_text = "Thích kẹo +2"
				mood_color = Color("#D96B43")
				EventBus.toast_requested.emit("%s rất vui khi được thối thêm kẹo (+2 Tình làng)!" % customer_name, Color("#E5A93C"))
			else:
				EconomyManager.add_money(total_bill)
				mood_text = "+%sđ" % EconomyManager.format_vnd(total_bill)
		"credit":
			GameManager.play_sfx("rubber_stamp")
			var item_name: String = item.display_name if item else "Hàng tạp hóa"
			EconomyManager.add_debt_record(
				customer_name,
				customer_role,
				total_bill,
				"Mua %d %s (Ghi sổ nợ)" % [wanted_qty, item_name],
				shirt_color
			)
			EconomyManager.add_reputation(3)
			mood_text = "Cảm ơn bà chủ +3"
			mood_color = SAGE_GREEN
			EventBus.toast_requested.emit("Đã ghi sổ nợ cho %s (%s đ) +3 Tình làng nghĩa xóm!" % [customer_name, EconomyManager.format_vnd(total_bill)], SAGE_GREEN)

	GameManager.daily_customers_served += 1
	_start_leaving()
	EventBus.checkout_resolved.emit(self, method)

func get_total_bill() -> int:
	var item: ItemData = EconomyManager.item_catalog.get(wanted_item_id)
	var unit_price: int = item.retail_price if item else 2000
	return unit_price * wanted_qty

func _draw() -> void:
	var is_moving: bool = state in [State.STROLLING_SIDEWALK, State.WALKING_TO_SHELF, State.WALKING_TO_CASHIER, State.LEAVING] and not waypoints.is_empty()
	var bob: float = abs(sin(walk_bob_time)) * -4.0 if is_moving else 0.0

	# 1. Bóng đổ màu nước dưới chân
	draw_circle(Vector2(0, 2), 15.0, Color(0.18, 0.14, 0.11, 0.18))

	# 2. Vẽ nhân vật Chibi màu nước
	var c_tex: Texture2D = char_textures.get(sprite_key)
	var char_rect := Rect2(-26, -78 + bob, 52, 82)
	if c_tex != null:
		draw_texture_rect(c_tex, char_rect, false)

	# 3. Vẽ thanh độ kiên nhẫn (Patience Bar) khi đang đứng chờ thu ngân
	if state == State.WAITING_AT_CASHIER and not GameManager.auto_cashier_enabled:
		var ratio: float = clampf(patience_left / max(1.0, patience_max), 0.0, 1.0)
		var bar_bg := Rect2(-22, 6, 44, 5)
		var bar_fg := Rect2(-21, 7, 42 * ratio, 3)
		var p_col: Color = SAGE_GREEN if ratio > 0.5 else (Color("#E5A93C") if ratio > 0.25 else STAMP_RED)
		draw_rect(bar_bg, PAPER_CREAM, true)
		draw_rect(bar_fg, p_col, true)
		draw_rect(bar_bg, INK_COLOR, false, 1.0)

	# 4. Vẽ Bong Bóng Thoại & Tâm Lý trên đầu (To rõ chuẩn Mobile 14px, Icon 22x22)
	var item: ItemData = EconomyManager.item_catalog.get(wanted_item_id)
	var icon_to_draw: Texture2D = null
	var badge_text: String = ""

	match state:
		State.STROLLING_SIDEWALK:
			badge_text = "Ngó tiệm..."
		State.SITTING_AT_TEA_TABLE:
			badge_text = "Uống trà đá" if waypoints.is_empty() else "Ghé trà đá..."
		State.WALKING_TO_SHELF:
			if item != null:
				icon_to_draw = item.icon
		State.BROWSING_AT_SHELF:
			if item != null:
				icon_to_draw = item.icon
			badge_text = "Đắn đo..." if initial_intent == "window_shop" else "Xem giá..."
		State.WALKING_TO_CASHIER:
			if item != null:
				icon_to_draw = item.icon
		State.WAITING_AT_CASHIER:
			var ratio: float = patience_left / max(1.0, patience_max)
			if ratio < 0.35:
				icon_to_draw = tex_money
				badge_text = "Lẹ giúp!"
			elif queue_index == 0:
				# Chỉ người đứng ĐẦU HÀNG mới hiện chữ "Tính tiền!" để không bao giờ bị đè bong bóng!
				icon_to_draw = tex_money
				badge_text = "Tính tiền!"
			else:
				icon_to_draw = item.icon if item != null else tex_money
		State.LEAVING:
			badge_text = mood_text

	if icon_to_draw != null or badge_text != "":
		var font: Font = ThemeDB.fallback_font
		var b_rect: Rect2
		if badge_text == "":
			b_rect = Rect2(-24, -120 + bob, 48, 36)
		else:
			var text_w: float = max(84.0, float(badge_text.length()) * 7.8 + (32.0 if icon_to_draw != null else 18.0))
			b_rect = Rect2(-text_w * 0.5, -120 + bob, text_w, 36)

		if tex_bubble != null:
			draw_texture_rect(tex_bubble, b_rect, false)
		else:
			draw_rect(b_rect, PAPER_CREAM, true)
			draw_rect(b_rect, INK_COLOR, false, 1.5)

		if badge_text == "" and icon_to_draw != null:
			draw_texture_rect(icon_to_draw, Rect2(-12, -114 + bob, 24, 22), false)
		else:
			var text_x: float = b_rect.position.x + 10.0
			if icon_to_draw != null:
				draw_texture_rect(icon_to_draw, Rect2(b_rect.position.x + 6, b_rect.position.y + 5, 22, 22), false)
				text_x = b_rect.position.x + 31.0
			draw_string(
				font,
				Vector2(text_x, b_rect.position.y + 22),
				badge_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				mood_color if state == State.LEAVING else INK_COLOR
			)
