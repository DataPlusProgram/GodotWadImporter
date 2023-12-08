extends Node

var meshNode = null
var soundCache = {}
var cast : RayCast



export(String) var weaponName = ""
export(int) var category = 1
export(Array,String) var idleAnims = []
export(Array,String) var fireAnims = []
export(Array,String) var reloadAnims = []
export(String) var bringupAnim = "bringUp"
export(String) var bringdownAnim = "bringDown"
export(Array,AudioStream) var shootSounds = []
export(String, FILE, "*.tscn,*.scn") var projectile = null
export(Texture) var bulletImpactTexture = load("res://addons/godotWad/sprites/bulletImpact.png")
export(Vector3) var scaleFactor
export(Dictionary) var reloadSounds = {
	0:""
	}
#export(Array,int,0,10000,1,String) var test = []

export var fullyAutomatic = true
export var shootDurationMS = 270
export var magSize = 17
export var damage = 8
export var timeTillIdleAnim = 1000
export var spread = Vector2(20,20)
export var bulletPerShot = 1
export var reloadDurMs = 1000

export(int) var firstShotAccuracy = 1
export(int) var firstShotCooldonwMS = 100



onready var curMag = magSize

var soundPlayer
var anims : AnimationPlayer = null


var ready = false
var shootSoundIdx = 0
var directory = ""
var instancedShootSounds = []
var instancedReloadSounds = {}
var isReady = false


var shootStartTime = -1
var lastShootEndTime = 0
var reloadStartTime = 0
var reloadSoundQueue = []
var sphere = null
var curReloadTarget = -1

onready var curfirstShotAccuracy = firstShotAccuracy
onready var curFirstShotCooldown =  0

func _get_configuration_warning():
	
	if !has_node("AnimationPlayer"):
		return "Child AnimationPlayer Node required"

	return ''


enum {
	IDLE,
	SHOOT_END,
	SHOOTING,
	RELOADING,
	DRYFIRE,
	BRINGUP,
	BRINGDOWN
}

var stateToString = {
	IDLE:"IDLE",
	SHOOT_END:"SHOOT_END",
	SHOOTING:"SHOOTING",
	RELOADING:"RELOADING",
	DRYFIRE:"DRYFIRE",
	BRINGUP:"BRINGUP",
	BRINGDOWN:"BRINGDOWN"
	
}

var state = IDLE

func _ready():
	#res = load(resPath)#
	anims = get_node("AnimationPlayer")
	if !InputMap.has_action("shoot"): InputMap.add_action("shoot")
	if !InputMap.has_action("reload"): InputMap.add_action("reload")
	
	
	
	if get_parent().has_node("shootCast"):#if the parent node has a shoot cast we will defer to that
		cast = $"../shootCast"
	else:
		cast = $shootCast
		

	soundPlayer = get_node("soundPlayer")
	isReady = true
	


func _draw():
	pass
	##if get_node_or_null("AnimatedSprite"):
	#	$AnimatedSprite.scale = get_viewport().size.x * 0.0012 
	#	$AnimatedSprite.scale.y = get_viewport().size.y * 0.0012


	
