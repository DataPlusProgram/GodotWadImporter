@tool
extends Node3D

var meshNode = null
var cast : RayCast3D
var shooter

@export var weaponName: String = ""

@export var category: int = 1
@export var categorySubIndex: int = 0
@export var ammoType: String = "9mm"

@export var bringupAnim: String = "bringUp"
@export var bringdownAnim: String = "bringDown"
@export var pickupSound: AudioStream = null
#export(String, FILE, "*.tscn,*.scn") var projectile = ""
@export var projectile = ""
@export var bulletImpactTexture: Texture2D = load("res://addons/godotWad/sprites/bulletImpact.png")
@export var worldSprite: Texture2D = null

@export var fullyAutomatic = true
@export var magSize = 17
@export var damage = 8
@export var pickupAmmo = 10
@export var initialSpread = Vector2(0,0)
@export var maxSpread = Vector2(20,20)
@export var spreadPerShot = Vector2(5,0)
@export var bulletPerShot = 1
@export var ammoConsumedPerShot = 1
@export var reloadDurMs = 1000
@export var maxDb = 3.0
@export var absRange: float = 1000.0
@export var firstShotAccuracy: int = 1
@export var firstShotCooldownMS: int = 100
@export var curve: Curve
@export var wallHitSprite: AnimatedTexture = null
@export var scaleFactor = Vector3.ONE
@export var stateResPath : String= ""
@onready var curAmmoInMag = magSize
var curSpread
@export var holsterY = 0
@onready var initialState = 0
@onready var curState = initialState
@onready var curStateWait = 0
@onready var damageIsKnockBack = true
@export var worldSpriteName = ""
var stateData = []
var anims : AnimationPlayer = null
var disabled = false
var shootSoundIdx = 0
var directory = ""
var entityName = ""
var gameName = ""
@export var shootStateID : int
@export var shootStateDetour : int = -1
var isReady = false
var isFiring = false
@onready var soundPlayer = $AudioStreamPlayer3D
var stateChanged = true

@onready var curfirstShotAccuracy = firstShotAccuracy
@onready var curFirstShotCooldown =  0

func _get_configuration_warnings():
	
	if !has_node("AnimationPlayer"):
		return "Child AnimationPlayer Node required"

	return ''


var ticksPerShot
var audioCountdown = null


var audioSplitPoint
@onready var initialY = position.y

func _ready():
	

	
	
	if Engine.is_editor_hint():
		return
	
	
	stateData = load(stateResPath).getRowsAsArray()
	
	var t = Engine.physics_ticks_per_second
	var tickDur = 1.0/Engine.physics_ticks_per_second
	
	curSpread = initialSpread

	anims = get_node("AnimationPlayer")
	
	#anims.play("idle")
	if !InputMap.has_action("shoot"): InputMap.add_action("shoot")
	if !InputMap.has_action("reload"): InputMap.add_action("reload")

	
	if get_node("../../") != null:
		if get_node("../../").has_node("shootCast"):#if the parent node has a shoot cast we will defer to that
			cast = $"../../shootCast"
	else:
		if get_node_or_null("shootCast") != null:
			cast = $shootCast
	
	if cast != null:
		cast.add_exception($"../../../../")
		#cast.add_exception($"../../../../")

	isReady = true
	
	


func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	
	
	if curState == 0:
		isFiring = false
	else:
		isFiring = true
		
	
	
	if anims.current_animation == bringdownAnim:
		$muzzleFlash.visible = false
	
	#print(get_tree().get_frame())
	if shooter != null:
		if "processInput" in shooter:
			if shooter.processInput == false:
				return
	
	curStateWait -= delta

	#if $muzzleFlash.visible:
	#	$muzzleFlash.modulate = $AnimatedSprite3D.modulate
	
	
	if Input.is_action_pressed("shoot"):
		if anims.current_animation != bringdownAnim and anims.current_animation != bringupAnim:
			if (getCurAmmo() >0 or magSize <0) and curState == 0:
				changeState(shootStateID,delta)
			
	
	#print(curState)
	
	while curStateWait <= 0.003 and curState != -1:
		changeState(getNextState(),delta)
	


