class_name ExampleBattleRewardApplication
extends GFApplication


func compose() -> void:
	var battle_module := get_node("BattleModule") as ExampleBattleModule
	var score_module := get_node("ScoreModule") as ExampleScoreModule
	var reward_feature := get_node("RewardFeature") as ExampleRewardFeature
	var demo := get_node("Demo") as ExampleBattleRewardDemo

	reward_feature.configure(battle_module, score_module)
	demo.configure(reward_feature)
