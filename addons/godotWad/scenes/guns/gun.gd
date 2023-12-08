tool
extends Spatial

var meshNode = null
var cast : RayCast
var shooter

export(String) var weaponName = ""

export(int) var category = 1
export(int) var categorySubIndex = 0
export(String) var ammoType = "9mm"

export(Array,String) var idleAnims = []
export(Array,String) var fireAnims = []
export(Array,String) var reloadAnims = []
export(String) var bringupAnim = "bringUp"
export(String) var bringdownAnim = "bringDown"
#export(String, FILE, "*.tscn,*.scn") var projectile = ""
export var projectile = ""
export(Texture) var bulletImpactTexture = load("res://addons/godotWad/sprites/bulletImpact.png")
export(Texture) var worldSprite = null
export(Dictionary) var reloadSounds = {
	0:""
	}

export var fullyAutomatic = true
export var shootDurationMS = 270
export var magSize = 17
export var damage = 8
export var pickupAmmo = 10
export var timeTillIdleAnim = 1000
export var initialSpread = Vector2(0,0)
export var maxSpread = Vector2(20,20)
export var spreadPerShot = Vector2(5,0)
export var bulletPerShot = 1
export var ammoConsumedPerShot = 1
export var reloadDurMs = 1000
export var maxDb = 3.0
export(float) var absRange = 1000.0
export(int) var firstShotAccuracy = 1
export(int) var firstShotCooldownMS = 100
export(Curve) var curve
export(AnimatedTexture) var wallHitSprite = null
export var scaleFactor = Vector3.ONE
onready var shootDurSec = shootDurationMS/1000.0

onready var curAmmoInMag = magSize
var curSpread

var anims : AnimationPlayer = null
var disabled = false
var ready = false
var shootSoundIdx = 0
var directory = ""

var isReady = false

var shootStartTime = INF
var lastShootEndTime = 0
var reloadStartTime = 0
var reloadSoundQueue = []
var sphere = null
var curReloadTarget = -1


var pState = null
var state = IDLE
var stateChanged = true

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
	BRINGDOWN,
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

var ticksPerShot
var audioCountdown = null


var audioSplitPoint
var shootDurationS
onready var initialY = translation.y
var initialEnd
func _ready():
	
	
	
	
	if Engine.is_editor_hint():
		return
	
	var t = Engine.iterations_per_second
	var tickDur = 1.0/Engine.iterations_per_second
	shootDurationS =  shootDurationMS / 1000.0
	ticksPerShot = shootDurationS/tickDur
	ticksPerShot = stepify(ticksPerShot,1)
	
	
	
	audioSplitPoint = (ticksPerShot+2)*(1.0/Engine.iterations_per_second)
	

	
	sound()
	curSpread = initialSpread

	anims = get_node("AnimationPlayer")
	
	anims.play("idle")
	if !InputMap.has_action("shoot"): InputMap.add_action("shoot")
	if !InputMap.has_action("reload"): InputMap.add_action("reload")

	
	if get_node("../../") != null:
		if get_node("../../").has_node("shootCast"):#if the parent node has a shoot cast we will defer to that
			cast = $"../../shootCast"
	else:
		if get_node_or_null("shootCast") != null:
			cast = $shootCast
	
	if cast != null:
		cast.add_exception($"../../../")

	isReady = true
	
	


func _physics_process(delta):
	
	if Engine.editor_hint: return
	
	if shooter != null:
		if "processInput" in shooter:
			if shooter.processInput == false:
				return
		
	
	#translation.y =  initialY - (3.8321985e-05 * pow(x,2) - 0.000699710*x - 0.14274416) - 0.00
		
	if ready == false:
		if has_node("AnimationPlayer"):
			
			anims = get_node("AnimationPlayer")
			
			ready = true
			
		else:
			return

	if curFirstShotCooldown >0:
		curFirstShotCooldown = max(0,curFirstShotCooldown-(1000.0*delta))# every tick we decrement first bullet timer
	
	
	if curFirstShotCooldown == 0:#once the timer is 0 go back to full accuracy
		curSpread = initialSpread
		curfirstShotAccuracy = firstShotAccuracy
		curFirstShotCooldown = -1

		
	
	
	if state == BRINGUP:
		if anims.current_animation == "":#if we are brining up our gun and the animation is over go to idle
			state = IDLE
			
			updateState()

	if state == IDLE:#if we are in idle state
		idleState()
		updateState()
		


	if state == SHOOTING:
		shootState(delta)
		updateState()
	elif state == SHOOT_END:
		shootStateEnd(delta)
	
		
	if state == RELOADING:
		reloadState()
		updateState()

	

