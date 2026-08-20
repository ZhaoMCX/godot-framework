class_name ExampleScoreChangedEvent
extends GFEvent

const TYPE := &"example.battle_reward.score_changed"

var total_score: int
var awarded_points: int


func _init(
		new_total_score: int,
		points: int,
		command_id: String,
		event_id: String = "",
) -> void:
	super(command_id, event_id)
	total_score = new_total_score
	awarded_points = points


func get_message_type() -> StringName:
	return TYPE


func to_payload() -> Dictionary:
	return {
		"total_score": total_score,
		"awarded_points": awarded_points,
	}
