class_name GameUIController
extends Control

const INK_DARK := Color("#2C221E")
const PAPER_CREAM := Color("#FBF8F1")
const PAPER_WARM := Color("#F2E6D0")
const STAMP_RED := Color("#C84B31")
const SAGE_GREEN := Color("#6B8E78")
const OCHRE_GOLD := Color("#E5A93C")

const TEX_CARD_BROWN: Texture2D = preload("res://assets/sprites/ui/ui_card_brown.png")
const TEX_CARD_RED_TAPE: Texture2D = preload("res://assets/sprites/ui/ui_card_red_tape.png")
const TEX_STRIP_LONG: Texture2D = preload("res://assets/sprites/ui/ui_strip_long.png")
const TEX_STRIP_SHORT: Texture2D = preload("res://assets/sprites/ui/ui_strip_short.png")
const TEX_NOTEBOOK: Texture2D = preload("res://assets/sprites/ui/ui_notebook_page.png")
const TEX_BTN_GREEN: Texture2D = preload("res://assets/sprites/ui/ui_btn_green.png")
const TEX_BTN_YELLOW: Texture2D = preload("res://assets/sprites/ui/ui_btn_yellow.png")
const TEX_BTN_PINK: Texture2D = preload("res://assets/sprites/ui/ui_btn_pink.png")
const TEX_BTN_CREAM: Texture2D = preload("res://assets/sprites/ui/ui_btn_cream.png")
const TEX_STAMP_RING: Texture2D = preload("res://assets/sprites/ui/ui_stamp_ring.png")
const TEX_SHOPKEEPER: Texture2D = preload("res://assets/sprites/characters/char_shopkeeper.png")
const ICON_MONEY: Texture2D = preload("res://assets/sprites/items/icon_money.png")
const ICON_HEART: Texture2D = preload("res://assets/sprites/items/icon_heart.png")
const ICON_CANDY: Texture2D = preload("res://assets/sprites/items/icon_candy_jar.png")
const ICON_SUN: Texture2D = preload("res://assets/sprites/items/icon_sun.png")
const ICON_RAIN: Texture2D = preload("res://assets/sprites/items/icon_rain.png")
const ICON_CLOCK: Texture2D = preload("res://assets/sprites/items/icon_clock.png")

var SafeMarginRoot: MarginContainer
var MainVBox: VBoxContainer
var MiddleWorkspace: Control

# Daytime HUD Labels & Buttons
var lbl_day_time: Label
var icon_weather_hud: TextureRect
var lbl_weather: Label
var lbl_money: Label
var lbl_rep_candy: Label

var toast_panel: PanelContainer
var toast_label: Label
var _toast_tween: Tween

var lbl_level_title: Label
var btn_upgrade_level: Button

var btn_toggle_ledger: Button
var btn_toggle_build: Button
var btn_auto_cashier: Button
var btn_speed: Button
var btn_close_night: Button

# Floating Notepad (Right-side responsive Ledger & Debt Book)
var ledger_panel: PanelContainer
var tab_inventory_box: VBoxContainer
var tab_debt_box: VBoxContainer
var current_ledger_tab: String = "inventory"

# Compact Checkout Popup (Bottom-left cashier receipt, above toolbar)
var checkout_panel: PanelContainer
var checkout_item_icon: TextureRect
var lbl_checkout_queue_badge: Label
var lbl_checkout_info: Label
var checkout_patience_bar: ProgressBar
var active_customer: CustomerEntity = null
var waiting_queue: Array[CustomerEntity] = []

# Red Rubber Stamp Effect
var stamp_badge: PanelContainer
var lbl_stamp_text: Label

# ==========================================
# MULTI-SCENE MODAL SCREENS (Scenes 1, 2, 3, 5)
# ==========================================
var SceneBackdrop: ColorRect
var StoryIntroModal: PanelContainer
var OwnerSetupModal: PanelContainer
var MorningMarketModal: PanelContainer
var NightHomeModal: PanelContainer

# Scene 2 (Owner Setup) Controls
var input_owner_name: LineEdit
var input_store_name: LineEdit
var selected_perk_id: String = "neighbor"
var perk_buttons: Dictionary = {}

# Scene 3 (Morning Market) Controls
var lbl_market_header: Label
var lbl_market_budget: Label
var lbl_market_forecast: Label
var market_items_grid: GridContainer

# Scene 5 (Night Home Summary) Controls
var lbl_night_title: Label
var lbl_night_story: Label
var lbl_night_stats: Label
var night_debt_box: VBoxContainer
var btn_night_upgrade: Button

var _build_active: bool = false
var _selected_furn_idx: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.current_phase = GameManager.StorePhase.OPEN_FOR_BUSINESS
	_build_responsive_skeleton()
	_build_floating_ledger_notepad()
	_build_checkout_drawer()
	_build_stamp_fx()
	_build_multi_scene_modals()
	_connect_signals()
	_refresh_all_ui()
	_on_store_phase_changed("OPEN_FOR_BUSINESS")

func _process(_delta: float) -> void:
	if checkout_panel and checkout_panel.visible:
		if not is_instance_valid(active_customer) or active_customer.state != CustomerEntity.State.WAITING_AT_CASHIER:
			_show_next_waiting_customer()
		elif checkout_patience_bar != null:
			var ratio: float = clampf(active_customer.patience_left / maxf(1.0, active_customer.patience_max), 0.0, 1.0)
			checkout_patience_bar.value = ratio * 100.0

func _connect_signals() -> void:
	EventBus.time_updated.connect(_on_time_updated)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.rush_hour_changed.connect(_on_rush_hour_changed)
	EventBus.store_phase_changed.connect(_on_store_phase_changed)
	EventBus.money_changed.connect(func(_m: int, _d: int) -> void: _refresh_stats())
	EventBus.reputation_changed.connect(func(_r: int, _d: int) -> void: _refresh_stats())
	EventBus.candy_jar_changed.connect(func(_c: int) -> void: _refresh_stats())
	EventBus.inventory_updated.connect(_on_inventory_or_debt_changed)
	EventBus.debt_ledger_updated.connect(_on_inventory_or_debt_changed)
	EventBus.store_level_changed.connect(func(_l: int, _t: String, _r: float) -> void: _refresh_level_badge())
	EventBus.customer_waiting_at_checkout.connect(_on_customer_waiting_at_checkout)
	EventBus.checkout_resolved.connect(_on_checkout_resolved)
	EventBus.toast_requested.connect(_show_toast)
	EventBus.stamp_effect_requested.connect(_play_stamp_effect)

func _on_inventory_or_debt_changed() -> void:
	_rebuild_ledger_lists()
	if MorningMarketModal and MorningMarketModal.visible:
		_refresh_morning_market_modal()
	if NightHomeModal and NightHomeModal.visible:
		_refresh_night_home_modal()

func _style_tex_panel(tex: Texture2D, tex_margin: int = 20, pad_h: int = 22, pad_top: int = 18, pad_bot: int = 16) -> StyleBoxTexture:
	var sbt := StyleBoxTexture.new()
	sbt.texture = tex
	sbt.texture_margin_left = tex_margin
	sbt.texture_margin_right = tex_margin
	sbt.texture_margin_top = tex_margin
	sbt.texture_margin_bottom = tex_margin
	sbt.expand_margin_left = 4
	sbt.expand_margin_right = 4
	sbt.expand_margin_top = 4
	sbt.expand_margin_bottom = 4
	sbt.content_margin_left = pad_h
	sbt.content_margin_right = pad_h
	sbt.content_margin_top = pad_top
	sbt.content_margin_bottom = pad_bot
	return sbt

