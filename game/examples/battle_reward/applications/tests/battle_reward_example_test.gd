extends GdUnitTestSuite

const EXAMPLE_SCENE := preload(
	"res://game/examples/battle_reward/applications/battle_reward_example.tscn"
)


func test_battle_reward_example_scene_can_start() -> void:
	var application := auto_free(EXAMPLE_SCENE.instantiate()) as ExampleBattleRewardApplication

	add_child(application)

	assert_object(application).is_instanceof(ExampleBattleRewardApplication)
	assert_bool(application.is_inside_tree()).is_true()
	assert_object(application.reward_feature).is_instanceof(ExampleRewardFeature)
	assert_int(application.reward_feature.get_score_snapshot().total_score).is_equal(100)
	assert_array(application.reward_feature.get_score_snapshot().awards).contains_exactly(100)
