tool
extends KinematicBody

export(float) var initialHP  = 3
var dead : bool = false
var sum : int = 0
var count : int = 0
export var npcName = "npc"
export var height : float = 5 setget setHeight
export var thickness : float setget setThickness
export var projectile = ""
export var meleeRange : float = 3
export var projectileRange : float = 5
#export var originAtFeet = true
export(String)var drops = ""
export var deleteOnDeath = false
export var painTimeMS = 0.114284

var ASprite  = null
var APlayer : AnimationPlayer = null
var Sounds  : AudioStreamPlayer3D = null

var projectileNodeRefernce : Node = null
var onFloor = true
var stateChanged : bool = false
var target : Node = null
var pTarget = null
var aiId : int = -1
var doTick = false
var damageImunity = ["nukage"]
var hurtCooldown = 0
var createdBloodDecal = []
var canHear = []
var projectileSpawnPoints = []
var projectilesPerShot = 1
var castDamage = 12
var speed = 5
var alwaysFire = false
export var continuousFire = false
onready var targetPos = translation
export var painChance = 0.7930
export var hitDecal : AnimatedTexture  = null
export var hitDecalSize = 1.0


enum STATE {
	WALK,
	ATTACK,
	DEAD, 
	HURT,
}

var state = STATE.WALK
var pState = null
var map = null
var broadphaseThisTick = null
onready var hp = initialHP

var velo : Vector3 = Vector3.ZERO


func _init():
	set_meta("originAtFeet",true)

func _ready():
	
	if Engine.editor_hint: 
		return
	
	if get_node_or_null("castWeapon") != null:
		$castWeapon.damage = castDamage
	$footCast.shape = $CollisionShape.shape.duplicate()
	$footCast.target_position = Vector3(0,-0.1,0)
	
	WADG.setCollisionShapeHeight($footCast,0.1)
	
	
	ASprite = $AnimatedSprite3D
	APlayer = $AnimationPlayer
	Sounds = $AudioStreamPlayer3D
	var t = ASprite.frames
	
	
	for i in get_children():
		if i.get_name().find("_") != -1:
			if i.get_name().split("_")[0] == "projectileSpawn":
				projectileSpawnPoints.append(i)
				
	
	if APlayer != null:
		if !APlayer.has_animation("fire"): 
			projectileRange = -1

	
	if get_node_or_null("../../") != null:
		if get_parent().get_parent().get("aiEnts") != null:
			get_parent().get_parent().registerAi(self)
			aiId = get_parent().get_parent().aiEnts.size()-1
	
	
	map =  get_node_or_null("../../")
	if map != null:
		if !("aiEnts" in map):
			map = null
		
	
	if map == null:
		return
	
	if !map.has_meta(npcName):
		map.set_meta(npcName,0)

	map.set_meta(npcName,map.get_meta(npcName)+1)
	
	

var pGetCurSpriteWidth : int = 0
func _physics_process(delta):
	
	
	if Engine.editor_hint:
		setSpriteDir()
		return
	
	
	broadphaseThisTick == null
	
	
	for i in createdBloodDecal:
		if is_instance_valid(createdBloodDecal):
			createdBloodDecal.erase(i)
		
	
	
	if doTick == false and map != null:
		return

	if get_node_or_null("castWeapon") != null:
		if state == STATE.ATTACK:
			$castWeapon.get_child(0).enabled = true
		else:
			$castWeapon.get_child(0).enabled = false
	
		
	if Engine.editor_hint: return
	
	velo.x *= 0.3
	velo.z *= 0.3

	
	pTarget = target
	if !dead:
		look()
	
	if get_node_or_null("lightValue") != null:
		$lightValue.tick()
	
	if pTarget != target:
		Sounds.playAlert()
		count = 8
		
	
	 
	if hurtCooldown > 0:
		hurtCooldown = max(0,hurtCooldown-delta)
		if hurtCooldown <= 0 and state == STATE.HURT:
			state = STATE.WALK
	
	if hp < 0:
		state = STATE.DEAD

	if pState != state:
		stateChanged = true
	else:
		stateChanged = false
	
	pState = state
	
	
	if state == STATE.WALK:
		stateWalk()
	elif state == STATE.ATTACK and is_instance_valid(target):
		if $AnimationPlayer.has_animation("melee"):
			if (translation-target.translation).length() <= meleeRange:
				stateMelee()
				return
				
		if $AnimationPlayer.has_animation("fire"): 
			stateFire()
	elif state == STATE.DEAD:
		deadState(delta)
	elif state == STATE.HURT:
		 $AnimationPlayer.play("hurt")

	
	if !$footCast.is_colliding():
		velo.y -= 1.7*delta
	else:
		velo.y = 0


	doTick = false
	if velo.length_squared() > 0.001:
		if is_equal_approx(velo.x, 0) and is_equal_approx(velo.z,0):
			move_and_collide(velo)
		else:
			move_and_slide(velo)
	

