extends Node

signal progress_changed

const LEVELS = [
	{"id":1,"name":"THE SEWER","scene":"res://renameit.tscn","three":9.0,"two":20.0},
	{"id":2,"name":"RAT ISLANDS","scene":"res://rat_level.tscn","three":11.0,"two":20.0},
	{"id":3,"name":"THE WIDE SHAFT","scene":"res://level_3.tscn","three":30.0,"two":40.0},
	{"id":4,"name":"RAT RELAY","scene":"res://level4.tscn","three":6.2,"two":10.0},
	{"id":5,"name":"THE CITY","scene":"res://city_level.tscn","three":11.55,"two":15.0}
]
const ALIASES = {"res://rat_run.tscn":2,"res://rat_level_base.tscn":2,"res://next_level.tscn":3,"res://city_finale.tscn":5}
var save_path := "user://level_progress.cfg"
var records: Dictionary = {}
var current_level := 0
var elapsed := 0.0
var run_finished := false
var current_instance := 0
var last_result: Dictionary = {}
var overlay: Control
var panel: PanelContainer
var rows: VBoxContainer
var resume_button: Button
var main_button: Button
var restart_button: Button
var pause_restart: Button
var heading: Label
var clock: Label
var toast: Label
var toast_left := 0.0
var previous_focus: WeakRef

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_progress()
	_build_ui()

func _load_progress() -> void:
	records.clear()
	var config = ConfigFile.new()
	if config.load(save_path) != OK:
		progress_changed.emit()
		return
	for level in LEVELS:
		var section = str(level.id)
		var stars = config.get_value(section,"stars",0)
		var best = config.get_value(section,"best",-1.0)
		if (stars is int or stars is float) and (best is int or best is float):
			if stars >= 1 and stars <= 3 and best >= 0 and is_finite(float(best)):
				records[level.id] = {"stars":int(stars),"best":float(best)}

	progress_changed.emit()

func _save_progress() -> void:
	var config = ConfigFile.new()
	config.set_value("save","version",1)
	for id in records:
		config.set_value(str(id),"stars",records[id].stars)
		config.set_value(str(id),"best",records[id].best)
	var error = config.save(save_path)
	if error != OK:
		toast.text="Could not save progress. Your results are kept for this session."
		toast_left=6.0

func level_from_scene(path: String) -> int:
	for level in LEVELS:
		if level.scene == path:return level.id
	return int(ALIASES.get(path,0))

func _sync_scene() -> void:
	var scene = get_tree().current_scene
	var instance = scene.get_instance_id() if is_instance_valid(scene) else 0
	if instance == current_instance:return
	current_instance=instance
	current_level=level_from_scene(scene.scene_file_path) if is_instance_valid(scene) else 0
	elapsed=0.0
	run_finished=false
	if overlay.visible:
		overlay.hide()
		get_tree().paused=false
	clock.visible=current_level>0
	restart_button.visible=current_level==1
	if current_level==1:
		StoryDirector.play_intro.call_deferred()

func _physics_process(delta: float) -> void:
	_sync_scene()
	if current_level>0 and not run_finished and not get_tree().paused:
		elapsed+=delta

func _process(delta: float) -> void:
	_sync_scene()
	if current_level>0:
		var second_line="RESULT: "+star_text(int(last_result.get("stars",0))) if run_finished else "3 STARS: "+format_time(LEVELS[current_level-1].three)
		clock.text="TIME "+format_time(elapsed)+"\n"+second_line+" | Esc: menu"
	if toast_left>0:
		toast_left=maxf(0,toast_left-delta)
	toast.visible=toast_left>0 and not overlay.visible

func stars_for(id: int, seconds: float) -> int:
	if id<1 or id>LEVELS.size():return 0
	var limits=LEVELS[id-1]
	if seconds<=limits.three+0.000001:return 3
	if seconds<=limits.two+0.000001:return 2
	return 1

