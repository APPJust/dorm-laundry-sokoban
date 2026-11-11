extends Control

const CREAM := Color("#fff4d8")
const INK := Color("#153c45")
const TEAL := Color("#267b78")


func _ready() -> void:
	_build_screen()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#e3f0df")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(CREAM, 26))
	center.add_child(panel)
	var content := MarginContainer.new()
	content.add_theme_constant_override("margin_left", 30)
	content.add_theme_constant_override("margin_top", 26)
	content.add_theme_constant_override("margin_right", 30)
	content.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(content)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(stack)

	var headline := "洗衣任務完成！" if GameSession.won else "洗衣間打烊了"
	var accent := TEAL if GameSession.won else Color("#bd654c")
	var title := _label(headline, 36, accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)

	var detail_text := "太棒了，所有洗衣籃都回到正確位置。" if GameSession.won else "時間到了，洗衣籃還沒全部歸位。"
	var detail := _label(detail_text, 19, INK)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(detail)

	var score := _label("總分　%d" % GameSession.score, 28, INK)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(score)

	var total_seconds := int(GameSession.elapsed_seconds)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	var stats := _label(
		"完成關卡　%d / %d\n總用時　%02d:%02d\n移動步數　%d　・　推籃次數　%d" % [
			GameSession.levels_cleared,
			GameSession.LEVELS.size(),
			minutes,
			seconds,
			GameSession.total_moves,
			GameSession.total_pushes,
		],
		18,
		Color("#49666a")
	)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(stats)

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	stack.add_child(buttons)
	var replay := _button("再玩一次", TEAL)
	replay.pressed.connect(_replay)
	buttons.add_child(replay)
	var home := _button("回到首頁", Color("#cf8c4d"))
	home.pressed.connect(_home)
	buttons.add_child(home)

	var credits := _label("製作：資通系 李振偉\n字型：Noto Sans TC，SIL OFL 1.1（Google Fonts）", 14, Color("#49666a"))
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(credits)


func _replay() -> void:
	SoundManager.play_sfx("button")
	GameSession.start_run()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _home() -> void:
	SoundManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/Home.tscn")


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 52)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", CREAM)
	button.add_theme_stylebox_override("normal", _panel_style(color, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.08), 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.08), 14))
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