func _style_tex_button(tex: Texture2D, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var sbt := StyleBoxTexture.new()
	sbt.texture = tex
	sbt.modulate_color = modulate
	sbt.texture_margin_left = 22
	sbt.texture_margin_right = 22
	sbt.texture_margin_top = 12
	sbt.texture_margin_bottom = 14
	sbt.expand_margin_left = 2
	sbt.expand_margin_right = 2
	sbt.expand_margin_top = 2
	sbt.expand_margin_bottom = 2
	sbt.content_margin_left = 14
	sbt.content_margin_right = 14
	sbt.content_margin_top = 6
	sbt.content_margin_bottom = 8
	return sbt

func _style_paper_panel(bg_col: Color, border_col: Color, border_width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.17, 0.13, 0.11, 0.14)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(2, 3)
	return sb

func _apply_button_theme(btn: Button, bg_col: Color = PAPER_CREAM, text_col: Color = INK_DARK, _border_col: Color = INK_DARK, f_size: int = 13) -> void:
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, 38.0)
	var btn_tex: Texture2D = TEX_BTN_CREAM
	if bg_col == Color("#D5E8D4"):
		btn_tex = TEX_BTN_GREEN
	elif bg_col == Color("#F9E79F"):
		btn_tex = TEX_BTN_YELLOW
	elif bg_col == Color("#FADBD8"):
		btn_tex = TEX_BTN_PINK

	btn.add_theme_stylebox_override("normal", _style_tex_button(btn_tex, Color.WHITE))
	btn.add_theme_stylebox_override("hover", _style_tex_button(btn_tex, Color(1.06, 1.04, 1.0, 1.0)))
	btn.add_theme_stylebox_override("pressed", _style_tex_button(btn_tex, Color(0.92, 0.89, 0.85, 1.0)))
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", STAMP_RED)
	btn.add_theme_color_override("font_pressed_color", INK_DARK)
	btn.add_theme_font_size_override("font_size", f_size)

func _build_responsive_skeleton() -> void:
	SafeMarginRoot = MarginContainer.new()
	SafeMarginRoot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SafeMarginRoot.add_theme_constant_override("margin_left", 14)
	SafeMarginRoot.add_theme_constant_override("margin_right", 14)
	SafeMarginRoot.add_theme_constant_override("margin_top", 10)
	SafeMarginRoot.add_theme_constant_override("margin_bottom", 10)
	SafeMarginRoot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(SafeMarginRoot)

	MainVBox = VBoxContainer.new()
	MainVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MainVBox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	MainVBox.add_theme_constant_override("separation", 6)
	MainVBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SafeMarginRoot.add_child(MainVBox)

	# ==========================================
	# 1. TOP BAR (Left Status | Center Auto-Fading Toast | Right Level Upgrade)
	# ==========================================
	var top_hbox := HBoxContainer.new()
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_theme_constant_override("separation", 10)
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MainVBox.add_child(top_hbox)

	# 1A. Top-Left Status Card
	var tl_panel := PanelContainer.new()
	tl_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tl_panel.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 18, 20, 14, 12))
	top_hbox.add_child(tl_panel)

	var tl_vbox := VBoxContainer.new()
	tl_vbox.add_theme_constant_override("separation", 3)
	tl_panel.add_child(tl_vbox)

	var row_dt := HBoxContainer.new()
	row_dt.add_theme_constant_override("separation", 6)
	tl_vbox.add_child(row_dt)
	var ic_clk := TextureRect.new()
	ic_clk.texture = ICON_CLOCK
	ic_clk.custom_minimum_size = Vector2(18, 18)
	ic_clk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_clk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_dt.add_child(ic_clk)
	lbl_day_time = Label.new()
	lbl_day_time.add_theme_color_override("font_color", INK_DARK)
	lbl_day_time.add_theme_font_size_override("font_size", 12)
	row_dt.add_child(lbl_day_time)

	var row_wt := HBoxContainer.new()
	row_wt.add_theme_constant_override("separation", 6)
	tl_vbox.add_child(row_wt)
	icon_weather_hud = TextureRect.new()
	icon_weather_hud.texture = ICON_SUN
	icon_weather_hud.custom_minimum_size = Vector2(18, 18)
	icon_weather_hud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_weather_hud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_wt.add_child(icon_weather_hud)
	lbl_weather = Label.new()
	lbl_weather.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.25))
	lbl_weather.add_theme_font_size_override("font_size", 12)
	row_wt.add_child(lbl_weather)

	var row_mn := HBoxContainer.new()
	row_mn.add_theme_constant_override("separation", 6)
	tl_vbox.add_child(row_mn)
	var ic_mn := TextureRect.new()
	ic_mn.texture = ICON_MONEY
	ic_mn.custom_minimum_size = Vector2(20, 20)
	ic_mn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_mn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_mn.add_child(ic_mn)
	lbl_money = Label.new()
	lbl_money.add_theme_color_override("font_color", STAMP_RED)
	lbl_money.add_theme_font_size_override("font_size", 14)
	row_mn.add_child(lbl_money)

	var row_rc := HBoxContainer.new()
	row_rc.add_theme_constant_override("separation", 6)
	tl_vbox.add_child(row_rc)
	var ic_ht := TextureRect.new()
	ic_ht.texture = ICON_HEART
	ic_ht.custom_minimum_size = Vector2(18, 18)
	ic_ht.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_ht.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_rc.add_child(ic_ht)
	lbl_rep_candy = Label.new()
	lbl_rep_candy.add_theme_color_override("font_color", INK_DARK)
	lbl_rep_candy.add_theme_font_size_override("font_size", 12)
	row_rc.add_child(lbl_rep_candy)

	# 1B. Top-Center Auto-Fading Toast Strip (NEVER permanently covers the store signboard!)
	var center_holder := HBoxContainer.new()
	center_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	center_holder.alignment = BoxContainer.ALIGNMENT_CENTER
	center_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(center_holder)

	toast_panel = PanelContainer.new()
	toast_panel.custom_minimum_size = Vector2(320, 0)
	toast_panel.add_theme_stylebox_override("panel", _style_paper_panel(Color("#FFF8E8"), Color("#8A4B38"), 2))
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.modulate.a = 0.0
	center_holder.add_child(toast_panel)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", INK_DARK)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(toast_label)

	# 1C. Top-Right Level & Watercolor Expansion Widget
	var tr_panel := PanelContainer.new()
	tr_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tr_panel.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 18, 20, 14, 12))
	top_hbox.add_child(tr_panel)

	var tr_vbox := VBoxContainer.new()
	tr_vbox.add_theme_constant_override("separation", 4)
	tr_panel.add_child(tr_vbox)

	lbl_level_title = Label.new()
	lbl_level_title.add_theme_color_override("font_color", INK_DARK)
	lbl_level_title.add_theme_font_size_override("font_size", 13)
	tr_vbox.add_child(lbl_level_title)

	btn_upgrade_level = Button.new()
	_apply_button_theme(btn_upgrade_level, Color("#F9E79F"), INK_DARK, STAMP_RED, 12)
	btn_upgrade_level.pressed.connect(func() -> void: GameManager.try_upgrade_store_level())
	tr_vbox.add_child(btn_upgrade_level)

	# ==========================================
	# 2. MIDDLE EXPANDING WORKSPACE
	# ==========================================
	MiddleWorkspace = Control.new()
	MiddleWorkspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MiddleWorkspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	MiddleWorkspace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MainVBox.add_child(MiddleWorkspace)

	# ==========================================
	# 3. BOTTOM SLIM WATERCOLOR TOOLBAR
	# ==========================================
	var bot_center_row := HBoxContainer.new()
	bot_center_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_center_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_center_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MainVBox.add_child(bot_center_row)

	var bot_panel := PanelContainer.new()
	bot_panel.add_theme_stylebox_override("panel", _style_tex_panel(TEX_STRIP_LONG, 20, 28, 10, 10))
	bot_center_row.add_child(bot_panel)

	var bot_hbox := HBoxContainer.new()
	bot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_hbox.add_theme_constant_override("separation", 8)
	bot_panel.add_child(bot_hbox)

	var btn_menu_home := Button.new()
	btn_menu_home.text = "📖 Menu"
	_apply_button_theme(btn_menu_home, PAPER_CREAM)
	btn_menu_home.pressed.connect(func() -> void:
		GameManager.save_game()
		GameManager.change_to_phase_scene(GameManager.StorePhase.STORY_INTRO)
	)
	bot_hbox.add_child(btn_menu_home)

	btn_toggle_ledger = Button.new()
	btn_toggle_ledger.text = "📓 Sổ Cái & Sổ Nợ"
	_apply_button_theme(btn_toggle_ledger, PAPER_WARM)
	btn_toggle_ledger.pressed.connect(_toggle_ledger_panel)
	bot_hbox.add_child(btn_toggle_ledger)

	btn_toggle_build = Button.new()
	btn_toggle_build.text = "🔨 Đóng Kệ: TẮT"
	_apply_button_theme(btn_toggle_build, PAPER_CREAM)
	btn_toggle_build.pressed.connect(_on_toggle_build_pressed)
	bot_hbox.add_child(btn_toggle_build)

	var btn_refill_candy := Button.new()
	btn_refill_candy.text = "🍬 Mua Kẹo (-3.000đ)"
	_apply_button_theme(btn_refill_candy, PAPER_CREAM)
	btn_refill_candy.pressed.connect(func() -> void: EconomyManager.refill_candy_jar())
	bot_hbox.add_child(btn_refill_candy)

	btn_auto_cashier = Button.new()
	btn_auto_cashier.text = "⚡ Tự Thu Ngân: TẮT"
	_apply_button_theme(btn_auto_cashier, PAPER_CREAM)
	btn_auto_cashier.pressed.connect(_on_toggle_auto_cashier)
	bot_hbox.add_child(btn_auto_cashier)

	btn_speed = Button.new()
	btn_speed.text = "⏩ Tốc Độ: x1"
	_apply_button_theme(btn_speed, PAPER_CREAM)
	btn_speed.pressed.connect(_on_toggle_speed)
	bot_hbox.add_child(btn_speed)

	btn_close_night = Button.new()
	btn_close_night.text = "🌙 Đóng Tiệm Về Nhà"
	_apply_button_theme(btn_close_night, Color("#D5E8D4"), INK_DARK, SAGE_GREEN)
	btn_close_night.pressed.connect(func() -> void: GameManager.close_store_for_night())
	bot_hbox.add_child(btn_close_night)

