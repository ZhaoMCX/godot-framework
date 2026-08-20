class_name ExampleAddScoreCommand
extends GFCommand

const TYPE := &"example.battle_reward.add_score"

var points: int
var source_event_id: String


func _init(added_points: int, caused_by_event_id: String, id: String = "") -> void:
	super(id)
	points = added_points
	source_event_id = caused_by_event_id


func get_message_type() -> StringName:
	return TYPE


func to_payload() -> Dictionary:
	return {
		"points": points,
		"source_event_id": source_event_id,
	}
