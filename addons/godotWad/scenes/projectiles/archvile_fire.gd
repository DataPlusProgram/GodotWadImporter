extends Node3D

var curState = 0

@export var stateDataPath : String = ""
var stateData
var curStateWait = 0
@export var scaleFactor : Vector3
@export var spawnSound : AudioStream
@export var fireStartSound : AudioStream
@export var crackleSound : AudioStream
@export var explosionSound : AudioStream

@onready var soundPlayer = $AudioStreamPlayer3D

var curseTarget : Node = null
var dmg = 70

func _ready():
	soundPlayer.stream = spawnSound
	stateData = load(stateDataPath).getRowsAsArray()
	soundPlayer.play()



func _physics_process(delta):
	
	
	$Sprite3D.position.y = ($Sprite3D.texture.get_height()/2.0)*scaleFactor.y
	
	if is_instance_valid(curseTarget):
		global_position = curseTarget.global_position
		
		if "facingDir" in curseTarget:
			global_position += curseTarget.facingDir
	
	curStateWait -= delta
	
	if curStateWait <= 0 and curState != -1:
		procState(stateData[curState],delta)

func procState(state,delta):
	 
	curState = state["Next"]
	curStateWait = state["Dur"]*(1.0/35)
	
	if !state["Function"].is_empty():
		var callFunc = Callable(self,state["Function"])
		callFunc.call()
	
	#$Sprite3D.texture.current_frame = state["Frame"]


func playSpawn():
	soundPlayer.stream = spawnSound
	pass
	
func playCrackle():
	soundPlayer.stream = crackleSound
	soundPlayer.play()
	

func blastDamage():
	for i in $BlastZone.get_overlapping_bodies():
			
		if i == self: 
			continue

		if i.has_method("takeDamage"):
			var dist = i.global_position.distance_to(global_position)/scaleFactor.x
			i.takeDamage({"amt":max(0,dmg-dist),"type":"explosive"})
