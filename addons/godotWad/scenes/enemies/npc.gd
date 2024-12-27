@tool
extends CharacterBody3D

signal heightSetSignal
signal thicknessSetSignal

@export var initialHP: float  = 3
var dead : bool = false
var sum : int = 0
var count : int = 0
@export var npcName : String = "npc"
@export var height : float = 5: set = setHeight
@export var thickness : float: set = setThickness
@export var mass : float = 100
@export var projectile : String = ""
@export var meleeRange : float = 3
@export var meleeDamage : float = 20

@export var projectileRange : float = 5
#export var originAtFeet = true
@export var drops : Array[String]
@export var deleteOnDeath : bool= false
@export var painTimeMS : float= 0.114284
@export var stateDataPath : String = "res://addons/godotWad/resources/impState.tres"
@export var modulate : Color = Color.WHITE

@onready var initialColLayer = collision_layer
@onready var lookTimeoutCount = 20 
@onready var lookTimeoutTickSec = 0.8

var forceStateChange = false
var attackLastFrame = false
@onready var ASprite = get_node_or_null("visual/AnimatedSprite3D")
var APlayer : AnimationPlayer = null
var sounds  : AudioStreamPlayer3D = null
var stateData 
var reactionTime = 8
var movementTime = 8
var projectileNodeRefernce : Node = null
var onFloor = true
var stateChanged : bool = false
var target : Node = null
var potentialTarget : Node = null
var pTarget = null
var doTick : bool = false
var damageImunity = ["nukage"]
var hurtCooldown : float = 0
var createdBloodDecal : Array = []
var canHear : Array = []
var projectileSpawnPoints = []
var projectilesPerShot = 1
var activationDistance = 100
var isMoving = false
var matToSetThisFrame = null
var ambush = false
var castDamage = 12
var npcInteract = false
var pTargetSide = 0
var alwaysFire = false
var pAnim : String = ""
var pFrame : int = 0
var pWidth : int = 0
var movementDir = Vector3.ZERO
var facingDir = movementDir
var pFacingDir = null
var instancedProjectile : Node = null
var rezTarget = null
var activeRange = 1000
var knockBack = Vector3.ZERO
@export var mapHandlesTooFar2 : bool = true
var enabled = true
@export var entityName: String
@export var gameName : String

@export var attackStateId : int= 10
@export var painStateId : int= 14
var curSpriteId : int= 0
var lastMovementDir : Vector3 = Vector3.ZERO
var moveCounter = 0
#var walkStates = []
@export var deadStateId: int = 16
@export var chaseStateId: int = 2
@export var gibStateId : int= -1
@export var meleeStateId : int= -1
@export var reviveStateId : int = -1
@export var reviverState : int = -1

var stuckDir = null
var curReviving = null
@export var defaultProjectileHeight = 32
@export var speed : float= 8
@export var chargeSpeed : float = 8
@onready var colShape = $CollisionShape3D
@export var continuousFire : bool= false
@onready var targetPos = position
@export var painChance : float= 0.7930
@export var hitDecal : AnimatedTexture  = null
@export var hitDecalSize = 1.0
@onready var isEditor : bool =  Engine.is_editor_hint()
@onready var castWeapon : Node = get_node_or_null("castWeapon") 
@onready var cast : RayCast3D = $cast
@onready var hp : float = initialHP
@onready var navigationLogic : Node = get_node_or_null("navigationLogic")
@onready var rezCheck : Area3D = null
@export var flying = false

#@onready var internalAngle = rotation.y
var nextFrameImpulse = Vector3(0,0,0)
var charging = false
var canCharge = false
var movementBlocked = []

enum STATE {
	WALK,
	ATTACK,
	DEAD, 
	HURT,
}

var state = STATE.WALK
var pState = null
var map : Node = null
var broadphaseThisTick : bool = false
var tree : SceneTree

var onGround : bool = false
var pOnGround : bool = false
var soundManager = null

var velo : Vector3 = Vector3.ZERO
var viewport : Viewport = null
@onready var initialState = 0
@onready var curState = initialState : set = stateSetter
@onready var curStateWait = 0

func _init():
	set_meta("originAtFeet",true)

func _ready():
	#queue_free() dont't put this before edtior check, it will wipe the file
	if isEditor: 
		return

	tree = get_tree()
	soundManager = ENTG.getSoundManager(tree)
	viewport = get_viewport() 
	
	if flying:
		$movement.gravity = 0
	
	spawnEntityOverlaps()
	if has_meta("ambush"):
		ambush = get_meta("ambush")
	 
	stateData = load(stateDataPath).getRowsAsArray()
	
	for i in stateData:
		if i["Function"] == "charge":
			canCharge = true
			break
	
	
	ASprite.curAnimation ="A"
	facingDir = Vector3(0,0,-1).rotated(Vector3.UP,rotation.y)
	
	rotation = Vector3.ZERO
	
	$VisibleOnScreenNotifier3D.screen_entered.connect(ASprite._on_VisibilityNotifier_camera_entered)

	if get_node_or_null("rezCheckArea") != null:
		rezCheck = $rezCheckArea


	
	if castWeapon != null:
		castWeapon.damage = castDamage
		
	
	APlayer = $AnimationPlayer
	sounds = $AudioStreamPlayer3D

	
	
	for i in get_children():
		if i.get_name().find("_") != -1:
			if i.get_name().split("_")[0] == "projectileSpawn":
				projectileSpawnPoints.append(i)
				


	if map == null:
		map =  get_node_or_null("../../")
	
	if !("aiEnts" in map):
		map = null
	
	if map == null:
		return
	
	if map != null:
		map.registerAi(self)
	

	
	
	map.registerBirth(npcName)



