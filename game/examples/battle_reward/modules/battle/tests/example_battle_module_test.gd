extends GdUnitTestSuite

const FIRST_COMMAND_ID := "11111111111111111111111111111111"
const SECOND_COMMAND_ID := "22222222222222222222222222222222"


func test_valid_defeat_emits_domain_event_before_successful_completion() -> void:
	var module := auto_free(ExampleBattleModule.new()) as ExampleBattleModule
	var emission_order: Array[StringName] = []
	var defeated_events: Array[ExampleEnemyDefeatedEvent] = []
	var completed_events: Array[GFCommandCompletedEvent] = []
	module.enemy_defeated.connect(
		func(event: ExampleEnemyDefeatedEvent) -> void:
			emission_order.append(&"enemy_defeated")
			defeated_events.append(event)
	)
	module.command_completed.connect(
		func(event: GFCommandCompletedEvent) -> void:
			emission_order.append(&"command_completed")
			completed_events.append(event)
	)

	var result := module.submit_defeat_enemy(
		ExampleDefeatEnemyCommand.new(&"slime_01", 100, FIRST_COMMAND_ID)
	)

	assert_bool(result.accepted).is_true()
	assert_array(emission_order).contains_exactly(&"enemy_defeated", &"command_completed")
	assert_array(defeated_events).has_size(1)
	assert_str(defeated_events[0].causation_id).is_equal(FIRST_COMMAND_ID)
	assert_array(completed_events).has_size(1)
	assert_bool(completed_events[0].succeeded).is_true()


func test_duplicate_defeat_is_accepted_but_completes_with_failure() -> void:
	var module := auto_free(ExampleBattleModule.new()) as ExampleBattleModule
	var defeated_events: Array[ExampleEnemyDefeatedEvent] = []
	var completed_events: Array[GFCommandCompletedEvent] = []
	module.enemy_defeated.connect(
		func(event: ExampleEnemyDefeatedEvent) -> void: defeated_events.append(event)
	)
	module.command_completed.connect(
		func(event: GFCommandCompletedEvent) -> void: completed_events.append(event)
	)
	module.submit_defeat_enemy(
		ExampleDefeatEnemyCommand.new(&"slime_01", 100, FIRST_COMMAND_ID)
	)

	var duplicate_result := module.submit_defeat_enemy(
		ExampleDefeatEnemyCommand.new(&"slime_01", 100, SECOND_COMMAND_ID)
	)

	assert_bool(duplicate_result.accepted).is_true()
	assert_array(defeated_events).has_size(1)
	assert_array(completed_events).has_size(2)
	assert_bool(completed_events[1].succeeded).is_false()
	assert_str(completed_events[1].error_code).is_equal(&"enemy_already_defeated")


func test_invalid_command_is_rejected_without_events() -> void:
	var module := auto_free(ExampleBattleModule.new()) as ExampleBattleModule
	var defeated_events: Array[ExampleEnemyDefeatedEvent] = []
	var completed_events: Array[GFCommandCompletedEvent] = []
	module.enemy_defeated.connect(
		func(event: ExampleEnemyDefeatedEvent) -> void: defeated_events.append(event)
	)
	module.command_completed.connect(
		func(event: GFCommandCompletedEvent) -> void: completed_events.append(event)
	)

	var result := module.submit_defeat_enemy(
		ExampleDefeatEnemyCommand.new(&"slime_01", 100, "invalid-id")
	)

	assert_bool(result.accepted).is_false()
	assert_array(defeated_events).is_empty()
	assert_array(completed_events).is_empty()
