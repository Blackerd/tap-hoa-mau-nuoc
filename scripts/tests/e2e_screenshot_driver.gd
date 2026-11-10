extends Node

const OUTPUT_DIR := "res://test_screenshots"

var is_persistent_driver: bool = false
var report_steps: Array[Dictionary] = []


func _ready() -> void:
	if not is_persistent_driver:
		# Spawn a persistent sibling on root that is NOT current_scene
		var driver := Node.new()
		driver.name = "PersistentE2EDriver"
		driver.set_script(get_script())
		driver.set("is_persistent_driver", true)
		get_tree().root.add_child.call_deferred(driver)
		return
	call_deferred("_run_e2e_suite")


func _ensure_output_dir() -> String:
	var abs_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	return abs_dir


func _wait_frames(count: int = 12) -> void:
	for i in range(count):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _capture_step(step_id: String, description: String) -> void:
	await _wait_frames(15)
	var abs_dir := _ensure_output_dir()
	var file_path := abs_dir.path_join(step_id + ".png")
	var img: Image = get_viewport().get_texture().get_image()
	var err := img.save_png(file_path)
	var scene_name := "None"
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	var step_info := {
		"step_id": step_id,
		"description": description,
		"scene": scene_name,
		"resolution": "%dx%d" % [img.get_width(), img.get_height()],
		"saved_ok": (err == OK),
		"path": file_path
	}
	report_steps.append(step_info)
	print("[E2E] Captured: %s (%s) -> %s" % [step_id, description, file_path])


