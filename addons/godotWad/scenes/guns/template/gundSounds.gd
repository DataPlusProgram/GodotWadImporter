extends AudioStreamPlayer3D


export(Array,AudioStreamSample) var fireSounds = []

var audioQueueTime = null

func _ready():
	stream = fireSounds[0]

onready var lastPlay = OS.get_system_time_msecs()

func playFire():
		play()


#func _process(delta):
#	if audioQueueTime != null:
#		audioQueueTime += delta*1000
#		if audioQueueTime >= 0:
			#print(audioQueueTime)
#			seek(0)
#			play()
			#print("play")
#			audioQueueTime = null
#		

func _physics_process(delta):
	pass

func pre():
	if !Input.is_action_pressed("shoot"):
		fireSounds[0].loop_mode = AudioStreamSample.LOOP_DISABLED



func disableLoop():
	
	#print("disable loop:",get_playback_position())
	fireSounds[0].loop_mode = AudioStreamSample.LOOP_DISABLED
	#seek(0)

func enableLoop():
	#print("enable loop",get_playback_position())
	fireSounds[0].loop_mode = AudioStreamSample.LOOP_FORWARD

func playRandom(streamArr):
	if streamArr.size() == 0:
		return
	
	var idx = randi()%streamArr.size()
	stream = streamArr[idx]
	play()

func isDisabled():
	return fireSounds[0].loop_mode == AudioStreamSample.LOOP_DISABLED

func getDuration():
	var sampleRate = stream.mix_rate
	var data = stream.data
	var numSamps = data.size()
	var soundDur = (1.0/sampleRate) * data.size()
	return soundDur

func position():
	return get_playback_position()