func finish_level(id: int) -> void:
	_sync_scene()
	if id!=current_level or run_finished:return
	run_finished=true
	var stars=stars_for(id,elapsed)
	var old:Dictionary=records.get(id,{"stars":0,"best":INF})
	records[id]={"stars":maxi(stars,int(old.stars)),"best":minf(elapsed,float(old.best))}
	last_result={"id":id,"time":elapsed,"stars":stars}
	toast.text="LEVEL %d COMPLETE  %s  %s" % [id,star_text(stars),format_time(elapsed)]
	toast_left=4.5
	_save_progress()
	progress_changed.emit()

func can_replay(id: int) -> bool:
	return id>=1 and id<=LEVELS.size() and (id==1 or records.has(id) or records.has(id-1))

func format_time(seconds: float) -> String:
	var total=maxi(0,roundi(seconds*100.0))
	return "%02d:%02d.%02d" % [floori(total/6000.0),floori(total/100.0)%60,total%100]

func star_text(count: int) -> String:
	return "★".repeat(clampi(count,0,3))+"☆".repeat(3-clampi(count,0,3))

func restart_level() -> void:
	if current_level<1:return
	overlay.hide()
	get_tree().paused=false
	StoryDirector.skip_next_intro=true
	get_tree().reload_current_scene.call_deferred()

func _input(event: InputEvent) -> void:
	if StoryDirector.active:return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_R and current_level==1 and not get_tree().paused:
		restart_level()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		if overlay.visible:
			close_menu()
		elif current_level>0:
			show_levels()
		else:return
		get_viewport().set_input_as_handled()

func show_levels() -> void:
	_sync_scene()
	var focused=get_viewport().gui_get_focus_owner()
	previous_focus=weakref(focused) if focused else null
	get_tree().paused=true
	heading.text="PAUSED · LEVELS" if current_level>0 else "LEVELS"
	resume_button.text="RESUME LEVEL" if current_level>0 else "BACK"
	main_button.visible=current_level>0
	pause_restart.visible=current_level==1
	_refresh_rows()
	overlay.show()
	resume_button.grab_focus()

func close_menu() -> void:
	overlay.hide()
	# Leave a frame for the UI activation key to clear before gameplay resumes.
	await get_tree().process_frame
	get_tree().paused=false
	if previous_focus and is_instance_valid(previous_focus.get_ref()):
		previous_focus.get_ref().grab_focus()
	else:get_viewport().gui_release_focus()

func _change_scene(path: String) -> void:
	overlay.hide()
	get_tree().paused=false
	get_tree().change_scene_to_file.call_deferred(path)

func _replay(id: int) -> void:
	if not can_replay(id):return
	_change_scene(LEVELS[id-1].scene)

func _refresh_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for level in LEVELS:
		var record:Dictionary=records.get(level.id,{})
		var unlocked=can_replay(level.id)
		var status="Best: "+format_time(record.best) if not record.is_empty() else ("Unlocked · ready to play" if unlocked else "Locked · finish the previous level")
		var text="%d. %s   %s   %s\n3★ ≤ %ss   ·   2★ ≤ %ss   ·   1★: finish" % [level.id,level.name,star_text(int(record.get("stars",0))),status,str(level.three),str(level.two)]
		var button=_button(text)
		button.name="Level%d"%level.id
		button.custom_minimum_size.y=78
		button.disabled=not unlocked
		button.add_theme_font_size_override("font_size",16)
		button.pressed.connect(_replay.bind(level.id))
		rows.add_child(button)

func _label(text: String, size: int) -> Label:
	var label=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color(0.92,0.97,0.95))
	return label

func _style(color: Color, border: Color, width: int=2) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(width)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=9
	style.content_margin_bottom=9
	return style

