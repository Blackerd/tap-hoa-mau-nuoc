extends Control

const INK_DARK := Color("#2C221E")
const PAPER_CREAM := Color("#FBF8F1")
const PAPER_WARM := Color("#F2E6D0")
const STAMP_RED := Color("#C84B31")
const SAGE_GREEN := Color("#6B8E78")

const TEX_BG_STORE: Texture2D = preload("res://assets/art/bg_store_ortho.jpg")
const TEX_CARD_BROWN: Texture2D = preload("res://assets/sprites/ui/ui_card_brown.png")
const TEX_BTN_GREEN: Texture2D = preload("res://assets/sprites/ui/ui_btn_green.png")
const TEX_BTN_YELLOW: Texture2D = preload("res://assets/sprites/ui/ui_btn_yellow.png")
const TEX_BTN_PINK: Texture2D = preload("res://assets/sprites/ui/ui_btn_pink.png")
const TEX_BTN_CREAM: Texture2D = preload("res://assets/sprites/ui/ui_btn_cream.png")
const TEX_SHOPKEEPER: Texture2D = preload("res://assets/sprites/characters/char_shopkeeper.png")
const TEX_CASHIER_DESK: Texture2D = preload("res://assets/sprites/furniture/cashier_desk.png")
const ICON_MONEY: Texture2D = preload("res://assets/sprites/items/icon_money.png")
const ICON_HEART: Texture2D = preload("res://assets/sprites/items/icon_heart.png")
const ICON_CANDY: Texture2D = preload("res://assets/sprites/items/icon_candy_jar.png")

var input_owner_name: LineEdit
var input_store_name: LineEdit
var lbl_preview_sign_title: Label
var lbl_preview_sign_owner: Label
var lbl_preview_greeting: Label

var selected_perk_id: String = "neighbor"
var perk_buttons: Dictionary = {}
var kb_modal: PanelContainer
var kb_target_input: LineEdit
var kb_preview_lbl: Label
var kb_title_lbl: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_update_live_preview()
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)

func _style_tex_panel(tex: Texture2D, pad_h: int = 28, pad_v: int = 22) -> StyleBoxTexture:
	var sbt := StyleBoxTexture.new()
	sbt.texture = tex
	sbt.texture_margin_left = 22
	sbt.texture_margin_right = 22
	sbt.texture_margin_top = 22
	sbt.texture_margin_bottom = 22
	sbt.content_margin_left = pad_h
	sbt.content_margin_right = pad_h
	sbt.content_margin_top = pad_v
	sbt.content_margin_bottom = pad_v
	return sbt

func _style_tex_button(tex: Texture2D, modulate_col: Color = Color.WHITE) -> StyleBoxTexture:
	var sbt := StyleBoxTexture.new()
	sbt.texture = tex
	sbt.modulate_color = modulate_col
	sbt.texture_margin_left = 22
	sbt.texture_margin_right = 22
	sbt.texture_margin_top = 12
	sbt.texture_margin_bottom = 14
	sbt.content_margin_left = 14
	sbt.content_margin_right = 14
	sbt.content_margin_top = 6
	sbt.content_margin_bottom = 8
	return sbt

func _apply_btn(btn: Button, tex: Texture2D, f_size: int = 15) -> void:
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, 44.0)
	btn.add_theme_stylebox_override("normal", _style_tex_button(tex, Color.WHITE))
	btn.add_theme_stylebox_override("hover", _style_tex_button(tex, Color(1.06, 1.04, 1.0, 1.0)))
	btn.add_theme_stylebox_override("pressed", _style_tex_button(tex, Color(0.92, 0.89, 0.85, 1.0)))
	btn.add_theme_color_override("font_color", INK_DARK)
	btn.add_theme_color_override("font_hover_color", STAMP_RED)
	btn.add_theme_font_size_override("font_size", f_size)

