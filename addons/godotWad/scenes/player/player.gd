@tool
extends CharacterBody3D

var curMap

signal heightSetSignal
signal thicknessSetSignal
signal dieSignal
signal weaponPickupSignal
signal interact
signal physicsProc

#@export var airSpeed : float = 0.0

@export var mouseSensitivity = 0.05
@export var headBobAmount = 0.1
@export var headBobSpeed = 1000


@export var initialHp = 100
@export var maxHp = 100
@export var initialArmor = 0
@export var maxArmor = 100
var iFameDict : Dictionary = {}
var pPos = position
 
@onready var hp = 100
@onready var armor = initialArmor


var dead = false
@export var maxSpeed = 1600
var dir : Vector3 = Vector3.ZERO
var inputPressedThisTick = false
@export var keyMove = 0.03
@export var thickness = 0.5: set = changeThickness
@export var height = 2.15: set = changeHeight
@export var eyeHeightRatio = 0.7321

var gunManager
var interactHoldTime = -1
@export var hudIndex = 0
@export var ammoLimits : gsheet = null
var prev_position : Transform3D
var next_position : Transform3D
var forceResourcesUnique = true # this is used by ENTG
var pSpawnsReady = false
var weaponManager= null
var weaponManagerInitialY = 0

var pOnGround = false
var onGround = false
var jumpSound = false
var interactPressed = false
var pLightLevel = 0
var eyeHeight
var damageImunity = []
var camOffsetY = 0
var processInput = true
var bobAngle = 0
var facingDir = -basis.z
var invinciblbeTimeout = -1
var invincible = false
@onready var colShape = $"CollisionShape3D"

var prev_time : int
var next_time : int

var camera

var initialShapeDim = Vector2.ONE

@onready var sprite = get_node_or_null("visual/AnimatedSprite3D")
@onready var lastStep = position
@onready var lastMat = "-"
@onready var footstepSound = $"footstepSound"
@onready var remoteTransform : RemoteTransform3D = $visual/cameraAttach/remoteTransform
@onready var hasRunAnim : bool = $AnimationPlayer.has_animation("run")
@export var gameName : String
@export var entityName : String
@onready var colorOverlay = get_node_or_null("UI/ColorOverlay")

var backupCam = null
var ammoCapDict = {}
@export var runTransitionSpeed : float = 14.9
@onready var speedMeter = $UI/speedmeter
@export var states : gsheet = preload("res://addons/godotWad/resources/playerState.tres")

var footstepDict = {

}
var categoryToWeaponDict = {}
var categoryIndex = []
var cachedSounds = {}
var modelLoaderNode
@export var inventory = {
	"fists":{"count":1,"persistant":true},
	"pistol":{"count":1,"persistant":true},
	"9mm":{"count":40,"persistant":true,"max":200,"rejectWhenFull":true},
	"energy":{"count":0,"persistant":true,"max":300,"rejectWhenFull":true},
	"shell":{"count":0,"persistant":true,"max":50,"rejectWhenFull":true},
	"rocket":{"count":0,"persistant":true,"max":50,"rejectWhenFull":true},
	}
@onready var pInventory = inventory.duplicate()

var uiKeys=[
	["Red keycard","keyR"],
	["Blue keycard","keyB"],
	["Yellow keycard","keyY"],
	["Blue skull key","skullB"],
	["Yellow skull key","skullY"],
	["Red skull key","skullR"]
]

