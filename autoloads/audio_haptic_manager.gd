extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"

const INK_DARK := Color("#2C221E")
const PAPER_CREAM := Color("#FBF8F1")
const PAPER_WARM := Color("#F2E6D0")
const STAMP_RED := Color("#C84B31")
const SAGE_GREEN := Color("#6B8E78")

const TEX_CARD_BROWN: Texture2D = preload("res://assets/sprites/ui/ui_card_brown.png")
const TEX_BTN_GREEN: Texture2D = preload("res://assets/sprites/ui/ui_btn_green.png")
const TEX_BTN_YELLOW: Texture2D = preload("res://assets/sprites/ui/ui_btn_yellow.png")
const TEX_BTN_PINK: Texture2D = preload("res://assets/sprites/ui/ui_btn_pink.png")
const TEX_BTN_CREAM: Texture2D = preload("res://assets/sprites/ui/ui_btn_cream.png")

var bgm_enabled: bool = true
var bgm_volume: float = 0.75
var sfx_enabled: bool = true
var sfx_volume: float = 0.90
var haptic_enabled: bool = true

var _sfx_bank: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_Cursor: int = 0
var _bgm_player: AudioStreamPlayer

var settings_backdrop: ColorRect
var settings_modal: PanelContainer
var btn_bgm_toggle: Button
var slider_bgm: HSlider
var lbl_bgm_pct: Label
var btn_sfx_toggle: Button
var slider_sfx: HSlider
var lbl_sfx_pct: Label
var btn_haptic_toggle: Button
var btn_auto_cashier_toggle: Button
var btn_speed_toggle: Button
var btn_reset_save: Button
var _reset_confirm_pending: bool = false
var _last_haptic_tick: int = -100
var _last_haptic_ms: int = 0

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_init_web_haptic_bridge()
	_build_audio_players()
	_synthesize_all_unique_audio()
	_build_settings_modal()
	_update_bgm_state()
	get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_hook_existing_buttons", get_tree().root)

func _input(event: InputEvent) -> void:
	# Global world touch haptic feedback (when touching screen anywhere)
	if event is InputEventScreenTouch and event.pressed:
		trigger_haptic("light")
		if _bgm_player and bgm_enabled and not _bgm_player.playing:
			_bgm_player.play()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trigger_haptic("light")
		# Ensure WebAudio context is unlocked on first user gesture
		if _bgm_player and bgm_enabled and not _bgm_player.playing:
			_bgm_player.play()

func _init_web_haptic_bridge() -> void:
	if OS.has_feature("web"):
		var js_code := """
		(function() {
			if (window._agyHapticInit) return;
			window._agyHapticInit = true;
			var lbl = document.createElement('label');
			lbl.style.cssText = 'position:fixed;left:-9999px;top:-9999px;width:1px;height:1px;opacity:0;pointer-events:none;';
			var inp = document.createElement('input');
			inp.type = 'checkbox';
			inp.setAttribute('switch', '');
			lbl.appendChild(inp);
			if (document.body) document.body.appendChild(lbl);
			window._agyTriggerHaptic = function(ms) {
				try {
					if (navigator.vibrate) {
						navigator.vibrate(ms);
					}
					if (lbl && inp) {
						lbl.click();
					}
				} catch (e) {}
			};
		})();
		"""
		JavaScriptBridge.eval(js_code, true)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		bgm_enabled = bool(cfg.get_value("audio", "bgm_enabled", true))
		bgm_volume = clampf(float(cfg.get_value("audio", "bgm_volume", 0.72)), 0.0, 1.0)
		sfx_enabled = bool(cfg.get_value("audio", "sfx_enabled", true))
		sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 0.88)), 0.0, 1.0)
		haptic_enabled = bool(cfg.get_value("haptic", "haptic_enabled", true))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "bgm_enabled", bgm_enabled)
	cfg.set_value("audio", "bgm_volume", bgm_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("haptic", "haptic_enabled", haptic_enabled)
	cfg.save(SETTINGS_PATH)

func _build_audio_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	add_child(_bgm_player)

	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		add_child(p)
		_sfx_players.append(p)

func _update_bgm_state() -> void:
	if _bgm_player == null:
		return
	if not bgm_enabled or bgm_volume <= 0.01:
		_bgm_player.stop()
		return
	var db: float = linear_to_db(clampf(bgm_volume * 0.42, 0.001, 1.0))
	_bgm_player.volume_db = db
	if not _bgm_player.playing and _bgm_player.stream != null:
		_bgm_player.play()

func play_sfx(sfx_id: String, pitch_var: float = 0.04) -> void:
	if not sfx_enabled or sfx_volume <= 0.01:
		return
	var stream: AudioStreamWAV = _sfx_bank.get(sfx_id)
	if stream == null:
		stream = _sfx_bank.get("wood_tap")
	if stream == null or _sfx_players.is_empty():
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_Cursor]
	_sfx_Cursor = (_sfx_Cursor + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = linear_to_db(clampf(sfx_volume * 0.85, 0.001, 1.0))
	p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	p.play()

func trigger_haptic(strength: String = "light") -> void:
	if not haptic_enabled:
		return
	var ms: int = 18
	if strength == "medium":
		ms = 32
	elif strength == "heavy":
		ms = 55
	var now: int = Time.get_ticks_msec()
	if now - _last_haptic_tick < 25 and ms <= _last_haptic_ms:
		return
	_last_haptic_tick = now
	_last_haptic_ms = ms
	Input.vibrate_handheld(ms)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(window._agyTriggerHaptic) window._agyTriggerHaptic(%d);" % ms, true)

func _on_tree_node_added(node: Node) -> void:
	if node is Button:
		_hook_button(node as Button)

func _hook_existing_buttons(root_node: Node) -> void:
	if root_node is Button:
		_hook_button(root_node as Button)
	for child in root_node.get_children():
		_hook_existing_buttons(child)

func _hook_button(btn: Button) -> void:
	if btn.has_meta("_agy_haptic_hooked"):
		return
	btn.set_meta("_agy_haptic_hooked", true)
	btn.button_down.connect(func() -> void:
		_animate_button_bounce(btn)
		var sfx_custom: String = str(btn.get_meta("sfx_id", "wood_tap"))
		var hap_custom: String = str(btn.get_meta("haptic_strength", "light"))
		trigger_haptic(hap_custom)
		play_sfx(sfx_custom)
	)

func _animate_button_bounce(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	if btn.size.x > 0 and btn.size.y > 0:
		btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.95, 0.93), 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.065).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.05)

