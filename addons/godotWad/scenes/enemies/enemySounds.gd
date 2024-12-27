@tool
extends AudioStreamPlayer3D

@export var deathSounds : Array # (Array,AudioStreamWAV)
@export var gibSounds : Array
@export var painSounds : Array # (Array,AudioStreamWAV)
@export var attackSounds : Array# (Array,AudioStreamWAV)
@export var alertSounds  : Array# (Array,AudioStreamWAV)
@export var meleeSounds : Array# (Array,AudioStreamWAV)
@export var searchSounds : Array
@export var stompSounds : Array


var soundManager = null

func _ready():
	soundManager = ENTG.getSoundManager(get_tree())


func playDeath():
	soundManager.playRandom(deathSounds,self,{})
	#playRandom(deathSounds)
		

func playHurt():
	soundManager.playRandom(painSounds,self,{"unique":true})
	#playRandom(painSounds)


func playAttack():
	if soundManager != null:
		soundManager.playRandom(attackSounds,self,{})
	#playRandom(attackSounds)

func playMelee():
	playRandom(meleeSounds)

func playStomp():
	playRandom(stompSounds)

func playGib():
	playRandom(gibSounds) 



func playRandom(streamArr):
	if streamArr.size() == 0:
		return
	
	var idx = randi()%streamArr.size()
	stream = streamArr[idx]
	play()
	

func playAlert():
	if soundManager != null:
		soundManager.playRandom(alertSounds,self,{})
	#playRandom(alertSounds)
	
func playSearch():
	playRandom(searchSounds)
