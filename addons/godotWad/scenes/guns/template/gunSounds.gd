tool
extends AudioStreamPlayer3D


export(Array,String) var fireSounds
export(AudioStream) var impactSound = null


onready var lastPlay = OS.get_system_time_msecs()
var audioQueueTime = null

func _ready():
	if get_parent() != null:
		if "max_db" in get_parent():
			max_db = get_parent().maxDb
	

func playImpact():
	stream = impactSound
	play()

func playFire():
	if fireSounds.empty():
		return
	stream = fireSounds[0]
	play()





func _physics_process(delta):
	if !get_parent().visible:
		if playing:
			stop()

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
