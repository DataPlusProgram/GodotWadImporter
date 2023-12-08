tool
extends AudioStreamPlayer3D

export(Array,AudioStreamSample) var deathSounds 
export(Array,AudioStreamSample) var painSounds 
export(Array,AudioStreamSample) var attackSounds 
export(Array,AudioStreamSample) var alertSounds 
export(Array,AudioStreamSample) var meleeSounds

func _ready():
	randomize()

func playDeath():
	playRandom(deathSounds)
		

func playHurt():
	playRandom(painSounds)


func playAttack():
	playRandom(attackSounds)

func playMelee():
	playRandom(meleeSounds)

func playRandom(streamArr):
	if streamArr.size() == 0:
		return
	
	var idx = randi()%streamArr.size()
	stream = streamArr[idx]
	play()
	

func playAlert():
	playRandom(alertSounds)
