class_name AudioEmitter
extends AudioStreamPlayer2D

const MIN_VOLUME: float = -80.00

@export_range(MIN_VOLUME, 24.00) var volume: float = 0
@export_range(0.01, 4.00) var pitchScale: float = 1
@export var speedOfSound: float = 343.00:
	set(spdOfSnd):
		speedOfSound = spdOfSnd
	get:
		return speedOfSound * 10

@export var dopplerEffect: bool = true
@export var sonicBoom: bool = false

@export var velocityComponent: VelocityComponent

@onready var observer: AudioObserver = get_tree().get_nodes_in_group("audio_observer")[0]

var sonicBoomNode
var sonicBoomReset: bool = true

func _ready():
	if (sonicBoom): 
		sonicBoomNode = load("res://assets/components/Audio/sonic_crack.tscn")

func _physics_process(_delta):
	if (dopplerEffect):
		DopplerEffect()	
	
const PITCH_RANGE: float = 18.00
const PITCH_SMOOTHING_COEFFICIENT: float = 2.00
@onready var pitchCeil = PITCH_RANGE - PITCH_SMOOTHING_COEFFICIENT
func DopplerEffect():
	var obvrVel = observer.velocityComponent.Velocity
	var selfVel = velocityComponent.Velocity
	
	var localVel = observer.get_global_transform().orthonormalized().basis_xform_inv(selfVel - obvrVel)
	var localPos = observer.get_global_transform().orthonormalized().affine_inverse().basis_xform(global_position)
	
	if localVel != Vector2.ZERO:
		var approaching = localPos.normalized().dot(localVel.normalized())
		var velocity = localVel.length()
		
		var dopplerPitchScale = pitchScale * speedOfSound / (speedOfSound + velocity * approaching)
		
		if (dopplerPitchScale <= 0):
			volume_db = MIN_VOLUME
			sonicBoomReset = true
		else:
			volume_db = volume
			playSonicBoom()
			sonicBoomReset = false
			
		if (dopplerPitchScale > pitchCeil):
			dopplerPitchScale = (normalizePitch(dopplerPitchScale))
		
		dopplerPitchScale = clamp(dopplerPitchScale, (1 / PITCH_RANGE), PITCH_RANGE)
		pitch_scale = dopplerPitchScale
	else:
		pitch_scale = pitchScale

func normalizePitch(value):
	return pitchCeil + (value - pitchCeil)/(4096.00 - pitchCeil) * (PITCH_RANGE - pitchCeil)

func playSonicBoom():
	if (sonicBoom and sonicBoomReset):
		var sonic = sonicBoomNode.instantiate()
		sonic.global_position = global_position
		World.add_child(sonic)
		sonic.Play()
