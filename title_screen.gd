extends Control

var starting := false
@onready var play_button: Button = %Button
var reset_dialog: ConfirmationDialog

func _ready() -> void:
	play_button.pressed.connect(_start_game)
	play_button.grab_focus()
	%LevelsButton.pressed.connect(GameProgress.show_levels)
	%Slime.add_child(preload("res://crown_accessory.gd").new())
	%ResetProgress.pressed.connect(_ask_reset)
	%ResetProgress.add_theme_color_override("font_color",Color(1,0.72,0.67))
	%ResetProgress.add_theme_stylebox_override("normal",GameProgress._style(Color(0.18,0.08,0.09),Color(0.65,0.3,0.27)))
	%ResetProgress.add_theme_stylebox_override("focus",GameProgress._style(Color(0,0,0,0),Color(1,0.85,0.4),3))
	reset_dialog=ConfirmationDialog.new()
	reset_dialog.title="Reset all progress?"
	reset_dialog.dialog_text="This clears all stars, best times, level unlocks and the crown.\nMusic settings will stay the same."
	reset_dialog.ok_button_text="RESET PROGRESS"
	reset_dialog.cancel_button_text="CANCEL"
	reset_dialog.exclusive=true
	reset_dialog.confirmed.connect(GameProgress.reset_progress)
	add_child(reset_dialog)

func _start_game() -> void:
	if starting:return
	starting = true
	play_button.disabled = true
	call_deferred("_open_level")

func _open_level() -> void:
	var error = get_tree().change_scene_to_file("res://renameit.tscn")
	if error != OK:
		starting = false
		play_button.disabled = false
		%Hint.text = "Could not open Level 1. Please try Play again."

func _ask_reset() -> void:
	reset_dialog.popup_centered(Vector2i(580,230))
	reset_dialog.get_cancel_button().grab_focus()