# ==============================================================================
# MULTI-SCENE MODAL BUILDER (SCENES 1, 2, 3, 5)
# ==============================================================================
func _build_multi_scene_modals() -> void:
	SceneBackdrop = ColorRect.new()
	SceneBackdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SceneBackdrop.color = Color(0.16, 0.12, 0.09, 0.58)
	SceneBackdrop.visible = false
	add_child(SceneBackdrop)

	_build_scene1_story_intro()
	_build_scene2_owner_setup()
	_build_scene3_morning_market()
	_build_scene5_night_home()

func _build_scene1_story_intro() -> void:
	StoryIntroModal = PanelContainer.new()
	StoryIntroModal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	StoryIntroModal.custom_minimum_size = Vector2(720, 440)
	StoryIntroModal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	StoryIntroModal.grow_vertical = Control.GROW_DIRECTION_BOTH
	StoryIntroModal.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 24, 38, 32, 30))
	StoryIntroModal.visible = false
	SceneBackdrop.add_child(StoryIntroModal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	StoryIntroModal.add_child(vbox)

	var title := Label.new()
	title.text = "🎨 TẠP HÓA MÀU NƯỚC — KÝ ỨC ĐẦU NGÕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", STAMP_RED)
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Chương Mở Đầu: Trở Về Dưới Bóng Cây Đa Cũ"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.25))
	sub.add_theme_font_size_override("font_size", 14)
	vbox.add_child(sub)

	var story_card := PanelContainer.new()
	story_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(story_card)

	var story_hbox := HBoxContainer.new()
	story_hbox.add_theme_constant_override("separation", 18)
	story_card.add_child(story_hbox)

	var portrait := TextureRect.new()
	portrait.texture = TEX_SHOPKEEPER
	portrait.custom_minimum_size = Vector2(110, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_hbox.add_child(portrait)

	var story_lbl := Label.new()
	story_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_lbl.add_theme_color_override("font_color", INK_DARK)
	story_lbl.add_theme_font_size_override("font_size", 14)
	story_lbl.text = (
		"Sau những năm tháng bôn ba nơi phố thị ồn ào, bạn quyết định trở về căn nhà nhỏ dưới bóng cây đa đầu ngõ.\n\n" +
		"Bà ngoại để lại chiếc quầy gỗ cũ, cuốn sổ cái ố vàng ghi những khoản nợ ân tình của bà con lối xóm, và hũ thủy tinh đựng kẹo lẻ...\n\n" +
		"Lúc này khu phố trong ký ức vẫn còn là những nét phác thảo chì mộc mạc. Mỗi gói mì trẻ em lúc tan trường, mỗi chén trà đá mát ruột dưới gốc đa và từng chút Tình Làng Nghĩa Xóm (♥) bạn vun đắp sẽ giúp màu nước loang rộng, tô ấm lại cả khu phố xưa!"
	)
	story_hbox.add_child(story_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_row)

	var btn_start := Button.new()
	btn_start.text = "📖 Mở Trang Ký Ức Mới (Đặt Tên Chủ & Khai Trương Tiệm)"
	btn_start.custom_minimum_size = Vector2(360, 44)
	_apply_button_theme(btn_start, Color("#F9E79F"), INK_DARK, STAMP_RED, 14)
	btn_start.pressed.connect(func() -> void: GameManager.begin_owner_setup())
	btn_row.add_child(btn_start)

	var btn_quick := Button.new()
	btn_quick.text = "▶ Vào Nhanh Tiệm Mặc Định"
	btn_quick.custom_minimum_size = Vector2(210, 44)
	_apply_button_theme(btn_quick, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 13)
	btn_quick.pressed.connect(func() -> void: GameManager.skip_to_daytime_store())
	btn_row.add_child(btn_quick)

func _build_scene2_owner_setup() -> void:
	OwnerSetupModal = PanelContainer.new()
	OwnerSetupModal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	OwnerSetupModal.custom_minimum_size = Vector2(740, 480)
	OwnerSetupModal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	OwnerSetupModal.grow_vertical = Control.GROW_DIRECTION_BOTH
	OwnerSetupModal.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 24, 36, 28, 26))
	OwnerSetupModal.visible = false
	SceneBackdrop.add_child(OwnerSetupModal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	OwnerSetupModal.add_child(vbox)

	var title := Label.new()
	title.text = "📝 GIẤY ĐĂNG KÝ KHAI TRƯƠNG TIỆM TẠP HÓA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", STAMP_RED)
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	# 1. Điền Tên Chủ Quán
	var owner_card := PanelContainer.new()
	owner_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(owner_card)

	var owner_vbox := VBoxContainer.new()
	owner_vbox.add_theme_constant_override("separation", 6)
	owner_card.add_child(owner_vbox)

	var lbl1 := Label.new()
	lbl1.text = "1. Tên Chủ Quán (Bà con hàng xóm & các cháu học sinh sẽ gọi bạn là):"
	lbl1.add_theme_color_override("font_color", INK_DARK)
	lbl1.add_theme_font_size_override("font_size", 13)
	owner_vbox.add_child(lbl1)

	var owner_row := HBoxContainer.new()
	owner_row.add_theme_constant_override("separation", 8)
	owner_vbox.add_child(owner_row)

	input_owner_name = LineEdit.new()
	input_owner_name.text = "Bà Ba"
	input_owner_name.placeholder_text = "Nhập tên chủ quán..."
	input_owner_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_owner_name.add_theme_color_override("font_color", INK_DARK)
	input_owner_name.add_theme_stylebox_override("normal", _style_paper_panel(PAPER_CREAM, INK_DARK, 1))
	owner_row.add_child(input_owner_name)

	for preset_owner in ["Bà Ba", "Cô Út", "Chú Tư", "Anh Minh"]:
		var b := Button.new()
		b.text = preset_owner
		_apply_button_theme(b, PAPER_CREAM, INK_DARK, INK_DARK, 12)
		var po: String = preset_owner
		b.pressed.connect(func() -> void: input_owner_name.text = po)
		owner_row.add_child(b)

	# 2. Đặt Tên Biển Hiệu Tạp Hóa
	var store_card := PanelContainer.new()
	store_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(store_card)

	var store_vbox := VBoxContainer.new()
	store_vbox.add_theme_constant_override("separation", 6)
	store_card.add_child(store_vbox)

	var lbl2 := Label.new()
	lbl2.text = "2. Tên Biển Hiệu Gỗ Trước Hiên Tiệm:"
	lbl2.add_theme_color_override("font_color", INK_DARK)
	lbl2.add_theme_font_size_override("font_size", 13)
	store_vbox.add_child(lbl2)

	var store_row := HBoxContainer.new()
	store_row.add_theme_constant_override("separation", 8)
	store_vbox.add_child(store_row)

	input_store_name = LineEdit.new()
	input_store_name.text = "TẠP HÓA BÀ BA"
	input_store_name.placeholder_text = "Nhập tên biển hiệu tạp hóa..."
	input_store_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_store_name.add_theme_color_override("font_color", STAMP_RED)
	input_store_name.add_theme_stylebox_override("normal", _style_paper_panel(PAPER_CREAM, INK_DARK, 1))
	store_row.add_child(input_store_name)

	for preset_store in ["TẠP HÓA BÀ BA", "TIỆM KÝ ỨC", "TẠP HÓA MÀU NƯỚC"]:
		var b := Button.new()
		b.text = preset_store
		_apply_button_theme(b, PAPER_CREAM, INK_DARK, INK_DARK, 11)
		var ps: String = preset_store
		b.pressed.connect(func() -> void: input_store_name.text = ps)
		store_row.add_child(b)

	# 3. Chọn Phương Châm Khởi Đầu
	var perk_card := PanelContainer.new()
	perk_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(perk_card)

	var perk_vbox := VBoxContainer.new()
	perk_vbox.add_theme_constant_override("separation", 6)
	perk_card.add_child(perk_vbox)

	var lbl3 := Label.new()
	lbl3.text = "3. Chọn Lợi Thế Khai Trương Của Gia Đình:"
	lbl3.add_theme_color_override("font_color", INK_DARK)
	lbl3.add_theme_font_size_override("font_size", 13)
	perk_vbox.add_child(lbl3)

	var perk_row := HBoxContainer.new()
	perk_row.add_theme_constant_override("separation", 8)
	perk_vbox.add_child(perk_row)

	var perks_info: Array[Dictionary] = [
		{"id": "neighbor", "label": "♥ Hiếu Khách (+10 ♥ & +10 Kẹo)"},
		{"id": "capital", "label": "💰 Vốn Mạnh (+15.000đ Vốn)"},
		{"id": "stock", "label": "📦 Kho Đầy (+6 Gói Mỗi Loại)"}
	]
	for p in perks_info:
		var pb := Button.new()
		pb.text = p["label"]
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pid: String = p["id"]
		perk_buttons[pid] = pb
		pb.pressed.connect(func() -> void: _select_perk(pid))
		perk_row.add_child(pb)
	_select_perk("neighbor")

	var btn_confirm := Button.new()
	btn_confirm.text = "💮 ĐÓNG DẤU KHAI TRƯƠNG & ĐI CHỢ SỈ SÁNG SỚM ➔"
	btn_confirm.custom_minimum_size = Vector2(0, 44)
	_apply_button_theme(btn_confirm, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 14)
	btn_confirm.pressed.connect(func() -> void:
		GameManager.complete_owner_setup(input_owner_name.text, input_store_name.text, selected_perk_id)
	)
	vbox.add_child(btn_confirm)

