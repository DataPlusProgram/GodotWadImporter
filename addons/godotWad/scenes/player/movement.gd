@tool
extends Node3D

enum SLOPESPEED{
	NO_COMPENSATION,
	PRESEVERE_TOTAL_VELOCITY,
	PRESERVE_xz_VELOCITY
}

@onready var footCast : ShapeCast3D= $footCast
@onready var highCast : ShapeCast3D= $ShapeCastH
@onready var footRay : RayCast3D = $footRay


@export var stepAmt = 0.94
@export var forwardSpeed = 1.5625
@export var sideSpeed: float = 1.5625
@export var airSpeed : float = 0.0
@export var friction: float = 0.90625
@export var airFriction: float = 1
@export var maxVelo = Vector3(30,INF,30)
@export var jumpVelo = 3
@export var gravity: float = 0.02857142857
@export var slopeAngle: float = 50
@export var wallSlide: bool = true
@export var snapDownAmt: float = 0.5
@export var slopeSpeed: SLOPESPEED = SLOPESPEED.PRESERVE_xz_VELOCITY
@export var canStepUp = true
@onready var groundNormal : Vector3 = Vector3.INF
@onready var hitNormal : Vector3 = Vector3.ZERO
@onready var par : Node3D = null 
@onready var parHasCamOffset : bool
@export var groundEmergeFix : bool = false

var pPos  = Vector3.ZERO
var onGround = false
var groundAngle = 0
var floatValue = 0.005
var mostRecentFloor : Vector3 = Vector3.ZERO
var touchEffects = {}
var interplateThisFrame = false
var touching : Array[Node]= [] 
var touchingPos : Array[Vector3]= []
var prevPos : Vector3= Vector3.ZERO
var hitWallLastFrame = false
var footprint : PackedVector2Array = []
func _ready():
	
	if !heightWasSet:#this will break npcs if you remove it.
		heightSet()
	
	
	footCast = $footCast
	
	var parColShape = get_node_or_null("../CollisionShape3D")
	
	
	if parColShape != null:
		var shape = parColShape.shape
		if shape != null:
			if shape.get_class() != parColShape.get_class():
				footCast.shape = shape.duplicate()
				highCast.shape = shape.duplicate()
			
	
	if get_parent().has_signal("heightSetSignal"):
		get_parent().connect("heightSetSignal", Callable(self, "heightSet"))
	if get_parent().has_signal("thicknessSetSignal"):
		get_parent().connect("thicknessSetSignal", Callable(self, "thicknessSet"))
		
		
	

	WADG.setCollisionShapeHeight(footCast,0.01)
	
	
	if Engine.is_editor_hint():
		return
	
	footCast.add_exception(get_parent())
	highCast.add_exception(get_parent())
	footRay.add_exception(get_parent())
	
	par = get_parent()
	parHasCamOffset  = "camOffsetY" in par
	


func dirToAcc(forward : Vector3,sideward : Vector3,dir : Vector3,delta):
	var ret = Vector3.ZERO

		
	if !par.onGround:
		dir.x *= airSpeed
		dir.z *= airSpeed
	
	else:
		ret += forward*forwardSpeed*dir.z
	
	if dir.x ==-2 or dir.x == 2: 
		ret +=  forward*forwardSpeed*dir.x*0.5
	else:
		ret += sideward*sideSpeed*dir.x
		#ret += forward*forwardSpeed*dir.z
	
	ret.y += dir.y * jumpVelo *delta
	
	#print(ret)
	return ret
	