func _style_box(bg_col: Color, border_col: Color, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _build_ui() -> void:
	var bg_color := ColorRect.new()
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_color.color = Color("#F5EFE6")
	add_child(bg_color)

	var bg_art := TextureRect.new()
	bg_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_art.texture = TEX_BG_STORE
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.modulate = Color(1.0, 0.98, 0.94, 0.25)
	add_child(bg_art)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1180, 664)
	card.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 32, 22))
	center.add_child(card)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	card.add_child(main_vbox)

	var title := Label.new()
	title.text = "GIẤY ĐĂNG KÝ KHAI TRƯƠNG TIỆM TẠP HÓA ĐẦU NGÕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", STAMP_RED)
	title.add_theme_font_size_override("font_size", 26)
	main_vbox.add_child(title)

	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 18)
	main_vbox.add_child(body_hbox)

	# ==========================================
	# CỘT TRÁI: XEM TRƯỚC BẢNG HIỆU GỖ & BÀ CHỦ QUÁN
	# ==========================================
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(325, 0)
	preview_panel.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 2))
	body_hbox.add_child(preview_panel)

	var prev_vbox := VBoxContainer.new()
	prev_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	prev_vbox.add_theme_constant_override("separation", 14)
	preview_panel.add_child(prev_vbox)

	var prev_caption := Label.new()
	prev_caption.text = "Xem Trước Biển Hiệu Tiệm"
	prev_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_caption.add_theme_color_override("font_color", INK_DARK)
	prev_caption.add_theme_font_size_override("font_size", 17)
	prev_vbox.add_child(prev_caption)

	# Mô phỏng tấm biển gỗ trên mái hiên
	var wood_board := PanelContainer.new()
	wood_board.add_theme_stylebox_override("panel", _style_box(Color("#D7B38C"), INK_DARK, 3))
	prev_vbox.add_child(wood_board)

	var wb_vbox := VBoxContainer.new()
	wb_vbox.add_theme_constant_override("separation", 4)
	wood_board.add_child(wb_vbox)

	lbl_preview_sign_title = Label.new()
	lbl_preview_sign_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preview_sign_title.add_theme_color_override("font_color", INK_DARK)
	lbl_preview_sign_title.add_theme_font_size_override("font_size", 21)
	wb_vbox.add_child(lbl_preview_sign_title)

	lbl_preview_sign_owner = Label.new()
	lbl_preview_sign_owner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preview_sign_owner.add_theme_color_override("font_color", Color("#7A3E26"))
	lbl_preview_sign_owner.add_theme_font_size_override("font_size", 16)
	wb_vbox.add_child(lbl_preview_sign_owner)

	var sk_tex := TextureRect.new()
	sk_tex.texture = TEX_SHOPKEEPER
	sk_tex.custom_minimum_size = Vector2(110, 145)
	sk_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sk_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prev_vbox.add_child(sk_tex)

	lbl_preview_greeting = Label.new()
	lbl_preview_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_preview_greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preview_greeting.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.28))
	lbl_preview_greeting.add_theme_font_size_override("font_size", 15)
	prev_vbox.add_child(lbl_preview_greeting)

	# ==========================================
	# CỘT PHẢI: ĐIỀN THÔNG TIN CHỦ QUÁN & TÊN TẠP HÓA
	# ==========================================
	var form_vbox := VBoxContainer.new()
	form_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_vbox.add_theme_constant_override("separation", 10)
	body_hbox.add_child(form_vbox)

	# Mục 1: Tên Chủ Quán
	var box1 := PanelContainer.new()
	box1.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	form_vbox.add_child(box1)

	var v1 := VBoxContainer.new()
	v1.add_theme_constant_override("separation", 6)
	box1.add_child(v1)

	var l1 := Label.new()
	l1.text = "1. Điền Tên / Cách Xưng Hô Của Chủ Quán (Player):"
	l1.add_theme_color_override("font_color", INK_DARK)
	l1.add_theme_font_size_override("font_size", 16)
	v1.add_child(l1)

	var inp_row1 := HBoxContainer.new()
	inp_row1.add_theme_constant_override("separation", 8)
	v1.add_child(inp_row1)

	input_owner_name = LineEdit.new()
	input_owner_name.text = "Bà Ba"
	input_owner_name.placeholder_text = "Ví dụ: Bà Ba, Cô Út, Chú Tư, Minh..."
	input_owner_name.virtual_keyboard_enabled = false
	input_owner_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_owner_name.custom_minimum_size = Vector2(0, 44)
	input_owner_name.add_theme_color_override("font_color", INK_DARK)
	input_owner_name.add_theme_font_size_override("font_size", 18)
	input_owner_name.add_theme_stylebox_override("normal", _style_box(PAPER_CREAM, INK_DARK, 1))
	input_owner_name.text_changed.connect(func(_t: String) -> void: _update_live_preview())
	input_owner_name.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_ingame_kb(input_owner_name, "NHẬP TÊN / CÁCH XƯNG HÔ CHỦ QUÁN")
	)
	inp_row1.add_child(input_owner_name)

	var btn_kb1 := Button.new()
	btn_kb1.text = "Gõ Tên Riêng"
	_apply_btn(btn_kb1, TEX_BTN_YELLOW, 15)
	btn_kb1.pressed.connect(func() -> void:
		_open_ingame_kb(input_owner_name, "NHẬP TÊN / CÁCH XƯNG HÔ CHỦ QUÁN")
	)
	inp_row1.add_child(btn_kb1)

	var row1_presets := HBoxContainer.new()
	row1_presets.add_theme_constant_override("separation", 8)
	v1.add_child(row1_presets)

	var preset_lbl1 := Label.new()
	preset_lbl1.text = "Chọn nhanh:"
	preset_lbl1.add_theme_color_override("font_color", INK_DARK)
	preset_lbl1.add_theme_font_size_override("font_size", 15)
	row1_presets.add_child(preset_lbl1)

	for po in ["Bà Ba", "Cô Út", "Chú Tư", "Dì Chánh", "Anh Minh", "Chị Lan"]:
		var b := Button.new()
		b.text = po
		_apply_btn(b, TEX_BTN_CREAM, 15)
		var val: String = po
		b.pressed.connect(func() -> void:
			input_owner_name.text = val
			_update_live_preview()
		)
		row1_presets.add_child(b)

	# Mục 2: Tên Biển Hiệu Tạp Hóa
	var box2 := PanelContainer.new()
	box2.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	form_vbox.add_child(box2)

	var v2 := VBoxContainer.new()
	v2.add_theme_constant_override("separation", 6)
	box2.add_child(v2)

	var l2 := Label.new()
	l2.text = "2. Đặt Tên Biển Hiệu Tiệm Tạp Hóa:"
	l2.add_theme_color_override("font_color", INK_DARK)
	l2.add_theme_font_size_override("font_size", 16)
	v2.add_child(l2)

	var inp_row2 := HBoxContainer.new()
	inp_row2.add_theme_constant_override("separation", 8)
	v2.add_child(inp_row2)

	input_store_name = LineEdit.new()
	input_store_name.text = "TẠP HÓA BÀ BA"
	input_store_name.placeholder_text = "Ví dụ: TẠP HÓA BÀ BA, TIỆM KÝ ỨC..."
	input_store_name.virtual_keyboard_enabled = false
	input_store_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_store_name.custom_minimum_size = Vector2(0, 44)
	input_store_name.add_theme_color_override("font_color", STAMP_RED)
	input_store_name.add_theme_font_size_override("font_size", 18)
	input_store_name.add_theme_stylebox_override("normal", _style_box(PAPER_CREAM, INK_DARK, 1))
	input_store_name.text_changed.connect(func(_t: String) -> void: _update_live_preview())
	input_store_name.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_ingame_kb(input_store_name, "ĐẶT TÊN BIỂN HIỆU TIỆM TẠP HÓA")
	)
	inp_row2.add_child(input_store_name)

	var btn_kb2 := Button.new()
	btn_kb2.text = "Gõ Tên Tiệm"
	_apply_btn(btn_kb2, TEX_BTN_YELLOW, 15)
	btn_kb2.pressed.connect(func() -> void:
		_open_ingame_kb(input_store_name, "ĐẶT TÊN BIỂN HIỆU TIỆM TẠP HÓA")
	)
	inp_row2.add_child(btn_kb2)

	var row2_presets := HBoxContainer.new()
	row2_presets.add_theme_constant_override("separation", 8)
	v2.add_child(row2_presets)

	var preset_lbl2 := Label.new()
	preset_lbl2.text = "Gợi ý tên tiệm:"
	preset_lbl2.add_theme_color_override("font_color", INK_DARK)
	preset_lbl2.add_theme_font_size_override("font_size", 15)
	row2_presets.add_child(preset_lbl2)

	for ps in ["TẠP HÓA BÀ BA", "TIỆM KÝ ỨC", "TẠP HÓA GỐC ĐA", "TẠP HÓA MÀU NƯỚC"]:
		var b := Button.new()
		b.text = ps
		_apply_btn(b, TEX_BTN_CREAM, 14)
		var val: String = ps
		b.pressed.connect(func() -> void:
			input_store_name.text = val
			_update_live_preview()
		)
		row2_presets.add_child(b)

	# Mục 3: Lợi Thế Khởi Nghiệp
	var box3 := PanelContainer.new()
	box3.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	form_vbox.add_child(box3)

	var v3 := VBoxContainer.new()
	v3.add_theme_constant_override("separation", 6)
	box3.add_child(v3)

	var l3 := Label.new()
	l3.text = "3. Chọn Lợi Thế Gia Truyền Khi Mở Tiệm:"
	l3.add_theme_color_override("font_color", INK_DARK)
	l3.add_theme_font_size_override("font_size", 16)
	v3.add_child(l3)

	var perk_row := HBoxContainer.new()
	perk_row.add_theme_constant_override("separation", 8)
	v3.add_child(perk_row)

	var perks_info: Array[Dictionary] = [
		{"id": "neighbor", "label": "Hiếu Khách (+10 Tình Làng & +10 Kẹo)", "icon": ICON_HEART},
		{"id": "capital", "label": "Vốn Mạnh (+15.000đ Vốn)", "icon": ICON_MONEY},
		{"id": "stock", "label": "Kho Đầy (+6 Gói Mỗi Loại)", "icon": ICON_CANDY}
	]
	for p in perks_info:
		var pb := Button.new()
		pb.text = p["label"]
		pb.icon = p["icon"]
		pb.expand_icon = true
		pb.custom_minimum_size = Vector2(0, 48)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pid: String = p["id"]
		perk_buttons[pid] = pb
		pb.pressed.connect(func() -> void: _select_perk(pid))
		perk_row.add_child(pb)
	_select_perk("neighbor")

	# Dòng nút xác nhận dưới đáy
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 14)
	main_vbox.add_child(bot_row)

	var btn_back := Button.new()
	btn_back.text = "<< Quay Lại Bìa Sổ"
	btn_back.custom_minimum_size = Vector2(200, 54)
	btn_back.set_meta("sfx_id", "page_flip")
	_apply_btn(btn_back, TEX_BTN_CREAM, 16)
	btn_back.pressed.connect(func() -> void:
		GameManager.change_to_phase_scene(GameManager.StorePhase.STORY_INTRO)
	)
	bot_row.add_child(btn_back)

	var btn_settings := Button.new()
	btn_settings.text = "Cài Đặt"
	btn_settings.custom_minimum_size = Vector2(145, 54)
	_apply_btn(btn_settings, TEX_BTN_CREAM, 16)
	btn_settings.pressed.connect(func() -> void:
		GameManager.open_settings()
	)
	bot_row.add_child(btn_settings)

	var btn_confirm := Button.new()
	btn_confirm.text = "ĐÓNG DẤU KHAI TRƯƠNG & ĐI CHỢ ĐẦU MỐI SÁNG SỚM >>"
	btn_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_confirm.custom_minimum_size = Vector2(0, 54)
	btn_confirm.set_meta("sfx_id", "rubber_stamp")
	btn_confirm.set_meta("haptic_strength", "heavy")
	_apply_btn(btn_confirm, TEX_BTN_GREEN, 18)
	btn_confirm.pressed.connect(func() -> void:
		GameManager.complete_owner_setup(input_owner_name.text, input_store_name.text, selected_perk_id)
	)
	bot_row.add_child(btn_confirm)

	_build_ingame_keyboard()

