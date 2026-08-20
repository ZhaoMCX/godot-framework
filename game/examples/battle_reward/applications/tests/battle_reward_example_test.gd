extends GdUnitTestSuite

const EXAMPLE_SCENE := preload(
	"res://game/examples/battle_reward/applications/battle_reward_example.tscn"
)


func test_battle_reward_example_scene_can_start() -> void:
	var application := auto_free(EXAMPLE_SCENE.instantiate()) as ExampleBattleRewardApplication

	add_child(application)

	var reward_feature := application.get_node("RewardFeature") as ExampleRewardFeature
	assert_object(application).is_instanceof(ExampleBattleRewardApplication)
	assert_bool(application.is_inside_tree()).is_true()
	assert_int(reward_feature.get_score_snapshot().total_score).is_equal(100)
	assert_array(reward_feature.get_score_snapshot().awards).contains_exactly(100)
