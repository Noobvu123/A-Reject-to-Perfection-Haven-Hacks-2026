extends Node2D

signal defeated

@export var left_limit: float = 0.0
@export var right_limit: float = 0.0
@export var move_speed: float = 65.0
@export var endless_chase: bool = false
@export var is_human: bool = false
var corpse_age: float = 0.0
var direction: float = -1.0
var is_dead: bool = false
var player: CharacterBody2D
var previous_player_bottom: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	player = get_parent().get_node("CharacterBody2D")
	previous_player_bottom = player.global_position.y + 19.4

func _physics_process(delta: float) -> void:
	if is_dead:
		if endless_chase:
			corpse_age += delta
			if corpse_age >= 1.0:
				queue_free()
		return
	if not is_instance_valid(player) or player.is_dead:
		return
	if endless_chase or absf(player.global_position.x - global_position.x) < 240.0:
		var chase_direction := signf(player.global_position.x - global_position.x)
		if chase_direction != 0.0:
			direction = chase_direction
	global_position.x = clampf(global_position.x + direction * move_speed * delta, left_limit, right_limit)
	if global_position.x <= left_limit:
		direction = 1.0
	elif global_position.x >= right_limit:
		direction = -1.0
	sprite.flip_h = direction < 0.0
	var rat_box := Rect2(global_position - Vector2(24, 34), Vector2(48, 48)) if is_human else Rect2(global_position - Vector2(32, 14), Vector2(64, 28))
	var player_box := Rect2(player.global_position - Vector2(19.4, 19.4), Vector2(38.8, 38.8))
	if rat_box.intersects(player_box):
		var stomp := player.velocity.y > 0.0 and previous_player_bottom <= rat_box.position.y + 4.0
		if stomp:
			is_dead = true
			if is_human:
				sprite.scale = Vector2(0.32,0.08)
				sprite.position.y = 7.44
				sprite.modulate.a = 0.55
			else:
				sprite.texture = load("res://Dead_mouse.png")
			player.velocity.y = -360.0
			player.sprite.texture = player.charged_texture
			defeated.emit()
		else:
			player.die()
	previous_player_bottom = player.global_position.y + 19.4

static func spawn(parent: Node2D, spawn_position: Vector2, left: float, right: float, speed: float = 65.0, human: bool = false) -> Node2D:
	var rat = Node2D.new()
	rat.set_script(load("res://rat.gd"))
	rat.position = spawn_position
	rat.left_limit = left
	rat.right_limit = right
	rat.move_speed = speed
	rat.is_human = human
	var image = Sprite2D.new()
	image.name = "Sprite2D"
	image.texture = load("res://assets/team/human_walk.png" if human else "res://Rat.png")
	image.scale = Vector2(0.26, 0.26) if human else Vector2(0.4, 0.4)
	image.position.y = -7.32 if human else -2.0
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rat.add_child(image)
	rat.z_index = 5
	parent.add_child(rat)
	rat.add_to_group("rats")
	return rat