func takeDamage(dict):
	var source = null
	
	
	if dict.has("specific"):
		if damageImunity.has(dict["specific"]):
			return
	
	if dict.has("source"):source = dict["source"]
	if dict.has("amt"): hp -=  dict["amt"]
	if dict.has("everyNframe"): 
		var t = Engine.get_physics_frames() % dict["everyNframe"]
		if Engine.get_physics_frames() % dict["everyNframe"] != 0:
			return
	
	if hp >0:
		$AudioStreamPlayer3D.playHurt()
	else:
		state = STATE.DEAD
		dead = true
		
	
	if source == null:
		return
	
	if target == source:
		pass
	
	elif source != null:
		pTarget = source
		target = source
		count = 0
		
	
	var r = randf()
	
	if r < painChance:

		state = STATE.HURT
		hurtCooldown = painTimeMS
	else:
		pass
		
	
	var decalPos = Vector3.ZERO
	
	if dict.has("position"):
		decalPos = dict["position"]
		
	spawnBlood(decalPos)


func stateWalk() -> void:
	if stateChanged == true:
		APlayer.play("idle")
		

	setSpriteDir()
	
	if target != null and is_instance_valid(target):
		if "hp" in target:
			if target.hp <= 0:
				target = null
	
	if target !=null and is_instance_valid(target):
		
		var distTo : float =  translation.distance_to(target.translation)
	
		
		
		
		look_at(target.translation,Vector3.UP)
		rotation_degrees.x = 0
		
		if count > 0:
			count -= 1
			return
		
		var r = (randi() % 80)
		
		
		if (r == 56 or alwaysFire) and lookBroadphaseCheck(target.translation,-get_global_transform().basis.z):
			if continuousFire:
				alwaysFire = true
			if canSeeNodeCast(target):
				state = STATE.ATTACK
		
		
		
		
		
		if distTo <= meleeRange or (distTo <= projectileRange and projectileRange > 0):
			state = STATE.ATTACK
		
		
		if get_node_or_null("navigationLogic") != null:
			if distTo > meleeRange:
				targetPos = $navigationLogic.tick()
			else:
				targetPos = null
	
	
	if target != null:
		if targetPos != null:
			velo.x = (targetPos-translation).normalized().x*speed
			velo.z = (targetPos-translation).normalized().z*speed
		
		



func stateMelee() -> void:
	

	if stateChanged == true:
		APlayer.play("melee")
		$castWeapon.fireCustomDmg(14)
		
	if !APlayer.is_playing():
		state = STATE.WALK

func stateFire() -> void:
	

	if stateChanged == true:
		APlayer.play("fire")

		
	if !APlayer.is_playing():
		state = STATE.WALK

func deadState(delta) -> void:
	
	if stateChanged:
		$footCast.enabled = true
		APlayer.stop(false)
		ASprite.curAnimation = "front"#only front sprites have death anims
		APlayer.play("die")
		
		for i in createdBloodDecal:
			if is_instance_valid(i):
				i.queue_free()


		
		for i in get_children():
			if i.get_class() == "CollisionShape":
				i.queue_free()
		
		dead = true
		
		
		if !drops.empty():
			var spawnPos = global_translation
			spawnPos.y += height / 2.0
			
			var ent = ENTG.spawn(get_tree(),drops,spawnPos,Vector3.ZERO,"",map)
			if ent.get_class() == "RigidBody":
				ent.add_central_force(-Vector3.UP*1000)
			#ent.linear_velocity.x = 10
			
