extends Node3D

var trackedSounds : Array[AudioStreamPlayer3D] = []
var newSoundsThisFrame : Array = []
# Called when the node enters the scene tree for the first time.

const MAX_SOUNDS = 7

var soundRoot =null

func _ready() -> void:
	get_tree().set_meta("soundManager",self)
	soundRoot = Node3D.new()
	soundRoot.name = "soundRoot"
	get_tree().get_root().call_deferred("add_child",soundRoot)
	#get_tree().get_root().add_child(soundRoot)


func play(stream : AudioStream,caller : Node,dict : Dictionary):
	
	var unique = false
	
	if dict.has("unique"):
		unique = dict["unique"]
	
	for i in newSoundsThisFrame:
		if i[0] == stream:
			return
	
	
	
	if unique:
		var toErase =[]
		
		for i in trackedSounds:
			if i.stream == stream:
				i.stop()
				toErase.append(i)
		
		for i in toErase:
			trackedSounds.erase(i)
	
	newSoundsThisFrame.append([stream,caller.global_position])
	
	
	return

func playRandom(streamArr : Array,caller : Node,dict : Dictionary):
	play(streamArr.pick_random(),caller,dict)

func _physics_process(delta: float) -> void:
	
	for i : Array in newSoundsThisFrame:
		createNewSound(i[0],i[1])
		
	
	
	newSoundsThisFrame = []
	
	

func createNewSound(stream : AudioStream, position : Vector3):
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	
	if trackedSounds.size() > 9:
		trackedSounds[0].stop()
		popFront()
	
	
	soundRoot.add_child(player)
	player.position = position
	trackedSounds.append(player)
	player.play()
	

func popFront():
	if trackedSounds.is_empty():
		return
	
	var player :AudioStreamPlayer3D = trackedSounds[0]
	player.stop()
	player.queue_free()
	trackedSounds.pop_front()
	
	
	return

