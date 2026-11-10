class_name PanZoomCamera
extends Camera2D

var target_zoom := Vector2(1.06, 1.06)
var min_zoom: float = 0.78
var max_zoom: float = 1.45
var pan_speed: float = 420.0
var _is_dragging: bool = false
var _touch_points: Dictionary = {}
var _last_pinch_dist: float = 0.0

func _ready() -> void:
	position = Vector2(705, 412)
	_auto_fit_device_aspect()
	get_viewport().size_changed.connect(_auto_fit_device_aspect)

func _auto_fit_device_aspect() -> void:
	# Phóng to sân chơi chuẩn Mobile-First (1.06x = lớn hơn 34% so với 0.79x trước đây), lấp đầy 85-90% màn hình 1280x720
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	var aspect: float = vp_size.x / vp_size.y
	if aspect < 1.5:
		target_zoom = Vector2(0.96, 0.96)
	elif aspect > 1.9:
		target_zoom = Vector2(1.08, 1.08)
	else:
		target_zoom = Vector2(1.05, 1.05)
	zoom = target_zoom

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	if dir != Vector2.ZERO:
		position += dir.normalized() * pan_speed * delta

	position.x = clampf(position.x, 520.0, 1020.0)
	position.y = clampf(position.y, 300.0, 580.0)
	zoom = zoom.lerp(target_zoom, clampf(delta * 10.0, 0.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	# Hỗ trợ cảm ứng đa điểm (Pinch-to-zoom 2 ngón & Kéo camera trên Mobile/iPad)
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)
			if _touch_points.size() < 2:
				_last_pinch_dist = 0.0

	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 2:
			var keys: Array = _touch_points.keys()
			var p1: Vector2 = _touch_points[keys[0]]
			var p2: Vector2 = _touch_points[keys[1]]
			var cur_dist: float = p1.distance_to(p2)
			if _last_pinch_dist > 10.0:
				var zoom_factor: float = cur_dist / _last_pinch_dist
				var z: float = clampf(target_zoom.x * zoom_factor, min_zoom, max_zoom)
				target_zoom = Vector2(z, z)
			_last_pinch_dist = cur_dist

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var z: float = clampf(target_zoom.x + 0.07, min_zoom, max_zoom)
			target_zoom = Vector2(z, z)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var z: float = clampf(target_zoom.x - 0.07, min_zoom, max_zoom)
			target_zoom = Vector2(z, z)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging = event.pressed
	elif event is InputEventMouseMotion and _is_dragging:
		position -= event.relative / zoom.x