# ==============================================================================
# PROCEDURAL ACOUSTIC & FOLEY AUDIO SYNTHESIZER (100% UNIQUE TO THIS GAME)
# ==============================================================================
func _synthesize_all_unique_audio() -> void:
	_sfx_bank["wood_tap"] = _synth_wood_tap()
	_sfx_bank["key_type"] = _synth_key_type()
	_sfx_bank["page_flip"] = _synth_page_flip()
	_sfx_bank["cash_coin"] = _synth_cash_coin()
	_sfx_bank["candy_jar"] = _synth_candy_jar()
	_sfx_bank["rubber_stamp"] = _synth_rubber_stamp()
	_sfx_bank["shelf_stock"] = _synth_shelf_stock()
	_sfx_bank["wind_chime"] = _synth_wind_chime()
	_sfx_bank["school_drum"] = _synth_school_drum()
	_sfx_bank["watercolor_up"] = _synth_watercolor_up()
	_bgm_player.stream = _synth_nostalgic_pentatonic_bgm()

func _make_wav(samples: PackedFloat32Array, mix_rate: int = 22050, looped: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, s)
	wav.data = bytes
	return wav

func _synth_wood_tap() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.055)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var env: float = exp(-t * 68.0)
		# Sub-bass 62Hz tactile pulse + warm 360->190Hz wooden block knock
		var freq: float = lerpf(360.0, 190.0, clampf(t * 25.0, 0.0, 1.0))
		var sig: float = sin(TAU * freq * t) * 0.58 + sin(TAU * 62.0 * t) * exp(-t * 95.0) * 0.42
		buf[i] = clampf(sig * env, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_key_type() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.042)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var env: float = exp(-t * 92.0)
		var click: float = sin(TAU * lerpf(620.0, 260.0, t * 28.0) * t) * 0.6 + sin(TAU * 70.0 * t) * 0.4
		buf[i] = clampf(click * env, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_page_flip() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.12)
	var buf := PackedFloat32Array()
	buf.resize(count)
	var prev: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / 0.12, 0.0, 1.0) * PI) * exp(-t * 14.0)
		var white: float = randf_range(-1.0, 1.0)
		prev = lerpf(prev, white, 0.32)
		var tone: float = sin(TAU * lerpf(280.0, 440.0, t / 0.12) * t) * 0.25
		buf[i] = clampf((prev * 0.65 + tone) * env * 0.75, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_cash_coin() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.34)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		# Two bright Vietnamese brass coin chimes (E6 -> A6 + E7 harmonic)
		var c1: float = (sin(TAU * 1318.5 * t) * 0.5 + sin(TAU * 2637.0 * t) * 0.25) * exp(-t * 18.0)
		var c2: float = 0.0
		if t >= 0.075:
			var t2: float = t - 0.075
			c2 = (sin(TAU * 1760.0 * t2) * 0.55 + sin(TAU * 3520.0 * t2) * 0.25) * exp(-t2 * 13.0)
		buf[i] = clampf((c1 + c2) * 0.78, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_candy_jar() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.26)
	var buf := PackedFloat32Array()
	buf.resize(count)
	var notes: Array[float] = [1567.98, 1975.53, 2349.32]
	for i in range(count):
		var t: float = float(i) / float(rate)
		var s: float = 0.0
		for idx in range(notes.size()):
			var onset: float = float(idx) * 0.055
			if t >= onset:
				var td: float = t - onset
				s += sin(TAU * notes[idx] * td) * exp(-td * 24.0) * 0.45
		buf[i] = clampf(s, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_rubber_stamp() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.22)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var thump: float = sin(TAU * lerpf(115.0, 46.0, clampf(t * 12.0, 0.0, 1.0)) * t) * exp(-t * 22.0) * 0.75
		var slap: float = (sin(TAU * 240.0 * t) + randf_range(-0.4, 0.4)) * exp(-t * 55.0) * 0.35
		buf[i] = clampf(thump + slap, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_shelf_stock() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.18)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var w1: float = sin(TAU * 220.0 * t) * exp(-t * 32.0) * 0.55
		var w2: float = 0.0
		if t >= 0.06:
			var t2: float = t - 0.06
			w2 = sin(TAU * 330.0 * t2) * exp(-t2 * 28.0) * 0.6
		buf[i] = clampf(w1 + w2, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_wind_chime() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.52)
	var buf := PackedFloat32Array()
	buf.resize(count)
	var pentatonic: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	for i in range(count):
		var t: float = float(i) / float(rate)
		var s: float = 0.0
		for n in range(pentatonic.size()):
			var onset: float = float(n) * 0.065
			if t >= onset:
				var td: float = t - onset
				s += (sin(TAU * pentatonic[n] * td) * 0.4 + sin(TAU * pentatonic[n] * 2.0 * td) * 0.12) * exp(-td * 9.5)
		buf[i] = clampf(s * 0.7, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_school_drum() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.65)
	var buf := PackedFloat32Array()
	buf.resize(count)
	var hits: Array[float] = [0.0, 0.16, 0.32]
	for i in range(count):
		var t: float = float(i) / float(rate)
		var s: float = 0.0
		for onset in hits:
			if t >= onset:
				var td: float = t - onset
				var f: float = lerpf(135.0, 82.0, clampf(td * 10.0, 0.0, 1.0))
				s += sin(TAU * f * td) * exp(-td * 18.0) * 0.65
		if t >= 0.42:
			var tb: float = t - 0.42
			s += sin(TAU * 1567.98 * tb) * exp(-tb * 14.0) * 0.35
		buf[i] = clampf(s, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_watercolor_up() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.78)
	var buf := PackedFloat32Array()
	buf.resize(count)
	var notes: Array[float] = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.50]
	for i in range(count):
		var t: float = float(i) / float(rate)
		var s: float = 0.0
		for n in range(notes.size()):
			var onset: float = float(n) * 0.085
			if t >= onset:
				var td: float = t - onset
				var f: float = notes[n]
				s += (sin(TAU * f * td) * 0.38 + sin(TAU * f * 2.0 * td) * 0.14 + sin(TAU * f * 3.0 * td) * 0.06) * exp(-td * 6.5)
		buf[i] = clampf(s * 0.72, -0.95, 0.95)
	return _make_wav(buf, rate)