func disable():
	
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if is_instance_valid(cast):
		cast.enabled = false
	$CollisionShape3D.disabled = true
	$movement.setShapeCasts(false)
	enabled = false

func enable():
	
	process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(cast):
		cast.enabled = true
	$CollisionShape3D.disabled = false
	enabled = true

func charge(delta):
	charging = true
	playAttack()
	
var line = null


func drawFacingDir():
	if line != null:
		line.queue_free()
		line = null
	
	line = WADG.drawLine(self,Vector3(0,height/2.0,0),Vector3(facingDir.x,facingDir.y+height/2.0,facingDir.z))

var spheres = []

func drawSpawnPoints():
	
	for i in spheres:
		if is_instance_valid(i):
			i.queue_free()
	
	for i in projectileSpawnPoints:
		if is_instance_valid(i):
			spheres.append(WADG.drawSphere(get_tree().get_root(),i.global_position))
		

func _physics_process(delta):
	
	
	
	if isEditor: 
		return

	#queue_free()
	
	#if is_instance_valid(cast):
	#	cast.queue_free()
	#return
	
	if facingDir != Vector3.ZERO and pFacingDir != facingDir:
		pFacingDir = facingDir
		if is_instance_valid(ASprite):
			ASprite.basis = ASprite.basis.looking_at(-facingDir)
	matToSetThisFrame = null
	
	
	
	if !mapHandlesTooFar2:
		if is_instance_valid(cast) and curState != -1:
			if isPlayerTooFar():
				disable()
				return
			else:
				enable()

	
	
	
	for i in createdBloodDecal:
		if is_instance_valid(i):
			createdBloodDecal.erase(i)
	
	
	if instancedProjectile != null:
		if is_instance_valid(instancedProjectile):
			if "curseTarget" in instancedProjectile:
				if !canSeeNodeCast(target):
					instancedProjectile.curseTarget = null
	
	
	
	if map != null:
		delta *= 2
		if doTick == false:
			return
		doTick = false
	
	
	curStateWait -= delta
	
	
	if (curStateWait <= 0 and curState != -1 and (!charging or dead)) or forceStateChange:
		procState(stateData[curState],delta)

	reactionTime -= 1
	if curState == attackStateId or curState == meleeStateId:
		isMoving = false
		$movement.hitWallLastFrame = false
	
	#if dead and curState != -1:
	#	breakpoint

	if dead:
		if matToSetThisFrame != null:
			if is_instance_valid(ASprite):
				ASprite.setMat(matToSetThisFrame)
		return
		
	
	
	if stuckDir != null:
		if $navigationLogic.isReachable( global_position + stuckDir):
			var nextP = $navigationLogic.get_next_path_position()
			stuckDir = null
		
	

	#if walkStates.has(curState):
	knockBack += nextFrameImpulse
	if isMoving:
		var checkPos = global_position + (movementDir).normalized()*sqrt(2*thickness)
		#n = WADG.drawSphere($/root,checkPos)
		
		if !flying:
			if !$navigationLogic.isReachable(checkPos):
				velocity.x = 0
				velocity.z = 0
				moveCounter = 0
			else:
				velocity.x = knockBack.x + movementDir.x * speed
				velocity.z = knockBack.z + movementDir.z * speed
		else:
			velocity.x = knockBack.x + movementDir.x * speed
			velocity.z = knockBack.z + movementDir.z * speed
	else:
		
		velocity.x = 0
		velocity.z = 0
	
#-------
	if charging: velocity = facingDir * chargeSpeed 
	
	if flying:
		if target != null:
			if (target.position.y - position.y) < -1:
				velocity.y = -speed
			
			if (target.position.y - position.y) > 1:
				velocity.y = speed
			
	if !dead:
		
		if stateData[curState]["Function"] == "chase":
			isMoving = true
		else:
			isMoving = false
		
		
		$movement.move(delta)
	
	
	
	if $movement.hitWallLastFrame and charging: 
		for i in $movement.touching:
			if i.has_method("takeDamage"):
				i.takeDamage({"source":self,"amt":meleeDamage})

		moveCounter = randi()%16
		charging = false
		
		curState = chaseStateId
		curStateWait = stateData[curState]["Dur"]*(1.0/35)
		attackLastFrame = true
		forceStateChange =true
	else:
		forceStateChange = false
	
	if matToSetThisFrame != null:
		ASprite.setMat(matToSetThisFrame)
		
	nextFrameImpulse = Vector3.ZERO
	knockBack *= 0.5
	
