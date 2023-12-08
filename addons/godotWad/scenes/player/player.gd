tool
extends KinematicBody

var curMap


signal heightSet
signal die
export var acc = 180
export var airSpeed = 1

export var mouseSensitivity = 0.05
export var headBobAmount = 0.1
export var headBobSpeed = 1000


export var initialHp = 100
export var maxHp = 100
export var initialArmor = 0
export var maxArmor = 100

var pPos = translation

onready var hp = 100
onready var armor = initialArmor


var dead = false
export var gravity = 280 
export var maxSpeed = 1600
var maxAcc = 0.5*maxSpeed
var dir = Vector2.ZERO
var inputPressedThisTick = false
export var keyMove = 0.03
export var friction = 1
export var thickness = 0.5 setget changeThickness
export var height = 2.15 setget changeHeight
export var eyeHeightRatio = 0.7321

var gunManager
export var jumpSpeed = 0.5
export var hudIndex = 0

var velocity = Vector3.ZERO
var pSpawnsReady = false
var weaponManager= null
var weaponManagerInitialY = 0
var initalGravity = gravity
var gravityVelo = Vector3()
var pOnGround = false
var onGround = false
var jumpSound = false
var interactPressed
var smoothY = false
var pLightLevel = 0
var eyeHeight
var damageImunity = []
var camOffsetY = 0
var processInput = true
var debugNode = null
onready var colShape = $"CollisionShape"
var camera

var initialShapeDim = Vector2.ONE

onready var lastStep = translation
onready var lastMat = "-"
onready var footstepSound = $"footstepSound"
var bspNode = null
var backupCam = null
var footStepDict = {

}

var categoryToWeaponDict = {}
var categoryIndex = []
var cachedSounds = {}
var modelLoaderNode
var inventory = {
	"fists":{"count":1,"persistant":true},
	"pistol":{"count":1,"persistant":true},
	"9mm":{"count":50,"persistant":true}
	}
onready var pInventory = inventory.duplicate()

func _ready():
	var t = filename
	
	
	
	if colShape != null:
		initialShapeDim = Vector2(colShape.shape.radius,colShape.shape.height)
	
	changeHeight(height)
	
	eyeHeight = height * eyeHeightRatio
	
	if Engine.editor_hint:
		return
	
	
	camera = get_node_or_null("Camera")
	gunManager = get_node_or_null("gunManager")
	
	if !get_tree().has_meta("globalCam"):
		backupCam = load("res://addons/gameAssetImporter/scenes/orbCam/orbCam.tscn").instance()
		backupCam.current = true
		backupCam.collides = true
		backupCam.dist = 0
		backupCam.name = "backup"
		
		var camPar = get_parent()
		
		if get_parent() == null:
			camPar = get_tree().get_root()

		#camPar.add_child(backupCam)
		camPar.call_deferred("add_child",backupCam)
		camera = backupCam.get_node("h/v/ClippedCamera")
		camera.add_exception(self)
		
		camera.get_node("../../../").rotationChildrenY = [self]
		camera.get_node("../../../").rotationChildrenX = [$gunManager]
		

	weaponManager = $gunManager
	

	weaponManagerInitialY = weaponManager.translation.y


	if !InputMap.has_action("shoot"): InputMap.add_action("shoot")
	if !InputMap.has_action("jump"): InputMap.add_action("jump")
	if !InputMap.has_action("interact"): InputMap.add_action("interact")
	if !InputMap.has_action("pause"):InputMap.add_action("pause")
	if !InputMap.has_action("strafe"):InputMap.add_action("strafe")
	if !InputMap.has_action("turnRight"):InputMap.add_action("turnRight")
	if !InputMap.has_action("turnLeft"):InputMap.add_action("turnLeft")
	if !InputMap.has_action("debug"):InputMap.add_action("debug")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	set_meta("height",$"CollisionShape".shape.height)



	for level in get_tree().get_nodes_in_group("levels"):
		curMap = level
		if curMap.spawnsReady == false:
			pSpawnsReady = false
		
		var possibleSpawns = level.getSpawns(0)
		if possibleSpawns.empty():
			return
		var posAndRot = possibleSpawns[0]

		if posAndRot == null:#no player spawn in map
			teleport(Vector3(0,0,0),rotation)
		else:
			var pos = posAndRot["pos"]
			var rot = posAndRot["rot"]
			teleport(pos,rot)