func _synth_nostalgic_pentatonic_bgm() -> AudioStreamWAV:
	# 12.8-second seamless Vietnamese Pentatonic Acoustic Guitar & Porch Chime Loop
	var rate := 22050
	var duration := 12.8
	var count := int(rate * duration)
	var buf := PackedFloat32Array()
	buf.resize(count)
	buf.fill(0.0)

	# 16 gentle plucked notes (each 0.8s) in C Major / A Minor Vietnamese Pentatonic (Ho-Xu-Xang-Xe-Cong)
	var melody_freqs: Array[float] = [
		261.63, 329.63, 392.00, 523.25,
		440.00, 392.00, 329.63, 293.66,
		261.63, 293.66, 329.63, 440.00,
		392.00, 329.63, 293.66, 261.63
	]
	var bass_freqs: Array[float] = [
		130.81, 130.81, 130.81, 130.81,
		110.00, 110.00, 110.00, 110.00,
		174.61, 174.61, 174.61, 174.61,
		196.00, 196.00, 130.81, 130.81
	]

	for step in range(16):
		var start_t: float = float(step) * 0.8
		var start_idx: int = int(start_t * rate)
		var note_len: int = int(1.45 * rate)
		var f_mel: float = melody_freqs[step]
		var f_bass: float = bass_freqs[step]
		var play_bass: bool = (step % 4 == 0)

		for j in range(note_len):
			var idx: int = (start_idx + j) % count
			var td: float = float(j) / float(rate)
			var env_m: float = (1.0 - exp(-td * 120.0)) * exp(-td * 3.2)
			# Acoustic guitar harmonic profile (fundamental + 2nd + 3rd harmonic with faster decay)
			var mel: float = (
				sin(TAU * f_mel * td) * 0.24 +
				sin(TAU * f_mel * 2.0 * td) * exp(-td * 5.0) * 0.11 +
				sin(TAU * f_mel * 3.0 * td) * exp(-td * 8.0) * 0.04
			) * env_m

			var bass: float = 0.0
			if play_bass:
				var env_b: float = (1.0 - exp(-td * 80.0)) * exp(-td * 1.6)
				bass = (sin(TAU * f_bass * td) * 0.22 + sin(TAU * f_bass * 2.0 * td) * 0.08) * env_b

			buf[idx] = clampf(buf[idx] + mel + bass, -0.85, 0.85)

	return _make_wav(buf, rate, true)

