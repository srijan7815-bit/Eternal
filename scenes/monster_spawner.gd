extends Node2D

@export var monster_scene: PackedScene = preload("res://scenes/monster.tscn")
@export var player_path: NodePath = NodePath("../player")
@export var spawn_gap := 0.65
@export var break_between_waves := 2.5

const WAVE_COUNTS := [3, 5, 7, 9, 11]
const WAVE_SPEEDS := [58.0, 72.0, 86.0, 100.0, 114.0]
const WAVE_HEALTH := [1, 2, 2, 3, 4]
const WAVE_DAMAGE := [1, 1, 2, 2, 3]
const WAVE_COOLDOWNS := [1.25, 1.1, 0.95, 0.85, 0.75]

var player: CharacterBody2D
var game_root: Node
var alive_in_wave := 0
var current_wave := 0


func _ready() -> void:
	call_deferred("_run_campaign")


func _run_campaign() -> void:
	game_root = get_parent()
	player = get_node_or_null(player_path) as CharacterBody2D
	if player == null:
		push_error("MonsterSpawner: player not found. Expected a sibling node named 'player'.")
		return
	if monster_scene == null:
		push_error("MonsterSpawner: monster_scene is empty; assign res://scenes/monster.tscn.")
		return

	var total_waves := WAVE_COUNTS.size()
	for wave_index in range(total_waves):
		if not await _wait_for_player_revive():
			return
		current_wave = wave_index + 1
		var wave_count: int = WAVE_COUNTS[wave_index]
		alive_in_wave = 0
		get_tree().call_group("hud", "show_wave", current_wave, total_waves, wave_count)
		get_tree().call_group("hud", "set_total", wave_count)

		for i in range(wave_count):
			if not await _wait_for_player_revive():
				return
			var monster := monster_scene.instantiate() as CharacterBody2D
			if monster == null:
				push_error("MonsterSpawner: monster scene root must be CharacterBody2D.")
				return
			monster.call(
				"configure",
				player,
				WAVE_SPEEDS[wave_index],
				WAVE_HEALTH[wave_index],
				WAVE_DAMAGE[wave_index],
				WAVE_COOLDOWNS[wave_index],
				current_wave
			)
			monster.connect("defeated", Callable(self, "_on_monster_defeated"))
			game_root.add_child(monster)
			var x_offset := 175.0 + float(i % 4) * 42.0
			var y_offset := float((i % 3) - 1) * 28.0
			monster.global_position = player.global_position + Vector2(x_offset, y_offset)
			alive_in_wave += 1
			await get_tree().create_timer(spawn_gap).timeout

		while alive_in_wave > 0:
			if not await _wait_for_player_revive():
				return
			await get_tree().create_timer(0.2).timeout
		if not await _wait_for_player_revive():
			return

		if wave_index < total_waves - 1:
			get_tree().call_group("hud", "show_intermission", current_wave)
			if player.has_method("heal"):
				player.heal(2)
			await get_tree().create_timer(break_between_waves).timeout

	get_tree().call_group("hud", "show_victory")


func _on_monster_defeated() -> void:
	alive_in_wave = maxi(alive_in_wave - 1, 0)


func _wait_for_player_revive() -> bool:
	if not is_instance_valid(player):
		return false
	while int(player.get("health")) <= 0:
		await get_tree().create_timer(0.2).timeout
		if not is_instance_valid(player):
			return false
	return true
