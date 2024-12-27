extends AudioStreamPlayer3D


# var b = "text"
@export var explosionSounds = [] # (Array,AudioStreamWAV)
@export var idleSounds = [] # (Array,AudioStreamWAV)
@export var spawnSounds = [] # (Array,AudioStreamWAV)

func playSpawn():
	if spawnSounds.is_empty():
		return
	stream = spawnSounds[0]
	ENTG.getSoundManager(get_tree()).play( stream,self,{"unique":true})
	
func playExplode():
	if explosionSounds.is_empty():
		return 0
	
	ENTG.getSoundManager(get_tree()).play( explosionSounds[0],self,{"unique":true})
	
	if explosionSounds[0] == null:
		return 0
	
	return explosionSounds[0].get_length()
	
	

	
func playIdle():
	if idleSounds.is_empty():
		return
	
	stream = idleSounds[0]
	play()


func playRandom(streamArr):
	if streamArr.size() == 0:
		return
	
	var idx = randi()%streamArr.size()
	stream = streamArr[idx]
	
	play()