func move(delta : float) -> void:
	var pOnGround : bool = par.onGround
	var iY : float = global_position.y
	var velocity : Vector3 = get_parent().velocity
	var headBonk : bool = false
	
	groundNormal = Vector3.ZERO
	interplateThisFrame = false
	if setFlag:
		return
	
	var skipInput : bool = false
	var touchChange : bool = false
	
	#for i in footprint:
	#	WADG.drawSphere(get_tree().get_root(),Vector3(global_position.x+i.x,0,global_position.z+i.y))
	#print(WADG.getShapeHeight(highCast))


	if "processInput" in par:
		if par.processInput == false:
			skipInput = true
	
	if (par.global_position-prevPos).length_squared() > 0.0001 or velocity.y > 0.001:#if I move
		
		#if "charging" in get_parent():
		#	if get_parent().charging:
		#		breakpoint
		
		if velocity.y <= 0:
			if !didTouchingBodiesMove():
				#if isInTouchingShape():
				touchChange = false
			
		touchChange = true

	else: #prevPos == global_position:
		touchChange = didTouchingBodiesMove()
	
	if !touchChange and groundEmergeFix:
		footRay.force_raycast_update()
		var col = footRay.get_collider()
		if !touching.has(col):
			touchChange = true
	
	if touchChange:
		touching = []
		touchingPos = []
		hitWallLastFrame = false
	
	prevPos = global_position
	par.pOnGround = onGround

	velocity.x = clamp(velocity.x,-maxVelo.x,maxVelo.x)
	velocity.y = clamp(velocity.y,-maxVelo.y,maxVelo.y)
	velocity.z = clamp(velocity.z,-maxVelo.z,maxVelo.z)

	
	var remainingVelo : Vector3 = Vector3(velocity.x,0,velocity.z)
	var colliders : Array[Node3D]= []
	
	
	if XZ(velocity).length_squared() > 0.001 or touchChange:
		colliders = moveXZ(remainingVelo,delta)
	
	
	if !onGround or velocity.y > 0.001:

		velocity.y -= gravity*delta
		
		if get_parent().pOnGround == true :#initial tick of leaving the ground doubles gravity
			velocity.y -= gravity*delta
	
		
	
		var col : KinematicCollision3D= get_parent().move_and_collide(Vector3(0,velocity.y*delta,0))
		
		if pOnGround and velocity.y <= 0:#this is snapping down small amounts such a when going down stairs
			footCast.enabled = true
			footCast.force_shapecast_update()
			
			for i in footCast.get_collision_count():
				
				var amt = stepAmt#stepRatio*par.height
				var h = global_position.y - footCast.get_collision_point(i).y
				
				if !touching.has(footCast.get_collider(i)):
					touching.append(footCast.get_collider(i))
					touchingPos.append(footCast.get_collider(i).global_position)
				
				if h <= snapDownAmt:
					var c =  par.move_and_collide(Vector3(0,-snapDownAmt,0))
					interplateThisFrame = true
					if c!= null:
						col = c
				
		if col != null:
			
			if (global_position.y-col.get_position(0).y) > 0.0:#point needs to be below us
				var angle =  col.get_normal(0)
				if !touching.has(col.get_collider()):
						touching.append(col.get_collider())
						touchingPos.append(col.get_collider().global_position)
				
				if isNormalStandable(angle):
					var point = col.get_position(0)
					mostRecentFloor =Vector3(point.x, get_parent().position.y,point.z) - get_parent().position
			else:
				headBonk = true
		else:#if we have no collision after moving on the y axis 
			onGround = false
	
	
	if onGround and touchChange:
		
		var col : KinematicCollision3D =par.move_and_collide(Vector3(0,-0.9*delta,0))
		
		if col != null:
			if !touching.has(col.get_collider()):
				touching.append(col.get_collider())
				touchingPos.append(col.get_collider().global_position)
		
		
		
	if onGround or headBonk:
		velocity.y = 0
		
	
	for i in touching:
		touchingNode(i)
	

	if onGround:
		velocity.x *= pow(friction,delta * 60)# *delta
		velocity.z *= pow(friction,delta * 60)#* friction *delta
	else:
		velocity.x *= pow(airFriction,delta * 60)# *delta
		velocity.z *= pow(airFriction,delta * 60)#* friction *delta
		
	
	if interplateThisFrame:
		if parHasCamOffset:
			par.camOffsetY += (iY -global_position.y)

	par.onGround = onGround
	par.velocity = velocity
	
	

var endFlag = false

