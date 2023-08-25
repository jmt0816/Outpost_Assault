class_name Shooter
extends Node2D

@export var fire_rate := 0.1
@export var rot_speed := 8.0
@export var projectile_type: PackedScene
@export var projectile_speed := 1500
@export var projectile_damage := 3

var targets: Array[Node2D]
var can_shoot := true
var map: Node

@onready var gun := $Gun as AnimatedSprite2D
@onready var muzzle_flash := $MuzzleFlash as AnimatedSprite2D
@onready var shoot_sound := $ShootSound as AudioStreamPlayer2D
@onready var lookahead := $LookAhead as RayCast2D
@onready var firerate_timer := $FireRateTimer as Timer

func _ready() -> void:
	map = find_parent('Map')


func _physics_process(delta: float) -> void:
	if not targets.is_empty():
		var target_pos: Vector2 = targets.front().global_position
		var target_rot: float = global_position.direction_to(target_pos).angle()
		rotation = lerp_angle(rotation, target_rot, rot_speed * delta)
		print(target_rot)
		if can_shoot and lookahead.is_colliding():
			shoot()


func shoot() -> void:
	can_shoot = false
	for _muzzle in gun.get_children():
		_instantiate_projectile(_muzzle.global_position)
	_play_animations("shoot")
	shoot_sound.play()
	firerate_timer.start(fire_rate)
	
	
func die() -> void:
	set_physics_process(false)
	can_shoot = false
	firerate_timer.stop()
	muzzle_flash.hide()
	gun.play("die")


func _instantiate_projectile(_position: Vector2) -> void:
	var projectile: Projectile = projectile_type.instantiate()
	projectile.start(_position,rotation, projectile_speed, projectile_damage)
	projectile.collision_mask = $Detector.collision_mask
	if map:
		map.add_child(projectile)
	else:
		owner.add_child(projectile)


func _play_animations(anim_name: String) -> void:
	gun.frame = 0
	muzzle_flash.frame = 0
	gun.play(anim_name)
	muzzle_flash.play(anim_name)


func _on_detector_body_entered(body: Node2D) -> void:
	if body not in targets:
		targets.append(body)


func _on_detector_body_exited(body: Node2D) -> void:
	if body in targets:
		targets.erase(body)


func _on_detector_area_entered(area: Area2D) -> void:
	if area not in targets:
		targets.append(area)


func _on_detector_area_exited(area: Area2D) -> void:
	if area in targets:
		targets.erase(area)


func _on_fire_rate_timer_timeout() -> void:
	can_shoot = true


func _on_gun_animation_finished() -> void:
	if gun.animation.contains("shoot"):
		_play_animations("idle")
