@tool
class_name StoreWorld
extends Node2D

const GRID_COLS: int = 10
const GRID_ROWS: int = 5
const CELL_SIZE := Vector2(71.7, 78.3)
const GRID_ORIGIN := Vector2(435.0, 231.0)

const ENTRY_POINT := Vector2(220.0, 675.0)
const STORE_DOOR_SIDEWALK := Vector2(688.0, 672.0)
const CASHIER_POS := Vector2(618.0, 582.0)
const EXIT_POINT := Vector2(1320.0, 675.0)

const INK_COLOR := Color("#2C221E")

var bg_texture: Texture2D = preload("res://assets/art/bg_store_ortho.jpg")
var tex_cashier_desk: Texture2D = preload("res://assets/sprites/furniture/cashier_desk.png")
var tex_shopkeeper: Texture2D = preload("res://assets/sprites/characters/char_shopkeeper.png")
var astar_grid := AStarGrid2D.new()
var shelves_by_cell: Dictionary = {} # Vector2i -> ShelfEntity
var hovered_cell: Vector2i = Vector2i(-1, -1)

var is_build_mode: bool = false
var selected_furniture_id: String = "wooden_shelf"

var _spawn_timer: float = 2.0
var _rain_particles: Array[Vector2] = []

@onready var entities_container: Node2D = $YSortEntities
@onready var reveal_overlay: ColorRect = $WatercolorRevealMask

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	_setup_astar_grid()
	_spawn_starter_shelves()
	_init_rain_particles()

	EventBus.build_mode_toggled.connect(_on_build_mode_toggled)
	EventBus.store_level_changed.connect(_on_store_level_changed)
	EventBus.weather_changed.connect(func(_w: String, _l: String) -> void: queue_redraw())
	EventBus.store_phase_changed.connect(_on_store_phase_changed)

func _on_store_phase_changed(new_phase: String) -> void:
	if new_phase != "OPEN_FOR_BUSINESS":
		for child in entities_container.get_children():
			if child is CustomerEntity:
				child.queue_free()
	queue_redraw()

func _setup_astar_grid() -> void:
	astar_grid.region = Rect2i(0, 0, GRID_COLS, GRID_ROWS)
	astar_grid.cell_size = CELL_SIZE
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	# Khóa cứng vùng Quầy Thu Ngân & Bà Chủ Quán (Cột 0..1, Hàng 3..4) để NPC KHÔNG BAO GIỜ đi xuyên qua bàn thu ngân!
	for cx in range(0, 2):
		for cy in range(3, GRID_ROWS):
			astar_grid.set_point_solid(Vector2i(cx, cy), true)

func _spawn_starter_shelves() -> void:
	if reveal_overlay and reveal_overlay.material is ShaderMaterial:
		var mat: ShaderMaterial = reveal_overlay.material
		mat.set_shader_parameter("reveal_radius", GameManager.get_reveal_radius())

	if GameManager.saved_shelves.is_empty():
		GameManager._init_default_shelves()

	var initial_list: Array[Dictionary] = GameManager.saved_shelves.duplicate(true)
	for entry in initial_list:
		var cx: int = int(entry.get("x", 1))
		var cy: int = int(entry.get("y", 1))
		var fid: String = str(entry.get("furn_id", "wooden_shelf"))
		var iid: String = str(entry.get("item_id", "mi_tre_em"))
		var stk: int = int(entry.get("stock", 8))
		place_shelf_at(Vector2i(cx, cy), fid, iid, stk, true)

func sync_shelves_to_game_manager() -> void:
	var list: Array[Dictionary] = []
	for cell_key in shelves_by_cell:
		var s: ShelfEntity = shelves_by_cell[cell_key]
		if is_instance_valid(s):
			list.append({
				"x": s.grid_cell.x,
				"y": s.grid_cell.y,
				"furn_id": s.furniture_id,
				"item_id": s.item_id,
				"stock": s.current_stock
			})
	GameManager.saved_shelves = list