func hitWall(normalDeg,delta : float,point : Vector3,isOnGround,velo : Vector3,objectsHit : Array[Node3D]) -> Vector3:
	if endFlag:
		return velo

	hitWallLastFrame = true
	var height = par.height
	var maxStepAmt =  stepAmt
	
	#xz is just the current position but at y = point of collision y
	var xz = Vector3(par.global_position.x,point.y,par.global_position.z)
	var diff =   point - xz
	

	
	#highcast is height of player
	#highcast y=0 would be half above ground and half under
	#by adding half height it is the same as the players collision box
	#we then add the maxStepAmt and cast down by the step amount
	
	
	highCast.position.y = (height/2.0) + maxStepAmt
	highCast.target_position.y = -maxStepAmt 
	
	
	highCast.global_position.x =(xz + (diff).normalized()*0.1).x
	highCast.global_position.z =(xz + (diff).normalized()*0.1).z
	
	highCast.force_shapecast_update()
	
		
	if !highCast.is_colliding():
		return velo
		
		
	var destY: float =  -INF

	var count = highCast.get_collision_count()
	var lowestCeil = INF
	
	if get_parent().velocity.y > 0.001:#stop stepping up when jumping up
		return velo
	
	
	#we check each collision of the highcast
	#>90 will be the collision with the wall
	#==0 will be the flat floor
	#if it's not standable we set it as lowCeil
	
	
	var result : Array = checkHighCast()
	
	destY = result[0]
	lowestCeil = result[1]
	
	
	if destY == -INF:
		return velo
	
	
	destY = destY -global_position.y
	pPos = par.global_position.y
	
	
	var diffN = diff.normalized()*0.06
	
	
	if destY >= maxStepAmt:#this is more of an edge case where multiple upper meshes exist
		destY = - INF
		

		if (global_position.y + maxStepAmt) > lowestCeil:
			return velo
		
		var distFromFloorToCeil = lowestCeil-0.01 - global_position.y
		
		if distFromFloorToCeil < height:#not enough space to fit the character
			return velo
		
		
		highCast.position.y = distFromFloorToCeil - (height/2.0)#middle of char
		highCast.target_position.y =  -distFromFloorToCeil#-((height/2.0)+distFromFloorToCeil)#floorCeilingSpace - (height/2.0)
		
		

		highCast.force_shapecast_update()
		
		var highestFloor = -INF
		
		for i in highCast.get_collision_count():#for each high cast collision
		
			var angle = normalToDegree(highCast.get_collision_normal(i))
			
			
			if angle <= slopeAngle:
				if highCast.get_collision_point(i).y > highestFloor:
					highestFloor = highCast.get_collision_point(i).y
			
		
		if highestFloor > global_position.y and (highestFloor-global_position.y) < maxStepAmt:
			destY = highestFloor-global_position.y

		
		if destY == -INF:#if your hitting a regular wall you will exit here
			return velo
	

	

	var preJumpY = global_position.y
	par.move_and_collide(Vector3(0,destY,0))
	
	
	
	if(par.test_move(global_transform,velo.normalized()*0.01)):#we have made a mistake and cannot move forward after jump - undo
		get_parent().position.y = preJumpY
		return velo
		
	var col = par.move_and_collide(velo*delta)
	var diffY = par.global_position.y - pPos

	
	if col != null:
		return adjustVeloToRemainder(velo,col.get_remainder(),hitNormal)
	
	interplateThisFrame=true
	hitWallLastFrame = false
	
	return Vector3.ZERO


			

var setFlag = false

func normalToDegree(normal : Vector3):
	return rad_to_deg(normal.angle_to(Vector3.UP))

@onready var initialFootRayY = 0.9

var heightWasSet = false

func heightSet():
	
	if !"height" in get_parent():
		return
	var h = get_parent().height
	$ShapeCastH.position.y = h*2
	
	footCast.position.y =  WADG.getShapeHeight($footCast) + 0.1
	footRay.position.y = 0.9#floatValue
	footRay.target_position.y = -(initialFootRayY + floatValue)
	WADG.setCollisionShapeHeight($footCast,0.1)
	heightWasSet = true
	
	

func thicknessSet():
	var thickness = WADG.getShapeThickness($"../CollisionShape3D")
	WADG.setShapeThickness($footCast,thickness)
	WADG.setShapeThickness($ShapeCastH,thickness)
	


