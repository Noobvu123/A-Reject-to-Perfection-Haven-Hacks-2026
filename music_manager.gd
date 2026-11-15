extends Node

const SETTINGS_PATH = "user://audio_settings.cfg"
var muted := false
var music: AudioStreamPlayer
var mute_button: Button
var music_bus: int

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_bus = AudioServer.get_bus_index("Music")
	if music_bus == -1:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus, "Music")
	var settings = ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		muted = settings.get_value("audio", "music_muted", false)
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	music.bus = "Music"
	music.volume_db = -18.0
	var stream = load("res://assets/music/calm_track-loop.ogg") as AudioStreamOggVorbis
	stream.loop = true
	music.stream = stream
	add_child(music)
	var hud = CanvasLayer.new()
	hud.layer = 100
	add_child(hud)
	var corner = Control.new()
	corner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(corner)
	mute_button = Button.new()
	mute_button.name = "MuteMusic"
	corner.add_child(mute_button)
	mute_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mute_button.offset_left = -164
	mute_button.offset_right = -16
	mute_button.offset_top = 14
	mute_button.offset_bottom = 58
	mute_button.add_theme_font_size_override("font_size", 18)
	mute_button.tooltip_text = "Mute or unmute background music (M)"
	mute_button.pressed.connect(toggle_mute)
	# Keep gameplay Space jumps from activating the music button; M is the keyboard shortcut.
	mute_button.focus_mode = Control.FOCUS_NONE
	_apply_mute()
	music.play()

func toggle_mute() -> void:
	muted = not muted
	_apply_mute()
	var settings = ConfigFile.new()
	settings.set_value("audio", "music_muted", muted)
	settings.save(SETTINGS_PATH)

func _apply_mute() -> void:
	AudioServer.set_bus_mute(music_bus, muted)
	mute_button.text = "Music: OFF [M]" if muted else "Music: ON [M]"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		toggle_mute()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(music):
		if music.stream:
			music.stream.loop = false
		music.stop()
		music.stream = null