func getNextState() -> int:
	return stateData[curState]["Next"]
	
func hit(collider,point = null):
	if collider == shooter:
		return
	
	if collider.has_method("takeDamage"):
		
		var dict = {"amt":damage,"source":shooter}
		
		if point == null:
			dict["position"] = cast.get_collision_point()
			#collider.takeDamage({"amt":damage,"source":shooter,"position":cast.get_collision_point()})
		else:
			dict["position"] = point
			#collider.takeDamage({"amt":damage,"source":shooter,"position":point})
		
		if damageIsKnockBack:
			dict["knockback"] = damage
		
		collider.takeDamage(dict)
	else:
		var diff = cast.get_collision_point()-global_position
		var diffLen = diff.length()
		
		if wallHitSprite != null:
			spawnPuff(global_position+(diff.normalized()*diffLen*.99))
		createDecal(cast.get_collision_point(),collider,cast.get_collision_normal())
	

var shootCommit = false
var curShootTick = 0
var audioSplit = 0


func queueFire(delta):
	if Input.is_action_pressed("shoot"):
		curState = shootStateID

func checkFire(delta):
	if Input.is_action_pressed("shoot"):
		if anims.current_animation != bringdownAnim and anims.current_animation != bringupAnim:
			if shootStateDetour != -1:
				breakpoint
			changeState(shootStateID,delta)
		#curState = shootStateID
		#curStateWait = stateData[shootStateID]["Dur"]*(1.0/35)

func changeState(newStateId,delta):

	curState = newStateId
	var state = stateData[curState]
	curStateWait = state["Dur"]*(1.0/35) + min(0,curStateWait)
	
	if !state["Function"].is_empty():
		var callFunc = Callable(self,state["Function"])
		callFunc.call(delta)
		
	
	$AnimatedSprite3D.setMat(stateData[curState]["Frame"])
	
	
	
	if !stateData[curState]["flashFrame"].is_empty():
		var x = [stateData[curState]["flashFrame"]]
		$muzzleFlash.visible = true
		$muzzleFlash.setMat(stateData[curState]["flashFrame"])
	else:
		$muzzleFlash.visible = false
		#$muzzleFlash.visible = true
	#	breakpoint
	

func shootState(delta,fromCommit = false):
	
	if shooter == null:
		return
	
	var inventory

	if "inventory" in shooter:
		inventory = shooter.inventory
		if !inventory.has(ammoType):
			inventory[ammoType] = {"count":0}
			
			
		if inventory[ammoType]["count"] == 0 and magSize != -1:
			return
			
	audioCountdown = delta
	shootBullets()
		
	curShootTick = 1

	
	if getCurAmmo() >0 :
		inventory[ammoType]["count"] = max(0,inventory[ammoType]["count"]-ammoConsumedPerShot)
		curAmmoInMag = inventory[ammoType]["count"]
	anims.stop(true)
		

	if shooter != null:
		if shooter.get_node_or_null("AnimationPlayer") != null:
			var ap : AnimationPlayer = shooter.get_node("AnimationPlayer")
			ap.play("fire")
		
	soundPlayer.playFire()
	curShootTick += 1



func getCurAmmo() -> int: 
	if shooter == null:
		return 0
	
	if !shooter.inventory.has(ammoType):
		shooter.inventory[ammoType] = {"count":0}
	
	
	return shooter.inventory[ammoType]["count"]

	
func setCurAmmo(amount):
	if !shooter.inventory.has(ammoType):
		shooter.inventory[ammoType] = {"count":amount}
		
	shooter.inventory[ammoType] = {"count":amount}
		




