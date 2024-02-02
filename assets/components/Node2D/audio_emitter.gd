class_name AudioEmitter
extends AudioStreamPlayer2D
##

const MIN_VOLUME : float = -80.00
const PITCH_RANGE : float = 8.00
const MAX_FREQ : float = 20500.00

@export_category("Values")
@export_range(MIN_VOLUME, 24.00) var volume: float = 0
@export_range(0.01, 4.00) var pitch_scale_value: float = 1
@export var speed_of_sound: float = 343.00:
	set(spdOfSnd):
		speed_of_sound = spdOfSnd
	get:
		return speed_of_sound * 10

@export_category("Bools")
@export var active : bool = true:
	set(state):
		active = state
		stream_paused = !active
	get:
		return active
@export var play_on_start : bool = false
@export var loop : bool = false

@export_category("Distance Effects")
@export var doppler_effect : bool = true
@export var doppler_effect_strength : float = 1.00
@export var sound_travel : bool = true
@export var distance_based_lowpass : bool = false
@export_exp_easing("attenuation") var cutoff_attenuation : float = 2.00
@export var lowpass_filter : AudioEffectLowPassFilter

@export_category("Trans-Sonic")
@export var trans_sonic : bool = false
@export var trans_sonic_sound : AudioStream

@export_category("Composition")
@export var velocity_component : VelocityComponent

@onready var observer : AudioObserver = get_tree().get_nodes_in_group("audio_observer")[0]

var _trans_sonic_node
var _trans_sonic_reset : bool = true


##
func _ready():
	stream_paused = !active

	if (trans_sonic): 
		_trans_sonic_node = load("res://assets/components/Audio/sonic_crack.tscn")

	if (distance_based_lowpass):
		_init_unique_audio_bus()

	if (play_on_start):
		play_sound()


##
func _physics_process(_delta):
	if (doppler_effect):
		_doppler_effect()	

	if (distance_based_lowpass):
		_distance_based_lowpass()


##
func play_sound(loop: bool = false):
	if (!active):
		return
	if (loop):
		play()
		return

	if (sound_travel):
		var dist = global_position.distance_to(observer.global_position)
		var time = dist / speed_of_sound
		await get_tree().create_timer(time).timeout

	play()


##
func _on_finished():
	if (loop):
		play_sound(true)


##
func _doppler_effect():
	# why do maths when you can't even hear it?
	if (global_position.distance_to(observer.global_position) > max_distance):
		return

	# grabbing some variables for maths
	var obvr_vel = observer.velocity_component.velocity
	var self_vel = Vector2.ZERO
	# check if we move at all
	if (velocity_component != null):
		self_vel = velocity_component.velocity

	# not entirely sure if this extra fancy stuff is needed but it works so i wont change it
	var local_vel = observer.get_global_transform().orthonormalized().basis_xform_inv(self_vel - obvr_vel)
	var local_pos = observer.get_global_transform().orthonormalized().affine_inverse().basis_xform(global_position)

	# if we are even currently moving. if we aren't there is no doppler effect
	if local_vel != Vector2.ZERO:
		# grabbing some more variables for maths
		var approaching = local_pos.normalized().dot(local_vel.normalized())\
				 / doppler_effect_strength
		var velocity = local_vel.length()

		# since pitch works off of scale instead of frequency, we have some math magic here
		var doppler_pitch_scale = pitch_scale_value * speed_of_sound\
				 / (speed_of_sound + velocity * approaching)

		# if our scale is below or equal to 0, we are super-sonic and approaching
		if (doppler_pitch_scale <= 0):
			# things approaching at super-sonic dont make noise
			volume_db = MIN_VOLUME
			_trans_sonic_reset = true
		else:
			# make sure volume is correct, and play the trans sonic sound if we have it
			volume_db = volume
			play_soundTransSonicSound(velocity)
			_trans_sonic_reset = false

		# making sure our pitch doesnt go so high it sound weird, or is set to zero
		doppler_pitch_scale = clamp(doppler_pitch_scale, (1.00 / PITCH_RANGE), PITCH_RANGE)
		pitch_scale = doppler_pitch_scale
	else:
		pitch_scale = pitch_scale_value


##
func _distance_based_lowpass():
	var dist = global_position.distance_to(observer.global_position)
	var freqMulti = pow(1.00 - dist / max_distance, cutoff_attenuation)
	var freq = clamp(freqMulti * MAX_FREQ, 1.00, MAX_FREQ)
	lowpass_filter.cutoff_hz = freq


##
func play_soundTransSonicSound(velocity: float):
	# just checking first if we are super-sonic to our observer
	if (trans_sonic and _trans_sonic_reset and velocity > speed_of_sound):
		var sonic = _trans_sonic_node.instantiate()
		if (trans_sonic_sound != null):
			sonic.stream = trans_sonic_sound
		sonic.global_position = global_position
		World.add_child(sonic)
		sonic.play_sound()


##
func _init_unique_audio_bus():
	# unfortunately the only resonable way to add filter effects to one sound is 
	# to make and assign a new bus to EVERY. SINGLE. EMITTER. (that uses filter effects)
	var id = str(get_instance_id())
	AudioServer.add_bus(AudioServer.get_bus_count())
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, id)
	var custom_bus_idx = AudioServer.get_bus_index(id)
	AudioServer.add_bus_effect(custom_bus_idx, lowpass_filter, -1)
	bus = str(id)