func procState(state : Dictionary,delta : float):
	
	curState = state["Next"]
	
	if state["Function"] == "chase":
		isMoving = true
	else:
		isMoving = false
	
	curStateWait = state["Dur"]*(1.0/35)
	
	if !state["Function"].is_empty():
		var callFunc = Callable(self,state["Function"])
		callFunc.call(delta)
	
	matToSetThisFrame = state["Frame"]
	if is_instance_valid(ASprite):
		ASprite.setMat(state["Frame"])
	
	
	
func playGib(delta):
	$AudioStreamPlayer3D.playGib()

func idle(delta):
	attackLastFrame = false
	var foundPlayer = look() 
	if !foundPlayer:
		return

	if !canCharge:
		get_tree().create_timer(lookTimeoutTickSec).timeout.connect(lookTimeout.bind(lookTimeoutCount,target))
	
	if is_instance_valid(cast):
		cast.targetNode = null
	
	if soundManager == null:
		$AudioStreamPlayer3D.playAlert()
	else:
		var t = $AudioStreamPlayer3D.alertSounds
		if t.size() >0:
			soundManager.play($AudioStreamPlayer3D.alertSounds[0],self,{"deleteOnFinish":true})
		
	curState = chaseStateId

func face(delta):
	
	if target == null:
		return
	
	attackLastFrame = false
	
	var toTarget =(target.global_position -global_position).normalized()
	facingDir = toTarget.normalized()
	
	#var orindal = closesOrdinal(target,toTarget)
	#rotation.y = -Vector2.UP.angle_to(Vector2(toTarget.x,toTarget.z))


func chase(delta):
	
	moveCounter -= 1
	
	
	if rezCheck!= null:
		runRezCheck()
		
	
	
	if !is_instance_valid(target):
		curState = initialState
		attackLastFrame = false
		target = null
		return
	
	if "dead" in target:
		if target.dead:
			curState = initialState
			target = null
			return
	
	var distTo : float =  global_position.distance_to(target.position)
	
	
	if meleeRange >= 0 and distTo < meleeRange: #and !attackLastFrame:# and moveCounter <= 0:
		if meleeStateId == -1:#if we don't have a dedicated melee attack just use the general attack state 
			curState = attackStateId
		else:
			curState = meleeStateId
		
		curStateWait = stateData[curState]["Dur"]*(1.0/35) + delta
		return
	
	
	distTo -= 1.984 #decrease by 64
	
	
	if meleeRange <0:
		distTo -= 3.968
	
	if reactionTime > 0 or moveCounter > 0:
		if attackLastFrame:
			attackLastFrame = false
		return
	distTo = min(6.2,distTo)#cap at 200
	
	var rand = randf()*7.905#0-255
	if rand > distTo and projectileRange != 0 and  ((global_position.distance_to(target.position) < projectileRange) or projectileRange < 0):#negative range means infite projectile range
		if !attackLastFrame:
			if canSeeNodeCast(target):
				curState = attackStateId
				curStateWait = stateData[curState]["Dur"]*(1.0/35) + delta
				return


	
	movementDir = move(target.global_position,delta)
	facingDir = movementDir
	if (randf() * 100) <= 0.6883:
		sounds.playSearch()
	
	
func move(targetPos:Vector3,delta) -> Vector3:
	npcInteract = true#for opening doors
	
	
	if moveCounter > 0:
		movementDir  

	moveCounter = randi()%16
	
	var allDirs : Array[Vector3]= [Vector3(1,0,0),Vector3(1,0,1),Vector3(0,0,1),Vector3(-1,0,1),Vector3(0,0,-1),Vector3(-1,0,-1),Vector3(0,0,-1),Vector3(1,0,-1)]