#		if drops != null:
#			var rand = randf()
#			for i in drops:
#				if typeof(i) != TYPE_ARRAY:
#					continue
#				if i.size() < 2:
#					continue
#				if rand < i[1]:
#					var ent = ENTG.spawn(get_tree(),i[0],global_translation,Vector3.ZERO)
					#ent.sleeping = false
					#ent.linear_velocity.y = -1000
					#ent.add_central_force(-Vector3.UP*100)
					
			
		
		
		if map != null:
			map.set_meta(npcName,map.get_meta(npcName)-1)
		yield(APlayer,"animation_finished")
		
		
		
		if deleteOnDeath:
			queue_free()
		else:
			deleteNodes()
		
	
	if !$footCast.is_colliding():
		move_and_collide(Vector3.DOWN*3*delta)
		#translation.y -= 3 * delta

func revive() -> void:
	APlayer.play_backwards("die")
	#ASprite.translation.y += height*0.5
	hp = initialHP
	dead = false


func deleteNodes():
	for i in get_children():
		var className = i.get_class()
		if(className != "AudioStreamPlayer3D" and i.name != "AnimatedSprite3D" and i.name != "footCast" and className != "VisibilityNotifier"):
			i.queue_free()


var pCameraPos : Vector3 = Vector3(0,0,0)
var pCameraForward : Vector3 = Vector3(0,0,0)

func setSpriteDir() -> void:
	
	
	if !Engine.editor_hint:
		if !$VisibilityNotifier.is_on_screen():
			return
	
	if ASprite == null:
		return
	
	var camera : Camera = get_viewport().get_camera()
	
	if camera == null:
		return
	

	if camera.translation == pCameraPos and -camera.global_transform.basis.z == pCameraForward:
		return
	
	
	
	var cameraForward = -camera.global_transform.basis.z
	
	pCameraPos = camera.translation
	pCameraForward = cameraForward
	
	var forward : Vector3 = -global_transform.basis.z
	var left : Vector3 = global_transform.basis.x
	
	var forwardDot : float = forward.dot(cameraForward)
	
	

	
	var anim : String = ASprite.curAnimation
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
		ASprite.curAnimation = newAnim

func setHeight(h):
	
	
	
	#if get_parent() == null and !Engine.editor_hint:
	#	return
	#if !Engine.editor_hint:
	#	return
	
	if h < 0:
		h = 0.01
	
	height = h
	
	
	
	if get_node_or_null("cast") != null:
		$cast.translation.y = height * 0.8
	
	if get_node_or_null("CollisionShape") == null:
		return
	
	WADG.setCollisionShapeHeight($CollisionShape,h)
	
	$CollisionShape.translation.y = h/2.0
	$VisibilityNotifier.aabb.size.y =h#
	$VisibilityNotifier.aabb.position.y = 0

func setThickness(thick):
	thickness = thick
	if get_node_or_null("CollisionShape") != null:
		WADG.setShapeThickness($CollisionShape,thickness)
		
	if get_node_or_null("footCast") != null:
		WADG.setShapeThickness($footCast,thickness)

func getCurSpriteHeight():
	var curFrame = ASprite.frame
	var curAnim = ASprite.animation
	var cSprite = ASprite.frames.get_frame(curAnim,curFrame)
	var curSpriteHieght = cSprite.get_height()
	
	return(curSpriteHieght*ASprite.pixel_size)-height

var pAnim : String = ""
var pFrame : int = 0
var pWidth : int = 0
func getCurSpriteWidth() -> int:
	if is_instance_valid(ASprite):
		if ASprite.animation != null:
			if ASprite.animation == pAnim and ASprite.frame == pFrame:
				return pWidth
	
		pAnim = ASprite.animation
		pFrame = ASprite.frames.frame
	
		#var cSprite = ASprite.frames.get_frame(ASprite.animation,ASprite.frame)
		#pWidth = cSprite.get_width()
		return pWidth
		
	return 0