# ==============================================================================
# VIETNAMESE TELEX REAL-TIME COMPOSER (FOR FULL-SCREEN IN-GAME KEYBOARD)
# ==============================================================================
const VN_VOWEL_TABLE := {
	"A": ["A", "Á", "À", "Ả", "Ã", "Ạ"],
	"Ă": ["Ă", "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ"],
	"Â": ["Â", "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ"],
	"E": ["E", "É", "È", "Ẻ", "Ẽ", "Ẹ"],
	"Ê": ["Ê", "Ế", "Ề", "Ể", "Ễ", "Ệ"],
	"I": ["I", "Í", "Ì", "Ỉ", "Ĩ", "Ị"],
	"O": ["O", "Ó", "Ò", "Ỏ", "Õ", "Ọ"],
	"Ô": ["Ô", "Ố", "Ồ", "Ổ", "Ỗ", "Ộ"],
	"Ơ": ["Ơ", "Ớ", "Ờ", "Ở", "Ỡ", "Ợ"],
	"U": ["U", "Ú", "Ù", "Ủ", "Ũ", "Ụ"],
	"Ư": ["Ư", "Ứ", "Ừ", "Ử", "Ữ", "Ự"],
	"Y": ["Y", "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ"]
}

const TONE_KEY_MAP := {
	"S": 1,
	"F": 2,
	"R": 3,
	"X": 4,
	"J": 5,
	"Z": 0
}

func apply_telex_key(current_text: String, key_raw: String) -> String:
	var k: String = key_raw.to_upper()
	if current_text == "" or k == " ":
		return current_text + k

	# Split last word (after last space)
	var last_space: int = current_text.rfind(" ")
	var prefix: String = ""
	var word: String = current_text
	if last_space >= 0:
		prefix = current_text.substr(0, last_space + 1)
		word = current_text.substr(last_space + 1)

	if word == "":
		return current_text + k

	# 1. Check "D" -> "Đ" (DD at start of word or anywhere in word)
	if k == "D":
		if word.ends_with("D"):
			return prefix + word.substr(0, word.length() - 1) + "Đ"
		elif word.begins_with("D") and word.length() >= 2:
			return prefix + "Đ" + word.substr(1)

	# 2. Check double vowel circumflex: AA -> Â, EE -> Ê, OO -> Ô
	if k in ["A", "E", "O"]:
		var transformed := _try_apply_circumflex(word, k)
		if transformed != "":
			return prefix + transformed

	# 3. Check W modifier: AW -> Ă, OW -> Ơ, UW -> Ư, UOW -> ƯƠ (works even at end of word like DONGW / DUONGW!)
	if k == "W":
		var w_transformed := _try_apply_horn_breve(word)
		if w_transformed != "":
			return prefix + w_transformed

	# 4. Check Tone marks: S (Sắc), F (Huyền), R (Hỏi), X (Ngã), J (Nặng), Z (Xóa dấu)
	if TONE_KEY_MAP.has(k):
		var tone_idx: int = TONE_KEY_MAP[k]
		var toned_word := _try_apply_tone(word, tone_idx)
		if toned_word != "":
			return prefix + toned_word

	return current_text + k

