extends CharacterBody2D

signal defeated

const FX_FACTORY = preload("res://scripts/fx_factory.gd")
const GHOST_ATTACK_SHEET = preload("res://assets/effects/ghost_attack.png")

@export var move_speed := 65.0
@export var max_health := 1
@export var contact_damage := 1
@export var contact_range := 42.0
@export var contact_cooldown := 1.15

var target: Node2D
var hp := 1
var contact_wait := 0.7
var wave_number := 1
var wave_tint := Color.WHITE

@onready var animated_sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func configure(
	target_node: Node2D, speed: float, health: int, damage: int, cooldown: float, wave: int
) -> void:
	target = target_node
	move_speed = speed
	max_health = health
	hp = health
	contact_damage = damage
	contact_cooldown = cooldown
	wave_number = wave


func _ready() -> void:
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Ghost attacks are proximity-based; don't let body collision push Rowan.
	collision_layer = 0
	collision_mask = 0
	hp = max_health
	_set_animation()
	_set_wave_tint()


func _set_animation() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = animated_sprite.sprite_frames
	var names := frames.get_animation_names()
	if names.is_empty():
		return
	var animation_name := "float" if frames.has_animation("float") else String(names[0])
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, 8.0)
	animated_sprite.play(animation_name)


func _set_wave_tint() -> void:
	match wave_number:
		1:
			wave_tint = Color.WHITE
		2:
			wave_tint = Color("#c7aaff")
		3:
			wave_tint = Color("#ff9db5")
	if animated_sprite != null:
		animated_sprite.modulate = wave_tint


func _physics_process(delta: float) -> void:
	contact_wait = maxf(contact_wait - delta, 0.0)
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var offset: Vector2 = target.global_position - global_position
	var distance := offset.length()
	if distance > contact_range:
		velocity = offset.normalized() * move_speed
		if animated_sprite != null and absf(offset.x) > 1.0:
			# The source ghost faces left by default; invert for correct chase facing.
			animated_sprite.flip_h = offset.x > 0.0
	else:
		velocity = Vector2.ZERO
		if contact_wait <= 0.0 and target.has_method("take_damage"):
			_play_attack_animation()
			target.take_damage(contact_damage)
			contact_wait = contact_cooldown
	move_and_slide()


func _play_attack_animation() -> void:
	var effect := AnimatedSprite2D.new()
	effect.name = "GhostAttackFX"
	effect.sprite_frames = FX_FACTORY.make_frames(GHOST_ATTACK_SHEET, 48, 48, "attack", 18.0, false)
	effect.animation = "attack"
	effect.z_index = 12
	var scene := get_tree().current_scene
	scene.add_child(effect)
	effect.global_position = (global_position + target.global_position) * 0.5
	effect.animation_finished.connect(effect.queue_free)
	effect.play("attack")


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if animated_sprite != null:
		animated_sprite.modulate = Color.WHITE
		var tween := create_tween()
		tween.tween_property(animated_sprite, "modulate", Color("#ff6b83"), 0.05)
		tween.tween_property(animated_sprite, "modulate", wave_tint, 0.12)
	if hp <= 0:
		defeated.emit()
		get_tree().call_group("hud", "add_kill")
		queue_free()
