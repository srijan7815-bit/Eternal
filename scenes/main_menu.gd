extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const LOGO_TEXTURE = preload("res://assets/ui/eternal_logo.png")
const PIXEL_FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var pixel_theme := Theme.new()
	pixel_theme.default_font = PIXEL_FONT
	pixel_theme.default_font_size = 12
	theme = pixel_theme

	_add_logo_background()
	_add_menu()


func _add_logo_background() -> void:
	var background := TextureRect.new()
	background.name = "LogoBackground"
	background.texture = LOGO_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "ContrastShade"
	shade.color = Color(0.015, 0.025, 0.07, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_menu() -> void:
	var bottom_area := CenterContainer.new()
	bottom_area.name = "StartMenuArea"
	bottom_area.anchor_left = 0.0
	bottom_area.anchor_top = 0.66
	bottom_area.anchor_right = 1.0
	bottom_area.anchor_bottom = 1.0
	bottom_area.offset_left = 0.0
	bottom_area.offset_top = 0.0
	bottom_area.offset_right = 0.0
	bottom_area.offset_bottom = -8.0
	add_child(bottom_area)

	var panel := PanelContainer.new()
	panel.name = "StartMenuPanel"
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	bottom_area.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	panel.add_child(stack)

	var tagline := Label.new()
	tagline.text = "A WINTER ARCADE ADVENTURE"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 8)
	tagline.add_theme_color_override("font_color", Color("#d8eaff"))
	stack.add_child(tagline)

	var start_button := _make_button("START GAME", Color("#173e62"), Color("#70ddeb"))
	start_button.custom_minimum_size = Vector2(250, 44)
	start_button.pressed.connect(_start_game)
	stack.add_child(start_button)
	_breathe(start_button)

	var quit_button := _make_button("QUIT", Color("#241f42"), Color("#c6aaff"))
	quit_button.custom_minimum_size = Vector2(250, 38)
	quit_button.pressed.connect(_quit_game)
	stack.add_child(quit_button)

	var controls := Label.new()
	controls.text = "MOVE A/D  JUMP SPACE  ATTACK J"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 7)
	controls.add_theme_color_override("font_color", Color("#b9c7df"))
	stack.add_child(controls)
	start_button.call_deferred("grab_focus")


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.12, 0.84)
	style.border_color = Color("#70ddeb")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _make_button(text: String, base_color: Color, accent_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#f3f6ff"))
	button.add_theme_color_override("font_hover_color", Color("#101522"))
	button.add_theme_color_override("font_pressed_color", Color("#101522"))
	button.add_theme_stylebox_override("normal", _button_style(base_color, accent_color, false))
	button.add_theme_stylebox_override("hover", _button_style(accent_color, accent_color, true))
	button.add_theme_stylebox_override(
		"pressed", _button_style(Color("#f4b96a"), Color("#fff0cf"), true)
	)
	button.add_theme_stylebox_override("focus", _button_style(base_color, Color("#f4b96a"), false))
	return button


func _button_style(fill: Color, border: Color, thick: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3 if thick else 2)
	style.set_corner_radius_all(2)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _breathe(button: Button) -> void:
	button.pivot_offset = Vector2(125.0, 22.0)
	var pulse := button.create_tween().set_loops()
	(
		pulse
		. tween_property(button, "scale", Vector2(1.035, 1.035), 0.75)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	pulse.tween_property(button, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)


func _start_game() -> void:
	var error := get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Could not load game scene at %s (error %d)." % [GAME_SCENE, error])


func _quit_game() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()