#	var oppDir = Vector3(sign(global_basis.z.x),0,sign(global_basis.z.z))
	var oppDir = -movementDir
	allDirs.erase(oppDir)
	
	
	
	var diff = global_position - targetPos
	diff.y = 0
	var absDiff = abs(diff)
	
	
	if absDiff.x <= 3.1: 
		diff.x = 0
	if absDiff.z <= 3.1:
		diff.z = 0
	
	if diff.x != 0 and diff.z != 0 :#try to move both directions
		var testDir = Vector3(sign(diff.x),0,sign(diff.z))
		
		if testDir != oppDir:
			if !flying:
				if isReachable(-testDir,delta):
					return -testDir
			else:
				return -testDir
			allDirs.erase(-testDir)
	
	var closestAxis = Vector3(sign(diff.x),0,0)#new we try to move an a signle direction which if first the closest axis and then the furthest one
	var furthestAxis =  Vector3(0,0,sign(diff.z))
	
	if absDiff.z < absDiff.x:
		closestAxis =  Vector3(0,0,sign(diff.z))
		furthestAxis =  Vector3(sign(diff.x),0,0)
		
	
	if furthestAxis.length() != 0:
		if -furthestAxis != oppDir:
			if isReachable(-furthestAxis,delta):
				return -furthestAxis
			
			allDirs.erase(-furthestAxis)
	
	if closestAxis.length() !=0:# if we actually need to move in this direction
		if -closestAxis != oppDir:
			if isReachable(-closestAxis,delta):
				return -closestAxis
		
			allDirs.erase(-closestAxis)
	
	
	if diff.x == 0 and !diff.z == 0:#if on x/-x axis check the diagnals
		var testDir = -Vector3(1,0,sign(diff.z))
		
		if testDir != oppDir:
			if isReachable(testDir,delta):
				return testDir
		allDirs.erase(testDir)
		
		testDir = -Vector3(1,0,sign(diff.z))
		if testDir != oppDir:
			if isReachable(Vector3(testDir),delta):
				return testDir
				
		allDirs.erase(testDir)
	
	if diff.x != 0 and diff.z == 0:#if on z/-z axis check the diagnals
		var testDir = -Vector3(sign(diff.x),0,1)
		
		if testDir != oppDir:
			if isReachable(testDir,delta):
				return  testDir
		allDirs.erase(testDir)
		
		testDir = -Vector3(sign(diff.x),0,-1)
		if testDir != oppDir:
			if isReachable(Vector3(testDir),delta):
				return testDir
				
		allDirs.erase(testDir)
	
	if movementDir.length() != 0:
		if isReachable(movementDir,delta):#things are not looking good so we just move in last frames direction
			return movementDir
		
		allDirs.erase(movementDir)
	
	allDirs.shuffle()
	
	for i : Vector3 in allDirs:
		if isReachable(i,delta):
			movementDir = i
			return i
		
		
	if isReachable(oppDir,delta):
		return oppDir
		
	return Vector3.ZERO
	


func getFreeDir(initDir,initAngle,delta):
	var td = rad_to_deg(initAngle)
	var checkDir = initDir
	
	
	var checkSign = 1
	if randi()%1 == 1:
		checkSign = -1
	
	
	for i in range(0,135,45):
		
		var checkAngle = initAngle+deg_to_rad(i)
		
		
		if is_equal_approx(checkAngle,PI):
			continue
			
		
		checkAngle = initAngle + deg_to_rad(i)*checkSign
		var checkAngleD = rad_to_deg(checkAngle)

		if checkAngle < 0: checkAngle += TAU
		if checkAngle > TAU: checkAngle -= TAU
			
		checkDir = Vector3.FORWARD.rotated(Vector3.UP,rotation.y+checkAngle)
		
		
		var checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		if $navigationLogic.isReachable(checkPos):
			return checkDir
			
		
		checkAngle = initAngle + deg_to_rad(i)*checkSign
		#print(checkAngleD)
		if checkAngle < 0: checkAngle += TAU
		if checkAngle > TAU: checkAngle -= TAU
			
		checkDir = Vector3.FORWARD.rotated(Vector3.UP,rotation.y+checkAngle)
		
		
		
		checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		if $navigationLogic.isReachable(checkPos):
			return checkDir
		
	
	
	
	#if initAngle >= PI-0.01:
		#var rand = randi()%1
		#var checkSign = 1
		#
		#if rand == 1:
			#checkSign = -1
		#
		#checkDir = Vector3.FORWARD.rotated(Vector3.UP,internalAngle-deg_to_rad(45)*checkSign)
		#var checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		#if $navigationLogic.isReachable(checkPos):
			#return checkPos
			#
		#checkDir = Vector3.FORWARD.rotated(Vector3.UP,internalAngle+deg_to_rad(45)*checkSign)
		#checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		#if $navigationLogic.isReachable(checkPos):
			#return checkPos
			#
		#checkDir = Vector3.FORWARD.rotated(Vector3.UP,internalAngle-deg_to_rad(90)*checkSign)
		#checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		#if $navigationLogic.isReachable(checkPos):
			#return checkPos
			#
		#checkDir = Vector3.FORWARD.rotated(Vector3.UP,internalAngle-deg_to_rad(90)*checkSign)
		#checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		#if $navigationLogic.isReachable(checkPos):
			#return checkPos
			#
		#checkDir = Vector3.FORWARD.rotated(Vector3.UP,internalAngle-deg_to_rad(135)*checkSign)
		#checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		#if $navigationLogic.isReachable(checkPos):
			#return checkPos
			#
		#checkDir = Vector3.FORWARD.rotated(Vector3.UP,internalAngle-deg_to_rad(135)*checkSign)
		#checkPos = global_position + ( checkDir.normalized() * speed *delta).normalized()*sqrt(2*thickness)
		#if $navigationLogic.isReachable(checkPos):
			#return checkPos
			
	
	
	

func attack(delta):
	face(delta)
	fire()
	#lastMovementDir = Vector3.ZERO
	
	attackLastFrame = true
	return
	
func melee(delta):
	fire(true)
	attackLastFrame = true
	return
	
