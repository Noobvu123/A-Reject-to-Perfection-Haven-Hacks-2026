extends Node

var active := false
var ending := false
var skip_next_intro := false
var page := 0
var scene_instance := 0
var overlay: Control
var title: Label
var body: Label
var picture: TextureRect
var crown: Sprite2D
var next_button: Button
var skip_button: Button
var fade: Tween
const INTRO = [
	["REJECTED", "\"You have been rejected, slime.\"\nThe humans threw you into the sewer."],
	["THROWN AWAY", "Alone in the dark, you were meant to disappear.\nBut a slime can always bounce back."],
	["BOUNCE BACK", "Now you will bounce back\nand kill the humans who rejected you."]
]

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	_build_ui()

func play_intro() -> void:
	if skip_next_intro:
		skip_next_intro=false
		return
	if active:return
	ending=false
	page=0
	_begin()
	_show_page()

func play_ending() -> void:
	ending=true
	_begin()
	title.text="YOU WIN!"
	body.text="You have won the war.\nYou have become perfection."
	picture.texture=load("res://Slime_still.png")
	crown.set_allowed(true)
	next_button.text="RETURN TO MENU"
	skip_button.hide()
	next_button.grab_focus()

func _begin() -> void:
	active=true
	scene_instance=get_tree().current_scene.get_instance_id()
	get_tree().paused=true
	overlay.show()

func _show_page() -> void:
	title.text=INTRO[page][0]
	body.text=INTRO[page][1]
	picture.texture=load("res://assets/team/human_walk.png" if page==0 else "res://Slime_still.png")
	crown.set_allowed(page>0)
	next_button.text="START LEVEL 1" if page==2 else "CONTINUE"
	skip_button.show()
	if fade and fade.is_running():fade.kill()
	picture.modulate.a=0.0
	fade=create_tween()
	fade.tween_property(picture,"modulate:a",1.0,0.25)
	next_button.grab_focus()

func _next() -> void:
	if ending:
		cancel()
		GameProgress._change_scene("res://title_screen.tscn")
	elif page<2:
		page+=1
		_show_page()
	else:
		skip_intro()

func skip_intro() -> void:
	if ending:
		_next()
		return
	cancel()
	# The story does not count toward a speed-run result.
	GameProgress.elapsed=0.0

func cancel() -> void:
	if not active:return
	active=false
	overlay.hide()
	get_tree().paused=false
	get_viewport().gui_release_focus()

func _process(_delta:float) -> void:
	if active:
		var scene=get_tree().current_scene
		if not is_instance_valid(scene) or scene.get_instance_id()!=scene_instance:cancel()

func _input(event:InputEvent) -> void:
	if not active:return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		skip_intro()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var layer=CanvasLayer.new()
	layer.layer=300
	add_child(layer)
	overlay=Control.new()
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop=ColorRect.new()
	backdrop.color=Color(0.015,0.05,0.06,0.99)
	overlay.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center=CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content=VBoxContainer.new()
	content.custom_minimum_size=Vector2(780,0)
	content.add_theme_constant_override("separation",24)
	center.add_child(content)
	title=GameProgress._label("",44)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color",Color(0.73,1,0.42))
	content.add_child(title)
	picture=TextureRect.new()
	picture.custom_minimum_size=Vector2(0,150)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	crown=preload("res://crown_accessory.gd").new()
	picture.add_child(crown)
	body=GameProgress._label("",25)
	body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(body)
	next_button=GameProgress._button("CONTINUE")
	next_button.pressed.connect(_next)
	content.add_child(next_button)
	skip_button=GameProgress._button("SKIP INTRO [Esc]")
	skip_button.pressed.connect(skip_intro)
	content.add_child(skip_button)
	overlay.hide()