func look() -> void:
	
	for i in canHear:
		if i.is_in_group("player"):
			target = i
			canHear = []
			return
	
	
	
	
	canHear = []
	var forward : Vector3 = -get_global_transform().basis.z
	
	var allPlayers = get_tree().get_nodes_in_group("player")
	
	for node in allPlayers:
		var diff : Vector3 = node.translation - translation
		if "hp" in node:
			if node.hp <= 0:
				continue
		
		if diff.length() <= 2:
			target = node
			return
		
		if lookBroadphaseCheck(node.translation,forward):
		#if true:
			if canSeeNodeCast(node):
				target = node
				$cast.targetNode = node
				
		else:
			$cast.targetNode = null


var pDiff : Vector3 = Vector3(0,0,0)
var pForwad : Vector3 = Vector3(0,0,0)
var pAcos : float = -9939
var pDot : float = 0


func lookBroadphaseCheck(targetPos :Vector3,forward : Vector3) -> bool:
	
	if get_node_or_null("cast") == null:
		broadphaseThisTick = false
		return false
	
	var diff : Vector3 = targetPos - translation
	diff = (diff).normalized()
	var forwardDot : float = diff.dot(forward)
		
		
	if forwardDot < 0.00:
		$cast.enabled = false
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
		
	$cast.enabled = false
	broadphaseThisTick = true
	return false


func fire():
	var p = null
	

	if !projectile.empty():
		
		if projectileSpawnPoints.empty():
			p = createProjectile(projectile,global_transform)
			if p!= null:
				$"/root".add_child(p)
				
		else:
			for i in projectileSpawnPoints:
				var t = i.global_transform
				t.origin.y -= height*0.5
				p = createProjectile(projectile,t)
				if p!= null:
					$"/root".add_child(p)

		#if p.has_method("reset_physics_interpolation"):
		#	p.reset_physics_interpolation()
	
	else:
		$castWeapon.fire()


var pDiff2 : Vector3 = Vector3(0,0,0)
var pRot : float = 0

func createProjectile(projStr,projTransform):
	var p = ENTG.fetchEntity(projStr,get_tree(),"Doom",false)
	
	if p == null:
		return null
	
		
	p.visible = true
	var par = self
		
	p.exceptions.append(self)
	p.add_collision_exception_with(self)
	p.transform = projTransform
	p.translation.y += $cast.translation.y
		
		
	var diff = (projTransform.origin-target.translation).length()
		
	if "height" in target:
		diff -= randf()*target.height
	var angle = -atan(((projTransform.origin.y)-target.translation.y)/diff)
	
	p.rotation.x = angle
	
	p.shooter = self
	return p

func canSeeNodeCast(target : Node) -> bool:
	
	if target == null:
		return false
	
	if get_node_or_null("cast") == null:
		return false
	
	if $cast.targetNode != target:
		$cast.targetNode = target
		return false
	
	
	if $cast.get_collider() == target:
		return true
		
	return false
	#var diff : Vector3 = target.translation - Vector3(translation.x,translation.y,translation.z)
	
	#$cast.maxLength = diff.normalized().length() * 1.01
	
	#if pDiff2 != diff or -rotation.y != pRot:
	#	$cast.cast_to = diff.rotated(Vector3.UP,-rotation.y).normalized()
		
	#pDiff2 = diff
	#pRot = -rotation.y
	
			
	#if $cast.get_collider() == target:
	#	return true
	#else:
	#	return false


func spawnBlood(pos : Vector3 = Vector3.ZERO):
	var spr = Sprite3D.new()
	spr.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	spr.texture = hitDecal
	spr.translation = pos#-global_translation
	spr.pixel_size = hitDecalSize * 1
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.3
	timer.connect("timeout",spr,"queue_free")
	timer.autostart = true
	spr.add_child(timer)
	#add_child(spr)
	createdBloodDecal.append(spr)
	$"/root".add_child(spr)

func lightLevel():
	
	if map == null:
		return
	
	
	var posXZ = Vector2(global_translation.x,global_translation.z)
	var p = WADG.getSectorInfoForPoint(map,posXZ)
	
	var light = p["light"]/255.0
	ASprite.modulate = light
	