func _ready():
	changeHeight(height)
	#changeHeight(1)
	eyeHeight = height * eyeHeightRatio
	
	if Engine.is_editor_hint():
		return
	
	EGLO.bindConsole(get_tree())
	var console = EGLO.fetchConsole(get_tree())
	console.close.connect(enableInput)
	console.open.connect(disableInput)
	
	if ammoLimits != null:
		ammoCapDict = ammoLimits.getAsDict()
		
		for i in ammoCapDict.keys():
			if inventory.has(i):
				inventory[i]["max"] =ammoCapDict[i]["amt"]
	
	weaponManager =$visual/gunManager
	
	camera = get_node_or_null("Camera3D")
	if get_tree().get_first_node_in_group("gameMode")!= null:
		#$UI.theme = get_tree().get_first_node_in_group("gameMode").theme
		weaponManager.get_node("ui").theme =  get_tree().get_first_node_in_group("gameMode").theme
	
	#weaponManager.weaponPickupSignal.connect(test)
	weaponManager.weaponPickupSignal.connect(emit_signal.bind("weaponPickupSignal"))
	weaponManagerInitialY = weaponManager.position.y


	if !InputMap.has_action("shoot"): InputMap.add_action("shoot")
	if !InputMap.has_action("jump"): InputMap.add_action("jump")
	if !InputMap.has_action("interact"): InputMap.add_action("interact")
	if !InputMap.has_action("openMenu"):InputMap.add_action("openMenu")
	if !InputMap.has_action("strafe"):InputMap.add_action("strafe")
	if !InputMap.has_action("strafeLeft"):InputMap.add_action("strafeLeft")
	if !InputMap.has_action("strafeRight"):InputMap.add_action("strafeRight")
	if !InputMap.has_action("turnRight"):InputMap.add_action("turnRight")
	if !InputMap.has_action("turnLeft"):InputMap.add_action("turnLeft")
	if !InputMap.has_action("forward"):InputMap.add_action("forward")
	if !InputMap.has_action("backward"):InputMap.add_action("backward")
	
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	set_meta("height",WADG.getShapeHeight($"CollisionShape3D"))



	for level in get_tree().get_nodes_in_group("level"):
		curMap = level
		if curMap.spawnsReady == false:
			pSpawnsReady = false
		
		var possibleSpawns = level.getSpawns(0)
		if possibleSpawns.is_empty():
			continue
		var posAndRot = possibleSpawns[0]

		if posAndRot == null:#no player spawn in map
			teleport(Vector3(0,0,0),rotation)
		else:
			var pos = posAndRot["pos"]
			var rot = posAndRot["rot"]
			teleport(pos,rot)

	grabCameraFocus()
	
	
var teleportCooldown = 0

func grabCameraFocus():
	var cam = null
	
	if is_instance_valid(camera):
		return
	
	if get_tree().get_nodes_in_group("globalCam").size()== 0:
		cam = createCamera()
		return
	else:
		
		#for i in get_tree().get_nodes_in_group("globalCam"):
		#	i.active = false
			
		cam = get_tree().get_nodes_in_group("globalCam")[0]
		#cam.active = true
		if !is_instance_valid(cam):
			breakpoint
		
			
	cameraSet(cam)


func createCamera():
	camera = load("res://addons/gameAssetImporter/scenes/orbCam/orbCam.tscn").instantiate()
	camera.current = true
	camera.collides = true
	camera.dist = 0
	camera.name = "backup"
		
	var camPar = get_parent()
		
	if get_parent() == null:
		camPar = get_tree().get_root()

	camPar.call_deferred("add_child",camera)
	camera.ready.connect(cameraSet.bind(camera))
	return camera

func cameraSet(cam : Node):

	camera =cam
	
	#rotation = Vector3.ZERO
	camera.rotationChildrenY = [weaponManager]
	camera.rotationChildrenYprocess = [weaponManager]
	camera.rotationChildrenXprocess = [weaponManager]
	camera.facingDirChildren = [self]
	remoteTransform.remote_path = remoteTransform.get_path_to(cam)

func teleport(pos,rot=null,cooldown = 0):
	
	
	
	if teleportCooldown > 0:
		return
	
	teleportCooldown = cooldown
	position = pos + Vector3(0,height/2.0,0)

		
	if camera != null:
		if "rotH" in camera and rot != null:
			camera.rotH = 0#rad_to_deg(rot.y) 
			camera.rotV = 0#rad_to_deg(rot.x)
			camera.initialRot = Vector2(rad_to_deg(rot.y), rad_to_deg(rot.x))


