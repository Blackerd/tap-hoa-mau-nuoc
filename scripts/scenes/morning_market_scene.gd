extends Control
class_name MorningMarketScene

const TEX_CARD_BROWN: Texture2D = preload("res://assets/sprites/ui/ui_card_brown.png")
const TEX_CARD_RED: Texture2D = preload("res://assets/sprites/ui/ui_card_red_tape.png")
const TEX_BTN_GREEN: Texture2D = preload("res://assets/sprites/ui/ui_btn_green.png")
const TEX_BTN_YELLOW: Texture2D = preload("res://assets/sprites/ui/ui_btn_yellow.png")
const TEX_BTN_CREAM: Texture2D = preload("res://assets/sprites/ui/ui_btn_cream.png")
const TEX_BG_STORE: Texture2D = preload("res://assets/art/bg_store_ortho.jpg")

var header_title_lbl: Label
var stats_lbl: Label
var weather_lbl: Label
var discount_lbl: Label
var feedback_lbl: Label
var items_grid: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameManager.current_phase = GameManager.StorePhase.MORNING_PREP
	_build_ui()
	_connect_signals()
	_refresh_all()
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)


func _connect_signals() -> void:
	EventBus.money_changed.connect(func(_v: int, _d: int) -> void: _refresh_stats())
	EventBus.reputation_changed.connect(func(_v: int, _d: int) -> void: _refresh_stats())
	EventBus.candy_jar_changed.connect(func(_v: int) -> void: _refresh_stats())
	EventBus.inventory_updated.connect(func() -> void: _refresh_items_grid())
	EventBus.toast_requested.connect(_on_toast_requested)


func _make_card_style(tex: Texture2D, pad_h: int = 16, pad_v: int = 12) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 18
	sb.texture_margin_right = 18
	sb.texture_margin_top = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