func _select_perk(perk_id: String) -> void:
	selected_perk_id = perk_id
	for k in perk_buttons:
		var b: Button = perk_buttons[k]
		if k == perk_id:
			_apply_button_theme(b, Color("#F9E79F"), STAMP_RED, STAMP_RED, 12)
		else:
			_apply_button_theme(b, PAPER_CREAM, INK_DARK, INK_DARK, 12)

func _build_scene3_morning_market() -> void:
	MorningMarketModal = PanelContainer.new()
	MorningMarketModal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	MorningMarketModal.custom_minimum_size = Vector2(880, 560)
	MorningMarketModal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	MorningMarketModal.grow_vertical = Control.GROW_DIRECTION_BOTH
	MorningMarketModal.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 24, 32, 24, 22))
	MorningMarketModal.visible = false
	SceneBackdrop.add_child(MorningMarketModal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	MorningMarketModal.add_child(vbox)

	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	lbl_market_header = Label.new()
	lbl_market_header.text = "🚲 CHỢ ĐẦU MỐI SÁNG SỚM — NGÀY 1 (06:30)"
	lbl_market_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_market_header.add_theme_color_override("font_color", STAMP_RED)
	lbl_market_header.add_theme_font_size_override("font_size", 18)
	top_row.add_child(lbl_market_header)

	lbl_market_budget = Label.new()
	lbl_market_budget.add_theme_color_override("font_color", INK_DARK)
	lbl_market_budget.add_theme_font_size_override("font_size", 14)
	top_row.add_child(lbl_market_budget)

	var forecast_card := PanelContainer.new()
	forecast_card.add_theme_stylebox_override("panel", _style_paper_panel(Color("#F9E79F"), INK_DARK, 1))
	vbox.add_child(forecast_card)

	lbl_market_forecast = Label.new()
	lbl_market_forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_market_forecast.add_theme_color_override("font_color", INK_DARK)
	lbl_market_forecast.add_theme_font_size_override("font_size", 13)
	forecast_card.add_child(lbl_market_forecast)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	market_items_grid = GridContainer.new()
	market_items_grid.columns = 2
	market_items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_items_grid.add_theme_constant_override("h_separation", 10)
	market_items_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(market_items_grid)

	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 12)
	vbox.add_child(bot_row)

	var btn_buy_candy := Button.new()
	btn_buy_candy.text = "🍬 Mua Thêm +10 Viên Kẹo Lẻ (-3.000đ)"
	_apply_button_theme(btn_buy_candy, PAPER_CREAM, INK_DARK, INK_DARK, 13)
	btn_buy_candy.pressed.connect(func() -> void:
		EconomyManager.refill_candy_jar()
		_refresh_morning_market_modal()
	)
	bot_row.add_child(btn_buy_candy)

	var btn_open_store := Button.new()
	btn_open_store.text = "🔓 KÉO CỬA MỞ HÀNG ĐÓN KHÁCH (BẮT ĐẦU 07:00 SÁNG) ➔"
	btn_open_store.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_open_store.custom_minimum_size = Vector2(0, 44)
	_apply_button_theme(btn_open_store, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 14)
	btn_open_store.pressed.connect(func() -> void: GameManager.open_store_for_day())
	bot_row.add_child(btn_open_store)

