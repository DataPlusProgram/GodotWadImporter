tool
extends AudioStreamPlayer3D

export(Array,AudioStreamSample) var deathSounds 
export(Array,AudioStreamSample) var hurtSounds 
export(AudioStreamSample) var gruntSound

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func playDeath():
	if deathSounds.size() == 0:
		return
	stream = deathSounds[0]
	play()

func playHurth():
	
	if playing and get_playback_position() < 0.5:
		return
		
	
	if hurtSounds.size() == 0:
		return
	stream = hurtSounds[0]
	play()
