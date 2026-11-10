extends Control

const INK_DARK := Color("#2C221E")
const PAPER_CREAM := Color("#FBF8F1")
const PAPER_WARM := Color("#F2E6D0")
const STAMP_RED := Color("#C84B31")
const SAGE_GREEN := Color("#6B8E78")

const TEX_BG_SKETCH: Texture2D = preload("res://assets/art/bg_tiem_ba_ba.jpg")
const TEX_CARD_BROWN: Texture2D = preload("res://assets/sprites/ui/ui_card_brown.png")
const TEX_BTN_GREEN: Texture2D = preload("res://assets/sprites/ui/ui_btn_green.png")
const TEX_BTN_YELLOW: Texture2D = preload("res://assets/sprites/ui/ui_btn_yellow.png")
const TEX_BTN_CREAM: Texture2D = preload("res://assets/sprites/ui/ui_btn_cream.png")
const TEX_SHOPKEEPER: Texture2D = preload("res://assets/sprites/characters/char_shopkeeper.png")
const TEX_SCHOOLBOY: Texture2D = preload("res://assets/sprites/characters/char_schoolboy.png")
const TEX_UNCLE: Texture2D = preload("res://assets/sprites/characters/char_uncle.png")

var current_page: int = 0
var lbl_page_indicator: Label
var lbl_story_heading: Label
var lbl_story_body: Label
var story_portrait: TextureRect
var btn_prev_page: Button
var btn_next_page: Button

var story_pages: Array[Dictionary] = [
	{
		"heading": "Trang 1/3 — Trở Về Con Ngõ Nhỏ Dưới Bóng Đa",
		"body": "Sau những năm tháng bôn ba nơi phố thị ồn ào, một chiều cuối thu bạn quyết định xếp lại hành lý, trở về căn nhà nhỏ dưới bóng cây đa đầu ngõ.\n\nNơi đây, bà ngoại từng gắn bó cả cuộc đời với tiệm tạp hóa gỗ mộc mạc — nơi lưu giữ biết bao tiếng cười trẻ thơ mỗi giờ tan học.",
		"tex": TEX_SHOPKEEPER
	},
	{
		"heading": "Trang 2/3 — Chiếc Quầy Gỗ & Cuốn Sổ Cái Ố Vàng",
		"body": "Mở cánh cửa gỗ khép hờ, trên bàn thu ngân vẫn còn nguyên hũ thủy tinh đựng kẹo lẻ dùng để thối tiền và cuốn Sổ Ghi Nợ ố vàng ghi những dòng chữ thân thương của Bác Tư, Cô Hoa, Anh Tuấn...\n\nỞ con ngõ nhỏ này, người ta mua bán không chỉ bằng tiền mặt, mà còn bằng cả Tình Làng Nghĩa Xóm.",
		"tex": TEX_UNCLE
	},
	{
		"heading": "Trang 3/3 — Hành Trình Tô Màu Lại Ký Ức",
		"body": "Lúc này, khu phố trong ký ức vẫn còn là những nét phác thảo chì trầm lắng.\n\nMỗi sáng sớm đạp xe đi chợ đầu mối nhập hàng theo dự báo nắng mưa, mỗi gói mì trẻ em bán ra lúc trống trường điểm và từng nụ cười hàng xóm sẽ giúp nét cọ màu nước loang rộng, tô ấm lại cả khu phố xưa!",
		"tex": TEX_SCHOOLBOY
	}
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_story_page()
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)

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
	sbt.content_margin_left = 16
	sbt.content_margin_right = 16
	sbt.content_margin_top = 8
	sbt.content_margin_bottom = 8
	return sbt

func _apply_btn(btn: Button, tex: Texture2D, f_size: int = 17) -> void:
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, 50.0)
	btn.add_theme_stylebox_override("normal", _style_tex_button(tex, Color.WHITE))
	btn.add_theme_stylebox_override("hover", _style_tex_button(tex, Color(1.06, 1.04, 1.0, 1.0)))
	btn.add_theme_stylebox_override("pressed", _style_tex_button(tex, Color(0.92, 0.89, 0.85, 1.0)))
	btn.add_theme_color_override("font_color", INK_DARK)
	btn.add_theme_color_override("font_hover_color", STAMP_RED)
	btn.add_theme_font_size_override("font_size", f_size)

