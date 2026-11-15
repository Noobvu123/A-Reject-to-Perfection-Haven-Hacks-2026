extends Node2D

var finished := false
var rats: Array[Node2D] = []
var best_chain := 0
@onready var player = $CharacterBody2D

func _ready() -> void:
	for i in range(8):
		var perch = get_node("Perch%d" % i)
		rats.append(preload("res://rat.gd").spawn(self, perch.position+Vector2(48,-14), perch.position.x+44, perch.position.x+52, 12.0))
		rats[i].set_physics_process(i==0)
		rats[i].sprite.modulate=Color.WHITE if i==0 else Color(0.65,0.7,0.75,0.4)

func _physics_process(_delta: float) -> void:
	if finished:return
	player.position.x = clampf(player.position.x,20,1460)
	var count := 0
	for rat in rats:
		if rat.is_dead:count += 1
	best_chain=maxi(best_chain,count)
	if count<rats.size():
		rats[count].set_physics_process(true)
		rats[count].sprite.modulate=Color.WHITE
	$HUD/Progress.value=100.0*count/rats.size()
	$HUD/Status.text="LEVEL 4 | RAT RELAY | Chain: %d / 8 | R: restart" % count
	if count<rats.size():
		var direction="RIGHT" if rats[count].position.x>player.position.x else "LEFT"
		$HUD/Controls.text="NEXT: RAT %d - %s | A/D or arrows: steer | R: restart" % [count+1,direction]
	if player.is_dead:
		$HUD/Status.text="CHAIN BROKEN! Restarting..."
		return
	if player.position.y>720:
		player.die()
	elif player.is_on_floor() and player.position.x<992:
		for i in range(8):
			var perch=get_node("Perch%d"%i)
			if absf(player.position.y+19.4-perch.position.y)<4 and player.position.x>perch.position.x-20 and player.position.x<perch.position.x+116:
				player.die()
	elif player.is_on_floor() and player.position.x>1140 and count==rats.size():
		finished=true
		GameProgress.finish_level(4)
		get_tree().change_scene_to_file.call_deferred("res://city_level.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_R:
		get_tree().reload_current_scene()