func _init_rain_particles() -> void:
	for i in range(48):
		_rain_particles.append(Vector2(randf_range(120.0, 1480.0), randf_range(60.0, 760.0)))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_handle_customer_spawning(delta)
	if GameManager.current_weather == "Rainy":
		for i in range(_rain_particles.size()):
			_rain_particles[i] += Vector2(-95.0, 340.0) * delta
			if _rain_particles[i].y > 780.0:
				_rain_particles[i] = Vector2(randf_range(160.0, 1520.0), randf_range(50.0, 120.0))
	queue_redraw()

func _handle_customer_spawning(delta: float) -> void:
	if GameManager.current_phase != GameManager.StorePhase.OPEN_FOR_BUSINESS:
		return

	var active_customers: int = 0
	for child in entities_container.get_children():
		if child is CustomerEntity:
			active_customers += 1

	# Nhịp sống ngõ nhỏ theo khung giờ (không phải lúc nào cũng đông nghịt khách!)
	var hr: int = GameManager.current_hour
	var is_quiet_school_hours: bool = (hr >= 9 and hr <= 10) or (hr >= 14 and hr <= 15)
	var max_allowed: int = 4 if GameManager.is_rush_hour else (2 if is_quiet_school_hours else 3)
	if active_customers >= max_allowed:
		return

	var base_interval: float = 7.5 - float(GameManager.store_level) * 0.6
	if GameManager.is_rush_hour:
		base_interval = 3.2
	elif is_quiet_school_hours:
		base_interval = randf_range(9.5, 13.5) # Khoảng lặng trưa/chiều vắng khách đời thường

	_spawn_timer -= delta * GameManager.time_speed_multiplier
	if _spawn_timer <= 0.0:
		_spawn_timer = base_interval
		spawn_customer()

