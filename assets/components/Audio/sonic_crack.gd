class_name SonicCrack
extends Node2D

@export var audioEmitter: AudioEmitter

func _on_audio_emitter_finished():
	queue_free()

func Play():
	audioEmitter.play()