func _process(delta: float) -> void:
	
	if Engine.is_editor_hint():
		return
	
	if processInput and ready and InputMap.has_action("shoot"):
		if Input.is_action_pressed("forward"):  dir.z = -1 
		if Input.is_action_pressed("backward"): dir.z = 1
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("strafeRight"):dir.x = 1
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("strafeLeft"):dir.x =  -1
		
		#if !pOnGround:
		#	dir.x *= airSpeed
		#	dir.z *= airSpeed
		
	var veloXY = Vector3(velocity.x,0,velocity.z).length()
	var angleInc = (delta*veloXY)
	bobAngle = bobAngle+angleInc
	sprite.basis =  sprite.basis.looking_at(-facingDir)
	
	#$visual/AnimatedSprite3D.rotate_y()

func _input(event):
	
	if processInput == false:
		return
	
	if Engine.is_editor_hint():
		return
	
	var just_pressed = event.is_pressed() and !event.is_echo()
	
	if Input.is_key_pressed(KEY_M) and just_pressed:
		if is_instance_valid(curMap):
			curMap.nextMap()

	if Input.is_key_pressed(KEY_ALT):
		if Input.is_key_pressed(KEY_ENTER) and just_pressed:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED

	if Input.is_key_pressed(KEY_CTRL):
		if Input.is_key_pressed(KEY_W) and just_pressed:
			get_tree().quit()

		
	
	if dead:
		return



var deg = 0

var angDelta = 1
var curAngle = 180



	

