extends Node2D
@export var level_number := 3
@export var with_rats := true
@export_file("*.tscn") var next_level_scene := "res://level4.tscn"
var finished := false
var highest_step := 0
var checkpoint := Vector2(96, 530)
var rats: Array[Node2D] = []
@onready var player = $CharacterBody2D
func _ready() -> void:
	if with_rats:
		for i in range(1, 12):
			var ledge = get_node("Step%d" % i)
			var from_x = player.position.x if i==1 else get_node("Step%d"%(i-1)).position.x+120.0
			var rat_x = ledge.position.x + (60.0 if from_x<ledge.position.x+120 else 180.0)
			rats.append(preload("res://rat.gd").spawn(self, Vector2(rat_x,ledge.position.y-14), rat_x-10,rat_x+10,12.0))
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.04,0.08,0.1)
	background.border_color = Color(0.8,0.9,0.9)
	background.set_border_width_all(2)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.65,1.0,0.25)
	$HUD/Charge.add_theme_stylebox_override("background",background)
	$HUD/Charge.add_theme_stylebox_override("fill",fill)
func _physics_process(_delta: float) -> void:
	if finished:return
	player.position.x = clampf(player.position.x,20,1132)
	if player.is_dead:return
	if player.is_on_floor():
		for i in range(1,12):
			var ledge = get_node("Step%d" % i)
			if absf(player.position.y+19.4-ledge.position.y)<5 and player.position.x>ledge.position.x-16 and player.position.x<ledge.position.x+(560 if i==11 else 240)+16:
				highest_step=maxi(highest_step,i)
				if i==5 and (not with_rats or rats[i-1].is_dead):
					checkpoint=ledge.position+Vector2(120,-22)
	# Returning to the cleared halfway ledge preserves defeated rats.
	if checkpoint.y<0 and player.position.y>checkpoint.y+650:
		player.position=checkpoint
		player.velocity=Vector2.ZERO
		player.charge_time=0
		player.is_charging=false
		player.reset_bounce_visuals()
	var remaining:=0
	for rat in rats:
		if not rat.is_dead:remaining+=1
	$HUD/Charge.value=100.0*player.charge_time/player.MAX_CHARGE_TIME
	$HUD/Status.text="LEVEL %d | Ledge %d / 11%s" % [level_number,highest_step," | Rats left: %d"%remaining if with_rats else (" | Checkpoint saved" if checkpoint.y<0 else " | Reach the ladder") ]
	var at_ladder=player.is_on_floor() and absf(player.position.x-$Ladder.position.x)<54 and absf(player.position.y+1019.4)<10
	$LadderHint.text="UP / W: CLIMB TO NEXT LEVEL" if remaining==0 else "STOMP ALL RATS TO OPEN LADDER"
	if at_ladder and remaining==0 and Input.is_action_just_pressed("ui_up"):
		finished=true
		GameProgress.finish_level(3)
		get_tree().change_scene_to_file.call_deferred(next_level_scene)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_R:
		get_tree().reload_current_scene()