func _build_ingame_keyboard() -> void:
	kb_modal = PanelContainer.new()
	kb_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	kb_modal.custom_minimum_size = Vector2(1244, 688)
	kb_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	kb_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	kb_modal.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 24, 16))
	kb_modal.visible = false
	add_child(kb_modal)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	kb_modal.add_child(v)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	v.add_child(top_bar)

	kb_title_lbl = Label.new()
	kb_title_lbl.text = "NHẬP TÊN (BỘ GÕ TELEX TIẾNG VIỆT TỰ ĐỘNG)"
	kb_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kb_title_lbl.add_theme_color_override("font_color", STAMP_RED)
	kb_title_lbl.add_theme_font_size_override("font_size", 21)
	top_bar.add_child(kb_title_lbl)

	var telex_hint := Label.new()
	telex_hint.text = "Gõ kiểu Telex: DD=Đ | AA=Â | AW=Ă | EE=Ê | OO=Ô | OW/W=Ơ/Ư | S/F/R/X/J = Sắc/Huyền/Hỏi/Ngã/Nặng"
	telex_hint.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.28))
	telex_hint.add_theme_font_size_override("font_size", 15)
	top_bar.add_child(telex_hint)

	var preview_box := PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 62)
	preview_box.add_theme_stylebox_override("panel", _style_box(PAPER_CREAM, STAMP_RED, 3))
	v.add_child(preview_box)

	kb_preview_lbl = Label.new()
	kb_preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_preview_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kb_preview_lbl.add_theme_color_override("font_color", INK_DARK)
	kb_preview_lbl.add_theme_font_size_override("font_size", 28)
	preview_box.add_child(kb_preview_lbl)

	# Thanh gợi ý từ ghép nhanh 1 chạm
	var chip_row := HBoxContainer.new()
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip_row.add_theme_constant_override("separation", 8)
	v.add_child(chip_row)

	var chip_words: Array[String] = ["BÀ ", "CÔ ", "CHÚ ", "DÌ ", "ANH ", "CHỊ ", "TẠP HÓA ", "TIỆM ", "KÝ ỨC", "GỐC ĐA"]
	for cw in chip_words:
		var cbtn := Button.new()
		cbtn.text = "+" + cw.strip_edges()
		cbtn.custom_minimum_size = Vector2(106, 46)
		cbtn.set_meta("sfx_id", "key_type")
		_apply_btn(cbtn, TEX_BTN_YELLOW, 15)
		var w_val: String = cw
		cbtn.pressed.connect(func() -> void:
			if kb_target_input:
				if kb_target_input.text != "" and not kb_target_input.text.ends_with(" "):
					kb_target_input.text += " "
				kb_target_input.text += w_val
				kb_preview_lbl.text = kb_target_input.text
				_update_live_preview()
		)
		chip_row.add_child(cbtn)

	var rows: Array[Array] = [
		["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L", "Đ"],
		["Z", "X", "C", "V", "B", "N", "M", "Ă", "Â", "Ơ"]
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		v.add_child(h)
		for ch in r:
			var kbtn := Button.new()
			kbtn.text = ch
			kbtn.custom_minimum_size = Vector2(110, 68)
			kbtn.set_meta("sfx_id", "key_type")
			_apply_btn(kbtn, TEX_BTN_CREAM, 24)
			var c_str: String = ch
			kbtn.pressed.connect(func() -> void:
				_on_kb_key(c_str)
			)
			h.add_child(kbtn)

	var act_row := HBoxContainer.new()
	act_row.alignment = BoxContainer.ALIGNMENT_CENTER
	act_row.add_theme_constant_override("separation", 12)
	v.add_child(act_row)

	var btn_space := Button.new()
	btn_space.text = "Dấu Cách (Space)"
	btn_space.custom_minimum_size = Vector2(280, 62)
	btn_space.set_meta("sfx_id", "key_type")
	_apply_btn(btn_space, TEX_BTN_CREAM, 19)
	btn_space.pressed.connect(func() -> void:
		if kb_target_input:
			kb_target_input.text += " "
			kb_preview_lbl.text = kb_target_input.text
			_update_live_preview()
	)
	act_row.add_child(btn_space)

	var btn_bs := Button.new()
	btn_bs.text = "<< Xóa 1 Chữ"
	btn_bs.custom_minimum_size = Vector2(220, 62)
	btn_bs.set_meta("sfx_id", "key_type")
	_apply_btn(btn_bs, TEX_BTN_PINK, 19)
	btn_bs.pressed.connect(func() -> void:
		if kb_target_input and kb_target_input.text.length() > 0:
			kb_target_input.text = kb_target_input.text.substr(0, kb_target_input.text.length() - 1)
			kb_preview_lbl.text = kb_target_input.text
			_update_live_preview()
	)
	act_row.add_child(btn_bs)

	var btn_clear := Button.new()
	btn_clear.text = "Xóa Hết"
	btn_clear.custom_minimum_size = Vector2(180, 62)
	btn_clear.set_meta("sfx_id", "key_type")
	_apply_btn(btn_clear, TEX_BTN_PINK, 19)
	btn_clear.pressed.connect(func() -> void:
		if kb_target_input:
			kb_target_input.text = ""
			kb_preview_lbl.text = ""
			_update_live_preview()
	)
	act_row.add_child(btn_clear)

	var btn_done := Button.new()
	btn_done.text = "XONG (LƯU TÊN) >>"
	btn_done.custom_minimum_size = Vector2(360, 62)
	btn_done.set_meta("sfx_id", "rubber_stamp")
	btn_done.set_meta("haptic_strength", "medium")
	_apply_btn(btn_done, TEX_BTN_GREEN, 20)
	btn_done.pressed.connect(func() -> void:
		kb_modal.visible = false
		_update_live_preview()
	)
	act_row.add_child(btn_done)

func _open_ingame_kb(target: LineEdit, title_text: String) -> void:
	kb_target_input = target
	kb_title_lbl.text = title_text
	kb_preview_lbl.text = target.text
	GameManager.play_sfx("page_flip")
	GameManager.trigger_haptic("medium")
	kb_modal.visible = true

func _on_kb_key(c_str: String) -> void:
	if kb_target_input:
		kb_target_input.text = GameManager.apply_telex_key(kb_target_input.text, c_str)
		kb_preview_lbl.text = kb_target_input.text
		_update_live_preview()

func _select_perk(perk_id: String) -> void:
	selected_perk_id = perk_id
	for k in perk_buttons:
		var b: Button = perk_buttons[k]
		if k == perk_id:
			_apply_btn(b, TEX_BTN_YELLOW, 15)
		else:
			_apply_btn(b, TEX_BTN_CREAM, 15)

func _update_live_preview() -> void:
	var o_name: String = input_owner_name.text.strip_edges()
	if o_name == "":
		o_name = "Bà Ba"
	var s_name: String = input_store_name.text.strip_edges().to_upper()
	if s_name == "":
		s_name = "TẠP HÓA MÀU NƯỚC"

	lbl_preview_sign_title.text = s_name
	lbl_preview_sign_owner.text = "Chủ tiệm: " + o_name
	lbl_preview_greeting.text = "Hàng xóm sẽ chào:\n\"%s ơi, bán cho cháu bịch mì trẻ em ở %s với ạ!\"" % [o_name, s_name]