func _physics_process(delta):
	
	if !is_inside_tree():
		return
	
	camOffsetY = clamp(camOffsetY,-0.5*eyeHeight,0.9*height)
	
	if camOffsetY < 0:
		camOffsetY = min(0,camOffsetY+delta*5)
	
	if camOffsetY > 0:
		camOffsetY = max(0,camOffsetY-delta*5)
	
	
	
	if Engine.is_editor_hint():
		return

	
	
	#setSpriteDir()

	if camera != null:
		camera.fov = SETTINGS.getSetting(get_tree(),"fov")
	
	
	
	if camera != null:
		if camera.dist >= 1:
			weaponManager.visible = false
			sprite.visible = true
		else:
			weaponManager.visible = true
			sprite.visible = false
	
	#camera.translation.z += 0.1
	
	var curHud = $UI/HUDS.get_child(hudIndex)
	
	for i in iFameDict:
		iFameDict[i] -= delta
		if iFameDict[i] <= 0:
			iFameDict.erase(i)
	
	
	for i in $UI/HUDS.get_children():
		if i != curHud:
			i.visible = false
		else:
			i.visible = true
	
	var veloXY = Vector3(velocity.x,0,velocity.z).length()
	

	#$movement.isOnGround()
	teleportCooldown -= delta * 1000
	
	if invinciblbeTimeout >0 :
		invinciblbeTimeout -= delta
		if invinciblbeTimeout <= 0:
			invinciblbeTimeout = -1
			invincible = false
	
	if curHud != null:
		
		var hpLabel = curHud.find_child("hp",true,false)
		var armorLabel = curHud.find_child("armor",true,false)
		var ammoLabel = curHud.find_child("ammo",true,false)
		
		if hpLabel != null:
			
			var tHp = hp
			if tHp > 0.0 and tHp < 1.0:
				tHp = 1.0
			
			if hpLabel.has_method("setText"):
				hpLabel.setText(str(int(tHp)))
			else:
				hpLabel.text = str(int(tHp))
		

		if armorLabel != null:
			var armorSet = str(int(armor))
			if armor <= 0:
				armorSet = ""
				
			if armorLabel.has_method("setText"):
				armorLabel.setText(armorSet)
			else:
				armorLabel.text = armorSet

		
		
		
		
		
		if weaponManager.curGun != null:
			var t = weaponManager.curGun.ammoType
			if weaponManager.curGun.magSize < 0:
				ammoLabel.visible = false
			else:
				ammoLabel.visible = true
			if inventory.has(t):
				if ammoLabel!= null:
					if ammoLabel.has_method("setText"):
						if t == "none":
							ammoLabel.setText("")
						else:
							ammoLabel.setText(str(inventory[t]["count"]))
					else:
						ammoLabel.text = str(inventory[t]["count"])
			else:
				if ammoLabel.has_method("setText"):
					ammoLabel.setText("")
				else:
					ammoLabel.text = ""
		else:
			if ammoLabel.has_method("setText"):
					ammoLabel.setText("")
			else:
				ammoLabel.text = ""
		
		
		updateKeyUI()
	
	if is_instance_valid(curMap):
		if !pSpawnsReady and curMap.spawnsReady:
			var spawns = curMap.getSpawns(0)
			if spawns == null:
				return
			if !spawns.is_empty():
				
				var posAndRot = curMap.getSpawns(0)[0]
				if posAndRot != null:
					var pos = posAndRot["pos"]
					var rot = posAndRot["rot"]
					pSpawnsReady = true
					teleport(pos,rot)
		
		var a = Time.get_ticks_msec()
		var posXZ = Vector2(global_position.x,global_position.z)
		var p = WADG.getSectorInfoForPoint(curMap,posXZ)
		
		if p != null:
			if p.has("light"):
				if weaponManager.curGun != null:
				#for i in $gunManager.get_children():
					var weaponSprite =weaponManager.curGun.get_node_or_null("AnimatedSprite3D")
					if  weaponSprite != null:
						if "modulate" in weaponSprite:
							var l : float = 0.0
								
							if p["light"] != 0:
								l = 255.0/p["light"]

							weaponSprite.modulate = p["light"]/255.0
							
		
		
		

	if !is_instance_valid(curMap):
		for level in get_tree().get_nodes_in_group("level"):
			curMap = level
			var posAndRot = level.getSpawns(0)
			if posAndRot.is_empty():
				return
			
			posAndRot = posAndRot[0]
			var pos = posAndRot["pos"]
			var rot = posAndRot["rot"]
			teleport(pos,rot)
			
			for i in inventory.keys():
				if inventory[i].has("persistant"):
					if inventory[i]["persistant"] == false:
						inventory.erase(i)
						

	if Engine.is_editor_hint():
		return


	if hp <= 0:
		die()

	
	var spr = null
	
	if weaponManager!=null:
		if curHud !=null:
			spr = weaponManager.getUIsprite()
			#var weaponIconTexture = getChilded(curHud,"weaponIcon")
			var weaponIconTexture = find_child("weaponIcon",true,false)
			
			if weaponIconTexture != null:
				weaponIconTexture.texture = spr

		
	#interactHoldTime = max(0,interactHoldTime-delta)

	if Input.is_action_just_pressed("interact"):
		interactPressed = true
	else: #interactHoldTime <= 0:
		interactPressed = false

	
		
		#if Input.get_action_strength("forward") != 0: dir.z -= 1 * Input.get_action_strength("forward")
		#if Input.get_action_strength("backward") != 0: dir.z += 1 * Input.get_action_strength("backward")
		#if Input.get_action_strength("strafeRight") != 0: dir.x += 1 * Input.get_action_strength("strafeRight")
		#if Input.get_action_strength("strafeLeft") != 0: dir.x -= 1 * Input.get_action_strength("strafeLeft")
		
		
		

	
	if dir != Vector3.ZERO:
		inputPressedThisTick = true
	else:
		inputPressedThisTick = false
	
	if processInput:
		if Input.is_action_just_pressed("jump"): 
			if onGround:
				$jumpPlayer.play()
				dir.y = 1
				if $AnimationPlayer.has_animation("jump"):
					$AnimationPlayer.play("jump")
	
	
	var beforePos = Vector3(global_position.x,0, global_position.z)
	
	#var jumpVelo = 800
	#var forwardSpeed = 1.5625
	#var sideSpeed: float = 1.5625
	#var friction: float = 0.90625
	if camera != null:
		var movementBasisX  = camera.get_node("h/v").global_transform.basis.x
		var movementBasisZ  = camera.get_node("h").global_transform.basis.z
	
		#velocity += movementBasisZ*forwardSpeed*dir.z

		
		#if dir.x ==-2 or dir.x == 2: 
		#	velocity +=  movementBasisX*forwardSpeed*dir.x*0.5
		#else:
		#	velocity += movementBasisX*sideSpeed*dir.x
	
	#velocity.y += dir.y * jumpVelo *delta
	
	
		velocity += $movement.dirToAcc(movementBasisZ,movementBasisX,dir,delta)
	var ppos = global_transform
	$movement.move(delta)
	#emit_signal("physicsProc",delta,ppos)
	$visual.tick(delta,ppos)
	
	
	if camera != null:
		camera.pingTransforms()
	
	if speedMeter != null:
		speedMeter.text = str((Vector3(global_position.x,0, global_position.z)-beforePos).length())

	veloXY = Vector3(velocity.x,0,velocity.z).length()


	var curAniStr : String =  $AnimationPlayer.current_animation
	if !$AnimationPlayer.is_playing() or curAniStr =="walk" or curAniStr == "idle" or curAniStr == "run" or (curAniStr == "jump" and onGround):
		if veloXY > 0.1:
			if veloXY > runTransitionSpeed  and hasRunAnim:
				$AnimationPlayer.play("run",-1)
			else:
				$AnimationPlayer.play("walk",-1)
		else:
			var to = $AnimationPlayer.get_animation_list()
			$AnimationPlayer.play("idle")
	footsteps()
	
	
	
	veloXY = Vector3(velocity.x,0,velocity.z).length()
	var angleInc = (delta*veloXY)
	#if veloXY > 0.05:
	
	

	var ang = rad_to_deg(bobAngle)
	
	prev_time = Time.get_ticks_msec()
	next_time = prev_time + (delta  * 1000)
	
	
	dir = Vector3.ZERO
	ppos = position
	
	