var teleportCooldown = 0



func teleport(pos,rot=null,cooldown = 0):
	
	
	
	if teleportCooldown > 0:
		return
	
	
	teleportCooldown = cooldown
	translation = pos + Vector3(0,height/2.0,0)
	if visible == true:
		reset_physics_interpolation()
	if rot != null:
		rotation = rot
		
	if camera != null:
		if camera.get_node_or_null("../../../") != null:
			var camBase =  camera.get_node_or_null("../../../")
			if "rotH" in camBase and rot != null:
				camBase.rotH = 0#rad2deg(rot.y) 
				camBase.rotV = 0#rad2deg(rot.x)
				camBase.initialRot = Vector2(rad2deg(rot.y), rad2deg(rot.x))


func _input(event):
	
	if processInput == false:
		return
	
	if Engine.editor_hint:
		return
	
	var just_pressed = event.is_pressed() and !event.is_echo()

	
	
	if Input.is_key_pressed(KEY_M) and just_pressed:
		if is_instance_valid(curMap):
			curMap.nextMap()

	if Input.is_key_pressed(KEY_ALT):
		if Input.is_key_pressed(KEY_ENTER) and just_pressed:
			OS.window_fullscreen = !OS.window_fullscreen

	if Input.is_key_pressed(KEY_CONTROL):
		if Input.is_key_pressed(KEY_W) and just_pressed:
			get_tree().quit()
	
	if Input.is_action_just_pressed("debug"):
		if debugNode == null:
			debugNode = load("res://addons/godotWad/scenes/entityDebugDialog.tscn").instance()
			debugNode.connect("hide",self,"enableInput")
			get_tree().get_root().add_child(debugNode)
			debugNode.popup_centered_ratio()
			disableInput()
			return
		
		if debugNode.visible == true:
			debugNode.visible = false
			enableInput()
		else:
			disableInput()
			debugNode.popup_centered_ratio()
		
	
	if dead:
		return



var deg = 0

