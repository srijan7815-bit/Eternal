extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const FX_FACTORY = preload("res://scripts/fx_factory.gd")
const ROWAN_ATTACK_SHEET = preload("res://assets/effects/rowan_attack.png")

@export var max_health := 10
@export var attack_damage := 1
@export var attack_range_x := 105.0
@export var attack_range_y := 105.0

var health := 10
var facing := 1.0
var attack_wait := 0.0
var hurt_wait := 0.0

@onready var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _ready() -> void:
	health = max_health
	add_to_group("player")
	call_deferred("_update_health_hud")


func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Space jumps; J or left-click attacks.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction = -1.0
	elif Input.is_physical_key_pressed(KEY_D):
		direction = 1.0
	if direction != 0.0:
		velocity.x = direction * SPEED
		facing = signf(direction)
		if sprite != null:
			sprite.flip_h = facing < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	attack_wait = maxf(attack_wait - delta, 0.0)
	hurt_wait = maxf(hurt_wait - delta, 0.0)
	if (
		(Input.is_physical_key_pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		and attack_wait <= 0.0
	):
		attack_wait = 0.38
		_attack()
	move_and_slide()


func _attack() -> void:
	_play_attack_animation()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		# Wide vertical tolerance catches the floating ghosts in this platformer.
		if absf(offset.x) <= attack_range_x and absf(offset.y) <= attack_range_y:
			enemy.take_damage(attack_damage)
	if sprite != null:
		sprite.modulate = Color("#70ddeb")
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.16)


func _play_attack_animation() -> void:
	var effect := AnimatedSprite2D.new()
	effect.name = "RowanSlashFX"
	effect.sprite_frames = FX_FACTORY.make_frames(ROWAN_ATTACK_SHEET, 64, 64, "attack", 22.0, false)
	effect.animation = "attack"
	effect.position = Vector2(facing * 25.0, -27.0)
	effect.scale = Vector2(1.0, 1.0)
	effect.flip_h = facing < 0.0
	effect.z_index = 10
	add_child(effect)
	effect.animation_finished.connect(effect.queue_free)
	effect.play("attack")


func take_damage(amount: int) -> void:
	if hurt_wait > 0.0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	hurt_wait = 0.75
	_update_health_hud()
	if sprite != null:
		sprite.modulate = Color("#ff6b83")
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	if health <= 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		get_tree().call_group("enemies", "set_physics_process", false)
		get_tree().call_group("hud", "show_game_over")


func revive(restore_health: int = 5) -> void:
	if health > 0:
		return
	health = mini(max_health, maxi(restore_health, 1))
	hurt_wait = 1.25
	attack_wait = 0.0
	velocity = Vector2.ZERO
	set_physics_process(true)
	get_tree().call_group("enemies", "set_physics_process", true)
	_update_health_hud()


func heal(amount: int) -> void:
	if health <= 0:
		return
	health = mini(max_health, health + amount)
	_update_health_hud()


func _update_health_hud() -> void:
	get_tree().call_group("hud", "set_health", health, max_health)
