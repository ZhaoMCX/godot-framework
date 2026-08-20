extends GdUnitTestSuite

const FIRST_COMMAND_ID := "11111111111111111111111111111111"
const SECOND_COMMAND_ID := "22222222222222222222222222222222"


func test_defeat_coordinates_modules_and_forwards_events_in_order() -> void:
	var battle_module := auto_free(ExampleBattleModule.new()) as ExampleBattleModule
	var score_module := auto_free(ExampleScoreModule.new()) as ExampleScoreModule
	var feature := auto_free(ExampleRewardFeature.new()) as ExampleRewardFeature
	var emission_order: Array[StringName] = []
	var completed_events: Array[GFCommandCompletedEvent] = []
	feature.score_changed.connect(
		func(_event: ExampleScoreChangedEvent) -> void: emission_order.append(&"score_changed")
	)
	feature.defeat_completed.connect(
		func(event: GFCommandCompletedEvent) -> void:
			emission_order.append(&"defeat_completed")
			completed_events.append(event)
	)
	feature.configure(battle_module, score_module)

	var result := feature.defeat_enemy(&"slime_01", 100, FIRST_COMMAND_ID)

	assert_bool(result.accepted).is_true()
	assert_array(emission_order).contains_exactly(&"score_changed", &"defeat_completed")
	assert_int(feature.get_score_snapshot().total_score).is_equal(100)
	assert_array(feature.get_score_snapshot().awards).contains_exactly(100)
	assert_bool(completed_events[0].succeeded).is_true()


func test_duplicate_and_invalid_defeats_do_not_add_score() -> void:
	var battle_module := auto_free(ExampleBattleModule.new()) as ExampleBattleModule
	var score_module := auto_free(ExampleScoreModule.new()) as ExampleScoreModule
	var feature := auto_free(ExampleRewardFeature.new()) as ExampleRewardFeature
	var completed_events: Array[GFCommandCompletedEvent] = []
	feature.defeat_completed.connect(
		func(event: GFCommandCompletedEvent) -> void: completed_events.append(event)
	)
	feature.configure(battle_module, score_module)
	feature.defeat_enemy(&"slime_01", 100, FIRST_COMMAND_ID)

	var duplicate_result := feature.defeat_enemy(&"slime_01", 100, SECOND_COMMAND_ID)
	var invalid_result := feature.defeat_enemy(&"slime_02", 100, "invalid-id")

	assert_bool(duplicate_result.accepted).is_true()
	assert_bool(invalid_result.accepted).is_false()
	assert_int(feature.get_score_snapshot().total_score).is_equal(100)
	assert_array(feature.get_score_snapshot().awards).contains_exactly(100)
	assert_array(completed_events).has_size(2)
	assert_bool(completed_events[1].succeeded).is_false()
	assert_str(completed_events[1].error_code).is_equal(&"enemy_already_defeated")
