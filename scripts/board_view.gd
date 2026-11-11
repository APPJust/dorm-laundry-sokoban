extends Control

const FLOOR := Color("#f7e9c6")
const FLOOR_ALT := Color("#f2dfb4")
const WALL := Color("#507c78")
const WALL_EDGE := Color("#315a58")

var board_width: int = 0
var board_height: int = 0
var walls: Dictionary = {}
var spills: Dictionary = {}
var goals: Dictionary = {}
var boxes: Array = []
var player_pos := Vector2i.ZERO
var bump_offset := Vector2.ZERO
var bump_left := 0.0
var celebration_left := 0.0


func _process(delta: float) -> void:
	if bump_left > 0.0:
		bump_left = maxf(0.0, bump_left - delta)
		if bump_left == 0.0:
			bump_offset = Vector2.ZERO
			queue_redraw()
	if celebration_left > 0.0:
		celebration_left = maxf(0.0, celebration_left - delta)
		queue_redraw()


func set_board(width: int, height: int, new_walls: Dictionary, new_spills: Dictionary, new_goals: Dictionary, new_boxes: Array, new_player: Vector2i) -> void:
	board_width = width
	board_height = height
	walls = new_walls.duplicate()
	spills = new_spills.duplicate()
	goals = new_goals.duplicate()
	boxes = new_boxes.duplicate(true)
	player_pos = new_player
	queue_redraw()


func bump(direction: Vector2i) -> void:
	bump_offset = Vector2(direction) * 7.0
	bump_left = 0.12
	queue_redraw()


func celebrate() -> void:
	celebration_left = 0.35
	queue_redraw()


func _draw() -> void:
	if board_width <= 0 or board_height <= 0:
		return
	var margin := 12.0
	var cell_size: float = floorf(minf((size.x - margin * 2.0) / float(board_width), (size.y - margin * 2.0) / float(board_height)))
	cell_size = maxf(12.0, cell_size)
	var board_size: Vector2 = Vector2(board_width, board_height) * cell_size
	var origin: Vector2 = (size - board_size) * 0.5
	var font := get_theme_default_font()
	for y in range(board_height):
		for x in range(board_width):
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			if walls.has(cell):
				_draw_wall(rect, cell_size)
			else:
				_draw_floor(rect, cell_size, (x + y) % 2 == 0)
				if spills.has(cell):
					_draw_spill(rect, cell_size)
				if goals.has(cell):
					_draw_goal(rect, cell_size, str(goals[cell]))
	for box in boxes:
		_draw_basket(_cell_rect(origin, cell_size, box["pos"]), cell_size, str(box["type"]))
	_draw_player(_cell_rect(origin, cell_size, player_pos), cell_size)
	if celebration_left > 0.0:
		var alpha := celebration_left / 0.35
		draw_rect(Rect2(origin, board_size), Color(1.0, 0.88, 0.4, 0.18 * alpha), false, 4.0)
	if font == null:
		return


func _cell_rect(origin: Vector2, cell_size: float, cell: Vector2i) -> Rect2:
	return Rect2(origin + Vector2(cell) * cell_size, Vector2.ONE * cell_size)


func _draw_floor(rect: Rect2, cell_size: float, alternate: bool) -> void:
	var inset := maxf(1.0, cell_size * 0.035)
	draw_rect(rect.grow(-inset), FLOOR_ALT if alternate else FLOOR, true)
	draw_rect(rect.grow(-inset), Color("#e2c996"), false, 1.0)


func _draw_wall(rect: Rect2, cell_size: float) -> void:
	draw_rect(rect.grow(-1.0), WALL, true)
	draw_rect(rect.grow(-1.0), WALL_EDGE, false, maxf(1.0, cell_size * 0.035))
	draw_line(rect.position + Vector2(4, cell_size * 0.35), rect.position + Vector2(cell_size - 4, cell_size * 0.35), Color("#78a099"), 2.0)
	draw_line(rect.position + Vector2(4, cell_size * 0.68), rect.position + Vector2(cell_size - 4, cell_size * 0.68), Color("#78a099"), 2.0)