func takeDamage(dict):
	var source = null
	reactionTime = 0
	
	
	if dict.has("specific"):
		var immune = true
		for i in dict["specific"]:
			if !damageImunity.has(i):
				immune = false
				
		if immune:
			return
	
	if dict.has("source"):source = dict["source"]
	if dict.has("amt"): hp -=  dict["amt"]
	if dict.has("everyNframe"): 
		var t = Engine.get_physics_frames() % dict["everyNframe"]
		if Engine.get_physics_frames() % dict["everyNframe"] != 0:
			return
	
	if source != null:
		if source.name == "castWeapon":
			breakpoint
	
	if hp >0:
		
		var r = randf()
		if r < painChance:
			curState = painStateId
			curStateWait = stateData[curState]["Dur"]*(1.0/35)
		
	elif !dead:
		if hp <= -((initialHP*2)+1):
			curState = gibStateId
			
			if curState == -1:
				curState = deadStateId
			
			curStateWait = stateData[curState]["Dur"]*(1.0/35)
		else:
			curState = deadStateId
			curStateWait = stateData[curState]["Dur"]*(1.0/35)
		
		state = STATE.DEAD
		dead = true
		
	
	if source == null:
		return
	if dict.has("knockback"):
		nextFrameImpulse += dict["knockback"]*((global_position - source.global_position)*50)/mass
	
	#velocity += diff
	
	if target == source:
		pass
	
	elif source != null and source != self:
		pTarget = source
		target = source
		curState = chaseStateId
		count = 0
	
	if projectileRange != 0:
		projectileRange = -INF
	
	var decalPos = Vector3.ZERO
	
	if dict.has("position"):
		decalPos = dict["position"]
		
	spawnBlood(decalPos)


func stateWalk() -> void:
	
	if stateChanged:
		APlayer.play("idle")


	
	var targetValid : bool = is_instance_valid(target)
	
	if target != null and targetValid:
		if "hp" in target:
			if target.hp <= 0:
				target = null
	
	if target != null and targetValid:

		#look_at(target.position,Vector3.UP)
		rotation_degrees.x = 0
		
		if count > 0:
			count -= 1
			return
		
		var r : float = (randi() % 80)
		
		
		if (r == 56 or alwaysFire) and lookBroadphaseCheck(target.position,facingDir):
			if continuousFire:
				alwaysFire = true
			if canSeeNodeCast(target):
				state = STATE.ATTACK
		
		
		
		var distTo : float =  position.distance_to(target.position)
		
		if distTo <= meleeRange or (distTo <= projectileRange and projectileRange > 0):
			state = STATE.ATTACK
		
		
		if navigationLogic != null:
			if distTo > meleeRange:
				targetPos = navigationLogic.tick()
			else:
				targetPos = null
	
	
	if target != null:
		if targetPos != null:
			velo.x = (targetPos-position).normalized().x*speed
			velo.z = (targetPos-position).normalized().z*speed
		
		

func playStomp(delta) -> void:
	sounds.playStomp()

func stateMelee() -> void:
	
	if stateChanged == true:
		APlayer.play("melee")
		castWeapon.fireCustomDmg(14)
		
	if !APlayer.is_playing():
		state = STATE.WALK

func stateFire() -> void:
	

	if stateChanged == true:
		APlayer.play("fire")

		
	if !APlayer.is_playing():
		state = STATE.WALK

func deadState(delta,instant = false) -> void:
	
	
	

		#APlayer.stop(false)
	ASprite.curAnimation = "A"#only front sprites have death anims
	matToSetThisFrame = stateData[curState]["Frame"]
		#APlayer.play("die")
		
	for i in createdBloodDecal:
		if is_instance_valid(i):
			i.queue_free()

	dead = true
		
		
	if !drops.is_empty() and !instant:
		var spawnPos = global_position
		spawnPos.y += height/2.0
		var pos = Vector3.ZERO
		
		var t = Transform3D.IDENTITY
		t.basis.z = -facingDir.normalized()
		
		for drop in drops:
			
			var ent = ENTG.spawn(get_tree(),drop,spawnPos+pos,t.basis.get_euler(),gameName,get_parent())
			
			if ent != null:
				if is_instance_valid(target):
					if "target" in ent:
						ent.target = target
			
			pos += Vector3(1,0,0)
			
			
		
		
	if map != null:
		map.registerDeath(npcName)
		#map.set_meta(npcName,map.get_meta(npcName)-1)


	if deleteOnDeath:
		queue_free()
	else:
		deleteNodes()
		
	var node : RayCast3D = RayCast3D.new()
	node.set_script(load("res://addons/godotWad/scenes/dropper.gd"))
	node.setHeight(min(height/2.0,0.1))
	add_child(node)
	


func checkFire(delta):
	if target == null:
		curState = 2
		curStateWait = stateData[curState]["Dur"]*(1.0/35)
		return
	
	cast.target_position = target.global_position - global_position
	if !canSeeNodeCast(target):
		
		curState = 2
		curStateWait = stateData[curState]["Dur"]*(1.0/35)