func _make_btn_style(tex: Texture2D, modulate_col: Color = Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 14
	sb.texture_margin_right = 14
	sb.texture_margin_top = 8
	sb.texture_margin_bottom = 8
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.modulate_color = modulate_col
	return sb


func _style_button(btn: Button, tex: Texture2D, font_size: int = 13) -> void:
	btn.add_theme_stylebox_override("normal", _make_btn_style(tex, Color.WHITE))
	btn.add_theme_stylebox_override("hover", _make_btn_style(tex, Color(1.06, 1.04, 0.98)))
	btn.add_theme_stylebox_override("pressed", _make_btn_style(tex, Color(0.92, 0.9, 0.85)))
	btn.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	btn.add_theme_color_override("font_hover_color", Color(0.78, 0.29, 0.19))
	btn.add_theme_color_override("font_pressed_color", Color(0.22, 0.16, 0.1))
	btn.add_theme_font_size_override("font_size", font_size)


func _build_ui() -> void:
	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.95, 0.91, 0.83, 1.0)
	add_child(bg_rect)

	var bg_art := TextureRect.new()
	bg_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_art.texture = TEX_BG_STORE
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.modulate = Color(1.0, 0.96, 0.9, 0.22)
	add_child(bg_art)

	var main_margin := MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 28)
	main_margin.add_theme_constant_override("margin_right", 28)
	main_margin.add_theme_constant_override("margin_top", 14)
	main_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(main_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)
	main_margin.add_child(root_vbox)

	# 1. Top Header Bar
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 18, 10))
	root_vbox.add_child(top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 16)
	top_panel.add_child(top_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	top_hbox.add_child(title_vbox)

	header_title_lbl = Label.new()
	header_title_lbl.add_theme_color_override("font_color", Color(0.78, 0.29, 0.19))
	header_title_lbl.add_theme_font_size_override("font_size", 19)
	title_vbox.add_child(header_title_lbl)

	stats_lbl = Label.new()
	stats_lbl.add_theme_color_override("font_color", Color(0.18, 0.45, 0.22))
	stats_lbl.add_theme_font_size_override("font_size", 14)
	title_vbox.add_child(stats_lbl)

	var btn_menu := Button.new()
	btn_menu.text = "📖 Bìa Sổ Ký Ức (Menu)"
	btn_menu.custom_minimum_size = Vector2(185, 38)
	_style_button(btn_menu, TEX_BTN_CREAM, 13)
	btn_menu.pressed.connect(func() -> void:
		GameManager.save_game()
		GameManager.change_to_phase_scene(GameManager.StorePhase.STORY_INTRO)
	)
	top_hbox.add_child(btn_menu)

	# 2. Forecast & Daily Market Deal Strip
	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(info_hbox)

	var weather_card := PanelContainer.new()
	weather_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weather_card.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 14, 8))
	info_hbox.add_child(weather_card)

	weather_lbl = Label.new()
	weather_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weather_lbl.add_theme_color_override("font_color", Color(0.22, 0.16, 0.1))
	weather_lbl.add_theme_font_size_override("font_size", 13)
	weather_card.add_child(weather_lbl)

	var discount_card := PanelContainer.new()
	discount_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	discount_card.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_RED, 14, 8))
	info_hbox.add_child(discount_card)

	discount_lbl = Label.new()
	discount_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	discount_lbl.add_theme_color_override("font_color", Color(0.55, 0.18, 0.12))
	discount_lbl.add_theme_font_size_override("font_size", 13)
	discount_card.add_child(discount_lbl)

	# 3. Main Wholesale Stalls Grid (Scrollable)
	var market_card := PanelContainer.new()
	market_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_card.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 16, 12))
	root_vbox.add_child(market_card)

	var market_vbox := VBoxContainer.new()
	market_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_vbox.add_theme_constant_override("separation", 8)
	market_card.add_child(market_vbox)

	var section_hdr := HBoxContainer.new()
	section_hdr.add_theme_constant_override("separation", 12)
	market_vbox.add_child(section_hdr)

	var sec_lbl := Label.new()
	sec_lbl.text = "🚲 SẠP HÀNG CHỢ SỈ ĐẦU HẺM & BẢNG GIÁ BÁN LẺ HÔM NAY"
	sec_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec_lbl.add_theme_color_override("font_color", Color(0.26, 0.17, 0.09))
	sec_lbl.add_theme_font_size_override("font_size", 15)
	section_hdr.add_child(sec_lbl)

	feedback_lbl = Label.new()
	feedback_lbl.text = "💡 Nhập hàng phù hợp thời tiết & bấm 'Châm Đầy Các Kệ' trước khi mở cửa!"
	feedback_lbl.add_theme_color_override("font_color", Color(0.2, 0.42, 0.24))
	feedback_lbl.add_theme_font_size_override("font_size", 13)
	section_hdr.add_child(feedback_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_vbox.add_child(scroll)

	items_grid = GridContainer.new()
	items_grid.columns = 2
	items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_grid.add_theme_constant_override("h_separation", 12)
	items_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(items_grid)

	# 4. Bottom Action Bar
	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 16, 10))
	root_vbox.add_child(bottom_panel)

	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 14)
	bottom_panel.add_child(bottom_hbox)

	var btn_restock_all := Button.new()
	btn_restock_all.text = "✨ Châm Đầy Hàng Lên Các Kệ Trong Quán"
	btn_restock_all.custom_minimum_size = Vector2(280, 42)
	_style_button(btn_restock_all, TEX_BTN_YELLOW, 14)
	btn_restock_all.pressed.connect(_on_restock_all_pressed)
	bottom_hbox.add_child(btn_restock_all)

	var btn_candy := Button.new()
	btn_candy.text = "🍬 Mua Hũ Kẹo Lẻ (+10 viên | -3.000đ)"
	btn_candy.custom_minimum_size = Vector2(260, 42)
	_style_button(btn_candy, TEX_BTN_CREAM, 14)
	btn_candy.pressed.connect(func() -> void: EconomyManager.refill_candy_jar())
	bottom_hbox.add_child(btn_candy)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)

	var btn_open_store := Button.new()
	btn_open_store.text = "🔓 Kéo Cửa Mở Hàng Đón Khách (07:00 Sáng) ➔"
	btn_open_store.custom_minimum_size = Vector2(340, 44)
	_style_button(btn_open_store, TEX_BTN_GREEN, 15)
	btn_open_store.pressed.connect(_on_open_store_pressed)
	bottom_hbox.add_child(btn_open_store)


func _refresh_all() -> void:
	_refresh_stats()
	_refresh_weather_and_discount()
	_refresh_items_grid()


func _refresh_stats() -> void:
	if header_title_lbl:
		header_title_lbl.text = "🌅 06:00 SÁNG NGÀY %d — ĐI CHỢ SỈ & SOẠN QUẦY [%s]" % [
			GameManager.current_day,
			GameManager.store_name
		]
	if stats_lbl:
		stats_lbl.text = "👤 Chủ tiệm: %s  |  💰 Vốn quán: %s đ  |  ♥ Tình làng xóm: %d  |  🍬 Hũ kẹo: %d viên" % [
			GameManager.player_name,
			EconomyManager.format_vnd(EconomyManager.money),
			EconomyManager.reputation,
			EconomyManager.candy_jar
		]


func _refresh_weather_and_discount() -> void:
	if weather_lbl:
		weather_lbl.text = GameManager.get_weather_forecast_advice()
	if discount_lbl:
		var disc_id: String = GameManager.daily_discount_item_id
		var disc_item: ItemData = EconomyManager.item_catalog.get(disc_id)
		if disc_item != null:
			var orig_cost: int = disc_item.wholesale_cost
			var sale_cost: int = EconomyManager.get_effective_wholesale_cost(disc_id)
			discount_lbl.text = "🏷️ KHUYẾN MÃI CHỢ SỈ HÔM NAY (-25%%):\nSạp [%s] giảm giá sỉ từ %sđ ➔ chỉ còn %sđ/món!" % [
				disc_item.display_name,
				EconomyManager.format_vnd(orig_cost),
				EconomyManager.format_vnd(sale_cost)
			]
		else:
			discount_lbl.text = "🏷️ Chợ sỉ sáng nay giá ổn định cho mọi mặt hàng."


