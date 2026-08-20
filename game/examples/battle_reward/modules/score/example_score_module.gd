class_name ExampleScoreModule
extends GFModule

signal score_changed(event: ExampleScoreChangedEvent)
signal command_completed(event: GFCommandCompletedEvent)

var _total_score := 0
var _awards: Array[int] = []


func submit_add_score(command: ExampleAddScoreCommand) -> GFSubmitResult:
	if not GFMessageValidator.is_valid_command(command):
		var command_id := "" if command == null else command.command_id
		return GFSubmitResult.rejected_result(
			command_id,
			&"invalid_command",
			"The command is not network safe.",
		)

	var submission := GFSubmitResult.accepted_result(command.command_id)
	if command.points <= 0:
		command_completed.emit(
			GFCommandCompletedEvent.new(
				command.command_id,
				false,
				&"invalid_score",
				"Score points must be positive.",
			)
		)
		return submission

	_total_score += command.points
	_awards.append(command.points)
	score_changed.emit(
		ExampleScoreChangedEvent.new(
			_total_score,
			command.points,
			command.command_id,
		)
	)
	command_completed.emit(GFCommandCompletedEvent.new(command.command_id, true))
	return submission


func get_snapshot() -> ExampleScoreSnapshot:
	return ExampleScoreSnapshot.new(_total_score, _awards)