func die():
	
	if dead:
		return
	
	
	
	#camera.rotate_z(deg2rad(90))
	if weaponManager != null:
		weaponManager.bringDown()
	dead = true
	changeHeight(1)
	
	if weaponManager!= null:
		pass
	
	$AnimationPlayer.play("die")
	$AudioStreamPlayer3D.playDeath()
	disableInput()
	emit_signal("dieSignal")
	return

func footsteps():
	return
	if velocity.length() < 0.1 and jumpSound == false:
		return

	var collider = null# = footCast.get_collider()
	if collider == null:
		return

	var matType = getFootMaterial()

	if matType == null:
		return



	if footstepDict.has(matType):
		if position.distance_to(lastStep) < 2 and lastMat == matType:
			lastMat = matType
			
			return

		lastMat = matType
		lastStep = position

		playMatStepSound(matType)


func getFootMaterial():
	return null
	var collider = null#= footCast.get_collider()
	if collider == null:
		return null

	if collider.get_parent() != null:
		if collider.get_parent().get_class()!= "MeshInstance3D":
			return


	var mesh = collider.get_parent()
	#var mat = getMatFromPos(mesh,mesh.mesh,footCast.get_collision_point())

func getMatFromPos(meshInstance,mesh,pos):
	var numSurf = mesh.get_surface_count()
	var runningDataArr = []

	for surf in numSurf:
		var meshData = MeshDataTool.new()
		meshData.create_from_surface(mesh,surf)
		runningDataArr.append(meshData)

	for surfData in runningDataArr:
		for vertIdx in surfData.get_vertex_count():
			for faceIdx in surfData.get_vertex_faces(vertIdx):
				if surfData.get_face_normal(faceIdx).dot(Vector3.UP) < 0.1:#if faces downwards
					continue

				var tri = getVertsOfFaceGlobal(surfData,faceIdx,meshInstance)
				if Geometry3D.ray_intersects_triangle(global_transform.origin,global_transform.origin.direction_to(pos),tri[0],tri[1],tri[2]):
					return surfData.get_material()




func getVertsOfFaceGlobal(surfData,faceIdx,meshInstance):
	var a = surfData.get_face_vertex(faceIdx,0)
	var b = surfData.get_face_vertex(faceIdx,1)
	var c = surfData.get_face_vertex(faceIdx,2)

	a = surfData.get_vertex(a)
	b = surfData.get_vertex(b)
	c = surfData.get_vertex(c)

	a = meshInstance.to_global(a)
	b = meshInstance.to_global(b)
	c = meshInstance.to_global(c)
	return [a,b,c]