func shootBullets():

	curFirstShotCooldown = firstShotCooldownMS
	
	if get_node_or_null("soundAlert") != null:
		for i in $soundAlert.get_overlapping_bodies():
			if "canHear" in i:
				i.canHear.append(shooter)
		
	
	if get_node_or_null("Area3D") != null:
		var area = $Area3D
		for body in area.get_overlapping_bodies():
			var pos : Vector3 = body.global_position
			pos.y = global_position.y
			hit(body,pos)
			
			if body != shooter:
				if "hp" in body:
					$AudioStreamPlayer3D.playImpact()
	
	for i in bulletPerShot:

		var shootVector = Vector3(0,0,1)
		
		if curfirstShotAccuracy <= 0:#no more accurate shots left
			#var spreX = randf_range(0,curSpread.x/2.0)
			
			var spreX = randfn(0,curSpread.x/3.4641)
			
			spreX = min(curSpread.x,spreX)
			
			var radiusX = tan(deg_to_rad(spreX))
			
			var angle = randfn(0,2*PI)
			
			
			var spreY = randfn(0,curSpread.y/3.4641)
			var radiusY = tan(deg_to_rad(spreY))
			
			var c = 1
			
			#var c = curve.interpolate(rand_range(0,1))

			#the idea is to pick a random point on a xy circle and scale it based on the spread
			#if spread is zero for both it will be (0,0,1)
			shootVector = Vector3(c*radiusX*cos(angle),c*radiusY*sin(angle),1)
			shootVector.normalized()
			
	

		
		shootVector *= -absRange
		cast.target_position = shootVector
		var p = null
		
		
		if projectile == "":#shoot bullet
			if get_node_or_null("Area3D") == null:
				cast.force_raycast_update()
				var collider = cast.get_collider()
				
				if collider != null:
					hit(collider)
					
		
		else:
			p = ENTG.spawn(get_tree(),projectile,shooter.global_transform.origin,WADG.transformToRotDegrees(shooter.global_transform),"Doom")
			
		if p != null:
			p.shooter = shooter
			p.visible = true
			var par = self

			p.add_collision_exception_with(shooter)
			p.transform = $"../".global_transform
			p.transform.origin -= p.transform.basis.z

		
	curSpread.x = min(curSpread.x+spreadPerShot.x,maxSpread.x)
	curSpread.y = min(curSpread.y+spreadPerShot.y,maxSpread.y)
	curfirstShotAccuracy = max(curfirstShotAccuracy-1,0)
	
	
	
func createDecal(pos,obj,normal):
	var spr = Sprite3D.new()
	spr.texture = bulletImpactTexture
	spr.add_to_group("decals")
	obj.add_child(spr)
	
	spr.global_transform.origin = pos
	spr.position+= normal*0.001
	
	var orthogonal
	
	if    normal == Vector3.UP   : orthogonal =  Vector3.RIGHT
	elif  normal == Vector3.DOWN : orthogonal =  Vector3.RIGHT
	else: orthogonal = Vector3.DOWN
	
	spr.look_at(pos + normal, orthogonal)
	
	if spr.has_method("reset_physics_interpolation"):
		spr.reset_physics_interpolation()



func playReload(delta):
	soundPlayer.playReload()

func playExtraSound1(delta):
	soundPlayer.playExtraSound1()
	
func playExtraSound2(delta):
	soundPlayer.playExtraSound2()

func spawnPuff(pos : Vector3 = Vector3.ZERO):
	wallHitSprite.one_shot = true
	var spr = Sprite3D.new()
	spr.billboard = StandardMaterial3D.BILLBOARD_FIXED_Y
	spr.texture = wallHitSprite.duplicate()
	spr.position = pos#-global_position
	spr.pixel_size = scaleFactor.x 
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.4
	timer.connect("timeout", Callable(spr, "queue_free"))
	timer.autostart = true
	spr.add_child(timer)

	$"/root".add_child(spr)
	

	
