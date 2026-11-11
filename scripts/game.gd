extends Control

const CREAM := Color("#fff4d8")
const INK := Color("#153c45")
const TEAL := Color("#267b78")
const BOARD_SCRIPT = preload("res://scripts/board_view.gd")

var board_view: Control
var score_label: Label
var timer_label: Label
var level_label: Label
var progress_label: Label
var player_pos := Vector2i.ZERO
var boxes: Array = []
var walls: Dictionary = {}
var spills: Dictionary = {}
var goals: Dictionary = {}
var credited_boxes: Dictionary = {}
var history: Array[Dictionary] = []
var time_limit: float = 120.0
var time_left: float = 120.0
var level_start_score: int = 0
var level_moves: int = 0
var level_pushes: int = 0
var game_over: bool = false
var transitioning: bool = false
var feedback_label: Label
var sound_button: Button


func _ready() -> void:
	_build_screen()
	_load_level()
	set_process(true)


func _process(delta: float) -> void:
	if game_over or transitioning:
		return
	time_left -= delta
	GameSession.elapsed_seconds += delta
	_refresh_hud()
	if time_left <= 0.0:
		time_left = 0.0
		_finish(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if game_over or transitioning or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_UP, KEY_W:
			direction = Vector2i.UP
		KEY_DOWN, KEY_S:
			direction = Vector2i.DOWN
		KEY_LEFT, KEY_A:
			direction = Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			direction = Vector2i.RIGHT
		KEY_Z:
			_undo()
			get_viewport().set_input_as_handled()
			return
		KEY_R:
			_restart_level()
			get_viewport().set_input_as_handled()
			return
	if direction != Vector2i.ZERO:
		_move_player(direction)
		get_viewport().set_input_as_handled()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#e3f0df")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	var heading_row := HBoxContainer.new()
	stack.add_child(heading_row)
	var heading := _label("洗衣間大塞車", 22, INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_row.add_child(heading)
	sound_button = _button(_sound_button_text(), Color("#cf8c4d"), 14)
	sound_button.custom_minimum_size = Vector2(96, 40)
	sound_button.pressed.connect(_toggle_sound)
	heading_row.add_child(sound_button)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 8)
	stack.add_child(status)
	score_label = _stat_label("分數 0")
	timer_label = _stat_label("時間 02:00")
	level_label = _stat_label("關卡 1 / 1")
	for item in [score_label, timer_label, level_label]:
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_child(item)

	progress_label = _label("推好 0 / 1 籃", 17, TEAL)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(progress_label)

	var board_area := Control.new()
	board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_area.custom_minimum_size = Vector2(160, 220)
	stack.add_child(board_area)
	board_view = Control.new()
	board_view.set_script(BOARD_SCRIPT)
	board_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_area.add_child(board_view)

	feedback_label = _label("", 24, Color("#b55b35"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.visible = false
	stack.add_child(feedback_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 14)
	stack.add_child(controls)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	controls.add_child(actions)
	var undo_button := _button("復原 Z", Color("#267b78"), 16)
	undo_button.custom_minimum_size = Vector2(96, 48)
	undo_button.pressed.connect(_undo)
	actions.add_child(undo_button)
	var restart_button := _button("重來 R", Color("#cf8c4d"), 16)
	restart_button.custom_minimum_size = Vector2(96, 48)
	restart_button.pressed.connect(_restart_level)
	actions.add_child(restart_button)
	controls.add_child(_make_direction_pad())

	var help := _label("方向鍵 / WASD 移動・Z 復原・R 重來本關", 14, Color("#49666a"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(help)


func _make_direction_pad() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var layout: Array = [
		["", Vector2i.ZERO], ["↑", Vector2i.UP], ["", Vector2i.ZERO],
		["←", Vector2i.LEFT], ["•", Vector2i.ZERO], ["→", Vector2i.RIGHT],
		["", Vector2i.ZERO], ["↓", Vector2i.DOWN], ["", Vector2i.ZERO],
	]
	for entry in layout:
		var text: String = entry[0]
		var direction: Vector2i = entry[1]
		if text.is_empty() or text == "•":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(52, 48)
			grid.add_child(spacer)
		else:
			var button := _button(text, Color("#267b78"), 24)
			button.custom_minimum_size = Vector2(52, 48)
			button.pressed.connect(_move_player.bind(direction))
			grid.add_child(button)
	return grid


func _load_level(preserve_time: bool = false) -> void:
	var level: Dictionary = GameSession.current_level()
	var rows: Array = level["rows"]
	var width: int = 0
	var height: int = rows.size()
	walls.clear()
	spills.clear()
	goals.clear()
	boxes.clear()
	history.clear()
	credited_boxes.clear()
	level_moves = 0
	level_pushes = 0
	level_start_score = GameSession.score
	time_limit = float(level["time_limit"])
	if not preserve_time:
		time_left = time_limit
	for row_index in range(height):
		var row: String = rows[row_index]
		width = maxi(width, row.length())
		for column in range(row.length()):
			var cell := Vector2i(column, row_index)
			match row.substr(column, 1):
				"#":
					walls[cell] = true
				"~":
					spills[cell] = true
				"P":
					player_pos = cell
				"B", "C", "T":
					boxes.append({"pos": cell, "type": row.substr(column, 1).to_lower()})
				"b", "c", "t":
					goals[cell] = row.substr(column, 1)
	board_view.call("set_board", width, height, walls, spills, goals, boxes, player_pos)
	level_label.text = "第 %d / %d 關・%s" % [GameSession.level_index + 1, GameSession.LEVELS.size(), level["title"]]
	_refresh_hud()


func _move_player(direction: Vector2i) -> void:
	if game_over or transitioning:
		return
	var next_cell := player_pos + direction
	if _blocked(next_cell):
		board_view.call("bump", direction)
		SoundManager.play_sfx("blocked")
		_show_feedback("碰到障礙了！")
		return
	var box_index := _box_at(next_cell)
	var will_push := box_index >= 0
	var destination := next_cell + direction
	if will_push and (_blocked(destination) or _box_at(destination) >= 0):
		board_view.call("bump", direction)
		SoundManager.play_sfx("blocked")
		_show_feedback("洗衣籃推不動！")
		return
	history.append({
		"player": player_pos,
		"boxes": boxes.duplicate(true),
		"moves": level_moves,
		"pushes": level_pushes,
		"was_push": will_push,
		"score": GameSession.score,
		"credited": credited_boxes.duplicate(true),
	})
	player_pos = next_cell
	level_moves += 1
	if will_push:
		boxes[box_index]["pos"] = destination
		level_pushes += 1
	GameSession.record_move(will_push)
	SoundManager.play_sfx("move")
	var placed_new_basket := false
	for index in range(boxes.size()):
		var box: Dictionary = boxes[index]
		if goals.get(box["pos"], "") == box["type"] and not credited_boxes.has(index):
			credited_boxes[index] = true
			GameSession.award_basket()
			placed_new_basket = true
	board_view.call("set_board", _board_width(), _board_height(), walls, spills, goals, boxes, player_pos)
	if placed_new_basket:
		board_view.call("celebrate")
		SoundManager.play_sfx("placed")
		_show_feedback("洗衣籃歸位！ +100")
	else:
		_hide_feedback()
	_refresh_hud()
	if _all_baskets_placed():
		_complete_level()


func _undo() -> void:
	if game_over or transitioning:
		return
	if history.is_empty():
		SoundManager.play_sfx("blocked")
		_show_feedback("目前沒有可復原的步驟")
		return
	var previous: Dictionary = history.pop_back()
	player_pos = previous["player"]
	boxes = previous["boxes"]
	level_moves = previous["moves"]
	level_pushes = previous["pushes"]
	GameSession.undo_move(previous["was_push"])
	GameSession.score = previous["score"]
	credited_boxes = previous["credited"]
	board_view.call("set_board", _board_width(), _board_height(), walls, spills, goals, boxes, player_pos)
	SoundManager.play_sfx("move")
	board_view.call("celebrate")
	_hide_feedback()
	_refresh_hud()


func _restart_level() -> void:
	if game_over or transitioning:
		return
	SoundManager.play_sfx("button")
	GameSession.score = level_start_score
	_load_level(true)
	_show_feedback("本關已重來")


func _complete_level() -> void:
	if transitioning or game_over:
		return
	transitioning = true
	SoundManager.play_sfx("clear")
	GameSession.complete_level(time_left)
	_refresh_hud()
	if GameSession.won:
		_finish(true)
		return
	feedback_label.text = "本關完成！準備下一間洗衣房…"
	feedback_label.visible = true
	await get_tree().create_timer(1.1).timeout
	if is_inside_tree() and not game_over:
		transitioning = false
		_load_level()


func _finish(did_win: bool) -> void:
	if game_over:
		return
	game_over = true
	if not did_win:
		SoundManager.play_sfx("fail")
	GameSession.finish_run(did_win)
	get_tree().change_scene_to_file("res://scenes/Result.tscn")


func _blocked(cell: Vector2i) -> bool:
	return walls.has(cell) or spills.has(cell)


func _box_at(cell: Vector2i) -> int:
	for index in range(boxes.size()):
		if boxes[index]["pos"] == cell:
			return index
	return -1


func _all_baskets_placed() -> bool:
	if boxes.is_empty():
		return false
	for box in boxes:
		if goals.get(box["pos"], "") != box["type"]:
			return false
	return true


func _matched_count() -> int:
	var count := 0
	for box in boxes:
		if goals.get(box["pos"], "") == box["type"]:
			count += 1
	return count


func _refresh_hud() -> void:
	if not is_instance_valid(score_label):
		return
	score_label.text = "分數 %04d" % GameSession.score
	var seconds := maxi(0, int(ceil(time_left)))
	timer_label.text = "時間 %02d:%02d" % [seconds / 60, seconds % 60]
	progress_label.text = "推好 %d / %d 籃　・　本關步數 %d" % [_matched_count(), boxes.size(), level_moves]


func _show_feedback(message: String) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = message
		feedback_label.visible = true


func _toggle_sound() -> void:
	SoundManager.set_enabled(not SoundManager.enabled)
	sound_button.text = _sound_button_text()
	if SoundManager.enabled:
		SoundManager.play_sfx("button")


func _sound_button_text() -> String:
	return "音效：開" if SoundManager.enabled else "音效：關"


func _hide_feedback() -> void:
	if is_instance_valid(feedback_label):
		feedback_label.visible = false


func _board_width() -> int:
	return int(GameSession.current_level()["rows"][0].length())


func _board_height() -> int:
	return GameSession.current_level()["rows"].size()


func _stat_label(text: String) -> Label:
	var label := _label(text, 17, INK)
	label.add_theme_stylebox_override("normal", _panel_style(CREAM, 12))
	return label


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text: String, color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", CREAM)
	button.add_theme_color_override("font_pressed_color", CREAM)
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
	return style