func _find_base_and_tone(ch: String) -> Array:
	for base in VN_VOWEL_TABLE:
		var arr: Array = VN_VOWEL_TABLE[base]
		var idx: int = arr.find(ch)
		if idx >= 0:
			return [base, idx]
	return ["", -1]

func _try_apply_circumflex(word: String, target_base: String) -> String:
	var new_base := ""
	if target_base == "A":
		new_base = "Â"
	elif target_base == "E":
		new_base = "Ê"
	elif target_base == "O":
		new_base = "Ô"
	for i in range(word.length() - 1, -1, -1):
		var info := _find_base_and_tone(word.substr(i, 1))
		if info[0] == target_base:
			var repl: String = VN_VOWEL_TABLE[new_base][info[1]]
			return word.substr(0, i) + repl + word.substr(i + 1)
	return ""

func _try_apply_horn_breve(word: String) -> String:
	# Check UO -> ƯƠ first (e.g., DUONG + W -> DƯƠNG)
	for i in range(word.length() - 1):
		var info1 := _find_base_and_tone(word.substr(i, 1))
		var info2 := _find_base_and_tone(word.substr(i + 1, 1))
		if (info1[0] == "U" or info1[0] == "Ư") and (info2[0] == "O" or info2[0] == "Ơ"):
			var r1: String = VN_VOWEL_TABLE["Ư"][info1[1]]
			var r2: String = VN_VOWEL_TABLE["Ơ"][info2[1]]
			return word.substr(0, i) + r1 + r2 + word.substr(i + 2)
	# Otherwise check last U, O, or A in the word
	for i in range(word.length() - 1, -1, -1):
		var info := _find_base_and_tone(word.substr(i, 1))
		var b: String = info[0]
		var t: int = info[1]
		if b == "U":
			return word.substr(0, i) + VN_VOWEL_TABLE["Ư"][t] + word.substr(i + 1)
		elif b == "O":
			return word.substr(0, i) + VN_VOWEL_TABLE["Ơ"][t] + word.substr(i + 1)
		elif b == "A":
			return word.substr(0, i) + VN_VOWEL_TABLE["Ă"][t] + word.substr(i + 1)
	return ""

func _try_apply_tone(word: String, tone_idx: int) -> String:
	var vowel_indices: Array[int] = []
	for i in range(word.length()):
		var ch := word.substr(i, 1)
		if ch == "I" and i > 0 and word.substr(i - 1, 1) == "G":
			continue
		if ch == "U" and i > 0 and word.substr(i - 1, 1) == "Q":
			continue
		var info := _find_base_and_tone(ch)
		if info[0] != "":
			vowel_indices.append(i)

	if vowel_indices.is_empty():
		return ""

	# Prefer vowel with diacritic (Ă, Â, Ê, Ô, Ơ, Ư), else standard Vietnamese tone placement
	var target_pos: int = vowel_indices[0]
	for vi in vowel_indices:
		var info := _find_base_and_tone(word.substr(vi, 1))
		if info[0] in ["Ă", "Â", "Ê", "Ô", "Ơ", "Ư"]:
			target_pos = vi
			break
	if vowel_indices.size() >= 2 and not (_find_base_and_tone(word.substr(target_pos, 1))[0] in ["Ă", "Â", "Ê", "Ô", "Ơ", "Ư"]):
		var last_vi: int = vowel_indices[vowel_indices.size() - 1]
		var has_trailing_consonant: bool = (last_vi < word.length() - 1)
		target_pos = last_vi if has_trailing_consonant else vowel_indices[0]

	var cur_info := _find_base_and_tone(word.substr(target_pos, 1))
	var base: String = cur_info[0]
	var cur_tone: int = cur_info[1]
	if cur_tone == tone_idx and tone_idx != 0:
		return ""
	# Clear existing tones on other vowels in the word first
	var cleaned := word
	for vi in vowel_indices:
		var inf := _find_base_and_tone(cleaned.substr(vi, 1))
		cleaned = cleaned.substr(0, vi) + VN_VOWEL_TABLE[inf[0]][0] + cleaned.substr(vi + 1)
	var new_vowel: String = VN_VOWEL_TABLE[base][tone_idx]
	return cleaned.substr(0, target_pos) + new_vowel + cleaned.substr(target_pos + 1)