func _get_shelf_stock_for_item(item_id: String) -> int:
	var total: int = 0
	for s in GameManager.saved_shelves:
		if str(s.get("item_id", "")) == item_id:
			total += int(s.get("stock", 0))
	return total


func _refresh_items_grid() -> void:
	if items_grid == null:
		return
	for child in items_grid.get_children():
		child.queue_free()

	for item_id in EconomyManager.item_catalog.keys():
		var item: ItemData = EconomyManager.item_catalog[item_id]
		var stock: int = int(EconomyManager.warehouse_stock.get(item_id, 0))
		var shelf_stock: int = _get_shelf_stock_for_item(item_id)
		var retail_price: int = item.retail_price
		var unit_wholesale: int = EconomyManager.get_effective_wholesale_cost(item_id)
		var is_discounted: bool = (GameManager.daily_discount_item_id == item_id)

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_tex: Texture2D = TEX_CARD_RED if is_discounted else TEX_CARD_BROWN
		card.add_theme_stylebox_override("panel", _make_card_style(card_tex, 14, 10))
		items_grid.add_child(card)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		if item.icon != null:
			var icon_rect := TextureRect.new()
			icon_rect.texture = item.icon
			icon_rect.custom_minimum_size = Vector2(46, 46)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(icon_rect)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		hbox.add_child(info_vbox)

		var name_lbl := Label.new()
		var sale_badge: String = " 🔥[-25% SỈ]" if is_discounted else ""
		name_lbl.text = "%s%s  |  Kho: %d  |  Trên kệ: %d" % [
			item.display_name,
			sale_badge,
			stock,
			shelf_stock
		]
		name_lbl.add_theme_color_override("font_color", Color(0.22, 0.14, 0.07))
		name_lbl.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(name_lbl)

		var raw_base: Variant = item.get("base_price")
		var safe_base: int = int(raw_base) if raw_base != null and int(raw_base) > 0 else (item.wholesale_cost * 2)
		var mood_tag: String = "👌 Giá chuẩn"
		if retail_price < safe_base:
			mood_tag = "💚 Giá rẻ hút khách"
		elif retail_price > safe_base:
			mood_tag = "⚠️ Giá cao (Dễ bị chê)"

		var price_lbl := Label.new()
		var profit_per_unit: int = retail_price - unit_wholesale
		price_lbl.text = "Giá sỉ: %sđ  |  Bán lẻ: %sđ (Lời +%sđ) [%s]" % [
			EconomyManager.format_vnd(unit_wholesale),
			EconomyManager.format_vnd(retail_price),
			EconomyManager.format_vnd(profit_per_unit),
			mood_tag
		]
		price_lbl.add_theme_color_override("font_color", Color(0.18, 0.44, 0.22))
		price_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(price_lbl)

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		info_vbox.add_child(btn_row)

		var cost8: int = unit_wholesale * 8
		var btn_buy8 := Button.new()
		btn_buy8.text = "+8 (%sđ)" % EconomyManager.format_vnd(cost8)
		_style_button(btn_buy8, TEX_BTN_GREEN, 12)
		var iid: String = str(item_id)
		btn_buy8.pressed.connect(func() -> void: EconomyManager.buy_wholesale_pack(iid, 8))
		btn_row.add_child(btn_buy8)

		var cost16: int = unit_wholesale * 16
		var btn_buy16 := Button.new()
		btn_buy16.text = "+16 (%sđ)" % EconomyManager.format_vnd(cost16)
		_style_button(btn_buy16, TEX_BTN_GREEN, 12)
		btn_buy16.pressed.connect(func() -> void: EconomyManager.buy_wholesale_pack(iid, 16))
		btn_row.add_child(btn_buy16)

		var btn_minus := Button.new()
		btn_minus.text = "Giá -500đ"
		_style_button(btn_minus, TEX_BTN_CREAM, 12)
		btn_minus.pressed.connect(func() -> void: EconomyManager.adjust_item_price(iid, -500))
		btn_row.add_child(btn_minus)

		var btn_plus := Button.new()
		btn_plus.text = "Giá +500đ"
		_style_button(btn_plus, TEX_BTN_CREAM, 12)
		btn_plus.pressed.connect(func() -> void: EconomyManager.adjust_item_price(iid, 500))
		btn_row.add_child(btn_plus)


func _on_restock_all_pressed() -> void:
	var added: int = GameManager.restock_all_saved_shelves_from_warehouse()
	if added > 0:
		_on_toast_requested("✨ Đã châm thêm %d món hàng từ Kho lên các kệ trong quán!" % added, Color("#6B8E78"))
	else:
		_on_toast_requested("📦 Các kệ trong quán đã đầy hoặc Kho đã hết mặt hàng tương ứng!", Color("#C84B31"))
	_refresh_items_grid()


func _on_open_store_pressed() -> void:
	GameManager.restock_all_saved_shelves_from_warehouse()
	GameManager.open_store_for_day()


func _on_toast_requested(msg: String, _color: Color) -> void:
	if feedback_lbl:
		feedback_lbl.text = msg