var angDelta = 1
var curAngle = 180
func _physics_process(delta):
	
	
	if camOffsetY < 0:
		camOffsetY = min(0,camOffsetY+delta*8)
	
	if camOffsetY > 0:
		camOffsetY = max(0,camOffsetY-delta*8)
	
	if Engine.editor_hint:
		return
	
	setSpriteDir()
	#viewBob(delta)
	
	if camera != null:
		camera.get_node("../../../").fov = SETTINGS.getSetting(get_tree(),"fov")
	
	if camera != null:
		if camera.translation.z >= 1:
			weaponManager.visible = false
			$AnimatedSprite3D.visible = true
		else:
			weaponManager.visible = true
			$AnimatedSprite3D.visible = false
	
	#camera.translation.z += 0.1
	
	var curHud = $UI/HUDS.get_child(hudIndex)
	
	
	
	
	for i in $UI/HUDS.get_children():
		if i != curHud:
			i.visible = false
		else:
			i.visible = true
	
	var veloXY = Vector3(velocity.x,0,velocity.z).length()
	

	teleportCooldown -= delta * 1000
	$movement.isOnGround()
	
	if curHud != null:
		
		var hpLabel = curHud.find_node("hp",true,false)
		var armorLabel = curHud.find_node("armor",true,false)
		var ammoLabel = curHud.find_node("ammo",true,false)
		
		if hpLabel != null:
			
			if hpLabel.has_method("setText"):
				hpLabel.setText(String(int(hp)))
			else:
				hpLabel.text = String(int(hp))
		

		if armorLabel != null:
			var armorSet = String(int(armor))
			if armor <= 0:
				armorSet = ""
				
			if armorLabel.has_method("setText"):
				armorLabel.setText(armorSet)
			else:
				armorLabel.text = armorSet

		
		
		
		
		
		if weaponManager.curGun != null:
			var t = weaponManager.curGun.ammoType
			if inventory.has(t):
				if ammoLabel!= null:
					if ammoLabel.has_method("setText"):
						if t == "none":
							ammoLabel.setText("")
						else:
							ammoLabel.setText(String(inventory[t]["count"]))
					else:
						ammoLabel.text = String(inventory[t]["count"])
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
			if !spawns.empty():
				
				var posAndRot = curMap.getSpawns(0)[0]
				if posAndRot != null:
					var pos = posAndRot["pos"]
					var rot = posAndRot["rot"]
					pSpawnsReady = true
					teleport(pos,rot)
		
		var x = curMap.get_meta("sectorPolyArr")
		var bbs = curMap.get_meta("polyBB")
		var a = OS.get_system_time_msecs()
		
		
		var polyInfo = curMap.get_meta("polyIdxToInfo")
		var posXZ = Vector2(global_translation.x,global_translation.z)

		
		var p = WADG.getSectorInfoForPoint(curMap,posXZ)
		
		if p != null:
			if p.has("light"):
				if $gunManager.curGun != null:
				#for i in $gunManager.get_children():
					var i = $gunManager.curGun
					if i.get_node_or_null("AnimatedSprite3D") != null:
						if "modulate" in i.get_node_or_null("AnimatedSprite3D"):
							var l = 0
								
							if p["light"] != 0:
								l = 255.0/p["light"]
								
							i.get_node("AnimatedSprite3D").modulate = p["light"]/255.0
		

	if !is_instance_valid(curMap):
		for level in get_tree().get_nodes_in_group("levels"):
			curMap = level
			var posAndRot = level.getSpawns(0)
			if posAndRot.empty():
				return
			
			posAndRot = posAndRot[0]
			var pos = posAndRot["pos"]
			var rot = posAndRot["rot"]
			teleport(pos,rot)
			
			for i in inventory.keys():
				if inventory[i].has("persistant"):
					if inventory[i]["persistant"] == false:
						inventory.erase(i)
						

	if Engine.editor_hint:
		return


	if hp <= 0:
		die()

	
	var spr = null
	
	if weaponManager!=null:
		if curHud !=null:
			spr = weaponManager.getUIsprite()
			#var weaponIconTexture = getChilded(curHud,"weaponIcon")
			var weaponIconTexture = find_node("weaponIcon",true,false)
			
			if weaponIconTexture != null:
				weaponIconTexture.texture = spr

		


	if Input.is_action_pressed("interact"):
		interactPressed = true
	else:
		interactPressed = false

	dir = Vector3.ZERO
#	if Input.is_action_pressed("ui_up"): dir -= transform.basis.z
#	if Input.is_action_pressed("ui_down"): dir += transform.basis.z
#	if Input.is_action_pressed("ui_right"): dir += transform.basis.x
#	if Input.is_action_pressed("ui_left"): dir -= transform.basis.x
	
	
	if onGround and processInput:
		if Input.is_action_pressed("ui_up"): dir -= Vector3(0,0,1)
		if Input.is_action_pressed("ui_down"): dir += Vector3(0,0,1)
		if Input.is_action_pressed("ui_right"): dir += Vector3(1,0,0)
		if Input.is_action_pressed("ui_left"): dir -= Vector3(1,0,0)
	
	if dir != Vector3.ZERO:
		inputPressedThisTick = true
	else:
		inputPressedThisTick = false
		
	if Input.is_action_pressed("jump"): 
		if onGround:
			dir.y += 10
	
	
	
	$movement.move(delta)
	
	
	if !$AnimationPlayer.is_playing() or $AnimationPlayer.current_animation =="walk" or $AnimationPlayer.current_animation == "idle":
		if velocity.length() > 0.1:
			!$AnimationPlayer.play("walk")
		else:
			 $AnimationPlayer.play("idle")
	footsteps()
	
	
	if camera != null:
		weaponManager.rotation.x = camera.global_rotation.x
	
	
	if camera.translation.z == 0:
		weaponManager.translation.y = eyeHeight + camOffsetY
	else:
		weaponManager.translation.y = (height * 1.1) + camOffsetY
	
	
	ppos = translation
	camera()


func enterLadder():
	print("player enter ladder")
	gravity = -initalGravity