func touchingNode(node):
	
	if node.get_parent().has_meta("damage"):
		
		var damageInfo = node.get_parent().get_meta("damage")
		
		if damageInfo.is_empty():
			return
		
		var amt = 10
		var tick = 500
		var grace = 0
		
		var dict = {}
		
		dict["source"] = node
		
		if damageInfo.has("amt"): dict["amt" ]= damageInfo["amt"]
		if damageInfo.has("tickRateMS"): dict["tick"] = damageInfo["tickRateMS"]
		if damageInfo.has("graceMS"):  dict["grace"] = damageInfo["graceMS"]
		if damageInfo.has("specific"):  dict["specific"] = damageInfo["specific"]
		if damageInfo.has("everyNframe") : dict["c"] = damageInfo["everyNframe"]
		touchEffects["damage"] = 1
		
		if damageInfo.has("atHp") and damageInfo.has("atHpAmt"):
			if get_parent().hp <= damageInfo["atHpAmt"]:
				if damageInfo["atHp"] == "nextLevel":
					if "curMap" in get_parent():
						if get_parent().curMap != null:
							if get_parent().curMap.has_method("nextMap"):
								get_parent().hp = 100
								get_parent().curMap.nextMap()

			get_parent().takeDamage(damageInfo)
		else:
			if damageInfo["amt"] > 0:
				get_parent().takeDamage(damageInfo)
		
		if damageInfo.has("specific"):  
			if dict["specific"].has("secret"):
				damageInfo["giveName"] = "secret"
				if get_parent().has_method("pickup"):
					get_parent().pickup(damageInfo)
				
		
		


var node
func debugDrawVelo(velo,color = Color.PURPLE):
	var pos = global_position
	pos.y += par.height/2.0
	
	if is_instance_valid(node):
		node.queue_free()
	#node = WADG.drawLine($"/root",pos,pos+velo,color)
	
## Move on XZ axis
func XZ(vector : Vector3) -> Vector2:
	return Vector2(vector.x,vector.z)



var line = null
func moveXZ(velocity : Vector3, delta : float) -> Array[Node3D]:

	onGround = false
	var objectsHit : Array[Node3D] = []
	
	
	
	var initialCollision : KinematicCollision3D = moveCollide(velocity,delta)
	var remainingVelo : Vector3= velocity
	
	hitNormal = Vector3.ZERO
	#var preInitialWallHitVelo = velocity


	if initialCollision != null and canStepUp:#if we hit someting and stepping up is allowed
		var t = remainingVelo
		remainingVelo = checkCollidersForStep(velocity,remainingVelo,delta,initialCollision,objectsHit,2)
		
	else:
		remainingVelo = Vector3.ZERO# we hit nothing so all velo was spent
			
	
	
	if onGround == false:
		isOnGround(objectsHit)
	
	
	#var posDiff = initialXY-Vector3(get_parent().position.x,0,get_parent().position.z)
	
	if remainingVelo.length() > 0.001:
		par.move_and_collide(remainingVelo*delta)
	
	
	
	setShapeCasts(false)
	
	par.pOnGround = par.onGround
	par.onGround = onGround
	
	if onGround == false:
		groundAngle = Vector3.INF
	
	
	if abs(velocity.x) < 0.001: velocity.x = 0
	if abs(velocity.z) < 0.001: velocity.z = 0
	
	par.velocity.x = velocity.x
	par.velocity.z = velocity.z
	
	
	return objectsHit
	

func moveCollide(velo : Vector3,delta) -> KinematicCollision3D:
	
	if velo.length() < 0.001:
		return null

	var col : KinematicCollision3D = par.move_and_collide(velo*delta)

	
	
	
	if col == null:
		return null
	
	for i in col.get_collision_count():
		if !touching.has(col.get_collider(i)):
				touching.append(col.get_collider(i))
				touchingPos.append(col.get_collider(i).global_position)
					
	for i in col.get_collision_count():
		var angle = normalToDegree(col.get_normal(i))
		
		
		
		if angle > slopeAngle and  angle <= 89:
			onGround = true
			groundNormal = col.get_normal(i)
			var point = col.get_position(i)
			mostRecentFloor = Vector3(point.x, get_parent().position.y,point.z) - get_parent().position

			break 
	
	return col



func projectVeloXZ(velo,normal):
	var project = velo.slide(normal)
	return Vector3(project.x,velo.y,project.z)

