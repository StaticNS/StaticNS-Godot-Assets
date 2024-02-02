class_name Player
extends CharacterBody2D
## Player node for just having something to move around and such

@export var velocity_component: VelocityComponent

var _x_cont := true
var _y_cont := true
var _x_move : int = 0;
var _y_move : int = 0;

#var inventory: Inventory = Inventory.new()


## Not currently in use
func _ready():
	pass


## Get input and do velocity_component component magic to move player around
func _process(delta):
	var input = _get_input()
	if input: 
		velocity_component.accelerate_in_direction(input)
	else:
		velocity_component.decelerate()
	velocity_component.move(self)


## For getting moving input only. 
## Returns normalized Vector2 that the velocity component takes
func _get_input():
	if !Input.is_anything_pressed():
		return

	var input = Vector2.ZERO

	# This input system may seem overcomplicated but its here for a reason.
	# In order to make the movement flow a smoothly as possibly for keyboard,
	#we need to make sure that movement is dictated by our last input rather
	#than two inputs on the same axis canceling each other out.

	input.x = int(Input.is_action_pressed("ui_right"))\
			 + int(Input.is_action_pressed("ui_left"))
	match int(input.x):
		1: 
			_x_move = int(Input.is_action_pressed("ui_right"))\
					 - int(Input.is_action_pressed("ui_left"))
			_x_cont = true
		2:
			if _x_cont:
				_x_move = int(Input.is_action_just_pressed("ui_right"))\
						 - int(Input.is_action_just_pressed("ui_left"))
				_x_cont = false
		_:
			_x_move = 0
			_x_cont = true

	input.y = int(Input.is_action_pressed("ui_down"))\
			 + int(Input.is_action_pressed("ui_up"))
	match int(input.y):
		1: 
			_y_move = int(Input.is_action_pressed("ui_down")) \
					- int(Input.is_action_pressed("ui_up"))
			_y_cont = true
		2:
			if _y_cont:
				_y_move = int(Input.is_action_just_pressed("ui_down")) \
						- int(Input.is_action_just_pressed("ui_up"))
				_y_cont = false
		_:
			_y_move = 0
			_y_cont = true

	input.x = _x_move
	input.y = _y_move

	return input.normalized()