func playMatStepSound(mat):
	pass


func changeHeight(h):
	
	
	height= max(0.2,h)
	eyeHeight = height * eyeHeightRatio
	if get_node_or_null("Camera3D") != null:
		$Camera3D.position.y = h*0.732143
	
	if get_node_or_null("MeshInstance3D") != null:
		$MeshInstance3D.position.y = h/2
		$MeshInstance3D.mesh.height = h

	if get_node_or_null("CollisionShape3D") == null:
		return
		
	WADG.setCollisionShapeHeight($CollisionShape3D,h)

	$CollisionShape3D.position.y = h/2.0
		
	emit_signal("heightSetSignal")

func changeThickness(t):
	
	thickness = t
	
	if get_node_or_null("CollisionShape3D") == null:
		return
	
	WADG.setShapeThickness($CollisionShape3D,t)
	
	if get_node_or_null("movement") == null:
		return
		
	WADG.setShapeThickness($movement/footCast,t)
	WADG.setShapeThickness($movement/ShapeCastH,t)


	emit_signal("thicknessSetSignal")

	
	

var ppos = Vector3.ZERO
var pLL = 0

func giveLimimted(value,giveAmount,naturalLimit,limitOverride):
	if limitOverride != -1:
		if value >= limitOverride:#don't pick up
			return [value,false]
				
		if value < limitOverride and (value+giveAmount) > limitOverride:#if we weren't over the limit and now we are then cap value at limimt
			value = limitOverride
			return [value,true]
		else:
			value += giveAmount
			return [value,true]
	else:
		
		if value >= naturalLimit:#don't pick up
			return [value,false]
					
			if value < naturalLimit and (value+giveAmount) > naturalLimit:#if we weren't over the limit and now we are then cap value at limit
				value = naturalLimit
				return[value,true]
			else:
				value += giveAmount
				return [value,true]
		else:
			value += giveAmount
			return [value,true]


func pickup(dict) -> bool:
	
	if dict.has("giveName"):

		var gName = dict["giveName"]
		var gAmount = 0
		
		
		if dict.has("giveAmount"):
			gAmount = dict["giveAmount"]
	
		if gName == ("hp"):
			var limitOverride = -1
			
			if dict.has("limit"):
				limitOverride = dict["limit"]
				
			var ret = giveLimimted(hp,gAmount,maxHp,limitOverride)
			hp = ret[0]
			
			if ret[1] == false:
				return false
			
			if colorOverlay:
				colorOverlay.get_node("AnimationPlayer").play("itemPickup")


		elif gName == "armor":
			var limitOverride = -1
			
			if dict.has("limit"):
				limitOverride = dict["limit"]
				
			var ret = giveLimimted(armor,gAmount,maxArmor,limitOverride)
			armor = ret[0]
			
			if ret[1] == false:
				return false
			
			if colorOverlay:
				colorOverlay.get_node("AnimationPlayer").play("itemPickup")
				
		elif gName == "secret":
			if !inventory.has(dict["path"]):
				inventory[dict["path"]] = {"persistant":false}
				popupText("Secret Discovered")
				if curMap != null:
					curMap.secretsFound += 1
		
		elif gName == "invincible":
			invincible = gAmount
			invinciblbeTimeout = dict["limit"]
			
			if colorOverlay:
				colorOverlay.get_node("AnimationPlayer").play("itemPickup")
			
		else:
			if !inventory.has(gName):
				inventory[gName] = {"count":0}
			
			var invItem = inventory[gName]


			if inventory[gName].has("max"):
				
				if invItem["count"] >=invItem["max"]:
					if invItem.has("rejectWhenFull"):
						if invItem["rejectWhenFull"] == true:
							return false
							
				if invItem["count"] + gAmount > invItem["max"]: 
					invItem["count"] = invItem["max"]
				else:
					invItem["count"] += gAmount
			else:
				invItem["count"] += gAmount
						
				
			
			inventory[gName]["persistant"] = dict["persistant"]
			
			var curHud= $UI/HUDS.get_child(hudIndex)
			
			
		
			for i in uiKeys:
				if gName == i[0] and curHud != null:
					var spr = dict["sprite"].duplicate()
					var uiIcon = getChilded(curHud,i[1])
					
					if uiIcon != null:
						uiIcon.texture = spr

				
			if dict.has("uiTexture"):
				if dict["uiTexture"][0] != null:
					inventory[gName]["uiTarget"] = dict["uiTexture"][0]
					inventory[gName]["textureName"] = dict["uiTexture"][1]
					
				inventory[gName]["gameName"] = dict["uiTexture"][2]
				inventory[gName]["entityName"] = dict["uiTexture"][3]

			
			if colorOverlay:
				$UI/ColorOverlay/AnimationPlayer.play("itemPickup")
	
	return true