# ==============================================================================
# UNIFIED SETTINGS MODAL (ACCESSIBLE FROM ALL 5 SCENES)
# ==============================================================================
func _style_tex_panel(tex: Texture2D, pad_h: int = 30, pad_v: int = 24) -> StyleBoxTexture:
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
	sbt.content_margin_bottom = 10
	return sbt

func _apply_btn(btn: Button, tex: Texture2D, f_size: int = 16) -> void:
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, 48.0)
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
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

func _build_settings_modal() -> void:
	settings_backdrop = ColorRect.new()
	settings_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_backdrop.color = Color(0.14, 0.10, 0.08, 0.68)
	settings_backdrop.visible = false
	add_child(settings_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_backdrop.add_child(center)

	settings_modal = PanelContainer.new()
	settings_modal.custom_minimum_size = Vector2(960, 600)
	settings_modal.add_theme_stylebox_override("panel", _style_tex_panel(TEX_CARD_BROWN, 34, 26))
	center.add_child(settings_modal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	settings_modal.add_child(vbox)

	# Header
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	var title := Label.new()
	title.text = "CÀI ĐẶT HỆ THỐNG — ÂM THANH & XÚC GIÁC (SETTINGS)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", STAMP_RED)
	title.add_theme_font_size_override("font_size", 24)
	header_row.add_child(title)

	var btn_close_top := Button.new()
	btn_close_top.text = "Đóng [X]"
	btn_close_top.custom_minimum_size = Vector2(120, 48)
	_apply_btn(btn_close_top, TEX_BTN_CREAM, 16)
	btn_close_top.pressed.connect(func() -> void: close_settings())
	header_row.add_child(btn_close_top)

	# 1. Nhạc Nền (BGM)
	var card_bgm := PanelContainer.new()
	card_bgm.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(card_bgm)

	var row_bgm := HBoxContainer.new()
	row_bgm.add_theme_constant_override("separation", 16)
	row_bgm.alignment = BoxContainer.ALIGNMENT_CENTER
	card_bgm.add_child(row_bgm)

	var lbl_bgm := Label.new()
	lbl_bgm.text = "1. Nhạc Nền Guitar & Chuông Gió (BGM):"
	lbl_bgm.custom_minimum_size = Vector2(340, 0)
	lbl_bgm.add_theme_color_override("font_color", INK_DARK)
	lbl_bgm.add_theme_font_size_override("font_size", 18)
	row_bgm.add_child(lbl_bgm)

	btn_bgm_toggle = Button.new()
	btn_bgm_toggle.custom_minimum_size = Vector2(150, 50)
	btn_bgm_toggle.pressed.connect(func() -> void:
		bgm_enabled = not bgm_enabled
		_update_bgm_state()
		save_settings()
		_refresh_settings_ui()
	)
	row_bgm.add_child(btn_bgm_toggle)

	slider_bgm = HSlider.new()
	slider_bgm.min_value = 0.0
	slider_bgm.max_value = 100.0
	slider_bgm.step = 5.0
	slider_bgm.value = bgm_volume * 100.0
	slider_bgm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_bgm.custom_minimum_size = Vector2(200, 44)
	slider_bgm.value_changed.connect(func(v: float) -> void:
		bgm_volume = v / 100.0
		if bgm_volume > 0.02 and not bgm_enabled:
			bgm_enabled = true
		_update_bgm_state()
		save_settings()
		_refresh_settings_ui()
	)
	row_bgm.add_child(slider_bgm)

	lbl_bgm_pct = Label.new()
	lbl_bgm_pct.custom_minimum_size = Vector2(70, 0)
	lbl_bgm_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_bgm_pct.add_theme_color_override("font_color", STAMP_RED)
	lbl_bgm_pct.add_theme_font_size_override("font_size", 18)
	row_bgm.add_child(lbl_bgm_pct)

	# 2. Hiệu Ứng Âm Thanh (SFX)
	var card_sfx := PanelContainer.new()
	card_sfx.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(card_sfx)

	var row_sfx := HBoxContainer.new()
	row_sfx.add_theme_constant_override("separation", 16)
	row_sfx.alignment = BoxContainer.ALIGNMENT_CENTER
	card_sfx.add_child(row_sfx)

	var lbl_sfx := Label.new()
	lbl_sfx.text = "2. Hiệu Ứng Âm Thanh Tạp Hóa (SFX):"
	lbl_sfx.custom_minimum_size = Vector2(340, 0)
	lbl_sfx.add_theme_color_override("font_color", INK_DARK)
	lbl_sfx.add_theme_font_size_override("font_size", 18)
	row_sfx.add_child(lbl_sfx)

	btn_sfx_toggle = Button.new()
	btn_sfx_toggle.custom_minimum_size = Vector2(150, 50)
	btn_sfx_toggle.pressed.connect(func() -> void:
		sfx_enabled = not sfx_enabled
		save_settings()
		_refresh_settings_ui()
		if sfx_enabled:
			play_sfx("cash_coin")
	)
	row_sfx.add_child(btn_sfx_toggle)

	slider_sfx = HSlider.new()
	slider_sfx.min_value = 0.0
	slider_sfx.max_value = 100.0
	slider_sfx.step = 5.0
	slider_sfx.value = sfx_volume * 100.0
	slider_sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_sfx.custom_minimum_size = Vector2(200, 44)
	slider_sfx.value_changed.connect(func(v: float) -> void:
		sfx_volume = v / 100.0
		if sfx_volume > 0.02 and not sfx_enabled:
			sfx_enabled = true
		save_settings()
		_refresh_settings_ui()
	)
	row_sfx.add_child(slider_sfx)

	lbl_sfx_pct = Label.new()
	lbl_sfx_pct.custom_minimum_size = Vector2(70, 0)
	lbl_sfx_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_sfx_pct.add_theme_color_override("font_color", STAMP_RED)
	lbl_sfx_pct.add_theme_font_size_override("font_size", 18)
	row_sfx.add_child(lbl_sfx_pct)

	# 3. Rung Phản Hồi Xúc Giác (Haptic Feedback)
	var card_hap := PanelContainer.new()
	card_hap.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(card_hap)

	var row_hap := HBoxContainer.new()
	row_hap.add_theme_constant_override("separation", 16)
	card_hap.add_child(row_hap)

	var lbl_hap := Label.new()
	lbl_hap.text = "3. Rung Phản Hồi Khi Chạm (Haptics):"
	lbl_hap.custom_minimum_size = Vector2(340, 0)
	lbl_hap.add_theme_color_override("font_color", INK_DARK)
	lbl_hap.add_theme_font_size_override("font_size", 18)
	row_hap.add_child(lbl_hap)

	btn_haptic_toggle = Button.new()
	btn_haptic_toggle.custom_minimum_size = Vector2(150, 50)
	btn_haptic_toggle.pressed.connect(func() -> void:
		haptic_enabled = not haptic_enabled
		save_settings()
		_refresh_settings_ui()
		if haptic_enabled:
			trigger_haptic("heavy")
	)
	row_hap.add_child(btn_haptic_toggle)

	var btn_test_hap := Button.new()
	btn_test_hap.text = "Thử Rung & Chuông Gió Tạp Hóa"
	btn_test_hap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_test_hap.custom_minimum_size = Vector2(0, 50)
	btn_test_hap.set_meta("sfx_id", "wind_chime")
	btn_test_hap.set_meta("haptic_strength", "heavy")
	_apply_btn(btn_test_hap, TEX_BTN_CREAM, 16)
	btn_test_hap.pressed.connect(func() -> void:
		trigger_haptic("heavy")
		play_sfx("wind_chime")
	)
	row_hap.add_child(btn_test_hap)

	# 4. Tiện Ích Nhịp Chơi (Auto Cashier & Game Speed)
	var card_game := PanelContainer.new()
	card_game.add_theme_stylebox_override("panel", _style_box(PAPER_WARM, INK_DARK, 1))
	vbox.add_child(card_game)

	var row_game := HBoxContainer.new()
	row_game.add_theme_constant_override("separation", 16)
	card_game.add_child(row_game)

	var lbl_game := Label.new()
	lbl_game.text = "4. Trợ Lý Bán Hàng & Tốc Độ Nhịp Sống:"
	lbl_game.custom_minimum_size = Vector2(340, 0)
	lbl_game.add_theme_color_override("font_color", INK_DARK)
	lbl_game.add_theme_font_size_override("font_size", 18)
	row_game.add_child(lbl_game)

	btn_auto_cashier_toggle = Button.new()
	btn_auto_cashier_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_auto_cashier_toggle.custom_minimum_size = Vector2(0, 50)
	btn_auto_cashier_toggle.pressed.connect(func() -> void:
		GameManager.auto_cashier_enabled = not GameManager.auto_cashier_enabled
		_refresh_settings_ui()
	)
	row_game.add_child(btn_auto_cashier_toggle)

	btn_speed_toggle = Button.new()
	btn_speed_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_speed_toggle.custom_minimum_size = Vector2(0, 50)
	btn_speed_toggle.pressed.connect(func() -> void:
		GameManager.toggle_time_speed()
		_refresh_settings_ui()
	)
	row_game.add_child(btn_speed_toggle)

	# 5. Lưu Sổ Cái & Đặt Lại Ký Ức
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 14)
	vbox.add_child(bot_row)

	var btn_save_now := Button.new()
	btn_save_now.text = "Lưu Sổ Cái Ngay"
	btn_save_now.custom_minimum_size = Vector2(210, 54)
	btn_save_now.set_meta("sfx_id", "rubber_stamp")
	btn_save_now.set_meta("haptic_strength", "medium")
	_apply_btn(btn_save_now, TEX_BTN_YELLOW, 16)
	btn_save_now.pressed.connect(func() -> void:
		GameManager.save_game()
		save_settings()
		btn_save_now.text = "Đã Lưu Sổ Cái!"
	)
	bot_row.add_child(btn_save_now)

	btn_reset_save = Button.new()
	btn_reset_save.text = "Xóa Sổ & Chơi Lại Từ Đầu"
	btn_reset_save.custom_minimum_size = Vector2(260, 54)
	_apply_btn(btn_reset_save, TEX_BTN_PINK, 16)
	btn_reset_save.pressed.connect(func() -> void:
		if not _reset_confirm_pending:
			_reset_confirm_pending = true
			btn_reset_save.text = "Bấm Lần Nữa Để Xác Nhận Xóa!"
		else:
			_reset_confirm_pending = false
			close_settings()
			GameManager.begin_new_game_onboarding()
	)
	bot_row.add_child(btn_reset_save)

	var btn_done := Button.new()
	btn_done.text = "Hoàn Tất & Tiếp Tục Chơi >>"
	btn_done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_done.custom_minimum_size = Vector2(0, 54)
	_apply_btn(btn_done, TEX_BTN_GREEN, 18)
	btn_done.pressed.connect(func() -> void: close_settings())
	bot_row.add_child(btn_done)

	_refresh_settings_ui()

