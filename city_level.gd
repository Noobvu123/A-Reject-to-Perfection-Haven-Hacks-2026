extends Node2D
var finished:=false
var humans: Array[Node2D] = []
var checkpoint:=Vector2(96,530)
@onready var player=$CharacterBody2D
@onready var menu_button: Button = $HUD/ReturnToMenu
func _ready() -> void:
	menu_button.pressed.connect(_return_to_menu)
	for i in range(1,6):
		var roof=get_node("Roof%d"%i)
		humans.append(preload("res://rat.gd").spawn(self,roof.position+Vector2(192,-14),roof.position.x+166,roof.position.x+218,18.0,true))
		humans[-1].defeated.connect(_on_human_defeated)
func _physics_process(_delta:float)->void:
	if finished:return
	player.position.x=clampf(player.position.x,20,3180)
	$HUD/Charge.value=100
	if player.is_on_floor() and player.position.x>1040 and player.position.x<1384 and absf(player.position.y+19.4)<5 and humans[1].is_dead:
		checkpoint=Vector2(1180,-22)
	if player.position.y>checkpoint.y+650:
		player.position=checkpoint
		player.velocity=Vector2.ZERO
		player.reset_bounce_visuals()
	var remaining:=0
	for human in humans:
		if not human.is_dead:remaining+=1
	$HUD/Status.text="FINAL LEVEL | HUMANS LEFT: %d / 5"%remaining
	$Goal.text="DEFEAT EVERY HUMAN\n%d REMAIN"%remaining if remaining>0 else "THE LAST ROOF\nCLAIM PERFECTION"
	if player.is_dead:return
	if remaining==0:
		_win_level()

func _on_human_defeated() -> void:
	for human in humans:
		if not human.is_dead:return
	_win_level()

func _win_level() -> void:
	if finished or player.is_dead:return
	finished=true
	GameProgress.finish_level(5)
	player.velocity=Vector2.ZERO
	player.reset_bounce_visuals()
	player.set_physics_process(false)
	$HUD/Status.text="YOU WON THE WAR. YOU BECAME PERFECTION."
	menu_button.show()
	StoryDirector.play_ending()

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_R:
		get_tree().reload_current_scene()

func _return_to_menu() -> void:
	if not finished:return
	menu_button.disabled = true
	get_tree().change_scene_to_file.call_deferred("res://title_screen.tscn")