func _physics_process(delta):
	
	
	

	
	if ready == false:
		if has_node("AnimationPlayer"):
			
			anims = get_node("AnimationPlayer")
			
			ready = true
			
		else:
			return
	
	if Engine.editor_hint: return
	
	
	curFirstShotCooldown = max(0,curFirstShotCooldown-(1000.0*delta))# every tick we decrement first bullet timer

	if curFirstShotCooldown == 0:#once the timer is 0 go back to full accuracy
		curfirstShotAccuracy = firstShotAccuracy
	
	
	if state == BRINGUP:
		if anims.current_animation == "":#if we are brining up our gun and the animation is over go to idel
			state = IDLE


	if state == IDLE:#if we are in idle state
		
		if OS.get_system_time_msecs() >lastShootEndTime+timeTillIdleAnim:
			if !idleAnims.has(anims.current_animation):#if not currently in idle anim
				idleAnims.shuffle()
				if !idleAnims.empty():
					if anims.get_animation(idleAnims[0]):
						anims.play(idleAnims[0])
					else: 
						print("idle animation:",idleAnims[0], " not found")
						idleAnims.erase(idleAnims[0])
		elif !idleAnims.empty():
			anims.play(idleAnims[0])

		if fullyAutomatic and Input.is_action_pressed("shoot"):
			if curMag >0 or magSize < 0:
				state = SHOOTING
				shootStartTime = -1
	
		elif Input.is_action_just_pressed("shoot"):
			if curMag >0 or magSize <0:
				state = SHOOTING
				shootStartTime = -1
		
		elif Input.is_action_pressed("reload"):
			if curMag < magSize or magSize <0:
				state = RELOADING
				reloadStartTime = -1

		if curMag <= 0 and magSize != -1:
			state = RELOADING
			reloadStartTime = -1

	

	if state == SHOOTING:
		if shootStartTime == -1:
			shootBullets()
			curFirstShotCooldown = firstShotCooldonwMS
		
			shootStartTime = OS.get_system_time_msecs()
			if !shootSounds.empty():
				shootSoundIdx = (shootSoundIdx+1)%shootSounds.size()
				soundPlayer.stream =shootSounds[shootSoundIdx]
				soundPlayer.play()
				
			if magSize >0 :
				curMag -= 1
			anims.stop(true)
			if !fireAnims.empty():
				if !idleAnims.empty():
					anims.animation_set_next(fireAnims[0],idleAnims[0])
					anims.play(fireAnims[0]) 
		
	
		
		if (shootStartTime+shootDurationMS) < OS.get_system_time_msecs():
			lastShootEndTime = OS.get_system_time_msecs()
			state = IDLE
		
	if state == RELOADING:
		
		var thisTime =  OS.get_system_time_msecs()

			
		if reloadStartTime == -1:
			reloadSoundQueue = reloadSounds.duplicate()#we have mutliple sound clips in case of diffent sound for mag going in and out
			curReloadTarget = -1
			reloadStartTime = OS.get_system_time_msecs()
			if !reloadAnims.empty():
				if anims.has_animation(reloadAnims[0]):
					anims.play(reloadAnims[0])
		
		

		if reloadSoundQueue.size() > 0 and state == RELOADING:
			if curReloadTarget > reloadSoundQueue.keys()[0] or curReloadTarget == -1:
				if !reloadSounds[0] == "":
					var t = reloadSoundQueue.keys()[0]
					#if (reloadStartTime + s) <= t
					curReloadTarget = reloadStartTime + t
					#soundPlayer.stream = instancedReloadSounds[t]
					#soundPlayer.play()
					#reloadSoundQueue.erase(reloadSoundQueue.keys()[0])
		
		
		if state == RELOADING and  OS.get_system_time_msecs()-reloadStartTime >= reloadDurMs:
			anims.stop()
			state = IDLE
			curMag = magSize

			
func drawSphere(pos):
	if sphere == null:
		var shape : SphereMesh = SphereMesh.new()
		shape.radius = 0.25/2
		shape.height = 0.5/2
		sphere = shape
	
	var meshInstance = MeshInstance.new()
	meshInstance.mesh = sphere
	meshInstance.translation = pos
	add_child(meshInstance)

func hit(collider):
	
	if collider.has_method("takeDamage"):
		collider.takeDamage(damage)
	
	
func shootBullets():
	var n : Area = get_node("Area") 
	var bodies = n.get_overlapping_bodies()
	for i in bodies:
		if i != get_parent().get_parent().get_parent():
			hit(i)
		


func createDecal(pos,obj,normal):
	var spr = Sprite3D.new()
	spr.texture = bulletImpactTexture
	obj.add_child(spr)
	spr.pixel_size = 0.2
	spr.global_transform.origin = pos
	spr.translation+= normal*0.1
	
	var tangent
	
	if    normal == Vector3.UP   : tangent =  Vector3.RIGHT
	elif  normal == Vector3.DOWN : tangent =  Vector3.RIGHT
	else: tangent = Vector3.DOWN
	
	spr.look_at(pos + normal, tangent)

