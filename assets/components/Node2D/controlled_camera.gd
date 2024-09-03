class_name ControlledCamera
extends Camera2D

@export var zoom_range := Vector2(1.0, 4.0)
@export var zoom_speed: float = 4.0


##
func _ready():
	# initializing the zoom to the avg zoom_range when instantiated
	set_both_zoom((zoom_range.x + zoom_range.y) / 2.0)


##
func _process(delta):
	if !Input.is_anything_pressed():
		return

	if Input.is_action_pressed("ui_zoom_in"):
		set_both_zoom(zoom.x + zoom_speed * delta)
	elif Input.is_action_pressed("ui_zoom_out"):
		set_both_zoom(zoom.x - zoom_speed * delta)


##
func set_both_zoom(z: float):
	var zoom_level: float = clamp(z, zoom_range.x, zoom_range.y)
	zoom = Vector2(zoom_level, zoom_level)
