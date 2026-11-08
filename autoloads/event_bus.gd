extends Node

# Thời gian & Môi trường
signal time_updated(day: int, hour: int, minute: int, phase_name: String)
signal weather_changed(weather_id: String, weather_label: String)
signal rush_hour_changed(is_active: bool, message: String)
signal store_phase_changed(new_phase: String)

# Kinh tế & Cấp độ
signal money_changed(new_amount: int, delta: int)
signal reputation_changed(new_rep: int, delta: int)
signal candy_jar_changed(new_count: int)
signal inventory_updated()
signal debt_ledger_updated()
signal store_level_changed(new_level: int, level_title: String, reveal_radius: float)

# Gameplay & UI
signal customer_waiting_at_checkout(customer_node: Node)
signal checkout_resolved(customer_node: Node, method: String)
signal build_mode_toggled(is_active: bool, furniture_id: String)
signal toast_requested(message: String, color: Color)
signal stamp_effect_requested(stamp_text: String, screen_pos: Vector2)