func _refresh_settings_ui() -> void:
	if btn_bgm_toggle == null:
		return
	btn_bgm_toggle.text = "Nhạc: BẬT" if bgm_enabled else "Nhạc: TẮT"
	_apply_btn(btn_bgm_toggle, TEX_BTN_GREEN if bgm_enabled else TEX_BTN_PINK, 16)
	lbl_bgm_pct.text = "%d%%" % int(round(bgm_volume * 100.0))

	btn_sfx_toggle.text = "SFX: BẬT" if sfx_enabled else "SFX: TẮT"
	_apply_btn(btn_sfx_toggle, TEX_BTN_GREEN if sfx_enabled else TEX_BTN_PINK, 16)
	lbl_sfx_pct.text = "%d%%" % int(round(sfx_volume * 100.0))

	btn_haptic_toggle.text = "Rung: BẬT" if haptic_enabled else "Rung: TẮT"
	_apply_btn(btn_haptic_toggle, TEX_BTN_GREEN if haptic_enabled else TEX_BTN_PINK, 16)

	var ac: bool = GameManager.auto_cashier_enabled
	btn_auto_cashier_toggle.text = "Tự Thu Ngân: %s" % ("BẬT" if ac else "TẮT")
	_apply_btn(btn_auto_cashier_toggle, TEX_BTN_YELLOW if ac else TEX_BTN_CREAM, 16)

	btn_speed_toggle.text = "Tốc Độ Nhịp: x%d" % int(GameManager.time_speed_multiplier)
	_apply_btn(btn_speed_toggle, TEX_BTN_CREAM, 16)

func open_settings() -> void:
	_reset_confirm_pending = false
	if btn_reset_save:
		btn_reset_save.text = "Xóa Sổ & Chơi Lại Từ Đầu"
	if slider_bgm:
		slider_bgm.set_value_no_signal(bgm_volume * 100.0)
	if slider_sfx:
		slider_sfx.set_value_no_signal(sfx_volume * 100.0)
	_refresh_settings_ui()
	play_sfx("page_flip")
	trigger_haptic("medium")
	settings_backdrop.visible = true
	settings_modal.scale = Vector2(0.92, 0.92)
	var tw: Tween = create_tween()
	tw.tween_property(settings_modal, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_settings() -> void:
	save_settings()
	play_sfx("page_flip")
	trigger_haptic("light")
	settings_backdrop.visible = false
