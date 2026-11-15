extends Area2D
var entered: bool = false
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
	if entered or not body is CharacterBody2D:
		return
	entered = true
	GameProgress.finish_level(1)
	get_tree().change_scene_to_file.call_deferred("res://rat_level.tscn")
