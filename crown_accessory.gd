extends Sprite2D

var allowed := true

func _ready() -> void:
	name="Crown"
	var atlas=AtlasTexture.new()
	atlas.atlas=preload("res://Crown.png")
	atlas.region=Rect2(48,32,176,160)
	texture=atlas
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	z_index=10
	if get_parent() is TextureRect:
		get_parent().resized.connect(_position_crown)
	_position_crown()
	GameProgress.progress_changed.connect(_refresh)
	_refresh()

func set_allowed(value: bool) -> void:
	allowed=value
	_refresh()

func _refresh() -> void:
	visible=allowed and GameProgress.has_crown()
	_position_crown()

func _position_crown() -> void:
	var host=get_parent()
	if host is TextureRect:
		if host.texture==null:return
		var factor=minf(host.size.x/host.texture.get_width(),host.size.y/host.texture.get_height())
		scale=Vector2.ONE*0.48*factor
		position=host.size/2.0+Vector2(6,-78)*factor
	else:
		scale=Vector2(0.48,0.48)
		position=Vector2(6,-78)
