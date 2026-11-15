extends Node2D
@export_file("*.tscn") var next_level_scene: String = "res://level_3.tscn"
var finished := false
var rats: Array[Node2D] = []
func _ready() -> void:
	for i in range(1, 4):
		var island = get_node("Island%d" % i)
		var x = island.position.x + 128.0
		rats.append(preload("res://rat.gd").spawn(self, Vector2(x, island.position.y - 14.0), x - 68, x + 68))
func _process(_delta: float) -> void:
	if finished:return
	var player = $CharacterBody2D
	if player.is_dead:
		$HUD/Message.text = "CAUGHT BY A RAT! Restarting..."
		return
	var remaining := 0
	for rat in rats:
		if not rat.is_dead:remaining += 1
	$HUD/Message.text = "LEVEL 2 | Jump the gaps | Rats left: %d / 3 | R: restart" % remaining
	$SurfaceRoute.text = "STOMP ALL RATS FIRST" if remaining > 0 else "NEXT LEVEL >"
	if remaining == 0 and player.position.x > 2280 and player.is_on_floor():
		finished = true
		GameProgress.finish_level(2)
		get_tree().change_scene_to_file.call_deferred(next_level_scene)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()
