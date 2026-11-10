@warning_ignore("unused_signal")
extends Node

# Thời gian & Môi trường
@warning_ignore("unused_signal")
signal time_updated(day: int, hour: int, minute: int, phase_name: String)
@warning_ignore("unused_signal")
signal weather_changed(weather_id: String, weather_label: String)
@warning_ignore("unused_signal")
signal rush_hour_changed(is_active: bool, message: String)
@warning_ignore("unused_signal")
signal store_phase_changed(new_phase: String)

# Kinh tế & Cấp độ
@warning_ignore("unused_signal")
signal money_changed(new_amount: int, delta: int)
@warning_ignore("unused_signal")
signal reputation_changed(new_rep: int, delta: int)
@warning_ignore("unused_signal")
signal candy_jar_changed(new_count: int)
@warning_ignore("unused_signal")
signal inventory_updated()
@warning_ignore("unused_signal")
signal debt_ledger_updated()
@warning_ignore("unused_signal")
signal store_level_changed(new_level: int, level_title: String, reveal_radius: float)

# Gameplay & UI
@warning_ignore("unused_signal")
signal customer_waiting_at_checkout(customer_node: Node)
@warning_ignore("unused_signal")
signal checkout_resolved(customer_node: Node, method: String)
@warning_ignore("unused_signal")
signal build_mode_toggled(is_active: bool, furniture_id: String)
@warning_ignore("unused_signal")
signal toast_requested(message: String, color: Color)
@warning_ignore("unused_signal")
signal stamp_effect_requested(stamp_text: String, screen_pos: Vector2)
