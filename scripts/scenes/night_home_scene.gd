extends Control
class_name NightHomeScene

const TEX_CARD_BROWN: Texture2D = preload("res://assets/sprites/ui/ui_card_brown.png")
const TEX_CARD_RED: Texture2D = preload("res://assets/sprites/ui/ui_card_red_tape.png")
const TEX_BTN_GREEN: Texture2D = preload("res://assets/sprites/ui/ui_btn_green.png")
const TEX_BTN_YELLOW: Texture2D = preload("res://assets/sprites/ui/ui_btn_yellow.png")
const TEX_BTN_PINK: Texture2D = preload("res://assets/sprites/ui/ui_btn_pink.png")
const TEX_BTN_CREAM: Texture2D = preload("res://assets/sprites/ui/ui_btn_cream.png")
const TEX_BG_STORE: Texture2D = preload("res://assets/art/bg_tiem_ba_ba.jpg")
const ICON_MONEY: Texture2D = preload("res://assets/sprites/items/icon_money.png")
const ICON_HEART: Texture2D = preload("res://assets/sprites/items/icon_heart.png")

var header_title_lbl: Label
var stats_lbl: Label
var diary_lbl: Label
var finance_lbl: Label
var customer_stats_lbl: Label
var feedback_lbl: Label
var btn_upgrade: Button
var debt_vbox: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameManager.current_phase = GameManager.StorePhase.NIGHT_SUMMARY
	GameManager.save_game()
	_build_ui()
	_connect_signals()
	_refresh_all()
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)


func _connect_signals() -> void:
	EventBus.money_changed.connect(func(_v: int, _d: int) -> void: _refresh_all())
	EventBus.reputation_changed.connect(func(_v: int, _d: int) -> void: _refresh_all())
	EventBus.debt_ledger_updated.connect(func() -> void: _refresh_debt_list())
	EventBus.store_level_changed.connect(func(_l: int, _t: String, _r: float) -> void: _refresh_all())
	EventBus.toast_requested.connect(_on_toast_requested)


func _make_card_style(tex: Texture2D, pad_h: int = 16, pad_v: int = 12) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 20
	sb.texture_margin_right = 20
	sb.texture_margin_top = 18
	sb.texture_margin_bottom = 18
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


func _make_paper_box(bg_col: Color, border_col: Color, bw: int = 2, pad_h: int = 16, pad_v: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	sb.shadow_color = Color(0.14, 0.1, 0.07, 0.16)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(1, 2)
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


func _style_button(btn: Button, tex: Texture2D, font_size: int = 16) -> void:
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, 46.0)
	btn.add_theme_stylebox_override("normal", _make_btn_style(tex, Color.WHITE))
	btn.add_theme_stylebox_override("hover", _make_btn_style(tex, Color(1.06, 1.04, 0.98)))
	btn.add_theme_stylebox_override("pressed", _make_btn_style(tex, Color(0.92, 0.9, 0.85)))
	btn.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	btn.add_theme_color_override("font_hover_color", Color(0.78, 0.29, 0.19))
	btn.add_theme_color_override("font_pressed_color", Color(0.22, 0.16, 0.1))
	btn.add_theme_font_size_override("font_size", font_size)