func _run_e2e_suite() -> void:
	print("=== STARTING AUTOMATED E2E SCREENSHOT & UI/UX AUDIT SUITE ===")
	_ensure_output_dir()

	# ---------------------------------------------------------
	# STEP 1: Scene 1 — Story Intro (Page 1 & Page 2)
	# ---------------------------------------------------------
	GameManager.change_to_phase_scene(GameManager.StorePhase.STORY_INTRO)
	await _wait_frames(18)
	await _capture_step("01_scene1_story_intro_p1", "Scene 1: Bìa Sổ Ký Ức & Cốt Truyện Mở Đầu (Trang 1)")

	var intro_scene := get_tree().current_scene
	if intro_scene and intro_scene.get("current_page") != null:
		intro_scene.set("current_page", 1)
		if intro_scene.has_method("_refresh_story_page"):
			intro_scene.call("_refresh_story_page")
		await _capture_step("02_scene1_story_intro_p2", "Scene 1: Cốt Truyện Mở Đầu (Trang 2 - Sổ Ghi Nợ)")

	# ---------------------------------------------------------
	# STEP 2: Scene 2 — Owner Setup (Đăng Ký Khai Trương)
	# ---------------------------------------------------------
	GameManager.begin_new_game_onboarding()
	await _wait_frames(18)
	var setup_scene := get_tree().current_scene
	if setup_scene:
		var inp_owner: LineEdit = setup_scene.get("input_owner_name")
		var inp_store: LineEdit = setup_scene.get("input_store_name")
		if inp_owner:
			inp_owner.text = "Dì Chánh"
		if inp_store:
			inp_store.text = "NGỌC TRÂN TẠP HÓA"
		if setup_scene.has_method("_select_perk"):
			setup_scene.call("_select_perk", "capital")
		if setup_scene.has_method("_update_live_preview"):
			setup_scene.call("_update_live_preview")
	await _capture_step("03_scene2_owner_setup", "Scene 2: Giấy Đăng Ký Khai Trương & Xem Trước Biển Hiệu")

	# ---------------------------------------------------------
	# STEP 3: Scene 3 — Morning Wholesale Market (Chợ Sỉ Sáng Sớm)
	# ---------------------------------------------------------
	GameManager.complete_owner_setup("Dì Chánh", "NGỌC TRÂN TẠP HÓA", "capital")
	await _wait_frames(18)
	await _capture_step("04_scene3_morning_market", "Scene 3: Chợ Sỉ Đầu Hẻm & Soạn Quầy Buổi Sáng (06:00)")

	# ---------------------------------------------------------
	# STEP 4: Scene 4 — Daytime Store Gameplay (Mở Cửa Bán Hàng)
	# ---------------------------------------------------------
	GameManager.restock_all_saved_shelves_from_warehouse()
	GameManager.open_store_for_day()
	await _wait_frames(20)

	var world_node := get_tree().current_scene.get_node_or_null("StoreWorld")
	if world_node and world_node.has_method("spawn_customer"):
		world_node.call("spawn_customer")
		await _wait_frames(10)
		world_node.call("spawn_customer")
		var ysort_clean := world_node.get_node_or_null("YSortEntities")
		if ysort_clean:
			var idx := 0
			for child in ysort_clean.get_children():
				if child is CustomerEntity:
					var c: CustomerEntity = child as CustomerEntity
					if idx == 0:
						c.position = Vector2(730.0, 420.0)
						c.state = CustomerEntity.State.BROWSING_AT_SHELF
					else:
						c.position = Vector2(688.0, 620.0)
					idx += 1
	await _capture_step("05_scene4_daytime_store_clean", "Scene 4: Giao Diện Bán Hàng Chính (07:00 - Không Chồng Chéo)")

	# Trigger Toast Notification
	EventBus.toast_requested.emit("🔔 Trống trường tan học! Học sinh ùa vào mua quà vặt!", Color("#C84B31"))
	await _capture_step("06_scene4_daytime_toast", "Scene 4: Kiểm Tra Thông Báo Toast Tự Mờ Ở Giữa Đỉnh Màn Hình")

	# Trigger Customer Checkout Popup
	var ui_ctrl := get_tree().current_scene.get_node_or_null("UILayer/GameUIController")
	if world_node and ui_ctrl:
		var ysort := world_node.get_node_or_null("YSortEntities")
		if ysort:
			for child in ysort.get_children():
				if child is CustomerEntity:
					var cust: CustomerEntity = child as CustomerEntity
					cust.position = Vector2(618.0, 582.0)
					cust.waypoints.clear()
					cust.state = CustomerEntity.State.WAITING_AT_CASHIER
					cust.wanted_item_id = "kem_mut"
					cust.wanted_qty = 2
					cust.asks_for_credit = true
					cust.mood_text = "Tính tiền!"
					EventBus.customer_waiting_at_checkout.emit(cust)
					break
	await _capture_step("07_scene4_checkout_popup", "Scene 4: Phiếu Tính Tiền Thu Ngân & Thanh Kiên Nhẫn")

	# Open Ledger Panel (Inventory Tab & Debt Tab)
	if ui_ctrl:
		if ui_ctrl.has_method("_toggle_ledger_panel"):
			ui_ctrl.call("_toggle_ledger_panel")
		await _capture_step("08_scene4_ledger_inventory", "Scene 4: Sổ Cái Nhập Sỉ & Chỉnh Giá Bán Lẻ")

		ui_ctrl.set("current_ledger_tab", "debt")
		if ui_ctrl.has_method("_rebuild_ledger_lists"):
			ui_ctrl.call("_rebuild_ledger_lists")
		await _capture_step("09_scene4_ledger_debt", "Scene 4: Sổ Ghi Nợ Hàng Xóm Trong Ngày")

		# Toggle Build Mode
		if ui_ctrl.has_method("_on_toggle_build_pressed"):
			ui_ctrl.call("_on_toggle_build_pressed")
		await _capture_step("10_scene4_build_mode", "Scene 4: Chế Độ Đóng Kệ & Mở Rộng Quầy")

	# ---------------------------------------------------------
	# STEP 5: Scene 5 — Night Home & Daily Summary (Đóng Cửa Về Nhà)
	# ---------------------------------------------------------
	GameManager.daily_revenue = 72500
	GameManager.daily_spent = 24000
	GameManager.daily_customers_served = 15
	GameManager.daily_customers_left = 2
	GameManager.close_store_for_night()
	await _wait_frames(20)
	await _capture_step("11_scene5_night_home_summary", "Scene 5: Đóng Cửa Về Nhà — Nhật Ký Gác Xép & Kết Sổ Tối (21:00)")

	var report_path := _ensure_output_dir().path_join("e2e_report.json")
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"project": "Tạp Hóa Màu Nước",
			"total_screenshots": report_steps.size(),
			"steps": report_steps
		}, "\t"))
		f.close()

	print("=== E2E SUITE COMPLETED SUCCESSFULLY (%d screenshots) ===" % report_steps.size())
	await _wait_frames(4)
	get_tree().quit(0)