func _refresh_morning_market_modal() -> void:
	if lbl_market_header == null:
		return
	lbl_market_header.text = "🚲 CHỢ ĐẦU MỐI SÁNG SỚM — NGÀY %d (%s)" % [GameManager.current_day, GameManager.store_name]
	lbl_market_budget.text = "💰 Vốn: %s đ  |  ♥ Tình làng xóm: %d  |  🍬 Kẹo: %d viên" % [
		EconomyManager.format_vnd(EconomyManager.money),
		EconomyManager.reputation,
		EconomyManager.candy_jar
	]
	lbl_market_forecast.text = GameManager.get_weather_forecast_advice()

	for child in market_items_grid.get_children():
		child.queue_free()

	for item_id in EconomyManager.item_catalog:
		var item: ItemData = EconomyManager.item_catalog[item_id]
		var stock: int = EconomyManager.warehouse_stock.get(item_id, 0)

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
		market_items_grid.add_child(card)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		if item.icon:
			var tr := TextureRect.new()
			tr.texture = item.icon
			tr.custom_minimum_size = Vector2(44, 44)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(tr)

		var ivbox := VBoxContainer.new()
		ivbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ivbox.add_theme_constant_override("separation", 3)
		hbox.add_child(ivbox)

		var name_lbl := Label.new()
		name_lbl.text = "%s  (Tồn kho: %d gói)" % [item.display_name, stock]
		name_lbl.add_theme_color_override("font_color", INK_DARK)
		name_lbl.add_theme_font_size_override("font_size", 13)
		ivbox.add_child(name_lbl)

		var raw_base: Variant = item.get("base_price")
		var safe_base: int = int(raw_base) if raw_base != null and int(raw_base) > 0 else (item.wholesale_cost * 2)
		var mood_tag: String = "👌 Giá chuẩn"
		if item.retail_price < safe_base:
			mood_tag = "💚 Giá rẻ hút khách"
		elif item.retail_price > safe_base:
			mood_tag = "⚠️ Giá cao (Dễ bị chê)"

		var price_lbl := Label.new()
		price_lbl.text = "Sỉ: %sđ → Bán lẻ: %sđ [%s]" % [
			EconomyManager.format_vnd(item.wholesale_cost),
			EconomyManager.format_vnd(item.retail_price),
			mood_tag
		]
		price_lbl.add_theme_color_override("font_color", INK_DARK.lightened(0.2))
		price_lbl.add_theme_font_size_override("font_size", 11)
		ivbox.add_child(price_lbl)

		var act_row := HBoxContainer.new()
		act_row.add_theme_constant_override("separation", 6)
		ivbox.add_child(act_row)

		var btn_buy := Button.new()
		btn_buy.text = "📦 Nhập +8 (%sđ)" % EconomyManager.format_vnd(item.wholesale_cost * 8)
		_apply_button_theme(btn_buy, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 11)
		btn_buy.pressed.connect(func() -> void: EconomyManager.buy_wholesale_pack(item.id, 8))
		act_row.add_child(btn_buy)

		var btn_minus := Button.new()
		btn_minus.text = "-500đ"
		_apply_button_theme(btn_minus, PAPER_CREAM, INK_DARK, INK_DARK, 11)
		btn_minus.pressed.connect(func() -> void: EconomyManager.adjust_item_price(item.id, -500))
		act_row.add_child(btn_minus)

		var btn_plus := Button.new()
		btn_plus.text = "+500đ"
		_apply_button_theme(btn_plus, PAPER_CREAM, INK_DARK, INK_DARK, 11)
		btn_plus.pressed.connect(func() -> void: EconomyManager.adjust_item_price(item.id, 500))
		act_row.add_child(btn_plus)

