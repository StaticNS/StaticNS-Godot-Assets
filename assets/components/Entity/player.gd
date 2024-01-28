class_name Player
extends CharacterBody2D

@export var velocityComponent: VelocityComponent

var xCont = true
var yCont = true
var xMove: int = 0;
var yMove: int = 0;

#var inventory: Inventory

func _ready():
	#inventory = GameHandler.initInventory("player_inventory", 2)
	#inventory.PrintInventory()
	pass

func _process(delta):
	var input = getInput()
	if input: 
		velocityComponent.AccelerateInDirection(input)
	else:
		velocityComponent.Decelerate()
	velocityComponent.Move(self)

func getInput():
	if !Input.is_anything_pressed():
		return
		
	var input = Vector2.ZERO

	## This input system may seem overcomplicated but its here for a reason.
	## In order to make the movement flow a smoothly as possibly for keyboard,
	## we need to make sure that movement is dictated by our last input rather
	## than two inputs on the same axis canceling each other out.
	input.x = int(Input.is_action_pressed("ui_right")) + int(Input.is_action_pressed("ui_left"))
	match int(input.x):
		1: 
			xMove = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
			xCont = true
		2:
			if xCont:
				xMove = int(Input.is_action_just_pressed("ui_right")) - int(Input.is_action_just_pressed("ui_left"))
				xCont = false
		_:
			xMove = 0
			xCont = true

	input.y = int(Input.is_action_pressed("ui_down")) + int(Input.is_action_pressed("ui_up"))
	match int(input.y):
		1: 
			yMove = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
			yCont = true
		2:
			if yCont:
				yMove = int(Input.is_action_just_pressed("ui_down")) - int(Input.is_action_just_pressed("ui_up"))
				yCont = false
		_:
			yMove = 0
			yCont = true

	input.x = xMove
	input.y = yMove
	
	return input.normalized()
