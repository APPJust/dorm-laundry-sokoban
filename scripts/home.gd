extends Control

const CREAM := Color("#fff4d8")
const INK := Color("#153c45")
const TEAL := Color("#267b78")


func _ready() -> void:
	_build_screen()


func _build_screen() -> void:
	_add_background(Color("#e3f0df"))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 440)
	panel.add_theme_stylebox_override("panel", _panel_style(CREAM, 28))
	center.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 30)
	content_margin.add_theme_constant_override("margin_top", 28)
	content_margin.add_theme_constant_override("margin_right", 30)
	content_margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(content_margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	content_margin.add_child(stack)

	var eyebrow := _label("宿舍洗衣間・推箱子解謎", 20, TEAL)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(eyebrow)

	var title := _label("洗衣間大塞車\n籃籃歸位", 44, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	stack.add_child(title)

	var description := _label("洗衣機快打烊了！在倒數時間內把洗衣籃\n推到同標記的洗衣機前。只能推，不能拉。", 20, INK)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(description)

	var start_button := _button("開始整理", TEAL, CREAM)
	start_button.custom_minimum_size = Vector2(200, 58)
	start_button.pressed.connect(_start_game)
	stack.add_child(start_button)
	var sound_button := _button(_sound_button_text(), Color("#d58c4e"), CREAM)
	sound_button.custom_minimum_size = Vector2(150, 42)
	sound_button.pressed.connect(_toggle_sound.bind(sound_button))
	stack.add_child(sound_button)

	var hint := _label("方向鍵 / WASD 移動　　Z 復原　　R 重來\n手機可點畫面方向鈕；也可用滑鼠點方向鈕。", 16, Color("#49666a"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(hint)

	var credit := _label("製作：資通系 李振偉｜美術與音效：程式繪製／合成\n字型：Noto Sans TC，SIL OFL 1.1（Google Fonts）", 14, Color("#49666a"))
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(credit)


func _start_game() -> void:
	SoundManager.play_sfx("button")
	GameSession.start_run()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _toggle_sound(button: Button) -> void:
	SoundManager.set_enabled(not SoundManager.enabled)
	button.text = _sound_button_text()
	if SoundManager.enabled:
		SoundManager.play_sfx("button")


func _sound_button_text() -> String:
	return "音效：開" if SoundManager.enabled else "音效：關"


func _add_background(color: Color) -> void:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text: String, color: Color, text_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _panel_style(color, 16))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.08), 16))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.08), 16))
	return button


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.08, 0.18, 0.2, 0.13)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style