func _build_scene5_night_home() -> void:
	NightHomeModal = PanelContainer.new()
	NightHomeModal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	NightHomeModal.custom_minimum_size = Vector2(780, 520)
	NightHomeModal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	NightHomeModal.grow_vertical = Control.GROW_DIRECTION_BOTH
	NightHomeModal.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 24, 34, 26, 24))
	NightHomeModal.visible = false
	SceneBackdrop.add_child(NightHomeModal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	NightHomeModal.add_child(vbox)

	lbl_night_title = Label.new()
	lbl_night_title.text = "🌙 ĐÓNG TIỆM VỀ NHÀ — TỔNG KẾT ĐÊM NGÀY 1"
	lbl_night_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_night_title.add_theme_color_override("font_color", STAMP_RED)
	lbl_night_title.add_theme_font_size_override("font_size", 19)
	vbox.add_child(lbl_night_title)

	# Nhật ký đêm xóm nhỏ
	var story_box := PanelContainer.new()
	story_box.add_theme_stylebox_override("panel", _style_paper_panel( Color("#F9E79F"), INK_DARK, 1))
	vbox.add_child(story_box)

	lbl_night_story = Label.new()
	lbl_night_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_night_story.add_theme_color_override("font_color", INK_DARK)
	lbl_night_story.add_theme_font_size_override("font_size", 13)
	story_box.add_child(lbl_night_story)

	# Bảng thống kê doanh thu & sổ nợ
	var mid_hbox := HBoxContainer.new()
	mid_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(mid_hbox)

	var stats_card := PanelContainer.new()
	stats_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	mid_hbox.add_child(stats_card)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_card.add_child(stats_vbox)

	lbl_night_stats = Label.new()
	lbl_night_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_night_stats.add_theme_color_override("font_color", INK_DARK)
	lbl_night_stats.add_theme_font_size_override("font_size", 13)
	stats_vbox.add_child(lbl_night_stats)

	btn_night_upgrade = Button.new()
	_apply_button_theme(btn_night_upgrade, Color("#F9E79F"), INK_DARK, STAMP_RED, 12)
	btn_night_upgrade.pressed.connect(func() -> void:
		GameManager.try_upgrade_store_level()
		_refresh_night_home_modal()
	)
	stats_vbox.add_child(btn_night_upgrade)

	var debt_card := PanelContainer.new()
	debt_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debt_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	mid_hbox.add_child(debt_card)

	var debt_scroll := ScrollContainer.new()
	debt_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debt_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debt_card.add_child(debt_scroll)

	night_debt_box = VBoxContainer.new()
	night_debt_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	night_debt_box.add_theme_constant_override("separation", 6)
	debt_scroll.add_child(night_debt_box)

	var btn_sleep := Button.new()
	btn_sleep.text = "🌅 ĐI NGỦ & SÁNG MAI ĐI CHỢ SỈ (QUA NGÀY MỚI) ➔"
	btn_sleep.custom_minimum_size = Vector2(0, 44)
	_apply_button_theme(btn_sleep, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 14)
	btn_sleep.pressed.connect(func() -> void: GameManager.start_next_day())
	vbox.add_child(btn_sleep)

func _refresh_night_home_modal() -> void:
	if lbl_night_title == null:
		return
	lbl_night_title.text = "🌙 ĐÓNG TIỆM VỀ NHÀ — TỔNG KẾT ĐÊM NGÀY %d (%s)" % [GameManager.current_day, GameManager.store_name]
	lbl_night_story.text = GameManager.get_daily_story_vignette()

	var net_profit: int = GameManager.daily_revenue - GameManager.daily_spent
	var profit_sign: String = "+" if net_profit >= 0 else ""
	lbl_night_stats.text = (
		"📊 BÁO CÁO THU CHI HÔM NAY:\n" +
		"• Doanh thu bán lẻ & trà đá: +%s đ\n" % EconomyManager.format_vnd(GameManager.daily_revenue) +
		"• Chi phí nhập sỉ & đóng kệ: -%s đ\n" % EconomyManager.format_vnd(GameManager.daily_spent) +
		"• Chênh lệch thu chi trong ngày: %s%s đ\n\n" % [profit_sign, EconomyManager.format_vnd(net_profit)] +
		"👥 LƯỢT KHÁCH GHÉ TIỆM:\n" +
		"• Khách mua hài lòng: %d lượt\n" % GameManager.daily_customers_served +
		"• Khách đổi ý / bỏ về: %d lượt\n\n" % GameManager.daily_customers_left +
		"💰 Vốn hiện có: %s đ  |  ♥ Tình làng xóm: %d" % [EconomyManager.format_vnd(EconomyManager.money), EconomyManager.reputation]
	)

	var lvl: int = GameManager.store_level
	var cfg: Dictionary = GameManager.level_configs[lvl]
	if lvl < 4:
		btn_night_upgrade.text = "🎨 Tô Màu Mở Rộng Cấp %d (%s đ & %d ♥)" % [
			lvl + 1,
			EconomyManager.format_vnd(cfg["upgrade_cost"]),
			cfg["rep_required"]
		]
		btn_night_upgrade.disabled = false
	else:
		btn_night_upgrade.text = "✨ Đã tô màu trọn vẹn khu phố!"
		btn_night_upgrade.disabled = true

	for child in night_debt_box.get_children():
		child.queue_free()

	var debt_head := Label.new()
	debt_head.text = "📓 Sổ Ghi Nợ Hàng Xóm (%s đ):" % EconomyManager.format_vnd(EconomyManager.get_unpaid_debt_total())
	debt_head.add_theme_color_override("font_color", STAMP_RED)
	debt_head.add_theme_font_size_override("font_size", 13)
	night_debt_box.add_child(debt_head)

	for rec: DebtRecord in EconomyManager.debt_records:
		if rec.is_paid:
			continue
		var row := HBoxContainer.new()
		night_debt_box.add_child(row)

		var rl := Label.new()
		rl.text = "• %s: %sđ" % [rec.customer_name, EconomyManager.format_vnd(rec.amount)]
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rl.add_theme_color_override("font_color", INK_DARK)
		rl.add_theme_font_size_override("font_size", 12)
		row.add_child(rl)

		var bc := Button.new()
		bc.text = "💮 Thu nợ"
		_apply_button_theme(bc, Color("#FADBD8"), STAMP_RED, STAMP_RED, 11)
		var rid: int = rec.record_id
		bc.pressed.connect(func() -> void: EconomyManager.collect_debt(rid))
		row.add_child(bc)

func _on_store_phase_changed(phase_id: String) -> void:
	var is_daytime: bool = (phase_id == "OPEN_FOR_BUSINESS")
	MainVBox.visible = is_daytime
	SceneBackdrop.visible = not is_daytime

	StoryIntroModal.visible = (phase_id == "STORY_INTRO")
	OwnerSetupModal.visible = (phase_id == "OWNER_SETUP")
	MorningMarketModal.visible = (phase_id == "MORNING_PREP")
	NightHomeModal.visible = (phase_id == "NIGHT_SUMMARY")

	if phase_id == "MORNING_PREP":
		_refresh_morning_market_modal()
	elif phase_id == "NIGHT_SUMMARY":
		waiting_queue.clear()
		active_customer = null
		checkout_panel.visible = false
		ledger_panel.visible = false
		_refresh_night_home_modal()

# ==============================================================================
# DAYTIME FLOATING PANELS (LEDGER & CHECKOUT)
# ==============================================================================
func _build_floating_ledger_notepad() -> void:
	ledger_panel = PanelContainer.new()
	ledger_panel.anchor_left = 1.0
	ledger_panel.anchor_right = 1.0
	ledger_panel.anchor_top = 0.0
	ledger_panel.anchor_bottom = 1.0
	ledger_panel.offset_left = -450.0
	ledger_panel.offset_right = 0.0
	ledger_panel.offset_top = 4.0
	ledger_panel.offset_bottom = -4.0
	ledger_panel.add_theme_stylebox_override("panel", _style_tex_panel(TEX_NOTEBOOK, 24, 28, 24, 18))
	ledger_panel.visible = false
	MiddleWorkspace.add_child(ledger_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 8)
	ledger_panel.add_child(main_vbox)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 6)
	main_vbox.add_child(header_hbox)

	var btn_tab_inv := Button.new()
	btn_tab_inv.text = "📦 Nhập Sỉ & Giá Bán"
	btn_tab_inv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_theme(btn_tab_inv, PAPER_WARM)
	btn_tab_inv.pressed.connect(func() -> void:
		current_ledger_tab = "inventory"
		_rebuild_ledger_lists()
	)
	header_hbox.add_child(btn_tab_inv)

	var btn_tab_debt := Button.new()
	btn_tab_debt.text = "📓 Sổ Ghi Nợ"
	btn_tab_debt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_theme(btn_tab_debt, Color("#FADBD8"))
	btn_tab_debt.pressed.connect(func() -> void:
		current_ledger_tab = "debt"
		_rebuild_ledger_lists()
	)
	header_hbox.add_child(btn_tab_debt)

	var btn_close := Button.new()
	btn_close.text = "✕"
	_apply_button_theme(btn_close, PAPER_CREAM, STAMP_RED)
	btn_close.pressed.connect(func() -> void:
		ledger_panel.visible = false
		_show_next_waiting_customer()
	)
	header_hbox.add_child(btn_close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	var content_holder := VBoxContainer.new()
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_holder)

	tab_inventory_box = VBoxContainer.new()
	tab_inventory_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_inventory_box.add_theme_constant_override("separation", 6)
	content_holder.add_child(tab_inventory_box)

	tab_debt_box = VBoxContainer.new()
	tab_debt_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_debt_box.add_theme_constant_override("separation", 6)
	content_holder.add_child(tab_debt_box)

func _build_checkout_drawer() -> void:
	checkout_panel = PanelContainer.new()
	checkout_panel.anchor_left = 0.0
	checkout_panel.anchor_right = 0.0
	checkout_panel.anchor_top = 1.0
	checkout_panel.anchor_bottom = 1.0
	checkout_panel.offset_left = 0.0
	checkout_panel.offset_right = 410.0
	checkout_panel.offset_top = -170.0
	checkout_panel.offset_bottom = -6.0
	checkout_panel.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 20, 20, 16, 16))
	checkout_panel.visible = false
	MiddleWorkspace.add_child(checkout_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	checkout_panel.add_child(vbox)

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	var title := Label.new()
	title.text = "🧾 PHIẾU TÍNH TIỀN"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", STAMP_RED)
	title.add_theme_font_size_override("font_size", 14)
	header_row.add_child(title)

	lbl_checkout_queue_badge = Label.new()
	lbl_checkout_queue_badge.text = "Đang chờ: 1"
	lbl_checkout_queue_badge.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.25))
	lbl_checkout_queue_badge.add_theme_font_size_override("font_size", 12)
	header_row.add_child(lbl_checkout_queue_badge)

	var item_card := PanelContainer.new()
	item_card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(item_card)

	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 10)
	item_card.add_child(info_hbox)

	checkout_item_icon = TextureRect.new()
	checkout_item_icon.custom_minimum_size = Vector2(44, 44)
	checkout_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	checkout_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info_hbox.add_child(checkout_item_icon)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	info_hbox.add_child(info_vbox)

	lbl_checkout_info = Label.new()
	lbl_checkout_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_checkout_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_checkout_info.add_theme_color_override("font_color", INK_DARK)
	lbl_checkout_info.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(lbl_checkout_info)

	checkout_patience_bar = ProgressBar.new()
	checkout_patience_bar.custom_minimum_size = Vector2(0, 6)
	checkout_patience_bar.show_percentage = false
	checkout_patience_bar.max_value = 100.0
	checkout_patience_bar.value = 100.0
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = PAPER_CREAM
	pb_bg.border_color = INK_DARK
	pb_bg.set_border_width_all(1)
	pb_bg.set_corner_radius_all(3)
	var pb_fg := StyleBoxFlat.new()
	pb_fg.bg_color = SAGE_GREEN
	pb_fg.set_corner_radius_all(2)
	checkout_patience_bar.add_theme_stylebox_override("background", pb_bg)
	checkout_patience_bar.add_theme_stylebox_override("fill", pb_fg)
	info_vbox.add_child(checkout_patience_bar)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var btn_exact := Button.new()
	btn_exact.text = "💵 Thu Đủ"
	btn_exact.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_theme(btn_exact, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 12)
	btn_exact.pressed.connect(func() -> void: _resolve_active_customer("exact"))
	btn_row.add_child(btn_exact)

	var btn_candy := Button.new()
	btn_candy.text = "🍬 Thối Kẹo (+2♥)"
	btn_candy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_theme(btn_candy, Color("#F9E79F"), INK_DARK, OCHRE_GOLD, 12)
	btn_candy.pressed.connect(func() -> void: _resolve_active_customer("candy"))
	btn_row.add_child(btn_candy)

	var btn_credit := Button.new()
	btn_credit.text = "📓 Ghi Nợ (+3♥)"
	btn_credit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_theme(btn_credit, Color("#FADBD8"), INK_DARK, STAMP_RED, 12)
	btn_credit.pressed.connect(func() -> void: _resolve_active_customer("credit"))
	btn_row.add_child(btn_credit)

