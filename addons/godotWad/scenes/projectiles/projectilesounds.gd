extends AudioStreamPlayer3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(Array,AudioStreamSample) var explosionSounds = []
export(Array,AudioStreamSample) var idleSounds = []
export(Array,AudioStreamSample) var spawnSounds = []

func playSpawn():
	if spawnSounds.empty():
		return
	stream = spawnSounds[0]
	play()
	
func playExplode():
	if explosionSounds.empty():
		return
	
	stream = explosionSounds[0]
	play() 
	
func playIdle():
	if idleSounds.empty():
		return
	
	stream = idleSounds[0]
	play()


func playRandom(streamArr):
	if streamArr.size() == 0:
		return
	
	var idx = randi()%streamArr.size()
	stream = streamArr[idx]
	play()
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