func exitLadder():
	print("player exit ladder")
	gravity = initalGravity

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
	disableInput()
	emit_signal("die")
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



	if footStepDict.has(matType):
		if translation.distance_to(lastStep) < 2 and lastMat == matType:
			lastMat = matType
			return

		lastMat = matType
		lastStep = translation

		playMatStepSound(matType)


func getFootMaterial():
	return null
	var collider = null#= footCast.get_collider()
	if collider == null:
		return null

	if collider.get_parent() != null:
		if collider.get_parent().get_class()!= "MeshInstance":
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
				if Geometry.ray_intersects_triangle(global_transform.origin,global_transform.origin.direction_to(pos),tri[0],tri[1],tri[2]):
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


func friction(delta):
	var speed = velocity.length()
	if speed != 0:
		var drop = speed * friction * delta
		velocity.x *= max(speed-drop,0)/speed
		velocity.z *= max(speed-drop,0)/speed

func velo(dir,delta):
	var proj = velocity.dot(dir)
	var accelVel = acc * delta

	if (proj + accelVel )> maxSpeed:
		accelVel = maxSpeed - proj

	velocity += dir * accelVel



func changeHeight(h):
	
	height= max(0.2,h)
	eyeHeight = height * eyeHeightRatio
	if get_node_or_null("Camera") != null:
		$Camera.translation.y = h*0.732143#*(41.0/56.0)
	
	
	
	
	
	if get_node_or_null("MeshInstance") != null:
		$MeshInstance.translation.y = h/2
		$MeshInstance.mesh.height = h

	if get_node_or_null("CollisionShape") == null:
		return
		
	WADG.setCollisionShapeHeight($CollisionShape,h)

	$CollisionShape.translation.y = h/2
		
	emit_signal("heightSet")

func changeThickness(t):
	
	thickness = t
	
	if get_node_or_null("CollisionShape") == null:
		return
	
	WADG.setShapeThickness($CollisionShape,t)
	
	if get_node_or_null("movement") == null:
		return
	
	$movement/footCast.shape.radius = $CollisionShape.shape.radius
	$movement/ShapeCastL.shape.radius  = $CollisionShape.shape.radius
	$movement/ShapeCastH.shape.radius  = $CollisionShape.shape.radius

	
	

	
func saveToDisk():
	

	var pack = PackedScene.new()
	pack.pack($"Camera/gunManager")
	ResourceSaver.save("dbg/gunManager.tscn",pack)


func recursiveOwn(node,newOwner):
	for i in node.get_children():
		recursiveOwn(i,newOwner)

var ppos = Vector3.ZERO
var pLL = 0



func pickup(dict) -> bool:
	if dict.has("giveName"):

		var gName = dict["giveName"]
		var gAmount = dict["giveAmount"]

		if gName == ("hp"):
			if dict.has("limit"):
				if hp  >= dict["limit"]:
					return false
			
			hp += gAmount
			if hp > maxHp:
				hp = maxHp
			
			if dict.has("limit"):
				if hp > dict["limit"]:
					hp =  dict["limit"]
			$UI/ColorOverlay/AnimationPlayer.play("itemPickup")


		elif gName == "armor":
			
			if dict.has("limit"):
				if armor  >= dict["limit"]:
					return false
			
			armor += gAmount
			if armor > maxArmor:
				armor = maxArmor
				
			if dict.has("limit"):
				if armor > dict["limit"]:
					armor =  dict["limit"]
				
			$UI/ColorOverlay/AnimationPlayer.play("itemPickup")

		else:
			if !inventory.has(gName):
				inventory[gName] = {"count":0}

			inventory[gName]["count"] += gAmount
			inventory[gName]["persistant"] = dict["persistant"]
			
			var curHud= $UI/HUDS.get_child(hudIndex)
			
			
			if gName == "Red keycard" and curHud != null:
				var spr = dict["sprite"].duplicate()
				var uiIcon = getChilded(curHud,"keyR")
				if uiIcon != null:
					uiIcon.texture = spr
			
			if gName == "Blue keycard" and curHud != null:
				var spr = dict["sprite"].duplicate()
				var uiIcon = getChilded(curHud,"keyB")
				if uiIcon != null:
					uiIcon.texture = spr
			
			if gName == "Yellow keycard" and curHud != null:
				var spr = dict["sprite"].duplicate()
				var uiIcon = getChilded(curHud,"keyY")
				if uiIcon != null:
					uiIcon.texture = spr
				
			
			$UI/ColorOverlay/AnimationPlayer.play("itemPickup")

	return true