func _build_stamp_fx() -> void:
	stamp_badge = PanelContainer.new()
	stamp_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stamp_badge.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 18, 22, 18, 16))
	stamp_badge.visible = false
	MiddleWorkspace.add_child(stamp_badge)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	stamp_badge.add_child(hbox)

	var ring_icon := TextureRect.new()
	ring_icon.texture = TEX_STAMP_RING
	ring_icon.custom_minimum_size = Vector2(36, 36)
	ring_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(ring_icon)

	lbl_stamp_text = Label.new()
	lbl_stamp_text.add_theme_color_override("font_color", STAMP_RED)
	lbl_stamp_text.add_theme_font_size_override("font_size", 20)
	hbox.add_child(lbl_stamp_text)

func _refresh_all_ui() -> void:
	_on_time_updated(GameManager.current_day, GameManager.current_hour, GameManager.current_minute, GameManager.get_phase_label())
	_on_weather_changed(GameManager.current_weather, GameManager.weather_label)
	_refresh_stats()
	_refresh_level_badge()
	_rebuild_ledger_lists()

func _refresh_stats() -> void:
	lbl_money.text = "Vốn quán: %s đ" % EconomyManager.format_vnd(EconomyManager.money)
	lbl_rep_candy.text = "Tình làng: %d  |  Hũ kẹo: %d viên" % [EconomyManager.reputation, EconomyManager.candy_jar]
	if MorningMarketModal and MorningMarketModal.visible:
		_refresh_morning_market_modal()
	if NightHomeModal and NightHomeModal.visible:
		_refresh_night_home_modal()

func _refresh_level_badge() -> void:
	var lvl: int = GameManager.store_level
	var cfg: Dictionary = GameManager.level_configs[lvl]
	lbl_level_title.text = "🎨 " + cfg["title"]
	if lvl < 4:
		btn_upgrade_level.text = "Tô Màu Mở Rộng Cấp %d (%s đ & %d ♥)" % [
			lvl + 1,
			EconomyManager.format_vnd(cfg["upgrade_cost"]),
			cfg["rep_required"]
		]
		btn_upgrade_level.disabled = false
	else:
		btn_upgrade_level.text = "✨ Đã tô màu toàn bộ khu phố!"
		btn_upgrade_level.disabled = true

func _on_time_updated(day: int, hour: int, minute: int, phase_name: String) -> void:
	var rhythm_label: String = phase_name
	if GameManager.current_phase == GameManager.StorePhase.OPEN_FOR_BUSINESS:
		if GameManager.is_rush_hour:
			rhythm_label = "🔔 Tan trường!"
		elif (hour >= 9 and hour <= 10) or (hour >= 14 and hour <= 15):
			rhythm_label = "🍃 Giờ học (Ngõ vắng)"
		elif hour < 9:
			rhythm_label = "🌅 Sáng mở hàng"
		elif hour >= 18:
			rhythm_label = "🏮 Tối xóm nhỏ"
		else:
			rhythm_label = "☀️ Nhịp thong thả"
	lbl_day_time.text = "Ngày %d — %02d:%02d (%s)" % [day, hour, minute, rhythm_label]

func _on_weather_changed(weather_id: String, label: String) -> void:
	if icon_weather_hud:
		icon_weather_hud.texture = ICON_RAIN if weather_id == "Rainy" else ICON_SUN
	lbl_weather.text = "Thời tiết: %s" % label

func _on_rush_hour_changed(is_active: bool, msg: String) -> void:
	if is_active and msg != "":
		_show_toast(msg, STAMP_RED)

func _toggle_ledger_panel() -> void:
	ledger_panel.visible = not ledger_panel.visible
	if ledger_panel.visible:
		checkout_panel.visible = false
		if _build_active:
			_build_active = false
			btn_toggle_build.text = "🔨 Đóng Kệ: TẮT"
			EventBus.build_mode_toggled.emit(false, "")
		_rebuild_ledger_lists()
	else:
		_show_next_waiting_customer()

func _on_toggle_build_pressed() -> void:
	var furn_keys: Array = EconomyManager.furniture_catalog.keys()
	if not _build_active:
		_build_active = true
		_selected_furn_idx = 0
		ledger_panel.visible = false
	else:
		_selected_furn_idx += 1
		if _selected_furn_idx >= furn_keys.size():
			_build_active = false
			_selected_furn_idx = 0

	if _build_active:
		var f_id: String = furn_keys[_selected_furn_idx]
		var furn: FurnitureData = EconomyManager.furniture_catalog[f_id]
		btn_toggle_build.text = "🔨 Đặt: %s (%sđ)" % [furn.display_name.substr(0, 10), EconomyManager.format_vnd(furn.cost)]
		EventBus.build_mode_toggled.emit(true, f_id)
		_show_toast("🔨 Chạm lên ô sàn trống để đặt %s" % furn.display_name, SAGE_GREEN)
	else:
		btn_toggle_build.text = "🔨 Đóng Kệ: TẮT"
		EventBus.build_mode_toggled.emit(false, "")

func _on_toggle_auto_cashier() -> void:
	GameManager.auto_cashier_enabled = not GameManager.auto_cashier_enabled
	btn_auto_cashier.text = "⚡ Tự Thu Ngân: %s" % ("BẬT" if GameManager.auto_cashier_enabled else "TẮT")
	if GameManager.auto_cashier_enabled and is_instance_valid(active_customer):
		_resolve_active_customer("exact")

func _on_toggle_speed() -> void:
	var spd: float = GameManager.toggle_time_speed()
	btn_speed.text = "⏩ Tốc Độ: x%d" % int(spd)

