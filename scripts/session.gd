extends Node

const LEVELS: Array[Dictionary] = [
	{
		"title": "新生練習",
		"time_limit": 120,
		"rows": [
			"########",
			"#......#",
			"#..P.Bb#",
			"#......#",
			"#......#",
			"########",
		],
	},
	{
		"title": "白衣和彩衣",
		"time_limit": 115,
		"rows": [
			"#########",
			"#.......#",
			"#.P.Bb..#",
			"#.......#",
			"#..Cc...#",
			"#.......#",
			"#########",
		],
	},
	{
		"title": "洗衣精漏了",
		"time_limit": 110,
		"rows": [
			"##########",
			"#........#",
			"#.P.B..b.#",
			"#...#....#",
			"#.C..c...#",
			"#..~.....#",
			"#.T...t..#",
			"##########",
		],
	},
	{
		"title": "推車窄走道",
		"time_limit": 100,
		"rows": [
			"##########",
			"#...#....#",
			"#.P.#.C.c#",
			"#.Bb#....#",
			"#........#",
			"#...#....#",
			"#.Tt#....#",
			"#...#....#",
			"##########",
		],
	},
	{
		"title": "打烊前大整理",
		"time_limit": 90,
		"rows": [
			"###########",
			"#.........#",
			"#.P.B...b.#",
			"#...~.....#",
			"#.C..c....#",
			"#....~....#",
			"#.T...t...#",
			"#.B...b...#",
			"###########",
		],
	},
]

var level_index: int = 0
var score: int = 0
var levels_cleared: int = 0
var total_moves: int = 0
var total_pushes: int = 0
var elapsed_seconds: float = 0.0
var won: bool = false


func start_run() -> void:
	level_index = 0
	score = 0
	levels_cleared = 0
	total_moves = 0
	total_pushes = 0
	elapsed_seconds = 0.0
	won = false


func current_level() -> Dictionary:
	return LEVELS[level_index]


func record_move(was_push: bool) -> void:
	total_moves += 1
	if was_push:
		total_pushes += 1


func undo_move(was_push: bool) -> void:
	total_moves = maxi(0, total_moves - 1)
	if was_push:
		total_pushes = maxi(0, total_pushes - 1)


func award_basket() -> void:
	score += 100


func complete_level(time_remaining: float) -> void:
	levels_cleared += 1
	score += 300 + maxi(0, int(time_remaining)) * 2
	won = levels_cleared >= LEVELS.size()
	if not won:
		level_index += 1


func finish_run(did_win: bool) -> void:
	won = did_win