func hit(collider,point = null):
	if collider == shooter:
		return
	
	if collider.has_method("takeDamage"):
		if point == null:
			collider.takeDamage({"amt":damage,"source":shooter,"position":cast.get_collision_point()})
		else:
			collider.takeDamage({"amt":damage,"source":shooter,"position":point})
	else:
		var diff = cast.get_collision_point()-global_translation
		var diffLen = diff.length()
		
		if wallHitSprite != null:
			spawnPuff(global_translation+(diff.normalized()*diffLen*.99))
		createDecal(cast.get_collision_point(),collider,cast.get_collision_normal())
	

var shootCommit = false
var curShootTick = 0
var audioSplit = 0

func shootState(delta,fromCommit = false):
	var inventory
	
	if stateChanged:
		if "inventory" in shooter:
			inventory = shooter.inventory
			if !inventory.has(ammoType):
				inventory[ammoType] = {"count":0}
			
			
			if inventory[ammoType]["count"] == 0 and magSize != -1:
				state = IDLE
				return
				
		audioCountdown = delta
		shootStartTime = OS.get_system_time_msecs()
		shootBullets()
		
		curShootTick = 1

	
		if getCurAmmo() >0 :
			inventory[ammoType]["count"] = max(0,inventory[ammoType]["count"]-ammoConsumedPerShot)
			curAmmoInMag = inventory[ammoType]["count"]
		anims.stop(true)
		
		if !fireAnims.empty():
			if !idleAnims.empty():
				anims.play(fireAnims[0]) 
		
		if shooter != null:
			if shooter.get_node_or_null("AnimationPlayer") != null:
				var ap : AnimationPlayer = shooter.get_node("AnimationPlayer")
				ap.play("fire")
		
		return

	curShootTick += 1
	if curShootTick == ticksPerShot:
	
		if Input.is_action_pressed("shoot"):
			state == SHOOTING
			updateState()


		state = IDLE




var statEndFrame = 0
func shootStateEnd(delta):
	if stateChanged:
		pass



func getCurAmmo():
	if shooter == null:
		return
	if !shooter.inventory.has(ammoType):
		shooter.inventory[ammoType] = {"count":0}
	
	
	return 	shooter.inventory[ammoType]["count"]


func setCurAmmo(amount):
	if !shooter.inventory.has(ammoType):
		shooter.inventory[ammoType] = {"count":amount}
		
	shooter.inventory[ammoType] = {"count":amount}
		
		

func idleState():
	
	
	if shooter == null:
		return
	
	if stateChanged:
		if !idleAnims.empty():
			anims.play(idleAnims[0])


	if fullyAutomatic and Input.is_action_pressed("shoot"):
		if getCurAmmo() >0 or magSize < 0:
			state = SHOOTING
			shootStartTime = -1
	
	elif Input.is_action_just_pressed("shoot"):
		if getCurAmmo() >0 or magSize <0:
			state = SHOOTING
			shootStartTime = -1
		
	elif Input.is_action_pressed("reload"):
		if getCurAmmo() < magSize or magSize <0:
			state = RELOADING
			reloadStartTime = -1

	if getCurAmmo() <= 0 and magSize != -1:
		state = RELOADING
		reloadStartTime = -1


func reloadState():
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
				curReloadTarget = reloadStartTime + t

		
		
	if state == RELOADING and  OS.get_system_time_msecs()-reloadStartTime >= reloadDurMs:
		anims.stop()
		state = IDLE
		#curAmmoInMag = magSize


var lastBang = -1