func _button(text: String) -> Button:
	var button=Button.new()
	button.text=text
	button.custom_minimum_size.y=46
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_stylebox_override("normal",_style(Color(0.09,0.18,0.19),Color(0.35,0.55,0.45)))
	button.add_theme_stylebox_override("hover",_style(Color(0.15,0.3,0.25),Color(0.7,0.95,0.4)))
	button.add_theme_stylebox_override("pressed",_style(Color(0.2,0.4,0.3),Color(0.7,0.95,0.4)))
	button.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),Color(1,0.85,0.4),3))
	button.add_theme_stylebox_override("disabled",_style(Color(0.08,0.12,0.14),Color(0.22,0.3,0.31)))
	button.add_theme_color_override("font_disabled_color",Color(0.62,0.7,0.71))
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	return button

func _build_ui() -> void:
	var layer=CanvasLayer.new()
	layer.layer=200
	add_child(layer)
	var ui=Control.new()
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	clock=_label("",15)
	ui.add_child(clock)
	clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock.offset_left=-390
	clock.offset_right=-174
	clock.offset_top=12
	clock.offset_bottom=64
	clock.add_theme_color_override("font_shadow_color",Color.BLACK)
	clock.add_theme_constant_override("shadow_offset_x",2)
	clock.add_theme_constant_override("shadow_offset_y",2)
	clock.mouse_filter=Control.MOUSE_FILTER_IGNORE
	clock.hide()
	restart_button=_button("RESTART LEVEL 1 [R]")
	restart_button.focus_mode=Control.FOCUS_NONE
	ui.add_child(restart_button)
	restart_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	restart_button.offset_left=-230
	restart_button.offset_right=-16
	restart_button.offset_top=-72
	restart_button.offset_bottom=-24
	restart_button.pressed.connect(restart_level)
	restart_button.hide()
	toast=_label("",20)
	ui.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_left=-400
	toast.offset_right=400
	toast.offset_top=84
	toast.offset_bottom=116
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color",Color(0.8,1,0.4))
	toast.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast.add_theme_constant_override("shadow_offset_y",2)
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast.hide()
	overlay=Control.new()
	overlay.name="PauseAndLevels"
	ui.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim=ColorRect.new()
	dim.color=Color(0.01,0.04,0.05,0.94)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center=CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel=PanelContainer.new()
	panel.custom_minimum_size=Vector2(850,0)
	panel.add_theme_stylebox_override("panel",_style(Color(0.035,0.085,0.1),Color(0.4,0.6,0.45)))
	center.add_child(panel)
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	panel.add_child(content)
	heading=_label("LEVELS",28)
	content.add_child(heading)
	var controls=HBoxContainer.new()
	controls.add_theme_constant_override("separation",12)
	content.add_child(controls)
	resume_button=_button("RESUME LEVEL")
	resume_button.pressed.connect(close_menu)
	controls.add_child(resume_button)
	main_button=_button("MAIN MENU")
	main_button.pressed.connect(_change_scene.bind("res://title_screen.tscn"))
	controls.add_child(main_button)
	pause_restart=_button("RESTART LEVEL 1")
	pause_restart.pressed.connect(restart_level)
	controls.add_child(pause_restart)
	content.add_child(_label("Finish a level to unlock the next. Replay your best runs.",16))
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(820,426)
	scroll.follow_focus=true
	content.add_child(scroll)
	rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	content.add_child(_label("Pause stops the clock. Your best time and stars stay saved.",15))
	overlay.hide()

func has_crown() -> bool:
	return records.has(5)

func reset_progress() -> bool:
	# Write the empty save first so a failed disk write never silently clears memory.
	var clean=ConfigFile.new()
	clean.set_value("save","version",1)
	if clean.save(save_path)!=OK:
		toast.text="Could not reset progress. Your saved results are unchanged."
		toast_left=6.0
		return false
	records.clear()
	last_result.clear()
	StoryDirector.skip_next_intro=false
	toast.text="Progress reset. Stars, unlocks and crown cleared."
	toast_left=4.5
	progress_changed.emit()
	if overlay.visible:_refresh_rows()
	return true