func spawn_customer() -> void:
	if shelves_by_cell.is_empty():
		return

	var candidate_shelves: Array = shelves_by_cell.values()
	var chosen_shelf: ShelfEntity = candidate_shelves.pick_random()
	for s: ShelfEntity in candidate_shelves:
		var item: ItemData = EconomyManager.item_catalog.get(s.item_id)
		if item and s.current_stock > 0:
			if GameManager.is_rush_hour and item.weather_boost == "SchoolRush" and randf() < 0.75:
				chosen_shelf = s
				break
			elif GameManager.current_weather == "Rainy" and item.weather_boost == "Rainy" and randf() < 0.8:
				chosen_shelf = s
				break
			elif GameManager.current_weather == "Sunny" and item.weather_boost == "Sunny" and randf() < 0.65:
				chosen_shelf = s
				break

	var profiles: Array[Dictionary] = [
		{"name": "Bé Nam (Lớp 5A)", "role": "Học trò đầu ngõ", "color": Color("#E5A93C"), "sprite": "schoolboy", "sens": 0.9, "patience": 15.0, "is_kid": true},
		{"name": "Bé Linh Khăn Đỏ", "role": "Học sinh tiểu học", "color": Color("#D96B43"), "sprite": "schoolgirl", "sens": 0.9, "patience": 16.0, "is_kid": true},
		{"name": "Anh Tuấn Kiến Trúc", "role": "Sinh viên thuê trọ", "color": Color("#5B84B1"), "sprite": "student", "sens": 1.35, "patience": 22.0, "is_kid": false},
		{"name": "Bác Tư Hàng Xóm", "role": "Khách quen trong xóm", "color": Color("#6B8E78"), "sprite": "uncle", "sens": 1.15, "patience": 24.0, "is_kid": false},
		{"name": "Cô Hoa Đầu Ngõ", "role": "Nội trợ", "color": Color("#B87D95"), "sprite": "auntie", "sens": 1.50, "patience": 19.0, "is_kid": false}
	]

	var hr: int = GameManager.current_hour
	var in_class_hours: bool = (hr >= 8 and hr <= 10) or (hr >= 14 and hr <= 15)
	var prof: Dictionary
	if GameManager.is_rush_hour and randf() < 0.72:
		prof = profiles[0] if randf() < 0.5 else profiles[1]
	elif in_class_hours:
		# Trong giờ học trên trường: chỉ người lớn / sinh viên đi lại trong ngõ
		var adult_profiles: Array[Dictionary] = [profiles[2], profiles[3], profiles[4]]
		prof = adult_profiles.pick_random()
	else:
		prof = profiles.pick_random()

	# Quyết định ý định tâm lý ban đầu (Không phải ai đi qua cũng vào mua ngay!)
	var intent: String = "shop"
	var roll: float = randf()
	if GameManager.is_rush_hour:
		intent = "window_shop" if roll < 0.18 else "shop"
	elif in_class_hours:
		if roll < 0.30:
			intent = "passerby" # Đi bộ ngang qua vỉa hè (Bấm vào khách để chào mời!)
		elif roll < 0.52 and prof["sprite"] in ["uncle", "student"]:
			intent = "tea_break" # Ghé bàn trà đá gốc đa ngồi hóng gió
		elif roll < 0.75:
			intent = "window_shop" # Vào ngó giá đắn đo
		else:
			intent = "shop"
	else:
		if roll < 0.16:
			intent = "passerby"
		elif roll < 0.32 and prof["sprite"] in ["uncle", "student"] and GameManager.current_weather != "Rainy":
			intent = "tea_break"
		elif roll < 0.50:
			intent = "window_shop"
		else:
			intent = "shop"

	var target_cell: Vector2i = chosen_shelf.grid_cell
	var stand_cell := Vector2i(target_cell.x, mini(GRID_ROWS - 1, target_cell.y + 1))
	# Lối vào chính diện tiệm nằm ở Cột 3, Hàng 4 (bên phải Quầy Thu Ngân, không bao giờ cắt ngang bàn thu ngân!)
	var start_cell := Vector2i(3, GRID_ROWS - 1)
	var id_path: Array[Vector2i] = astar_grid.get_id_path(start_cell, stand_cell)

	# Đi bộ dọc vỉa hè tới cửa tiệm (STORE_DOOR_SIDEWALK) rồi mới bước vào sàn gạch trong quán
	var world_waypoints: Array[Vector2] = [STORE_DOOR_SIDEWALK]
	for cell in id_path:
		world_waypoints.append(cell_to_world(cell) + Vector2(0, 14))
	if world_waypoints.size() == 1:
		world_waypoints.append(cell_to_world(target_cell) + Vector2(0, 22))

	var customer := CustomerEntity.new()
	customer.position = ENTRY_POINT
	entities_container.add_child(customer)
	customer.setup_customer(
		prof["name"],
		prof["role"],
		prof["color"],
		chosen_shelf.item_id,
		chosen_shelf,
		world_waypoints,
		CASHIER_POS,
		EXIT_POINT,
		prof["sprite"],
		intent,
		prof["sens"],
		prof["patience"]
	)