func isOnGround(objectsHit : Array[Node3D]):
	
	#WADG.drawSphere($"/root",mostRecentFloor,Color.RED)
	
	var colliders = []
	
	if footRay.enabled == false:
		footRay.enabled = true
		
	
	
	
	
	if isRayOnFloor(mostRecentFloor):
		#groundNormal = footRay.get_collision_normal()
		
		
		if isNormalStandable(groundNormal):
			var point = footRay.get_collision_point()
			var diff = point.y-global_position.y
			
			if diff < 0.5:
				par.position.y += max(0,diff)#clip out of floor if someting like a lift pushes into us
			mostRecentFloor =Vector3(point.x, get_parent().position.y,point.z) - get_parent().position
			return
		#if norm > slopeAngle and norm <= 90.1:
			#var point = footRay.get_collision_point()
			#mostRecentFloor =Vector3(point.x, get_parent().position.y,point.z) - get_parent().position
			#onGround = true
			#return

			 
			
			
	if footCast.enabled == false:
		footCast.enabled = true
	
	
	footCast.force_shapecast_update()
	

	for i in footCast.get_collision_count():
		
		var c = footCast.get_collision_count()
		
		var normal : Vector3 = footCast.get_collision_normal(i)
		if !objectsHit.has(footCast.get_collider(i)):
			objectsHit.append(footCast.get_collider(i))


		if !isNormalStandable(normal,false):
			continue
		
		#if norm > slopeAngle and norm <= 90.1:
		#	continue
		
		var point = footCast.get_collision_point(i);
		var h : float= get_parent().global_position.y -point.y
		
		
		if h <= 0.01:
			if (global_position.y-footCast.get_collision_point(i).y) > 0.0001:
				if isNormalStandable(normal):
					onGround = true
					
					groundNormal = normal
					mostRecentFloor =Vector3(point.x, get_parent().position.y,point.z) - get_parent().position
					return
	
	
			

func pushBack(col : KinematicCollision3D,delta):
	
	
	var normalDeg = normalToDegree(col.get_normal())
	var veloXZ = XZ(get_parent().velocity)
	
	var normalProj = XZ(par.velocity.project(col.get_normal()))

	if normalProj.length() < 0.001:
		return
	
	normalProj = XZ(par.velocity.project(col.get_normal()))*0.1
	
	
	par.velocity.x -= normalProj.x
	par.velocity.z -= normalProj.z
	

func parXZ():
	return(XZ(get_parent().velocity))

func parVelo():
	return(get_parent().velocity)

func parVeloSloped():

	var origLength = parVelo().length()
	var orignalXZlen = parXZ().length()
	
	if groundNormal != Vector3.INF:
		
		var velocityProjection = parVelo().project(groundNormal)
		
		var diff = parVelo() - velocityProjection
		
		var final = diff.normalized()*origLength
		
		if slopeSpeed == SLOPESPEED.PRESEVERE_TOTAL_VELOCITY:
			return final
		
		var t =  parXZ().normalized() * orignalXZlen
		var final2 = Vector3(t.x,final.y,t.z)

		return final2
		
	return parVelo()
	

func adjustVeloToRemainder(velo : Vector3,remainder : Vector3,colNormal,slide = true) -> Vector3:
	var speedAdjust = velo.normalized() * (velo.length() - remainder.length())
	
	if slide == false:
		return speedAdjust
	
	return speedAdjust.slide(colNormal)

func setShapeCasts(value : bool) -> void:

	highCast.enabled = value
	footCast.enabled = value
	footRay.enabled = value
	
func isRayOnFloor(pos : Vector3):


	footRay.position = global_position + Vector3(pos.x,initialFootRayY,pos.z)
	footRay.force_update_transform()
	footRay.force_raycast_update()
	
	if !footRay.is_colliding():
		return false
		
	var normal =  footRay.get_collision_normal()
	return isNormalStandable(normal)


func isNormalStandable(norm : Vector3,updateState : bool = true) -> bool:
	
	if norm == Vector3(0,0,1):
		return false
	
	if norm == Vector3(0,1,0):
		if updateState:
			onGround = true
			groundNormal = footRay.get_collision_normal()
		return true
	
	var angle : float = normalToDegree(footRay.get_collision_normal())
	
	
	
	if angle < slopeAngle:
		if updateState:
			onGround = true
			groundNormal = footRay.get_collision_normal()
		return true
		
	return false
	

func getBodyCollisionShape(body : CollisionObject3D):
	var ret = []
	for i in body.get_children():
		if !(i is CollisionShape3D):
			continue
		
		ret.append(i)
	
	return ret


func isInTouchingShape():
	
	if touching.size() != 1:
		return -1
	

	var shapes = getBodyCollisionShape(touching[0])
	if shapes.size() == 1:
		return checkColShapeOverlap(shapes[0])
	else: return -1

