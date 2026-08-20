class_name ExampleDefeatEnemyCommand
extends GFCommand

const TYPE := &"example.battle_reward.defeat_enemy"

var enemy_id: StringName
var reward_points: int


func _init(target_enemy_id: StringName, points: int, id: String = "") -> void:
	super(id)
	enemy_id = target_enemy_id
	reward_points = points


func get_message_type() -> StringName:
	return TYPE


func to_payload() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"reward_points": reward_points,
	}