func deathDelete():
	
	
	if deleteOnDeath:
		pass
		#queue_free()
		
	else:
		deleteNodes()

func revive() -> void:
	#hp = initialHP
	#dead = false
	#collision_layer = initialColLayer
	if reviveStateId != -1:
		curState = reviveStateId
	
	#ENTG.spawn(get_tree(),entityName,global_position,rotation,gameName,get_parent())


func deleteNodes():
		
	for i in get_children():
		var className = i.get_class()
		
		
		
		if(className != "AudioStreamPlayer3D" and i.name != "AnimatedSprite3D" and i.name != "footCast" and className != "VisibleOnScreenNotifier3D") and i.name != "movement" and i.name != "visual":
			if className == "CollisionShape3D":
				collision_layer = 0
				set_collision_layer_value(13,true)
				continue
			i.queue_free()


var pCameraPos : Vector3 = Vector3(0,0,0)
var pCameraForward : Vector3 = Vector3(0,0,0)

	
	
func setHeight(h):
	
	if h < 0:
		h = 0.01
	
	height = h
	
	if is_instance_valid(cast):
		cast.position.y = height * 0.8
	
	if get_node_or_null("CollisionShape3D") == null:
		return
	
	WADG.setCollisionShapeHeight($CollisionShape3D,h)
	
	$CollisionShape3D.position.y = height /2.0
	$VisibleOnScreenNotifier3D.aabb.size.y = h
	emit_signal("heightSetSignal")
	$cast.position.y = height
func setThickness(thick):
	thickness = thick
	if get_node_or_null("CollisionShape3D") != null:
		WADG.setShapeThickness($CollisionShape3D,thickness)
		
	if get_node_or_null("footCast") != null:
		WADG.setShapeThickness($footCast,thickness)
	
	
	
	emit_signal("thicknessSetSignal")
	
	
	var vis : VisibleOnScreenNotifier3D = get_node_or_null("VisibleOnScreenNotifier3D")
	
	if vis != null:
		
		vis.aabb.position.x =-thickness
		vis.aabb.position.z =-thickness
		vis.aabb.size.x =thickness*2
		vis.aabb.size.z = thickness*2
				

		


func look() -> bool:
	
	
	if target == null:
		for i in canHear:
			if is_instance_valid(i):
				if i.is_in_group("player"):
					if !ambush:
						target = i
						canHear = []
						return true
					else:
						cast.target_position = i.global_position - global_position
						cast.force_raycast_update()
						
						if cast.get_collider() == i:
							target = i
							return true
			
				
	
	
	
	
	canHear = []
	
	var allPlayers : Array = get_tree().get_nodes_in_group("player")
	var skip : bool = true
	
	for node in allPlayers:
		var diff : Vector3 = node.position - position
		
		if diff.length() <= 100:
			skip = false
			
	if skip ==  true:
		return false
	
	var forward : Vector3 = get_global_transform().basis.z
	
	
	if target == null:
		for node : Node in allPlayers:
			var diff : Vector3 = node.position - position
			if "hp" in node:
				if node.hp <= 0:
					continue
			
			
			if diff.length() <= 2:
				target = node
				return true
			
			if lookBroadphaseCheck(node.position,facingDir):
				if canSeeNodeCast(node):
					target = node
					#cast.targetNode = null
					return true
					
			#else:
			#	cast.targetNode = null
			
	return false


var pDiff : Vector3 = Vector3(0,0,0)
var pForwad : Vector3 = Vector3(0,0,0)
var pAcos : float = -9939
var pDot : float = 0


func lookBroadphaseCheck(targetPos :Vector3,forward : Vector3) -> bool:
	
	if cast == null:
		broadphaseThisTick = false
		return false
	
	var diff : Vector3 = targetPos - position
	diff = (diff).normalized()
	var forwardDot : float = diff.dot(forward)
		

	if forwardDot < 0.00:
		cast.enabled = false
		broadphaseThisTick = false
		return false
	
	
	var aCosVal : float
		
	if pDiff == diff and pForwad == forward:
		aCosVal = pAcos
	else:
		if abs(forwardDot-pDot) > 0.03:
			pDot = forwardDot
			aCosVal =  acos(forwardDot)
			pAcos = aCosVal
		
	pDiff = diff
	pForwad = forward
		
	
	if aCosVal <= PI:
		broadphaseThisTick = true
		return true
		
	cast.enabled = false
	broadphaseThisTick = true
	return false


