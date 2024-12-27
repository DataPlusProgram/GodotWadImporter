extends AudioStreamPlayer3D


@export var fireSounds = [] # (Array,AudioStreamWAV)

var audioQueueTime = null

func _ready():
	stream = fireSounds[0]

@onready var lastPlay = Time.get_ticks_msec()

func playFire():
		play()



#		

func _physics_process(delta):
	pass

func pre():
	if !Input.is_action_pressed("shoot"):
		fireSounds[0].loop_mode = AudioStreamWAV.LOOP_DISABLED



func disableLoop():
	fireSounds[0].loop_mode = AudioStreamWAV.LOOP_DISABLED


func enableLoop():
	fireSounds[0].loop_mode = AudioStreamWAV.LOOP_FORWARD

func playRandom(streamArr):
	if streamArr.size() == 0:
		return
	
	var idx = randi()%streamArr.size()
	stream = streamArr[idx]
	play()

func isDisabled():
	return fireSounds[0].loop_mode == AudioStreamWAV.LOOP_DISABLED

func getDuration():
	var sampleRate = stream.mix_rate
	var data = stream.data
	var numSamps = data.size()
	var soundDur = (1.0/sampleRate) * data.size()
	return soundDur

func position():
	return get_playback_position()
