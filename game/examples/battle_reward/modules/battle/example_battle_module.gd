class_name ExampleBattleModule
extends GFModule

signal enemy_defeated(event: ExampleEnemyDefeatedEvent)
signal command_completed(event: GFCommandCompletedEvent)

var _defeated_enemy_ids: Dictionary[StringName, bool] = {}


func submit_defeat_enemy(command: ExampleDefeatEnemyCommand) -> GFSubmitResult:
	if not GFMessageValidator.is_valid_command(command):
		var command_id := "" if command == null else command.command_id
		return GFSubmitResult.rejected_result(
			command_id,
			&"invalid_command",
			"The command is not network safe.",
		)

	var submission := GFSubmitResult.accepted_result(command.command_id)
	if command.enemy_id.is_empty() or command.reward_points <= 0:
		command_completed.emit(
			GFCommandCompletedEvent.new(
				command.command_id,
				false,
				&"invalid_enemy_reward",
				"Enemy ID and reward points must be valid.",
			)
		)
		return submission

	if _defeated_enemy_ids.has(command.enemy_id):
		command_completed.emit(
			GFCommandCompletedEvent.new(
				command.command_id,
				false,
				&"enemy_already_defeated",
				"The enemy was already defeated.",
			)
		)
		return submission

	_defeated_enemy_ids[command.enemy_id] = true
	enemy_defeated.emit(
		ExampleEnemyDefeatedEvent.new(
			command.enemy_id,
			command.reward_points,
			command.command_id,
		)
	)
	command_completed.emit(GFCommandCompletedEvent.new(command.command_id, true))
	return submission
