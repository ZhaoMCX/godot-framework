class_name ExampleEnemyDefeatedEvent
extends GFEvent

const TYPE := &"example.battle_reward.enemy_defeated"

var enemy_id: StringName
var reward_points: int


func _init(
		defeated_enemy_id: StringName,
		points: int,
		command_id: String,
		event_id: String = "",
) -> void:
	super(command_id, event_id)
	enemy_id = defeated_enemy_id
	reward_points = points


func get_message_type() -> StringName:
	return TYPE


func to_payload() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"reward_points": reward_points,
	}