func isFlat(points : PackedVector3Array):
	
	if points.size() < 2:
		return true
	
	var targetY = points[0].y
	
	for i in points:
		if i.y != targetY:
			return false
			
	return true 


var debug = []
func checkColShapeOverlap(col):
	
	
	
	if !(col.shape is ConvexPolygonShape3D):
		return -1
		#if col.shape is ConcavePolygonShape3D:
		#	var faces = col.shape.get_faces()
		#	breakpoint
		#else:
		#	return -1
		#
	if !isFlat(col.shape.points):
		return -1
	
	var pointsTransform : PackedVector2Array = []
	
	for idx in col.shape.points.size():
		pointsTransform.append(Vector2(col.shape.points[idx].x+col.global_position.x,col.shape.points[idx].z+col.global_position.z))
	
	#if footprint.is_empty():
	#	footprint = WADG.getCollisionShapeFootprint(parColShape.shape)
	
	#for i in debug:
	#	i.queue_free()
	
	#debug.clear()
	
	
	#for i in pointsTransform:
		#debug.append(WADG.drawSphere($"/root",Vector3(i.x,global_position.y,i.y)))
	#
	#for j in footprint:
		#debug.append(WADG.drawSphere($"/root",Vector3(j.x+global_position.x,global_position.y,j.y+global_position.z)))
	#
	#for j in footprint:
		#if !Geometry2D.is_point_in_polygon(j+Vector2(global_position.x,global_position.z),pointsTransform):
			#return 0
			
	
	return 1

func didTouchingBodiesMove() -> bool:
	for i : int in touching.size():
		if !is_instance_valid(touching[i]):
			return true
		if touching[i].global_position != touchingPos[i]:
			return true
		
	return false
	#Geometry2D.is_point_in_polygon()  

func checkHighCast():
	
	var lowestCeil : float = INF
	var destY: float =  -INF
	
	for i in highCast.get_collision_count():
		
		var angle = normalToDegree(highCast.get_collision_normal(i))

		if angle > slopeAngle:#a ceil
			if highCast.get_collision_point(i).y < lowestCeil:
				lowestCeil = highCast.get_collision_point(i).y
			
		if angle < 90.001:#floor
			if  highCast.get_collision_point(i).y > destY:
				destY = highCast.get_collision_point(i).y
				
	return [destY,lowestCeil]

var nodes = []

func checkCollidersForStep(velocity : Vector3, remainingVelo : Vector3,delta : float,collision : KinematicCollision3D,objectsHit : Array,breakThisTime = 1):
	for i in range(0,collision.get_collision_count()):
		var normalDeg = normalToDegree(collision.get_normal(i))

		
		if normalDeg > 89:# we have hit a wall
			
			remainingVelo = adjustVeloToRemainder(velocity,collision.get_remainder(),collision.get_normal(i),false)#we don't slide this time in particular as we might still be able to spend the remaining velo correctly if we jump over wall
			var t = remainingVelo
			remainingVelo = hitWall(normalDeg,delta,collision.get_position(i),get_parent().onGround,remainingVelo,objectsHit)
			
			if remainingVelo == t and breakThisTime > 0:
				#var newVelo = remainingVelo.slide(collision.get_normal(i))
				var newVelo = adjustVeloToRemainder(remainingVelo,collision.get_remainder(),collision.get_normal(i),true)

				if newVelo.length() > 0.01:
					
					var firstPos = get_parent().position
					var collision2 : KinematicCollision3D = moveCollide(newVelo,delta)
					
					
					if collision2 != null:
						
						var pRemainingVelo = remainingVelo
						remainingVelo = checkCollidersForStep(newVelo,remainingVelo,delta,collision2,objectsHit,breakThisTime-1)
						if (firstPos-get_parent().position).y == 0:
							#get_parent().position = firstPos
							return adjustVeloToRemainder(pRemainingVelo,collision.get_remainder(),collision.get_normal(i))
							
							
						
						return adjustVeloToRemainder(remainingVelo,collision2.get_remainder(),collision2.get_normal(i),false)
					else:
						return Vector3.ZERO# we hit nothing so all velo was spent
				 
				
		remainingVelo = adjustVeloToRemainder(velocity,collision.get_remainder(),collision.get_normal(i))
	
	return remainingVelo
