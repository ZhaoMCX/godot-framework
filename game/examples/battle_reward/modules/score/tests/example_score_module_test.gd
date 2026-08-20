extends GdUnitTestSuite

const COMMAND_ID := "11111111111111111111111111111111"
const EVENT_ID := "22222222222222222222222222222222"


func test_positive_score_emits_change_before_completion_and_updates_snapshot() -> void:
	var module := auto_free(ExampleScoreModule.new()) as ExampleScoreModule
	var emission_order: Array[StringName] = []
	var changed_events: Array[ExampleScoreChangedEvent] = []
	var completed_events: Array[GFCommandCompletedEvent] = []
	module.score_changed.connect(
		func(event: ExampleScoreChangedEvent) -> void:
			emission_order.append(&"score_changed")
			changed_events.append(event)
	)
	module.command_completed.connect(
		func(event: GFCommandCompletedEvent) -> void:
			emission_order.append(&"command_completed")
			completed_events.append(event)
	)

	var result := module.submit_add_score(ExampleAddScoreCommand.new(100, EVENT_ID, COMMAND_ID))
	var snapshot := module.get_snapshot()

	assert_bool(result.accepted).is_true()
	assert_array(emission_order).contains_exactly(&"score_changed", &"command_completed")
	assert_int(snapshot.total_score).is_equal(100)
	assert_array(snapshot.awards).contains_exactly(100)
	assert_str(changed_events[0].causation_id).is_equal(COMMAND_ID)
	assert_bool(completed_events[0].succeeded).is_true()


func test_non_positive_score_completes_with_failure_without_changing_state() -> void:
	var module := auto_free(ExampleScoreModule.new()) as ExampleScoreModule
	var completed_events: Array[GFCommandCompletedEvent] = []
	module.command_completed.connect(
		func(event: GFCommandCompletedEvent) -> void: completed_events.append(event)
	)

	var result := module.submit_add_score(ExampleAddScoreCommand.new(0, EVENT_ID, COMMAND_ID))
	var snapshot := module.get_snapshot()

	assert_bool(result.accepted).is_true()
	assert_int(snapshot.total_score).is_equal(0)
	assert_array(snapshot.awards).is_empty()
	assert_array(completed_events).has_size(1)
	assert_bool(completed_events[0].succeeded).is_false()
	assert_str(completed_events[0].error_code).is_equal(&"invalid_score")


func test_snapshot_awards_are_isolated_from_external_mutation() -> void:
	var module := auto_free(ExampleScoreModule.new()) as ExampleScoreModule
	module.submit_add_score(ExampleAddScoreCommand.new(100, EVENT_ID, COMMAND_ID))
	var external_awards := module.get_snapshot().awards

	external_awards.append(999)

	assert_array(module.get_snapshot().awards).contains_exactly(100)