func shootBullets():

	curFirstShotCooldown = firstShotCooldownMS
	
	if get_node_or_null("soundAlert") != null:
		for i in $soundAlert.get_overlapping_bodies():
			if "canHear" in i:
				i.canHear.append(shooter)
		
	
	if get_node_or_null("Area") != null:
		var area = $Area
		for body in area.get_overlapping_bodies():
			hit(body,body.global_translation)
			
			if body != shooter:
				if "hp" in body:
					$AudioStreamPlayer3D.playImpact()
	
	for i in bulletPerShot:

		var shootVector = Vector3(0,0,1)
		
		if curfirstShotAccuracy <= 0:#no more accurate shots left
			var spreX = rand_range(0,curSpread.x/2.0)
			
			#var spreX = rng.randfn((curSpread.x/2.0)/2.0)
			
			spreX = min(curSpread.x,spreX)
			var radiusX = tan(deg2rad(spreX))
			
			var angle = rand_range(0,2*PI)
			
			var spreY = rand_range(0,curSpread.y/2.0)
			var radiusY = tan(deg2rad(spreY))
			
			#var c = curve.interpolate(rand_range(0,1))
			var c = 1
			
			shootVector = Vector3(c*radiusX*cos(angle),c*radiusY*sin(angle),1)
			shootVector.normalized()

	

		
		shootVector *= -absRange
		cast.cast_to = shootVector
		var p = null
		
		
		if projectile == "":#shoot bullet
			if get_node_or_null("Area") == null:
				cast.force_raycast_update()
				var collider = cast.get_collider()
				
				if collider != null:
					hit(collider)
					
		
		
		#if typeof(projectile) == TYPE_NODE_PATH:
		#		p = get_node(projectile).duplicate()
				#p = projectile.duplicate()
		
		
		else:
			var par = $"../"
			p = ENTG.spawn(get_tree(),projectile,par.global_transform.origin,WADG.transformToRotDegrees(par.global_transform),"Doom")
			
		if p != null:
			p.shooter = shooter
			p.visible = true
			var par = self
			while par.get_class() != "KinematicBody":
				par = par.get_parent()
			p.add_collision_exception_with(par)
			p.transform = $"../".global_transform
			p.transform.origin -= p.transform.basis.z
			#p.shooter = shooter
			$"/root".add_child(p)
			#if p.has_rethod("reset_physics_interpolation"):
			#	p.reset_physics_interpolation()
		
		
	curSpread.x = min(curSpread.x+spreadPerShot.x,maxSpread.x)
	curSpread.y = min(curSpread.y+spreadPerShot.y,maxSpread.y)
	curfirstShotAccuracy = max(curfirstShotAccuracy-1,0)
	
	
	
func createDecal(pos,obj,normal):
	var spr = Sprite3D.new()
	spr.texture = bulletImpactTexture
	obj.add_child(spr)
	
	spr.global_transform.origin = pos
	spr.translation+= normal*0.001
	
	var tangent
	
	if    normal == Vector3.UP   : tangent =  Vector3.RIGHT
	elif  normal == Vector3.DOWN : tangent =  Vector3.RIGHT
	else: tangent = Vector3.DOWN
	
	spr.look_at(pos + normal, tangent)
	
	if spr.has_method("reset_physics_interpolation"):
		spr.reset_physics_interpolation()


func sound():
	return
	
	var stream = $AudioStreamPlayer3D.fireSounds[0]
	#var stream = $AudioStreamPlayer3D.fireSounds[0].duplicate(true)
	$AudioStreamPlayer3D.stream = stream
	var sampleRate = stream.mix_rate
	var data = stream.data
	var numSamps = data.size()
	
	var soundDur = (1.0/sampleRate) * data.size()
	var shootDur =shootDurationMS/1000.0
	
	
	
	if (shootDur < soundDur):
		var s = floor(shootDur/(1.0/sampleRate))
		
		data.resize(s) 
		stream.loop_end = s
		stream.loop_mode = AudioStreamSample.LOOP_FORWARD


func updateState():
	if pState != state:
		stateChanged = true
	else:
		stateChanged = false
		
	pState = state


func spawnPuff(pos : Vector3 = Vector3.ZERO):
	wallHitSprite.fps = 10
	wallHitSprite.oneshot = true
	var spr = Sprite3D.new()
	spr.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	spr.texture = wallHitSprite.duplicate()
	spr.translation = pos#-global_translation
	spr.pixel_size = scaleFactor.x 
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.4
	timer.connect("timeout",spr,"queue_free")
	timer.autostart = true
	spr.add_child(timer)

	#createdBloodDecal.append(spr)
	$"/root".add_child(spr)