func fire(forceMelee = false):
	var p = null
	
	if !is_instance_valid(target):
		return
	
	var distTo : float =  global_position.distance_to(target.position)
	
	if distTo <= meleeRange or forceMelee:
		if is_instance_valid(castWeapon):
			castWeapon.fire(target.position,forceMelee)
		
		return
		
	
		
	if !projectile.is_empty():
		if projectileSpawnPoints.is_empty():
			var t = global_transform
			t.origin.y -= height*0.8
			t.origin.y = global_position.y + defaultProjectileHeight
			t.basis = basis.looking_at(facingDir,Vector3.UP)
			
			p = createProjectile(projectile,t)
			
			if projectileRange == -INF:
				projectileRange = -1
				
			instancedProjectile = p

			
			if "curseTarget" in p:
				p.curseTarget = target
				
		else:
			for i in projectileSpawnPoints:
				var t : Transform3D = i.global_transform
				t.basis = basis.looking_at(facingDir,Vector3.UP)
				t.origin.y -= height*0.8
				t.origin.y = global_position.y + defaultProjectileHeight
				
				p = createProjectile(projectile,t)
				p.transform

	
	elif projectileRange != 0:
		castWeapon.fire(target.global_position)



func createProjectile(projStr,projTransform):
	#var p : Node3D = ENTG.fetchEntity(projStr,get_tree(),"Doom",false)
	var p : Node3D = ENTG.spawn(get_tree(),projectile,global_transform.origin,WADG.transformToRotDegrees(projTransform),gameName,get_parent())
	
	if p == null:
		return null
	
		
	p.visible = true

	if "add_collision_exception_with" in p:
		p.add_collision_exception_with(self)

	p.position.y += defaultProjectileHeight
	if "shooter" in p:
		p.shooter = self
	
	var transform = Transform3D.IDENTITY
	#transform.basis.z = -facingDir.normalized()
	

	p.transform = projTransform

	
	if "shooter" in p:
		p.shooter = self
		
	if "charging" in p:#lost souls
		p.charging = true
		p.facingDir = facingDir
		#p.playAttack()
	return p



func canSeeNodeCast(node : Node) -> bool:
	
	if node == null:
		return false
	
	if cast == null:
		return false
	
	var c = cast.targetNode 
	var s = cast.target_position
	var t = cast.enabled
	
	
	
	if cast.targetNode != node:
		cast.targetNode = node
		#return false
	
	cast.enabled = true
	cast.force_raycast_update()
	if cast.get_collider() == node:
		cast.enabled = false
		return true
	
	
	return false


func isPlayerTooFar() -> bool:
	for node in tree.get_nodes_in_group("player"):
		var diff : Vector3 = node.position - position

		if diff.length() <= activationDistance:#100^2
			return false
			
	return true

func spawnBlood(pos : Vector3 = Vector3.ZERO):
	var spr = Sprite3D.new()
	spr.billboard = StandardMaterial3D.BILLBOARD_FIXED_Y
	spr.texture = hitDecal.duplicate()
	spr.position = pos#-global_position
	spr.pixel_size = hitDecalSize * 1
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.3
	timer.connect("timeout", Callable(spr, "queue_free"))
	
	timer.autostart = true
	spr.add_child(timer)
	
	createdBloodDecal.append(spr)
	$"/root".add_child(spr)

func lightLevel():
	
	if map == null:
		return
	
	
	var posXZ = Vector2(global_position.x,global_position.z)
	var p = WADG.getSectorInfoForPoint(map,posXZ)
	
	var light = p["light"]/255.0
	ASprite.modulate = light
	

func playHurt(delta):
	charging = false
	sounds.playHurt()
	
func playDeath(delta):
	sounds.playDeath()

func _on_visible_on_screen_notifier_3d_screen_entered():
	if is_instance_valid(ASprite):
		ASprite.visible = true



func _on_visible_on_screen_notifier_3d_screen_exited():
	if is_instance_valid(ASprite):
		ASprite.visible = false

func closesOrdinal(target,targetToMe):
	var cameraForward : Vector3 = targetToMe

	var forward : Vector3 = -target.global_transform.basis.z
	var left : Vector3 = target.global_transform.basis.x
	
	var forwardDot : float = forward.dot(cameraForward)
	
	

	
	var anim : String = ASprite.curAnimation
	var newAnim  = anim
	
	

	if forwardDot < -0.85:
		#return  "front"
		return  Vector3.BACK
		
	elif forwardDot > 0.85:
		#return  "back"
		return Vector3.FORWARD
		
	else:
		var leftDot : float = left.dot(cameraForward)
		if leftDot > 0:#left
			if abs(forwardDot) < 0.3:
				return Vector3.RIGHT
				#return  "left"
			elif forwardDot < 0:
				return Vector3.RIGHT + Vector3.BACK
				#return  "frontLeft"
			else:
				#return  "backLeft"
				return Vector3.RIGHT + Vector3.FORWARD
		else:#right
			if abs(forwardDot) < 0.3:
				#return  "right"
				return Vector3.LEFT
			elif forwardDot < 0:
				#return  "frontRight"
				return Vector3.LEFT + Vector3.BACK
			else:
				return Vector3.LEFT + Vector3.FORWARD
				#return  "backRight"

	
func getSide(pos:Vector2,lineA,lineB):
	
	var tScale = Vector2(map.scale.x,map.scale.z)

	var playerPos = Vector2(pos.x,pos.y)
	var diff = (lineB-lineA)
	var norm = Vector2(diff.y,-diff.x)
	var dir = norm.dot(playerPos-lineA)
	return dir

