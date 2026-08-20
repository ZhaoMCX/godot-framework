class_name ExampleBattleRewardDemo
extends Node

var _reward_feature: ExampleRewardFeature


func configure(reward_feature: ExampleRewardFeature) -> void:
	_reward_feature = reward_feature
	_reward_feature.defeat_completed.connect(_on_defeat_completed)
	_reward_feature.score_changed.connect(_on_score_changed)


func _ready() -> void:
	var first_submission := _reward_feature.defeat_enemy(&"slime_01", 100)
	print("[BattleReward] first_submission.accepted=%s" % first_submission.accepted)

	var duplicate_submission := _reward_feature.defeat_enemy(&"slime_01", 100)
	print("[BattleReward] duplicate_submission.accepted=%s" % duplicate_submission.accepted)

	var invalid_submission := _reward_feature.defeat_enemy(&"slime_02", 100, "invalid-id")
	print("[BattleReward] invalid_submission.accepted=%s" % invalid_submission.accepted)

	var snapshot := _reward_feature.get_score_snapshot()
	var external_awards := snapshot.awards
	external_awards.append(999)
	var current_snapshot := _reward_feature.get_score_snapshot()
	var snapshot_isolated := current_snapshot.awards == [100]
	print(
		"[BattleReward] score=%d awards=%s snapshot_isolated=%s"
		% [current_snapshot.total_score, current_snapshot.awards, snapshot_isolated]
	)


func _on_defeat_completed(event: GFCommandCompletedEvent) -> void:
	print(
		"[BattleReward] defeat_completed succeeded=%s error=%s"
		% [event.succeeded, event.error_code]
	)


func _on_score_changed(event: ExampleScoreChangedEvent) -> void:
	print(
		"[BattleReward] score_changed total=%d awarded=%d"
		% [event.total_score, event.awarded_points]
	)