func _build_ui() -> void:
	# Cozy Night Amber Background
	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.24, 0.18, 0.15, 1.0)
	add_child(bg_rect)

	var bg_art := TextureRect.new()
	bg_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_art.texture = TEX_BG_STORE
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.modulate = Color(0.85, 0.72, 0.58, 0.18)
	add_child(bg_art)

	var main_margin := MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 12)
	main_margin.add_theme_constant_override("margin_bottom", 12)
	add_child(main_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)
	main_margin.add_child(root_vbox)

	# 1. Top Header
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 18, 10))
	root_vbox.add_child(top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 16)
	top_panel.add_child(top_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 3)
	top_hbox.add_child(title_vbox)

	header_title_lbl = Label.new()
	header_title_lbl.add_theme_color_override("font_color", Color(0.78, 0.29, 0.19))
	header_title_lbl.add_theme_font_size_override("font_size", 22)
	title_vbox.add_child(header_title_lbl)

	stats_lbl = Label.new()
	stats_lbl.add_theme_color_override("font_color", Color(0.18, 0.45, 0.22))
	stats_lbl.add_theme_font_size_override("font_size", 16)
	title_vbox.add_child(stats_lbl)

	feedback_lbl = Label.new()
	feedback_lbl.text = "Đã tự động lưu Sổ Cái cuối ngày."
	feedback_lbl.add_theme_color_override("font_color", Color(0.45, 0.26, 0.12))
	feedback_lbl.add_theme_font_size_override("font_size", 15)
	top_hbox.add_child(feedback_lbl)

	# 2. Center Split (Left: Diary + Financial Summary + Upgrade | Right: Neighbor Debt Book)
	var center_hbox := HBoxContainer.new()
	center_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_hbox.add_theme_constant_override("separation", 14)
	root_vbox.add_child(center_hbox)

	# Left Column
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 1.15
	left_vbox.add_theme_constant_override("separation", 10)
	center_hbox.add_child(left_vbox)

	# Story Vignette Card
	var diary_card := PanelContainer.new()
	diary_card.add_theme_stylebox_override("panel", _make_paper_box(Color("#FDF3D8"), Color("#C84B31"), 2, 18, 12))
	left_vbox.add_child(diary_card)

	var diary_vbox := VBoxContainer.new()
	diary_vbox.add_theme_constant_override("separation", 6)
	diary_card.add_child(diary_vbox)

	var diary_hdr := Label.new()
	diary_hdr.text = "NHẬT KÝ GÁC XÉP ĐÊM NAY"
	diary_hdr.add_theme_color_override("font_color", Color(0.55, 0.18, 0.12))
	diary_hdr.add_theme_font_size_override("font_size", 18)
	diary_vbox.add_child(diary_hdr)

	diary_lbl = Label.new()
	diary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diary_lbl.add_theme_color_override("font_color", Color(0.24, 0.16, 0.1))
	diary_lbl.add_theme_font_size_override("font_size", 16)
	diary_vbox.add_child(diary_lbl)

	# Financial & Customer Report Card
	var report_card := PanelContainer.new()
	report_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_card.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 18, 14))
	left_vbox.add_child(report_card)

	var report_vbox := VBoxContainer.new()
	report_vbox.add_theme_constant_override("separation", 8)
	report_card.add_child(report_vbox)

	var rep_hdr := Label.new()
	rep_hdr.text = "KẾT SỔ THU CHI & LƯỢT KHÁCH TRONG NGÀY"
	rep_hdr.add_theme_color_override("font_color", Color(0.26, 0.17, 0.09))
	rep_hdr.add_theme_font_size_override("font_size", 18)
	report_vbox.add_child(rep_hdr)

	finance_lbl = Label.new()
	finance_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finance_lbl.add_theme_color_override("font_color", Color(0.18, 0.42, 0.2))
	finance_lbl.add_theme_font_size_override("font_size", 16)
	report_vbox.add_child(finance_lbl)

	var sep := HSeparator.new()
	report_vbox.add_child(sep)

	customer_stats_lbl = Label.new()
	customer_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	customer_stats_lbl.add_theme_color_override("font_color", Color(0.24, 0.17, 0.1))
	customer_stats_lbl.add_theme_font_size_override("font_size", 16)
	report_vbox.add_child(customer_stats_lbl)

	var upg_spacer := Control.new()
	upg_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_vbox.add_child(upg_spacer)

	btn_upgrade = Button.new()
	btn_upgrade.custom_minimum_size = Vector2(0, 50)
	_style_button(btn_upgrade, TEX_BTN_YELLOW, 16)
	btn_upgrade.pressed.connect(func() -> void: GameManager.try_upgrade_store_level())
	report_vbox.add_child(btn_upgrade)

	# Right Column: Neighbor Debt Ledger
	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_card.size_flags_stretch_ratio = 0.95
	right_card.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 18, 14))
	center_hbox.add_child(right_card)

	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 10)
	right_card.add_child(right_vbox)

	var debt_hdr := Label.new()
	debt_hdr.text = "SỔ NỢ HÀNG XÓM (NHẮC KHÉO CUỐI NGÀY)"
	debt_hdr.add_theme_color_override("font_color", Color(0.55, 0.18, 0.12))
	debt_hdr.add_theme_font_size_override("font_size", 18)
	right_vbox.add_child(debt_hdr)

	var debt_scroll := ScrollContainer.new()
	debt_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debt_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(debt_scroll)

	debt_vbox = VBoxContainer.new()
	debt_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debt_vbox.add_theme_constant_override("separation", 8)
	debt_scroll.add_child(debt_vbox)

	# 3. Bottom Navigation Bar
	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", _make_card_style(TEX_CARD_BROWN, 16, 8))
	root_vbox.add_child(bottom_panel)

	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 16)
	bottom_panel.add_child(bottom_hbox)

	var btn_menu := Button.new()
	btn_menu.text = "<< Lưu & Về Bìa Sổ Ký Ức (Menu Chính)"
	btn_menu.custom_minimum_size = Vector2(340, 52)
	_style_button(btn_menu, TEX_BTN_CREAM, 16)
	btn_menu.pressed.connect(func() -> void:
		GameManager.save_game()
		GameManager.change_to_phase_scene(GameManager.StorePhase.STORY_INTRO)
	)
	bottom_hbox.add_child(btn_menu)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)

	var btn_next_day := Button.new()
	btn_next_day.text = "Đi Ngủ & Sáng Mai Đi Chợ Sỉ (Qua Ngày %d) >>" % (GameManager.current_day + 1)
	btn_next_day.custom_minimum_size = Vector2(440, 52)
	_style_button(btn_next_day, TEX_BTN_GREEN, 17)
	btn_next_day.pressed.connect(func() -> void: GameManager.start_next_day())
	bottom_hbox.add_child(btn_next_day)


