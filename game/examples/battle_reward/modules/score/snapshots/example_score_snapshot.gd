class_name ExampleScoreSnapshot
extends RefCounted

var total_score: int:
	get:
		return _total_score

var awards: Array[int]:
	get:
		return _awards.duplicate()

var _total_score: int
var _awards: Array[int]


func _init(score: int, award_history: Array[int]) -> void:
	_total_score = score
	_awards = award_history.duplicate()
