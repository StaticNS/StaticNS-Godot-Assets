class_name VelocityComponent
extends Node

@export var maxSpeed: float = 100:
	set(maxSpd):
		maxSpeed = maxSpd
	get:
		return maxSpeed * 10
@export var accelerationCoefficient: float = 10:
	set(accelCoe):
		accelerationCoefficient = accelCoe
	get:
		return accelerationCoefficient * 10

@export var debugMode: bool = false

var Velocity: Vector2 = Vector2.ZERO:
	set(vel):
		Velocity = vel
	get:
		return Velocity
var SpeedMultiplier: float = 1.00:
	set(spdMulti):
		SpeedMultiplier = spdMulti
	get:
		return SpeedMultiplier
var SpeedPercentModifier = func(): 
	var sum: float = 0.00
	for i in speedPercentModifiers.values():
		sum += float(i)
	return sum
var AccelerationCoefficientMultiplier: float = 1.00:
	set(accelCoeMulti):
		AccelerationCoefficientMultiplier = accelCoeMulti
	get:
		return AccelerationCoefficientMultiplier

var SpeedPercent = func():
	var maxSpeed = CalculatedMaxSpeed.call()
	min(Velocity.length() / (maxSpeed if maxSpeed > 0.00 else 1.00), 1.00)
var CalculatedMaxSpeed = func():
	return maxSpeed * (1.00 + SpeedPercentModifier.call()) * SpeedMultiplier

var speedPercentModifiers: Dictionary = {}

func _ready():
	set_process(false)
	if OS.is_debug_build() and debugMode:
		(owner as Node2D).draw.connect(Callable(OnDebugDraw).bind(owner))
		set_process(true)

func _process(delta):
	(owner as Node2D).queue_redraw()

func AccelerateToVelocity(velocity: Vector2):
	var accelTime = -accelerationCoefficient * AccelerationCoefficientMultiplier
	var blend = -(1.00 - pow(1.00 - accelTime, get_process_delta_time() * 4.00))
	Velocity = Velocity.lerp(velocity, blend) 

func AccelerateInDirection(direction: Vector2):
	AccelerateToVelocity(direction * CalculatedMaxSpeed.call())

func GetMaxVelocity(direction: Vector2):
	return direction * CalculatedMaxSpeed.call()
	
func MaximizeVelocity(direction: Vector2):
	Velocity = GetMaxVelocity(direction)

func Decelerate():
	AccelerateToVelocity(Vector2.ZERO)

func Move(characterBody: CharacterBody2D):
	characterBody.velocity = Velocity
	characterBody.move_and_slide()

func AddSpeedPercentModifier(name: String, change: float):
	if speedPercentModifiers.has(name):
		change += speedPercentModifiers[name]
	speedPercentModifiers[name] = change
	
func SetSpeedPercentModifier(name: String, change: float):
	speedPercentModifiers[name] = change
	
func GetSpeedPercentModifier(name: String):
	if speedPercentModifiers.has(name):
		return speedPercentModifiers[name]
		
	print("Dictionary \"speedPercentModifiers\" does not contain key: \"" + name + "\"")
	return 0.00
	
func OnDebugDraw(owner: Node2D):
	owner.draw_line(Vector2.ZERO, Velocity, Color.CYAN, 2.00)
