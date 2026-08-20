class_name ExampleBattleRewardApplication
extends GFApplication

@export var battle_module: ExampleBattleModule
@export var score_module: ExampleScoreModule
@export var reward_feature: ExampleRewardFeature
@export var demo: ExampleBattleRewardDemo


func compose() -> void:
	assert(battle_module != null, "BattleModule 必须由场景显式绑定。")
	assert(score_module != null, "ScoreModule 必须由场景显式绑定。")
	assert(reward_feature != null, "RewardFeature 必须由场景显式绑定。")
	assert(demo != null, "Demo 必须由场景显式绑定。")

	reward_feature.configure(battle_module, score_module)
	demo.configure(reward_feature)