func updateUIIcons():
	return
	for i in inventory.keys():
		breakpoint



var invulTime = {}
var heatTime = {} 

func popupText(txt : String,dur : float = 1.0):
	$UI/PopupTxts/Label.text = txt
	$UI/PopupTxts.visible = true
	$UI/PopupTxts.modulate = Color.WHITE
	await get_tree().create_timer(dur).timeout
	$UI/PopupTxts/fadeAmim.play("fadeOut")

func takeDamage(damage : Dictionary):
	
	var source = null
	if damage.has("source"): source = damage["source"]
	
	
	if invincible:
		return
	
	if damage.is_empty():
		return
	if dead:
		return
	
	if damage.has("specific"):
		if damageImunity.has(damage["specific"]):
			return
	
	if damage.has("everyNframe"): 
		var t = Engine.get_physics_frames() % damage["everyNframe"]
		if Engine.get_physics_frames() % damage["everyNframe"] != 0:
			return
	
	if source != null:
		if damage.has("iFrameMS"):
			if iFameDict.has(source):
				return
			
			#if iFameDict[source] <= 0:
			iFameDict[source] = damage["iFrameMS"]
			
			
				
		
	
	if damage.has("iMS") and damage.has("specific"):
		if !invulTime.has("specific"):
			invulTime["specific"] = [Time.get_ticks_msec(),damage["iMS"]]
		else:
			var diff = Time.get_ticks_msec() - invulTime["specific"][0]
			if diff < damage["iMS"]:
				return
			else:
				invulTime.erase("specific")
	
	
	#if !damage.has("specific"):
	#	heatTime[damage["specific"]] = Phyics.get_frame
	$AnimationPlayer.play("hurt")
	$AudioStreamPlayer3D.playHurth()
	if colorOverlay:
		$UI/ColorOverlay/AnimationPlayer.play("pain")
	

	var amt = damage["amt"]
	var arm = damage["amt"] * 0.3
	amt -= arm
	
	
	armor = max(0,armor - arm)
	amt += max(0,arm - armor)
	
	arm = min(0,arm-armor)
	
	if damage.has("amt"):
		hp -= amt

	if damage.has("onDeath"):
		if damage["onDeath"] == "nextMap":
			if hp <= 0:
				hp = initialHp
				if is_instance_valid(curMap):
					curMap.nextMap()

func _on_KinematicBody_child_entered_tree(node):
	pass # Replace with function body.

func normalToDegree(normal : Vector3):
	return rad_to_deg(normal.angle_to(Vector3.UP))

func disableInput():
	

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	processInput = false
	if camera!= null:
		if "par" in camera:
			camera.processInput = false

	
func enableInput():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	processInput = true
	
	if camera!= null:
		if "par" in camera:
			camera.processInput = true


func getChilded(node,nameStr):
	for i in node.get_children():
		if i.name == nameStr:
			return i
		else:
			var r = getChilded(i,nameStr)
			if r != null:
				return r
				

func updateKeyUI():
	var curHud= $UI/HUDS.get_child(hudIndex)
	
	if curHud == null:
		return
	

	var uiIcon = find_child("keyR",true,false)

	
	for i in uiKeys:
		var icon = curHud.find_child(i[1],true,false)
		
		if icon == null:
			return
		if icon.texture == null:
			continue
		
		var found = false
		for item in inventory:
			if item == i[0]:
				found = true
			
		if found == false:
			icon.texture = null