func _refresh_all() -> void:
	var lvl: int = GameManager.store_level
	var cfg: Dictionary = GameManager.level_configs[lvl]

	if header_title_lbl:
		header_title_lbl.text = "21:00 TỐI NGÀY %d — KHÉP CỬA VỀ NHÀ & KẾT SỔ [%s]" % [
			GameManager.current_day,
			GameManager.store_name
		]
	if stats_lbl:
		stats_lbl.text = "Chủ tiệm: %s  |  Vốn hiện có: %s đ  |  Tình làng xóm: %d  |  %s" % [
			GameManager.player_name,
			EconomyManager.format_vnd(EconomyManager.money),
			EconomyManager.reputation,
			str(cfg["title"])
		]
	if diary_lbl:
		diary_lbl.text = GameManager.get_daily_story_vignette()
	if finance_lbl:
		var net: int = GameManager.daily_revenue - GameManager.daily_spent
		var net_prefix: String = "+" if net >= 0 else ""
		finance_lbl.text = (
			"- Doanh thu bán lẻ & trà đá hôm nay: +%s đ\n" % EconomyManager.format_vnd(GameManager.daily_revenue)
			+ "- Chi phí nhập hàng sỉ & mua kẹo: -%s đ\n" % EconomyManager.format_vnd(GameManager.daily_spent)
			+ "-> CHÊNH LỆCH THU CHI TRONG NGÀY: %s%s đ" % [net_prefix, EconomyManager.format_vnd(net)]
		)
	if customer_stats_lbl:
		customer_stats_lbl.text = (
			"Thống kê bà con ghé quán hôm nay:\n"
			+ "  - Khách mua hàng hài lòng: %d lượt\n" % GameManager.daily_customers_served
			+ "  - Khách đổi ý / bỏ về vì hết món hoặc chờ lâu: %d lượt\n" % GameManager.daily_customers_left
			+ "  - Tổng nợ hàng xóm chưa thu: %s đ" % EconomyManager.format_vnd(EconomyManager.get_unpaid_debt_total())
		)
	if btn_upgrade:
		if lvl < 4:
			btn_upgrade.disabled = false
			btn_upgrade.text = "Tô Màu Mở Rộng Cấp %d (%s đ & %d Tình làng)" % [
				lvl + 1,
				EconomyManager.format_vnd(int(cfg["upgrade_cost"])),
				int(cfg["rep_required"])
			]
		else:
			btn_upgrade.disabled = true
			btn_upgrade.text = "Đã Tô Màu Trọn Vẹn Khu Phố Ký Ức!"
	_refresh_debt_list()


func _refresh_debt_list() -> void:
	if debt_vbox == null:
		return
	for child in debt_vbox.get_children():
		child.queue_free()

	var unpaid_count: int = 0
	for rec: DebtRecord in EconomyManager.debt_records:
		if rec.is_paid:
			continue
		unpaid_count += 1
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_paper_box(Color("#F6ECDC"), Color("#8A4B38"), 1, 14, 10))
		debt_vbox.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "%s (%s) — Ngày %d\n%s — Nợ: %s đ" % [
			rec.customer_name,
			rec.customer_role,
			rec.day_borrowed,
			rec.note,
			EconomyManager.format_vnd(rec.amount)
		]
		lbl.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
		lbl.add_theme_font_size_override("font_size", 15)
		row.add_child(lbl)

		var rid: int = rec.record_id
		var btn_collect := Button.new()
		btn_collect.text = "Thu Nợ (+2)"
		btn_collect.icon = ICON_HEART
		btn_collect.expand_icon = true
		btn_collect.custom_minimum_size = Vector2(130, 44)
		_style_button(btn_collect, TEX_BTN_GREEN, 15)
		btn_collect.pressed.connect(func() -> void:
			EconomyManager.collect_debt(rid)
			GameManager.save_game()
			_refresh_all()
		)
		row.add_child(btn_collect)

	if unpaid_count == 0:
		var empty_lbl := Label.new()
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.text = "Sổ nợ sạch trơn! Bà con lối xóm đều đã thanh toán đầy đủ."
		empty_lbl.add_theme_color_override("font_color", Color(0.22, 0.45, 0.24))
		empty_lbl.add_theme_font_size_override("font_size", 16)
		debt_vbox.add_child(empty_lbl)


func _on_toast_requested(msg: String, _color: Color) -> void:
	if feedback_lbl:
		feedback_lbl.text = msg
