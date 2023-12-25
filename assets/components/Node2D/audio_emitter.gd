class_name AudioEmitter
extends AudioStreamPlayer2D

const MIN_VOLUME: float = -80.00
const PITCH_RANGE: float = 8.00
const MAX_FREQ: float = 20500.00

@export_category("Values")
@export_range(MIN_VOLUME, 24.00) var volume: float = 0
@export_range(0.01, 4.00) var pitchScale: float = 1
@export var speedOfSound: float = 343.00:
	set(spdOfSnd):
		speedOfSound = spdOfSnd
	get:
		return speedOfSound * 10

@export_category("Bools")
@export var active: bool = true:
	set(state):
		active = state
		stream_paused = !active
	get:
		return active
@export var playOnStart: bool = false
@export var loop: bool = false

@export_category("Distance Effects")
@export var dopplerEffect: bool = true
@export var soundTravel: bool = true
@export var distanceBasedLowpass: bool = false
@export_exp_easing("attenuation") var cutoffAttenuation: float = 2.00
@export var lowpassFilter: AudioEffectLowPassFilter

@export_category("Trans-Sonic")
@export var transSonic: bool = false
@export var transSonicSound: AudioStream

@export_category("Composition")
@export var velocityComponent: VelocityComponent

@onready var observer: AudioObserver = get_tree().get_nodes_in_group("audio_observer")[0]

var transSonicNode
var transSonicReset: bool = true

func _ready():
	stream_paused = !active
	
	if (transSonic): 
		transSonicNode = load("res://assets/components/Audio/sonic_crack.tscn")
	
	if (distanceBasedLowpass):
		InitUniqueAudioBus()
	
	if (playOnStart):
		Play()

func _physics_process(_delta):
	if (dopplerEffect):
		DopplerEffect()	
	
	if (distanceBasedLowpass):
		DistanceBasedLowpass()

func Play(loop: bool = false):
	if (!active):
		return
	if (loop):
		play()
		return

	if (soundTravel):
		var dist = global_position.distance_to(observer.global_position)
		var time = dist / speedOfSound
		await get_tree().create_timer(time).timeout
	
	play()

func _on_finished():
	if (loop):
		Play(true)
		
func DopplerEffect():
	# why do maths when you can't even hear it?
	if (global_position.distance_to(observer.global_position) > max_distance):
		return
	
	# grabbing some variables for maths
	var obvrVel = observer.velocityComponent.Velocity
	var selfVel = Vector2.ZERO
	# check if we move at all
	if (velocityComponent != null):
		selfVel = velocityComponent.Velocity
	
	# not entirely sure if this extra fancy stuff is needed but it works so i wont change it
	var localVel = observer.get_global_transform().orthonormalized().basis_xform_inv(selfVel - obvrVel)
	var localPos = observer.get_global_transform().orthonormalized().affine_inverse().basis_xform(global_position)
	
	# if we are even currently moving. if we aren't there is no doppler effect
	if localVel != Vector2.ZERO:
		# grabbing some more variables for maths
		var approaching = localPos.normalized().dot(localVel.normalized())
		var velocity = localVel.length()
		
		# since pitch works off of scale instead of frequency, we have some math magic here
		var dopplerPitchScale = pitchScale * speedOfSound / (speedOfSound + velocity * approaching)
		
		# if our scale is below or equal to 0, we are super-sonic and approaching
		if (dopplerPitchScale <= 0):
			# things approaching at super-sonic dont make noise
			volume_db = MIN_VOLUME
			transSonicReset = true
		else:
			# make sure volume is correct, and play the trans sonic sound if we have it
			volume_db = volume
			PlayTransSonicSound(velocity)
			transSonicReset = false
		
		# making sure our pitch doesnt go so high it sound weird, or is set to zero
		dopplerPitchScale = clamp(dopplerPitchScale, (1.00 / PITCH_RANGE), PITCH_RANGE)
		pitch_scale = dopplerPitchScale
	else:
		pitch_scale = pitchScale

func DistanceBasedLowpass():
	var dist = global_position.distance_to(observer.global_position)
	var freqMulti = pow(1.00 - dist / max_distance, cutoffAttenuation)
	var freq = clamp(freqMulti * MAX_FREQ, 1.00, MAX_FREQ)
	lowpassFilter.cutoff_hz = freq

func PlayTransSonicSound(velocity: float):
	# just checking first if we are super-sonic to our observer
	if (transSonic and transSonicReset and velocity > speedOfSound):
		var sonic = transSonicNode.instantiate()
		if (transSonicSound != null):
			sonic.stream = transSonicSound
		sonic.global_position = global_position
		World.add_child(sonic)
		sonic.Play()

func InitUniqueAudioBus():
	# unfortunately the only resonable way to add filter effects to one sound is 
	# to make and assign a new bus to EVERY. SINGLE. EMITTER. (that uses filter effects)
	var id = str(get_instance_id())
	AudioServer.add_bus(AudioServer.get_bus_count())
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, id)
	var custom_bus_idx = AudioServer.get_bus_index(id)
	AudioServer.add_bus_effect(custom_bus_idx, lowpassFilter, -1)
	bus = str(id)