var theLine = null

func getTargetSide(udpate):
	if target == null:
		return 0
	var lastMovementDirLineA = global_position + (lastMovementDir).rotated(Vector3.UP,deg_to_rad(90))
	var lastMovementDirLineB = global_position - (lastMovementDir).rotated(Vector3.UP,deg_to_rad(90))
	
	#lastMovementDirLine.y = height / 2.0
	var lastMovementDirLineXZ = Vector2(lastMovementDirLineA.x,lastMovementDirLineA.z)
	if is_instance_valid(theLine):
		theLine.queue_free()
	#theLine = WADG.drawLine($/root, global_position,lastMovementDirLineA)
	#theLine = WADG.drawLine($/root,global_position +lastMovementDirLine,-(global_position +lastMovementDir))
	return sign(getSide(Vector2(target.global_position.x,target.global_position.z),Vector2(global_position.x,global_position.z),Vector2(lastMovementDirLineA.x,lastMovementDirLineA.z)))

#var ball = null

func isReachable(dir,delta):
	var hm : Vector3 =  ( dir * speed *delta)+(dir*sqrt(2*thickness))
	
	
	var checkPos = global_position + hm
		
		
	#if is_instance_valid(ball):
		#ball.queue_free()
	#ball = WADG.drawSphere($/root,checkPos)
	

	
	if !flying:
		if is_instance_valid(navigationLogic):
			if !$navigationLogic.isReachable(checkPos):
				return false
	
	return !test_move(global_transform,hm)
	
	
	
	
	var reachable = navigationLogic.isReachable(global_position + hm)
	
	if !reachable:
		return false
		
	var pos = navigationLogic.get_next_path_position()
	
	var diff = pos - global_position
	
	if diff.y > 0.5:
		return false
	
	return true
	
func playAttack():
	sounds.playAttack()

func runRezCheck():
	
	var toCheck : Array[Node] = []
	
	for i in rezCheck.get_overlapping_bodies():
		if i == self: continue
		
		if "reviveStateId" in i:
			toCheck.append(i)
	
	
	for body in toCheck:
		
		if !body.dead:
			continue
		
		if "curState" in body:
			if body.curState != -1:
				continue
		
		if $navigationLogic.isReachable(body.global_position):
			curState = reviverState
			curReviving = body
		

func reviveWaitOver(delta):
	if is_instance_valid(curReviving):
		if curReviving.dead:
			curReviving.revive()
		
	curReviving = null

func respawn(delta):
	
	
	var ent : Node3D = ENTG.spawn(get_tree(),entityName,global_position,rotation,gameName,get_parent())
	await ent.ready
	ent.facingDir = facingDir
	
	queue_free()
	
func serializeSave():
	var dict : Dictionary = {}
	
	dict["hp"] = hp
	dict["curState"] = curState
	dict["target"] = ""
	dict["facingDirX"] = facingDir.x
	dict["facingDirY"] = facingDir.y
	dict["facingDirZ"] = facingDir.z
	dict["enabled"] = enabled
	
	if target != null:
		if is_instance_valid(target):
			dict["target"] = get_path_to(target)
	
	return dict
	
func serializeLoad(dict : Dictionary):
	hp = dict["hp"]
	curState = dict["curState"]
	
	if hp <= 0:
		deadState(0,true)
	
	
	if !dict["target"].is_empty():
		var oldTargetPath = dict["target"]
		if get_node_or_null(oldTargetPath) != null:
			target = get_node_or_null(oldTargetPath)
	
	facingDir.x = dict["facingDirX"] 
	facingDir.y = dict["facingDirY"] 
	facingDir.z = dict["facingDirZ"] 
	
		

func lookTimeout(count,node):
	
	if node == null or cast == null:
		return
	
	if !is_instance_valid(node):
		return
	
	
	if !is_instance_valid(cast):
		return
	
	cast.targetNode = node
	
	await cast.physicsFrameSignal
	
	
	if target == null:
		curState = initialState
		attackLastFrame = false
		target = null
		
	if canSeeNodeCast(target):
		get_tree().create_timer(lookTimeoutTickSec).timeout.connect(lookTimeout.bind(lookTimeoutCount,node))
	
	elif count >0:
		get_tree().create_timer(lookTimeoutTickSec).timeout.connect(lookTimeout.bind(count-1,node))
	else:
		curState = initialState
		attackLastFrame = false
		target = null
		
		cast.targetNode = null
		
func stateSetter(nextState):
	if dead:#this is hack, it may cause problems later
		if nextState < curState and nextState >= 0:
			return
	
	curState = nextState

func spawnEntityOverlaps():
	var col = KinematicCollision3D.new()
	var b = test_move(global_transform,Vector3(0,0.001,0),col)
	
	if col == null:
		return
	
	for i in col.get_collision_count():
		var collider = col.get_collider(i)
		if collider is CharacterBody3D:
			add_collision_exception_with(collider)
			collider.add_collision_exception_with(self)
	

func delete():
	queue_free()
