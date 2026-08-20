class_name ExampleRewardFeature
extends GFFeature

signal defeat_completed(event: GFCommandCompletedEvent)
signal score_changed(event: ExampleScoreChangedEvent)

var _battle_module: ExampleBattleModule
var _score_module: ExampleScoreModule


func configure(battle_module: ExampleBattleModule, score_module: ExampleScoreModule) -> void:
	_disconnect_dependencies()
	_battle_module = battle_module
	_score_module = score_module
	_battle_module.enemy_defeated.connect(_on_enemy_defeated)
	_battle_module.command_completed.connect(_on_defeat_completed)
	_score_module.score_changed.connect(_on_score_changed)


func defeat_enemy(
		enemy_id: StringName,
		reward_points: int,
		command_id: String = "",
) -> GFSubmitResult:
	return _battle_module.submit_defeat_enemy(
		ExampleDefeatEnemyCommand.new(enemy_id, reward_points, command_id)
	)


func get_score_snapshot() -> ExampleScoreSnapshot:
	return _score_module.get_snapshot()


func _exit_tree() -> void:
	_disconnect_dependencies()


func _disconnect_dependencies() -> void:
	if _battle_module != null:
		if _battle_module.enemy_defeated.is_connected(_on_enemy_defeated):
			_battle_module.enemy_defeated.disconnect(_on_enemy_defeated)
		if _battle_module.command_completed.is_connected(_on_defeat_completed):
			_battle_module.command_completed.disconnect(_on_defeat_completed)
	if _score_module != null and _score_module.score_changed.is_connected(_on_score_changed):
		_score_module.score_changed.disconnect(_on_score_changed)


func _on_enemy_defeated(event: ExampleEnemyDefeatedEvent) -> void:
	_score_module.submit_add_score(
		ExampleAddScoreCommand.new(event.reward_points, event.event_id)
	)


func _on_defeat_completed(event: GFCommandCompletedEvent) -> void:
	defeat_completed.emit(event)


func _on_score_changed(event: ExampleScoreChangedEvent) -> void:
	score_changed.emit(event)
