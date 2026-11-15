extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
var charged_texture = preload("res://Slime_jump.png")
@onready var normal_texture = sprite.texture
@onready var normal_scale: Vector2 = sprite.scale
@onready var normal_sprite_position: Vector2 = sprite.position
@onready var takeoff_y: float = global_position.y
@onready var apex_y: float = global_position.y
@onready var last_position: Vector2 = global_position
var in_air := false
var recoil_time := 0.0
var recoil_strength := 0.0
var last_vertical_velocity := 0.0
const RECOIL_DURATION := 0.38
const MAX_STRETCH := 0.5

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_CHARGE_TIME = 0.75
const MIN_CHARGED_JUMP_SPEED = 250.0
const MAX_CHARGED_JUMP_SPEED = 650.0

@export var jump_power_multiplier: float = 1.0
@export var always_full_charge: bool = false
@export var rat_bounce_only: bool = false

var charge_time: float = 0.0
var is_charging: bool = false
var is_dead: bool = false
var crown: Sprite2D


func _ready() -> void:
	crown=preload("res://crown_accessory.gd").new()
	sprite.add_child(crown)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# A checkpoint teleport starts a fresh visual arc.
	if global_position.distance_to(last_position) > 200.0:
		reset_bounce_visuals()
	var before_move_y := global_position.y
	# Falling into the water returns to the starting ledge.
	if global_position.y > 820.0:
		global_position = Vector2(96, 530)
		velocity = Vector2.ZERO
		charge_time = 0.0
		is_charging = false
		sprite.scale = normal_scale
		sprite.texture = normal_texture
		reset_bounce_visuals()
		before_move_y = global_position.y

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Hold Down on the ground to charge, then release to bounce.
	if is_on_floor():
		if rat_bounce_only:
			is_charging = false
			charge_time = 0.0
		elif Input.is_action_pressed("ui_down"):
			is_charging = true
			charge_time = MAX_CHARGE_TIME if always_full_charge else minf(charge_time + delta, MAX_CHARGE_TIME)
			recoil_time = 0.0
		elif is_charging:
			var charge_ratio := charge_time / MAX_CHARGE_TIME
			velocity.y = -lerpf(MIN_CHARGED_JUMP_SPEED, MAX_CHARGED_JUMP_SPEED, charge_ratio) * jump_power_multiplier
			sprite.texture = charged_texture
			is_charging = false
			charge_time = 0.0
			sprite.scale = normal_scale
		elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("game_jump"):
			velocity.y = -MAX_CHARGED_JUMP_SPEED * jump_power_multiplier if always_full_charge else JUMP_VELOCITY * jump_power_multiplier
			sprite.texture = charged_texture
	else:
		# Walking off a ledge cancels a ground charge.
		is_charging = false
		charge_time = 0.0
		sprite.scale = normal_scale

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Rat stomps can launch a new arc without touching the floor.
	if in_air and velocity.y < 0.0 and last_vertical_velocity > 0.0:
		takeoff_y = before_move_y
		apex_y = before_move_y
	move_and_slide()
	_update_bounce_visuals(delta, before_move_y)
	last_position = global_position
	last_vertical_velocity = velocity.y

	# Check floor contact after movement so the jump texture lasts until landing.
	if is_on_floor():
		sprite.texture = normal_texture

func reset_bounce_visuals() -> void:
	in_air = false
	takeoff_y = global_position.y
	apex_y = global_position.y
	last_position = global_position
	last_vertical_velocity = 0.0
	recoil_time = 0.0
	recoil_strength = 0.0
	sprite.scale = normal_scale
	sprite.position = normal_sprite_position

func _update_bounce_visuals(delta: float, before_move_y: float) -> void:
	var shape := Vector2.ONE
	var hop := 0.0
	if not is_on_floor():
		if not in_air:
			in_air = true
			takeoff_y = before_move_y
			apex_y = before_move_y
		apex_y = minf(apex_y, global_position.y)
		recoil_time = 0.0
		var height := maxf(takeoff_y - global_position.y, 0.0)
		var stretch := 1.0 + MAX_STRETCH * clampf(height / 220.0, 0.0, 1.0)
		shape = Vector2(1.0 / sqrt(stretch), stretch)
	else:
		if in_air:
			var fall_distance := maxf(global_position.y - apex_y, 0.0)
			recoil_strength = clampf(fall_distance / 500.0, 0.0, 1.0)
			recoil_time = RECOIL_DURATION
			in_air = false
		if is_charging:
			var charge_ratio := charge_time / MAX_CHARGE_TIME
			shape = Vector2(1.0 + 0.15 * charge_ratio, 1.0 - 0.25 * charge_ratio)
		elif recoil_time > 0.0:
			var elapsed := RECOIL_DURATION - recoil_time
			var power := 0.08 + 0.38 * recoil_strength
			if elapsed < 0.09:
				var squash := power * (1.0 - elapsed / 0.09)
				shape = Vector2(1.0 + squash * 0.7, 1.0 - squash)
			else:
				var phase := clampf((elapsed - 0.09) / (RECOIL_DURATION - 0.09), 0.0, 1.0)
				var rebound := sin(phase * PI) * (1.0 - phase)
				shape = Vector2(1.0 - rebound * power * 0.3, 1.0 + rebound * power * 0.5)
				hop = rebound * (2.0 + 10.0 * recoil_strength)
			recoil_time = maxf(recoil_time - delta, 0.0)
	sprite.scale = normal_scale * shape
	# Keep the feet anchored during squash; the small rebound only moves the art.
	sprite.position = normal_sprite_position + Vector2(0, 19.4 * (1.0 - shape.y) - hop)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	crown.set_allowed(false)
	reset_bounce_visuals()
	velocity = Vector2.ZERO
	is_charging = false
	charge_time = 0.0
	sprite.scale = normal_scale
	sprite.texture = load("res://Slime_die.png")
	await get_tree().create_timer(0.65).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()