func _build_ui() -> void:
	# 1. Nền giấy kem ấm + Tranh màu nước Tiệm Bà Ba làm nền nghệ thuật
	var bg_color := ColorRect.new()
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_color.color = Color("#F5EFE6")
	add_child(bg_color)

	var bg_art := TextureRect.new()
	bg_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_art.texture = TEX_BG_SKETCH
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.modulate = Color(1.0, 0.98, 0.95, 0.32)
	add_child(bg_art)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 24)
	safe_margin.add_theme_constant_override("margin_right", 24)
	safe_margin.add_theme_constant_override("margin_top", 14)
	safe_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(safe_margin)

	var center_box := CenterContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe_margin.add_child(center_box)

	var main_card := PanelContainer.new()
	main_card.custom_minimum_size = Vector2(1160, 650)
	main_card.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 36, 26))
	center_box.add_child(main_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	main_card.add_child(vbox)

	# Tiêu đề Game
	var title := Label.new()
	title.text = "TẠP HÓA MÀU NƯỚC — KÝ ỨC ĐẦU NGÕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", STAMP_RED)
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Game Quản Lý Tiệm Tạp Hóa & Nhịp Sống Xóm Nhỏ (Style 8: Bút Mực & Màu Nước)"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.25))
	subtitle.add_theme_font_size_override("font_size", 17)
	vbox.add_child(subtitle)

	# Khung Sổ Cốt Truyện Mở Đầu (Có lật trang 1/3 -> 3/3)
	var story_panel := PanelContainer.new()
	story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sp_sb := StyleBoxFlat.new()
	sp_sb.bg_color = PAPER_WARM
	sp_sb.border_color = INK_DARK
	sp_sb.set_border_width_all(2)
	sp_sb.set_corner_radius_all(10)
	sp_sb.content_margin_left = 26
	sp_sb.content_margin_right = 26
	sp_sb.content_margin_top = 20
	sp_sb.content_margin_bottom = 20
	story_panel.add_theme_stylebox_override("panel", sp_sb)
	vbox.add_child(story_panel)

	var story_hbox := HBoxContainer.new()
	story_hbox.add_theme_constant_override("separation", 28)
	story_panel.add_child(story_hbox)

	# Cột trái: Minh họa bức tranh Tiệm Bà Ba + Nhân vật
	var art_vbox := VBoxContainer.new()
	art_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	art_vbox.add_theme_constant_override("separation", 12)
	story_hbox.add_child(art_vbox)

	var mini_painting := TextureRect.new()
	mini_painting.texture = TEX_BG_SKETCH
	mini_painting.custom_minimum_size = Vector2(300, 180)
	mini_painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini_painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_vbox.add_child(mini_painting)

	story_portrait = TextureRect.new()
	story_portrait.custom_minimum_size = Vector2(120, 140)
	story_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_vbox.add_child(story_portrait)

	# Cột phải: Nội dung cốt truyện + Nút lật trang
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 14)
	story_hbox.add_child(text_vbox)

	lbl_story_heading = Label.new()
	lbl_story_heading.add_theme_color_override("font_color", STAMP_RED)
	lbl_story_heading.add_theme_font_size_override("font_size", 22)
	text_vbox.add_child(lbl_story_heading)

	lbl_story_body = Label.new()
	lbl_story_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_story_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_story_body.add_theme_color_override("font_color", INK_DARK)
	lbl_story_body.add_theme_font_size_override("font_size", 18)
	text_vbox.add_child(lbl_story_body)

	var page_nav_row := HBoxContainer.new()
	page_nav_row.alignment = BoxContainer.ALIGNMENT_END
	page_nav_row.add_theme_constant_override("separation", 14)
	text_vbox.add_child(page_nav_row)

	btn_prev_page = Button.new()
	btn_prev_page.text = "<< Trang trước"
	btn_prev_page.custom_minimum_size = Vector2(165, 48)
	btn_prev_page.set_meta("sfx_id", "page_flip")
	_apply_btn(btn_prev_page, TEX_BTN_CREAM, 16)
	btn_prev_page.pressed.connect(func() -> void:
		current_page = maxi(0, current_page - 1)
		_refresh_story_page()
	)
	page_nav_row.add_child(btn_prev_page)

	lbl_page_indicator = Label.new()
	lbl_page_indicator.add_theme_color_override("font_color", INK_DARK)
	lbl_page_indicator.add_theme_font_size_override("font_size", 17)
	page_nav_row.add_child(lbl_page_indicator)

	btn_next_page = Button.new()
	btn_next_page.text = "Trang tiếp >>"
	btn_next_page.custom_minimum_size = Vector2(165, 48)
	btn_next_page.set_meta("sfx_id", "page_flip")
	_apply_btn(btn_next_page, TEX_BTN_CREAM, 16)
	btn_next_page.pressed.connect(func() -> void:
		current_page = mini(story_pages.size() - 1, current_page + 1)
		_refresh_story_page()
	)
	page_nav_row.add_child(btn_next_page)

	# Dòng Nút Hành Động Chính (Tiếp Tục Save Cũ, Khai Trương Quán Mới, Cài Đặt)
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 14)
	vbox.add_child(action_row)

	var save_info: Dictionary = GameManager.get_save_summary()
	if not save_info.is_empty():
		var s_store: String = str(save_info.get("store_name", "TẠP HÓA"))
		var s_owner: String = str(save_info.get("player_name", "Bà Ba"))
		var s_day: int = int(save_info.get("current_day", 1))
		var s_money: int = int(save_info.get("money", 45000))

		var btn_continue := Button.new()
		btn_continue.text = "Tiếp Tục: %s (%s — Ngày %d | %s đ) >>" % [
			s_store, s_owner, s_day, EconomyManager.format_vnd(s_money)
		]
		btn_continue.custom_minimum_size = Vector2(450, 56)
		btn_continue.set_meta("sfx_id", "rubber_stamp")
		btn_continue.set_meta("haptic_strength", "medium")
		_apply_btn(btn_continue, TEX_BTN_GREEN, 16)
		btn_continue.pressed.connect(func() -> void: GameManager.continue_saved_game())
		action_row.add_child(btn_continue)

	var btn_new_game := Button.new()
	btn_new_game.text = "Khai Trương Tiệm Mới (Đặt Tên Chủ & Tên Quán) >>"
	btn_new_game.custom_minimum_size = Vector2(450, 56)
	btn_new_game.set_meta("sfx_id", "rubber_stamp")
	btn_new_game.set_meta("haptic_strength", "medium")
	_apply_btn(btn_new_game, TEX_BTN_YELLOW, 17)
	btn_new_game.pressed.connect(func() -> void: GameManager.begin_new_game_onboarding())
	action_row.add_child(btn_new_game)

	var btn_settings := Button.new()
	btn_settings.text = "Cài Đặt"
	btn_settings.custom_minimum_size = Vector2(145, 56)
	_apply_btn(btn_settings, TEX_BTN_CREAM, 17)
	btn_settings.pressed.connect(func() -> void: GameManager.open_settings())
	action_row.add_child(btn_settings)

func _refresh_story_page() -> void:
	var p: Dictionary = story_pages[current_page]
	lbl_story_heading.text = p["heading"]
	lbl_story_body.text = p["body"]
	story_portrait.texture = p["tex"]
	lbl_page_indicator.text = " Trang %d / %d " % [current_page + 1, story_pages.size()]
	btn_prev_page.disabled = (current_page <= 0)
	btn_next_page.disabled = (current_page >= story_pages.size() - 1)