func setWeaponSpriteLightLevel(lightLevel):
	for i in gunManager.weapons.get_chlidren():
		if i.get_node_or_null("AnimatedSprite"):
			i.get_node("AnimatedSprite").modulate = Color(lightLevel,lightLevel,lightLevel,1)


var invulTime = {}
var heatTime = {} 
func takeDamage(damage : Dictionary):

	if dead:
		return
	
	if damage.has("specific"):
		if damageImunity.has(damage["specific"]):
			return
	
	if damage.has("everyNframe"): 
		var t = Engine.get_physics_frames() % damage["everyNframe"]
		if Engine.get_physics_frames() % damage["everyNframe"] != 0:
			return
	
	
	
	if damage.has("iMS") and damage.has("specific"):
		if !invulTime.has("specific"):
			invulTime["specific"] = [OS.get_system_time_msecs(),damage["iMS"]]
		else:
			var diff = OS.get_system_time_msecs() - invulTime["specific"][0]
			if diff < damage["iMS"]:
				return
			else:
				invulTime.erase("specific")
	
	
	#if !damage.has("specific"):
	#	heatTime[damage["specific"]] = Phyics.get_frame
	$AnimationPlayer.play("hurt")
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
	return rad2deg(normal.angle_to(Vector3.UP))

func disableInput():
	

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	processInput = false
	
	if camera!= null:
		if "par" in camera.get_node("../../../"):
			camera.get_node("../../../").processInput = false

	
func enableInput():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	processInput = true
	
	if camera!= null:
		if "par" in camera.get_node("../../../"):
			camera.get_node("../../../").processInput = true


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
	

	var uiIcon = find_node("keyR",true,false)
	var arr = [["keyR","Red keycard"],["keyB","Blue keycard"],["keyY","Yellow keycard"]]
	
	
	for i in arr:
		#var icon = getChilded(curHud,i[0])
		var icon = curHud.find_node(i[0],true,false)
		
		if icon == null:
			return
		if icon.texture == null:
			continue
		
		var found = false
		for item in inventory:
			if item == i[1]:
				found = true
			
		if found == false:
			icon.texture = null


func setSpriteDir() -> void:
	
	
	
	#if !$VisibilityNotifier.is_on_screen() and !Engine.editor_hint:
	#	return
	
	if get_node_or_null("AnimatedSprite3D") == null:
		return

	
	if camera == null:
		return
	

	
	
	var cameraForward = -camera.global_transform.basis.z

	var forward : Vector3 = -global_transform.basis.z
	var left : Vector3 = global_transform.basis.x
	
	var forwardDot : float = forward.dot(cameraForward)
	
	

	
	var anim : String = $AnimatedSprite3D.curAnimation
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
				newAnim = "frontRight"
	
	if anim != newAnim:
		$AnimatedSprite3D.curAnimation = newAnim

func camera():
	if camera == null:
		return
	
	if camera.translation.z == 0:
		camera.get_node("../../../").transform.origin = transform.origin + Vector3(0,eyeHeight + camOffsetY,0)
	else:
		camera.get_node("../../../").transform.origin = transform.origin + Vector3(0,(height*1.1)+camOffsetY,0)

func viewBob(delta):
	
	
	if inputPressedThisTick:
		curAngle += angDelta * Vector3(velocity.x,0,velocity.z).length()*0.006
	elif weaponManager.weapons.translation.y < -0.001:
		curAngle += angDelta *60*0.006
		
	var angle_radians = deg2rad(curAngle)
	var mapped_value = (sin(curAngle) + 1) / 2
	
	weaponManager.weapons.translation.y = -0.02* mapped_value
			
			
		#weaponManager.weapons.translation.y = lerp(weaponManager.weapons.translation.y,0,delta)

	