func place_shelf_at(cell: Vector2i, furn_id: String, item_id: String, initial_stock: int, is_free_starter: bool = false) -> bool:
	if not is_valid_cell(cell) or shelves_by_cell.has(cell):
		return false
	if cell.x <= 1 and cell.y >= GRID_ROWS - 1:
		EventBus.toast_requested.emit("Ô này là lối đứng Quầy Thu Ngân!", Color("#C84B31"))
		return false

	var furn: FurnitureData = EconomyManager.furniture_catalog.get(furn_id)
	if furn == null:
		return false

	if not is_free_starter:
		if not EconomyManager.spend_money(furn.cost):
			EventBus.toast_requested.emit("Không đủ tiền đóng kệ mới (Cần %s đ)!" % EconomyManager.format_vnd(furn.cost), Color("#C84B31"))
			return false

	var shelf := ShelfEntity.new()
	shelf.position = cell_to_world(cell)
	entities_container.add_child(shelf)
	shelf.setup(cell, furn, item_id, initial_stock)
	shelf.play_bounce()

	shelves_by_cell[cell] = shelf
	astar_grid.set_point_solid(cell, true)
	sync_shelves_to_game_manager()

	if not is_free_starter:
		GameManager.save_game()
		EventBus.toast_requested.emit("🔨 Đã đặt %s! Chạm 1 lần để châm hàng, Chạm đúp (2 lần) để đổi món." % furn.display_name, Color("#6B8E78"))
	return true

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion:
		var world_mouse: Vector2 = get_global_mouse_position()
		var cell: Vector2i = world_to_cell(world_mouse)
		hovered_cell = cell if is_valid_cell(cell) else Vector2i(-1, -1)
		for pos_key in shelves_by_cell:
			var s: ShelfEntity = shelves_by_cell[pos_key]
			var hov: bool = (pos_key == hovered_cell)
			if s.is_hovered != hov:
				s.is_hovered = hov
				s.queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		var world_mouse: Vector2 = get_global_mouse_position()

		# Cho phép Chạm / Click trực tiếp vào Khách Hàng để Chào Mời / Tư Vấn Niềm Nở!
		if event.button_index == MOUSE_BUTTON_LEFT and not is_build_mode:
			for child in entities_container.get_children():
				if child is CustomerEntity:
					var cust: CustomerEntity = child as CustomerEntity
					var hit_box := Rect2(cust.position + Vector2(-30, -85), Vector2(60, 90))
					if hit_box.has_point(world_mouse):
						cust.encourage_by_player()
						return

		var cell: Vector2i = world_to_cell(world_mouse)
		if not is_valid_cell(cell):
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_build_mode:
				var furn: FurnitureData = EconomyManager.furniture_catalog.get(selected_furniture_id)
				var def_item: String = furn.default_item_id if furn else "mi_tre_em"
				place_shelf_at(cell, selected_furniture_id, def_item, 6, false)
			elif shelves_by_cell.has(cell):
				var shelf: ShelfEntity = shelves_by_cell[cell]
				# Hỗ trợ Mobile/iPad: Chạm đúp (Double Tap) = Đổi mặt hàng, Chạm 1 lần = Châm hàng
				if event.double_click:
					shelf.cycle_assigned_item()
					var item: ItemData = EconomyManager.item_catalog.get(shelf.item_id)
					if item:
						EventBus.toast_requested.emit("🔄 Đã đổi kệ sang bày bán: %s" % item.display_name, Color("#5B84B1"))
				else:
					shelf.restock_from_warehouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if shelves_by_cell.has(cell):
				var shelf: ShelfEntity = shelves_by_cell[cell]
				shelf.cycle_assigned_item()
				var item: ItemData = EconomyManager.item_catalog.get(shelf.item_id)
				if item:
					EventBus.toast_requested.emit("🔄 Đã đổi kệ sang bày bán: %s" % item.display_name, Color("#5B84B1"))

func _on_build_mode_toggled(active: bool, furn_id: String) -> void:
	is_build_mode = active
	if furn_id != "":
		selected_furniture_id = furn_id
	queue_redraw()

