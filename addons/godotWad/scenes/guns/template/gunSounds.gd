@tool
extends AudioStreamPlayer3D


@export var fireSounds : Array# (Array,String)
@export var impactSound: AudioStream = null
@export var extraSound1 : AudioStream = null
@export var extraSound2 : AudioStream = null
@export var reloadSound : AudioStream = null
@onready var lastPlay = Time.get_ticks_msec()
var audioQueueTime = null

func _ready():
	if get_parent() != null:
		if "max_db" in get_parent():
			max_db = get_parent().maxDb
	

func playImpact():
	stream = impactSound
	play()



func playFire():
	if fireSounds.is_empty():
		return
	stream = fireSounds[0]
	play()

func playReload():
	stream = reloadSound
	play()

func playExtraSound1():
	stream = extraSound1
	play()
	

func playExtraSound2():
	stream = extraSound2
	play()
	
	
func _physics_process(delta):
	if !get_parent().visible:
		if playing:
			stop()

func pre():
	if !Input.is_action_pressed("shoot"):
		fireSounds[0].loop_mode = AudioStreamWAV.LOOP_DISABLED



func disableLoop():
	
	#print("disable loop:",get_playback_position())
	fireSounds[0].loop_mode = AudioStreamWAV.LOOP_DISABLED
	#seek(0)

func enableLoop():
	#print("enable loop",get_playback_position())
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