func setSpriteDir() -> void:
	

	if sprite == null:
		return

	
	if camera == null:
		return

	var cameraForward = -camera.global_transform.basis.z

	var forward : Vector3 = -camera.global_transform.basis.z
	var left : Vector3 = camera.global_transform.basis.x
	
	var forwardDot : float = forward.dot(cameraForward)
	
	

	
	var anim : String = sprite.curAnimation
	var newAnim  = anim
	
	
	
	if forwardDot < -0.85:
		newAnim = "front"
		
	elif forwardDot > 0.85:
		newAnim = "back"
	else:
		var leftDot : float = left.dot(cameraForward)
		if leftDot > 0:#left
			if abs(forwardDot) < 0.3:
				newAnim = "left"
			elif forwardDot < 0:
				newAnim = "frontLeft"
			else:
				newAnim = "backLeft"
		else:#right
			if abs(forwardDot) < 0.3:
				newAnim = "right"
			elif forwardDot < 0:
				newAnim = "frontRight"
			else:
				newAnim = "backRight"
	
	if anim != newAnim:
		sprite.curAnimation = newAnim



func viewBob(delta):
	
	
	if inputPressedThisTick:
		curAngle += angDelta * Vector3(velocity.x,0,velocity.z).length()*0.006
	elif weaponManager.weapons.position.y < -0.001:
		curAngle += angDelta *60*0.006
		
	var angle_radians = deg_to_rad(curAngle)
	var mapped_value = (sin(curAngle) + 1) / 2
	
	weaponManager.weapons.position.y = -0.02* mapped_value
			



func serializeSave():
	var ret : Dictionary = {}

	
	ret["posX"] = position.x
	ret["posY"] = position.y
	ret["posZ"] = position.z
	
	ret["rotX"] = rotation.x
	ret["rotY"] = rotation.y
	ret["rotZ"] = rotation.z
	ret["hp"] = hp
	ret["inventory"] = inventory
	
	ret["veloX"] = velocity.x
	ret["veloY"] = velocity.y
	ret["veloZ"] = velocity.z
	
	ret["gameName"] = gameName
	ret["entityName"] = entityName
	ret["height"] = height
	
	ret["camPitch"] = camera.pitch.rotation_degrees.x
	ret["camYaw"]  = camera.yaw.rotation_degrees.y 
	ret["armor"] = armor
	ret["desiredParent"] = get_parent().get_path()
	ret["camEnabled"] = camera.processInput
	
	
	
	return ret
	

func serializeLoad(data):
	
	velocity.x = data["veloX"]
	velocity.y = data["veloY"]
	velocity.z = data["veloZ"]
	
	colShape.position = Vector3.ZERO
	pSpawnsReady = true
	height = data["height"]
	armor = data["armor"]

	teleportCooldown = 1000
	hp = data["hp"]
	inventory = data["inventory"]
	
	for i in data["inventory"]:
		if i == "entityKey":
			breakpoint
	
	grabCameraFocus()

	
	camera.rotH = 0
	camera.rotV = 0
	camera.initialRot.x = data["camYaw"]
	camera.initialRot.y = data["camPitch"]
	camera.processInput = data["camEnabled"]
	
	
	for i in data["inventory"].values():
		if i.has("uiTarget"):
			if i["uiTarget"] != null:
				setUItexture(i["uiTarget"],i["gameName"],i["entityName"],i["textureName"])
	
	updateUIIcons()
	
	#weaponManager.rotation.y = rotation.y
	
func hideUI():
	$UI.visible = false

func showUI():
	$UI.visible = true
	
func setUItexture(uiTarget,gameName,entName,textureName):
	var curHud = $UI/HUDS.get_child(hudIndex)
	var uiIcon = getChilded(curHud,uiTarget)
		
	var t = ENTG.fetchTexture(get_tree(),textureName,gameName)
	
	if uiIcon != null:
		uiIcon.texture = t