func _draw_spill(rect: Rect2, cell_size: float) -> void:
	var center := rect.get_center()
	draw_circle(center, cell_size * 0.25, Color("#83c6d1"))
	draw_circle(center + Vector2(-cell_size * 0.1, -cell_size * 0.08), cell_size * 0.055, Color("#d5f4ed"))
	draw_circle(center + Vector2(cell_size * 0.1, cell_size * 0.1), cell_size * 0.04, Color("#d5f4ed"))


func _draw_goal(rect: Rect2, cell_size: float, kind: String) -> void:
	var center := rect.get_center()
	var color := _kind_color(kind)
	draw_circle(center, cell_size * 0.34, Color("#dce9df"))
	draw_circle(center, cell_size * 0.27, color.darkened(0.12))
	draw_circle(center, cell_size * 0.2, Color("#a9c9c0"))
	draw_circle(center, cell_size * 0.11, Color("#eff5df"))
	var mark := _kind_mark(kind)
	_draw_centered_text(mark, center + Vector2(0, cell_size * 0.39), cell_size * 0.23, Color("#315a58"))


func _draw_basket(rect: Rect2, cell_size: float, kind: String) -> void:
	var inset := cell_size * 0.16
	var basket_rect := Rect2(rect.position + Vector2(inset, inset * 1.35), Vector2(rect.size.x - inset * 2.0, rect.size.y - inset * 1.8))
	var color := _kind_color(kind)
	draw_rect(basket_rect, color, true)
	draw_rect(basket_rect, color.darkened(0.28), false, maxf(1.5, cell_size * 0.045))
	for slat in range(1, 4):
		var x := basket_rect.position.x + basket_rect.size.x * float(slat) / 4.0
		draw_line(Vector2(x, basket_rect.position.y + 3), Vector2(x, basket_rect.end.y - 3), color.darkened(0.18), maxf(1.0, cell_size * 0.025))
	draw_line(basket_rect.position + Vector2(0, -cell_size * 0.06), Vector2(basket_rect.end.x, basket_rect.position.y - cell_size * 0.06), color.darkened(0.3), maxf(2.0, cell_size * 0.06))
	_draw_centered_text(_kind_mark(kind), basket_rect.get_center() + Vector2(0, cell_size * 0.08), cell_size * 0.28, Color("#263e3b"))


func _draw_player(rect: Rect2, cell_size: float) -> void:
	var center := rect.get_center() + bump_offset
	var head_radius := cell_size * 0.16
	_draw_oval(center + Vector2(0, cell_size * 0.11), Vector2(cell_size * 0.23, cell_size * 0.28), Color("#e07f5f"))
	draw_circle(center + Vector2(0, -cell_size * 0.15), head_radius, Color("#f4bd8c"))
	draw_arc(center + Vector2(0, -cell_size * 0.17), head_radius * 1.04, PI, TAU, 12, Color("#44362e"), maxf(2.0, cell_size * 0.06))
	draw_circle(center + Vector2(-head_radius * 0.32, -cell_size * 0.16), maxf(1.0, cell_size * 0.022), Color("#44362e"))
	draw_circle(center + Vector2(head_radius * 0.32, -cell_size * 0.16), maxf(1.0, cell_size * 0.022), Color("#44362e"))
	_draw_centered_text("沐", center + Vector2(0, cell_size * 0.21), cell_size * 0.2, Color.WHITE)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_centered_text(text: String, center: Vector2, font_size: float, color: Color) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var size_px := maxi(10, int(font_size))
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	var baseline := center.y + float(size_px) * 0.35
	draw_string(font, Vector2(center.x - text_width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)


func _kind_color(kind: String) -> Color:
	match kind:
		"b":
			return Color("#f4f1df")
		"c":
			return Color("#84b9d1")
		"t":
			return Color("#e8bd68")
		_:
			return Color("#d7ae79")


func _kind_mark(kind: String) -> String:
	match kind:
		"b":
			return "白"
		"c":
			return "彩"
		"t":
			return "巾"
		_:
			return "?"