func _on_store_level_changed(_lvl: int, _title: String, target_radius: float) -> void:
	if reveal_overlay and reveal_overlay.material is ShaderMaterial:
		var mat: ShaderMaterial = reveal_overlay.material
		var tw: Tween = create_tween()
		tw.tween_method(
			func(val: float) -> void: mat.set_shader_parameter("reveal_radius", val),
			mat.get_shader_parameter("reveal_radius"),
			target_radius,
			1.2
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS

func cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2((cell.x + 0.5) * CELL_SIZE.x, (cell.y + 0.5) * CELL_SIZE.y)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var rel: Vector2 = world_pos - GRID_ORIGIN
	return Vector2i(floori(rel.x / CELL_SIZE.x), floori(rel.y / CELL_SIZE.y))

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font

	# 1. Vẽ tấm ảnh nền màu nước chính diện bạn vừa tạo (khớp chuẩn 10x5 ô gạch!)
	if bg_texture:
		draw_texture_rect(bg_texture, Rect2(0, 0, 1536, 856.5), false)

	# 1B. Hiển thị Biển Hiệu Tạp Hóa & Tên Chủ Quán do người chơi đặt trên mái hiên
	if not Engine.is_editor_hint():
		if GameManager.store_name != "TẠP HÓA MÀU NƯỚC" and GameManager.store_name != "":
			var sign_rect := Rect2(666, 74, 232, 92)
			draw_rect(sign_rect, Color("#D7B38C"), true)
			draw_rect(sign_rect, INK_COLOR, false, 2.5)
			draw_string(font, Vector2(676, 118), GameManager.store_name, HORIZONTAL_ALIGNMENT_CENTER, 212, 18, INK_COLOR)
			draw_string(font, Vector2(676, 148), "Chủ tiệm: " + GameManager.player_name, HORIZONTAL_ALIGNMENT_CENTER, 212, 13, Color("#7A3E26"))
		else:
			var owner_tag := Rect2(704, 170, 156, 22)
			draw_rect(owner_tag, Color("#FBF8F1"), true)
			draw_rect(owner_tag, INK_COLOR, false, 1.5)
			draw_string(font, Vector2(710, 185), "Chủ tiệm: " + GameManager.player_name, HORIZONTAL_ALIGNMENT_CENTER, 144, 11, INK_COLOR)

	# 2. Quầy Thu Ngân & Bà Chủ Quán màu nước đặt ở góc dưới bên trái sàn quán
	if tex_shopkeeper:
		var sk_size: Vector2 = tex_shopkeeper.get_size()
		var sk_h: float = 70.0
		var sk_w: float = sk_h * (sk_size.x / max(1.0, sk_size.y))
		draw_texture_rect(tex_shopkeeper, Rect2(476.0, 502.0, sk_w, sk_h), false)

	if tex_cashier_desk:
		draw_texture_rect(tex_cashier_desk, Rect2(436.0, 524.0, 132.0, 88.0), false)
	else:
		var desk_rect := Rect2(442, 560, 112, 46)
		draw_rect(desk_rect, Color("#C98A4B"), true)
		draw_rect(desk_rect, INK_COLOR, false, 2.2)
		draw_string(font, Vector2(454, 586), "QUẦY THU NGÂN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FBF8F1"))

	# 3. Preview ô lưới khi bật chế độ Đóng Kệ Mới
	if is_build_mode and is_valid_cell(hovered_cell):
		var cell_top_left := GRID_ORIGIN + Vector2(hovered_cell.x * CELL_SIZE.x, hovered_cell.y * CELL_SIZE.y)
		var can_build: bool = not shelves_by_cell.has(hovered_cell) and not (hovered_cell.x <= 1 and hovered_cell.y >= GRID_ROWS - 1)
		var ghost_col: Color = Color(0.42, 0.56, 0.47, 0.42) if can_build else Color(0.78, 0.29, 0.19, 0.42)
		draw_rect(Rect2(cell_top_left + Vector2(3, 3), CELL_SIZE - Vector2(6, 6)), ghost_col, true)
		draw_rect(Rect2(cell_top_left + Vector2(3, 3), CELL_SIZE - Vector2(6, 6)), INK_COLOR, false, 2.0)

	# 4. Hiệu ứng Thời tiết
	var cur_weather: String = "Sunny" if Engine.is_editor_hint() else GameManager.current_weather
	if cur_weather == "Rainy":
		for drop in _rain_particles:
			draw_line(drop, drop + Vector2(-6, 20), Color(0.35, 0.52, 0.69, 0.52), 1.6)
	elif cur_weather == "Sunny":
		draw_circle(Vector2(1380, 110), 95.0, Color(0.95, 0.72, 0.28, 0.14))