func _rebuild_ledger_lists() -> void:
	tab_inventory_box.visible = (current_ledger_tab == "inventory")
	tab_debt_box.visible = (current_ledger_tab == "debt")

	for child in tab_inventory_box.get_children():
		child.queue_free()
	for child in tab_debt_box.get_children():
		child.queue_free()

	if current_ledger_tab == "inventory":
		for item_id in EconomyManager.item_catalog:
			var item: ItemData = EconomyManager.item_catalog[item_id]
			var stock: int = EconomyManager.warehouse_stock.get(item_id, 0)

			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _style_paper_panel(PAPER_WARM, INK_DARK, 1))
			tab_inventory_box.add_child(card)

			var row_hbox := HBoxContainer.new()
			row_hbox.add_theme_constant_override("separation", 10)
			card.add_child(row_hbox)

			if item.icon:
				var icon_rect := TextureRect.new()
				icon_rect.texture = item.icon
				icon_rect.custom_minimum_size = Vector2(44, 44)
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row_hbox.add_child(icon_rect)

			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row_hbox.add_child(vbox)

			var top_lbl := Label.new()
			top_lbl.text = "%s  |  Kho: %d gói" % [item.display_name, stock]
			top_lbl.add_theme_color_override("font_color", INK_DARK)
			top_lbl.add_theme_font_size_override("font_size", 13)
			vbox.add_child(top_lbl)

			var desc_lbl := Label.new()
			var raw_base: Variant = item.get("base_price")
			var safe_base_price: int = int(raw_base) if raw_base != null and int(raw_base) > 0 else (item.wholesale_cost * 2)
			var price_mood: String = "👌 Giá chuẩn"
			if item.retail_price < safe_base_price:
				price_mood = "💚 Giá rẻ (Hút khách!)"
			elif item.retail_price > safe_base_price:
				price_mood = "⚠️ Giá cao (Dễ bị chê đắt!)"
			desc_lbl.text = "Giá sỉ: %sđ → Bán lẻ: %sđ  [%s]" % [
				EconomyManager.format_vnd(item.wholesale_cost),
				EconomyManager.format_vnd(item.retail_price),
				price_mood
			]
			desc_lbl.add_theme_color_override("font_color", INK_DARK.lightened(0.22))
			desc_lbl.add_theme_font_size_override("font_size", 11)
			vbox.add_child(desc_lbl)

			var act_row := HBoxContainer.new()
			act_row.add_theme_constant_override("separation", 6)
			vbox.add_child(act_row)

			var btn_buy := Button.new()
			var pack_cost: int = item.wholesale_cost * 8
			btn_buy.text = "📦 Nhập +8 (%sđ)" % EconomyManager.format_vnd(pack_cost)
			_apply_button_theme(btn_buy, Color("#D5E8D4"), INK_DARK, SAGE_GREEN, 12)
			btn_buy.pressed.connect(func() -> void: EconomyManager.buy_wholesale_pack(item.id, 8))
			act_row.add_child(btn_buy)

			var btn_minus := Button.new()
			btn_minus.text = "-500đ"
			_apply_button_theme(btn_minus, PAPER_CREAM, INK_DARK, INK_DARK, 12)
			btn_minus.pressed.connect(func() -> void: EconomyManager.adjust_item_price(item.id, -500))
			act_row.add_child(btn_minus)

			var btn_plus := Button.new()
			btn_plus.text = "+500đ"
			_apply_button_theme(btn_plus, PAPER_CREAM, INK_DARK, INK_DARK, 12)
			btn_plus.pressed.connect(func() -> void: EconomyManager.adjust_item_price(item.id, 500))
			act_row.add_child(btn_plus)
	else:
		var total_lbl := Label.new()
		total_lbl.text = "📓 Tổng nợ hàng xóm: %s đ" % EconomyManager.format_vnd(EconomyManager.get_unpaid_debt_total())
		total_lbl.add_theme_color_override("font_color", STAMP_RED)
		total_lbl.add_theme_font_size_override("font_size", 14)
		tab_debt_box.add_child(total_lbl)

		for rec: DebtRecord in EconomyManager.debt_records:
			var card := PanelContainer.new()
			var bg: Color = PAPER_WARM if not rec.is_paid else Color("#E8ECE9")
			card.add_theme_stylebox_override("panel", _style_paper_panel(bg, INK_DARK, 1))
			tab_debt_box.add_child(card)

			var vbox := VBoxContainer.new()
			card.add_child(vbox)

			var head := Label.new()
			head.text = "%s (%s) — %s đ" % [rec.customer_name, rec.customer_role, EconomyManager.format_vnd(rec.amount)]
			head.add_theme_color_override("font_color", INK_DARK)
			head.add_theme_font_size_override("font_size", 13)
			vbox.add_child(head)

			var note := Label.new()
			note.text = "Ngày %d: %s" % [rec.day_borrowed, rec.note]
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.add_theme_color_override("font_color", INK_DARK.lightened(0.2))
			note.add_theme_font_size_override("font_size", 11)
			vbox.add_child(note)

			if rec.is_paid:
				var paid_lbl := Label.new()
				paid_lbl.text = "[ CỘP DẤU: ĐÃ THU ĐỦ ✔ ]"
				paid_lbl.add_theme_color_override("font_color", SAGE_GREEN.darkened(0.2))
				paid_lbl.add_theme_font_size_override("font_size", 12)
				vbox.add_child(paid_lbl)
			else:
				var btn_collect := Button.new()
				btn_collect.text = "💮 ĐÓNG DẤU: ĐÃ THU (%s đ)" % EconomyManager.format_vnd(rec.amount)
				_apply_button_theme(btn_collect, Color("#FADBD8"), STAMP_RED, STAMP_RED, 12)
				var rid: int = rec.record_id
				btn_collect.pressed.connect(func() -> void:
					if EconomyManager.collect_debt(rid):
						_play_stamp_effect("ĐÃ THU NỢ ✔", Vector2.ZERO)
				)
				vbox.add_child(btn_collect)

func _on_customer_waiting_at_checkout(cust: Node) -> void:
	if not (cust is CustomerEntity):
		return
	var c: CustomerEntity = cust as CustomerEntity
	if not waiting_queue.has(c):
		waiting_queue.append(c)
	_show_next_waiting_customer()

func _show_next_waiting_customer() -> void:
	while not waiting_queue.is_empty() and not is_instance_valid(waiting_queue[0]):
		waiting_queue.pop_front()

	if waiting_queue.is_empty():
		active_customer = null
		checkout_panel.visible = false
		return

	active_customer = waiting_queue[0]
	var item: ItemData = EconomyManager.item_catalog.get(active_customer.wanted_item_id)
	var item_name: String = item.display_name if item else "Hàng tạp hóa"
	if checkout_item_icon:
		checkout_item_icon.texture = item.icon if item else null
		checkout_item_icon.visible = (item != null and item.icon != null)
	if lbl_checkout_queue_badge:
		lbl_checkout_queue_badge.text = "Khách chờ: %d" % waiting_queue.size()
	var bill: int = active_customer.get_total_bill()
	var credit_hint: String = "\n💬 '%s ơi cho ghi sổ bữa nay nhé?'" % GameManager.player_name if active_customer.asks_for_credit else ""

	lbl_checkout_info.text = "%s (%s)\nMua: %d x %s  —  Tổng: %s đ%s" % [
		active_customer.customer_name,
		active_customer.customer_role,
		active_customer.wanted_qty,
		item_name,
		EconomyManager.format_vnd(bill),
		credit_hint
	]
	checkout_panel.visible = not (ledger_panel != null and ledger_panel.visible)

func _resolve_active_customer(method: String) -> void:
	if is_instance_valid(active_customer):
		active_customer.complete_checkout(method)

func _on_checkout_resolved(cust: Node, _method: String) -> void:
	waiting_queue.erase(cust)
	_show_next_waiting_customer()

func _show_toast(message: String, color: Color) -> void:
	if toast_label == null or toast_panel == null:
		return
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", color.darkened(0.18))
	toast_panel.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.8)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.45)

func _play_stamp_effect(text: String, _pos: Vector2) -> void:
	lbl_stamp_text.text = text
	stamp_badge.visible = true
	stamp_badge.scale = Vector2(1.4, 1.4)
	var tw: Tween = create_tween()
	tw.tween_property(stamp_badge, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void: stamp_badge.visible = false)
