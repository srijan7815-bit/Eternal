extends CanvasLayer

var ui: Control
var hp_label: Label
var hp_bar: ProgressBar
var wave_label: Label
var kills_label: Label
var banner: Label
var result_overlay: Control
var kills_this_wave := 0
var enemies_this_wave := 0
var confetti_nodes: Array[ColorRect] = []
var confetti_velocity: Array[Vector2] = []
var rng := RandomNumberGenerator.new()
var result_shown := false
var revive_used := false
var confetti_elapsed := 0.0
const CONFETTI_DURATION := 5.0
const PIXEL_FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")


func _ready() -> void:
	add_to_group("hud")
	rng.randomize()
	_build_hud()
	set_health(10, 10)


func _build_hud() -> void:
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pixel_theme := Theme.new()
	pixel_theme.default_font = PIXEL_FONT
	pixel_theme.default_font_size = 10
	ui.theme = pixel_theme
	add_child(ui)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(14, 12)
	status_panel.custom_minimum_size = Vector2(278, 112)
	_style_panel(status_panel, Color("#101522"), Color("#70ddeb"))
	ui.add_child(status_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	status_panel.add_child(stack)

	var title := _label("ETERNAL / SURVIVE LARKSPUR", 9, Color("#e8e8f0"))
	stack.add_child(title)
	wave_label = _label("WAVE 1 / 5", 9, Color("#70ddeb"))
	stack.add_child(wave_label)
	var health_row := HBoxContainer.new()
	stack.add_child(health_row)
	hp_label = _label("ROWAN 10/10", 8, Color("#f4b96a"))
	hp_label.custom_minimum_size = Vector2(106, 20)
	health_row.add_child(hp_label)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(130, 17)
	hp_bar.max_value = 10
	hp_bar.show_percentage = false
	var hp_back := StyleBoxFlat.new()
	hp_back.bg_color = Color("#273247")
	hp_back.set_corner_radius_all(4)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("#70ddeb")
	hp_fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("background", hp_back)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	health_row.add_child(hp_bar)
	kills_label = _label("GHOSTS 0/0", 8, Color("#c5c3d2"))
	stack.add_child(kills_label)

	var controls := PanelContainer.new()
	controls.position = Vector2(406, 12)
	controls.custom_minimum_size = Vector2(220, 70)
	_style_panel(controls, Color("#101522"), Color("#7549a6"))
	ui.add_child(controls)
	var control_text := _label("MOVE A/D  JUMP SPACE\nATTACK J / CLICK", 8, Color("#d8d5e4"))
	control_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(control_text)

	var banner_panel := PanelContainer.new()
	banner_panel.position = Vector2(174, 130)
	banner_panel.custom_minimum_size = Vector2(292, 36)
	_style_panel(banner_panel, Color("#101522"), Color("#f4b96a"))
	ui.add_child(banner_panel)
	banner = _label("", 9, Color("#f4b96a"))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_outline_color", Color("#101522"))
	banner.add_theme_constant_override("outline_size", 3)
	banner_panel.add_child(banner)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _style_panel(panel: PanelContainer, background: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)


func set_health(current: int, maximum: int) -> void:
	if hp_label == null or hp_bar == null:
		return
	hp_label.text = "ROWAN  %d / %d" % [current, maximum]
	hp_bar.max_value = maximum
	hp_bar.value = current


func set_total(total: int) -> void:
	enemies_this_wave = total
	kills_this_wave = 0
	_update_kills()


func show_wave(wave: int, total_waves: int, enemies: int) -> void:
	result_shown = false
	wave_label.text = "WAVE %d / %d" % [wave, total_waves]
	banner.text = "WAVE %d - HERE THEY COME" % wave
	set_total(enemies)


func add_kill() -> void:
	kills_this_wave += 1
	_update_kills()


func _update_kills() -> void:
	if kills_label != null:
		kills_label.text = "GHOSTS  %d / %d" % [kills_this_wave, enemies_this_wave]


func show_intermission(wave: int) -> void:
	banner.text = "WAVE %d CLEARED - NEXT WAVE" % wave


func show_game_over() -> void:
	if result_shown:
		return
	result_shown = true
	banner.text = ""
	var game_over_message := "One revive is ready. Bounce back into the fight!"
	if revive_used:
		game_over_message = "Your revive is spent. Start over for another run."
	_show_result("ROWAN HAS FALLEN", game_over_message, false)


func show_victory() -> void:
	if result_shown:
		return
	result_shown = true
	banner.text = ""
	_show_result("LARKSPUR RESTORED", "FIVE WAVES CLEARED\nETERNAL - BOUNCE BACK", true)
	_spawn_confetti()


func _show_result(title_text: String, body_text: String, victory: bool) -> void:
	result_overlay = Control.new()
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.045, 0.08, 0.78)
	result_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 250)
	_style_panel(panel, Color("#111827"), Color("#f4b96a") if victory else Color("#ff6b83"))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)
	var title := _label(title_text, 11, Color("#e8e8f0"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var body := _label(body_text, 9, Color("#c9d7e4"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(340, 58)
	stack.add_child(body)
	if not victory:
		var bounce_back := Button.new()
		bounce_back.text = "REVIVE USED" if revive_used else "BOUNCE BACK"
		bounce_back.custom_minimum_size = Vector2(0, 44)
		bounce_back.disabled = revive_used
		if not revive_used:
			bounce_back.pressed.connect(_revive_player)
			_breathe_button(bounce_back)
		stack.add_child(bounce_back)
		var restart := Button.new()
		restart.text = "START OVER"
		restart.custom_minimum_size = Vector2(0, 38)
		restart.pressed.connect(_restart)
		stack.add_child(restart)
	else:
		var replay := Button.new()
		replay.text = "PLAY AGAIN"
		replay.custom_minimum_size = Vector2(0, 38)
		replay.pressed.connect(_restart)
		stack.add_child(replay)
	ui.add_child(result_overlay)


func _revive_player() -> void:
	if revive_used:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("revive"):
		return
	revive_used = true
	player.call("revive", 5)
	get_tree().call_group("enemies", "set_physics_process", true)
	if is_instance_valid(result_overlay):
		result_overlay.queue_free()
	result_overlay = null
	result_shown = false
	if banner != null:
		banner.text = "ROWAN BOUNCED BACK!"


func _breathe_button(button: Button) -> void:
	button.pivot_offset = Vector2(174.0, 22.0)
	var breathing := button.create_tween().set_loops()
	(
		breathing
		. tween_property(button, "scale", Vector2(1.045, 1.045), 0.7)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		breathing
		. tween_property(button, "scale", Vector2.ONE, 0.7)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)


func _restart() -> void:
	get_tree().reload_current_scene()


func _spawn_confetti() -> void:
	confetti_elapsed = 0.0
	var palette := [
		Color("#70ddeb"), Color("#f4b96a"), Color("#c6aaff"), Color("#ff9db5"), Color("#e8e8f0")
	]
	var viewport_size := get_viewport().get_visible_rect().size
	for i in range(70):
		var piece := ColorRect.new()
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.size = Vector2(rng.randf_range(5.0, 10.0), rng.randf_range(7.0, 13.0))
		piece.position = Vector2(
			rng.randf_range(0.0, viewport_size.x),
			rng.randf_range(-viewport_size.y, viewport_size.y)
		)
		piece.color = palette[rng.randi_range(0, palette.size() - 1)]
		ui.add_child(piece)
		confetti_nodes.append(piece)
		confetti_velocity.append(
			Vector2(rng.randf_range(-45.0, 45.0), rng.randf_range(70.0, 190.0))
		)


func _process(delta: float) -> void:
	if confetti_nodes.is_empty():
		return
	confetti_elapsed += delta
	if confetti_elapsed >= CONFETTI_DURATION:
		for piece in confetti_nodes:
			if is_instance_valid(piece):
				piece.queue_free()
		confetti_nodes.clear()
		confetti_velocity.clear()
		return
	var progress := clampf(confetti_elapsed / CONFETTI_DURATION, 0.0, 1.0)
	var viewport_size := get_viewport().get_visible_rect().size
	for i in range(confetti_nodes.size()):
		var piece := confetti_nodes[i]
		if not is_instance_valid(piece):
			continue
		var speed := confetti_velocity[i]
		# The shower accelerates toward the end, then vanishes after exactly five seconds.
		speed *= 1.0 + 0.18 * delta
		speed.y += (170.0 + 320.0 * progress) * delta
		confetti_velocity[i] = speed
		piece.position += speed * delta
		if piece.position.y > viewport_size.y + 20.0:
			piece.position.y = -20.0
			piece.position.x = rng.randf_range(0.0, viewport_size.x)


func _unhandled_input(event: InputEvent) -> void:
	if not result_shown or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.pressed and key_event.keycode == KEY_R:
		_restart()
