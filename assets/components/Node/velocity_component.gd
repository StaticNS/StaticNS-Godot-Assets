class_name VelocityComponent
extends Node

@export var max_speed : float = 10:
	set(maxSpd):
		max_speed = maxSpd
	get:
		return max_speed * 10
@export var acceleration_coefficient : float = 10:
	set(accelCoe):
		acceleration_coefficient = accelCoe
	get:
		return acceleration_coefficient * 10
@export var debug_mode := false

var velocity := Vector2.ZERO:
	set(vel):
		velocity = vel
	get:
		return velocity
var speed_multiplier : float = 1.00:
	set(spdMulti):
		speed_multiplier = spdMulti
	get:
		return speed_multiplier
var speed_percent_modifier := func() -> float: 
	var sum: float = 0.00
	for i in _speed_percent_modifiers.values():
		sum += float(i)
	return sum
var acceleration_coefficient_multiplier : float = 1.00:
	set(accel_coe_multi):
		acceleration_coefficient_multiplier = accel_coe_multi
	get:
		return acceleration_coefficient_multiplier

var _speed_percent = func():
	var max_speed = _calculated_max_speed.call()
	min(velocity.length() / (max_speed if max_speed > 0.00 else 1.00), 1.00)
var _calculated_max_speed = func() -> float:
	return max_speed * (1.00 + speed_percent_modifier.call()) * speed_multiplier
var _speed_percent_modifiers : Dictionary = {}


## Ready function
func _ready():
	set_process(false)
	if OS.is_debug_build() and debug_mode:
		(owner as Node2D).draw.connect(Callable(_on_debug_draw).bind(owner))
		set_process(true)


## Process function called every frame
func _process(delta):
	(owner as Node2D).queue_redraw()


## Accelerates to given velocity with the components stats. 
## DOES NOT MOVE PARENT[br]
## [param velocity] velocity you want to accel to.
func accelerate_to_velocity(velocity: Vector2):
	var accel_time : float = -acceleration_coefficient\
			 * acceleration_coefficient_multiplier
	var blend : float = -(1.00 - pow(
			1.00 - accel_time, 
			get_process_delta_time() * 4.00
	))
	self.velocity = velocity.lerp(velocity, blend) 


## Similar to accelerate_to_velocity, but for directions instead. 
## DOES NOT MOVE PARENT[br]
## [param direction] direction you want to accel in.
func accelerate_in_direction(direction: Vector2):
	accelerate_to_velocity(direction * _calculated_max_speed.call())


## Gets the calculated max velocity expected from moving in given direction.[br]
## [param direction] direction to get max speed from.[br]
## Returns a Vector2 of the direction multiplied by the max speed
func get_max_velocity(direction: Vector2) -> Vector2:
	return direction * _calculated_max_speed.call()


## Immediately changes velocity to its maximum in a given direction.
## DOES NOT MOVE PARENT[br]
## [param direction] direction to maximize the velocity in.
func maximize_velocity(direction: Vector2):
	velocity = get_max_velocity(direction)


## Decelerates the velocity until it reaches zero or is interupted. 
## DOES NOT MOVE PARENT
func decelerate():
	accelerate_to_velocity(Vector2.ZERO)


## Must be called if you want the velocity to be applied to the parent.[br]
## [param character_body] CharacterBody2D to have velocity applied to.
func move(character_body : CharacterBody2D):
	character_body.velocity = velocity
	character_body.move_and_slide()


## Adds a percent modifier to the total max speed (stacks).[br]
## [param name] name of the modifier for later access,[br]
## [param change] the amount of change (in percent) wanted to apply to the maxspeed.
func add_speed_percent_modifier(name: String, change: float):
	if _speed_percent_modifiers.has(name):
		change += _speed_percent_modifiers[name]
	_speed_percent_modifiers[name] = change


## Sets a percent modifier potetially replacing previous modifiers.[br]
## [param name] name of the modifier to be set,[br]
## [param change] the amount of change (in percent) wanted to apply to the maxspeed.
func set_speed_percent_modifier(name: String, change: float):
	_speed_percent_modifiers[name] = change


## Gets a percent modifier value from its name.[br]
## [param name] name of the modifier to be retrieved.[br]
## Returns the value of the speed percent modifier
func get_speed_percent_modifier(name: String) -> float:
	if _speed_percent_modifiers.has(name):
		return _speed_percent_modifiers[name]
		
	print("Dictionary \"_speed_percent_modifiers\" does not contain key: \"" + name + "\"")
	return 0.00


## Debug draw call.
func _on_debug_draw(owner: Node2D):
	owner.draw_line(Vector2.ZERO, velocity, Color.CYAN, 2.00)
