tool
extends Spatial

enum SLOPESPEED{
	NO_COMPENSATION,
	PRESEVERE_TOTAL_VELOCITY,
	PRESERVE_xz_VELOCITY
}

onready var footCast = $footCast
onready var lowCast = $ShapeCastL
onready var highCast = $ShapeCastH


export var stepRatio = 0.45
export var airStepRatio = 0.28
export var forwardSpeed = 1.5625
export(float) var sideSpeed = 1.5625
export(float) var friction = 0.90625
export var maxVelo = Vector3(30,INF,30)
export var jumpVelo = 3
export(float) var gravity = 0.02857142857
export(float) var slopeAngle = 50
export(bool) var wallSlide = true
export(float) var snapDownnAmt = 4 
export(SLOPESPEED) var slopeSpeed = SLOPESPEED.PRESERVE_xz_VELOCITY




var groundAngle = 0
var groundNormal = Vector3.ZERO
func _ready():
	get_parent().connect("heightSet",self,"heightSet")
	footCast.add_exception(get_parent())
	lowCast.add_exception(get_parent())
	highCast.add_exception(get_parent())
	
	
var touchEffects = {}




func move(delta):
	 
	var strafe = false
	var strafeDir = 0
	
	get_parent().dir
	var dir = get_parent().dir
	
	if setFlag:
		print(lowCast.is_colliding(),",",highCast.is_colliding())
		return
	
	var skipInput = false
	
	if "processInput" in get_parent():
		if get_parent().processInput == false:
			skipInput = true
	
	if skipInput == false:
		if Input.is_action_pressed("strafe"): strafe = true
		
		if !strafe: 
			if Input.is_action_pressed("turnRight"): get_parent().rotate_y(rad2deg(-1*delta*0.02))
			if Input.is_action_pressed("turnLeft"): get_parent().rotate_y(rad2deg(+1*delta*0.02))
		elif get_parent().onGround:
			if Input.is_action_pressed("turnRight"): dir.x += 1
			if Input.is_action_pressed("turnLeft"): dir.x -= 1
		
	
	
	
	get_parent().velocity += get_parent().transform.basis.z*forwardSpeed*dir.z
	if dir.x ==-2 or dir.x == 2: 
		get_parent().velocity += get_parent().transform.basis.x*forwardSpeed*dir.x*0.5
	else:
		get_parent().velocity += get_parent().transform.basis.x*sideSpeed*dir.x
		
	get_parent().velocity.y += dir.y * jumpVelo *delta * 60

	
	var pVelo = get_parent().velocity
	
	
	
	
	get_parent().velocity.x = clamp(pVelo.x,-maxVelo.x,maxVelo.x)
	get_parent().velocity.y = clamp(pVelo.y,-maxVelo.y,maxVelo.y)
	get_parent().velocity.z = clamp(pVelo.z,-maxVelo.z,maxVelo.z)

	

	if !get_parent().onGround:
		get_parent().velocity.y -= gravity*delta
		
		if get_parent().pOnGround == true :#initial tick of leaving the ground doubles gravity
			get_parent().velocity.y -= gravity*delta
			lowCast.force_shapecast_update()
			if lowCast.get_collision_count() > 0:
				var colY =  lowCast.get_collision_point(0).y - get_parent().global_translation.y
				if colY > -snapDownnAmt and colY < 0:
					get_parent().camOffsetY = -colY
					get_parent().move_and_collide(Vector3(0,colY,0))
					
					if get_parent().has_method("camera"):
						get_parent().camera
			#get_parent().move_and_collide(Vector3(0,-16,0))
	else:
		get_parent().velocity.y = - 0.01
	
	var parent = get_parent()
	var velocity = get_parent().velocity
	
	var veloXZ = Vector3(velocity.x,0,velocity.z)
	
	
	var colliders = rootMoveFunc(delta)
	
	
	for i in colliders:
		touchingNode(i)
	

	
	
	if get_parent().onGround:
		get_parent().velocity.x *= pow(friction,delta * 60)# *delta
		get_parent().velocity.z *= pow(friction,delta * 60)#* friction *delta
	
	parent.pPos = translation
	
func hitStair(normalDeg,point : Vector3,pCol : KinematicCollision,onGround):


	var xz = Vector3(get_parent().global_translation.x,point.y,get_parent().global_translation.z)

	
	
	var diff =   point - xz
	var angle = rad2deg((get_parent().velocity.normalized().angle_to(diff)))
	
	
	
	if angle > 80:
		return pCol
	
	var maxStepAmt = get_parent().height * stepRatio
	
	if !onGround: maxStepAmt = get_parent().height * airStepRatio

	lowCast.translation = Vector3.ZERO
	
	lowCast.global_translation =xz + (diff).normalized()*0.1
	lowCast.translation.y = maxStepAmt#we start the lowcast at the highest piont we could ever step up
	lowCast.target_position.y = -(get_parent().height)# + stepAmt
	


	var highestPoint = -Vector3.INF
	lowCast.force_shapecast_update()
	
	
	
	for i in lowCast.get_collision_count():
		var p = lowCast.get_collision_point(i)
		
		var normal =  normalToDegree(lowCast.get_collision_normal(i))
		
		
		if normal < 181:
			if p.y > highestPoint.y:
				highestPoint = p
			
	
	if highestPoint == -Vector3.INF:
		return pCol
	
	
	var thisStepHeight = (highestPoint.y-get_parent().global_translation.y)
	
	
	if thisStepHeight > maxStepAmt:#this should never happens but it does
		return pCol
	
	highCast.global_translation = lowCast.global_translation
	highCast.translation.y = thisStepHeight + get_parent().height  - WADG.getCollisionShapeHeight(highCast)/2.0
	highCast.target_position.y = -get_parent().height + WADG.getCollisionShapeHeight(highCast)#
	
	
	
	highCast.force_shapecast_update()
	
	var freeY = -INF
	
	if highCast.is_colliding():
		
		for i in highCast.get_collision_count():
			var p = highCast.get_collision_point(i)
			if p.y > freeY:
				freeY = p.y

		
		return pCol


	var diffN = diff.normalized()*0.05
	
	var r = pCol.remainder
	
	

	var veloN = XZ(get_parent().velocity).normalized()*0.01
	get_parent().camOffsetY = -thisStepHeight
	get_parent().move_and_collide(Vector3(0,thisStepHeight+0.01,0))
	var col = get_parent().move_and_collide(Vector3(diffN.x,0,diffN.z))

	return col



	
			

var setFlag = false

func normalToDegree(normal : Vector3):
	return rad2deg(normal.angle_to(Vector3.UP))

func heightSet():
	
	$ShapeCastH.translation.y = get_parent().height*2
	$footCast.translation.y = get_parent().height/2.0
	$footCast.target_position.y =  -get_parent().height
	WADG.setCollisionShapeHeight($footCast,get_parent().height/2.0)
	

func touchingNode(node):
	if node.get_parent().has_meta("damage"):
		
		var damageInfo = node.get_parent().get_meta("damage")
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
					if get_parent().curMap != null:
						if get_parent().curMap.has_method("nextMap"):
							get_parent().hp = 100
							get_parent().curMap.nextMap()

			get_parent().takeDamage(damageInfo)
		else:
			get_parent().takeDamage(damageInfo)
			
		


func XZ(vector : Vector3):
	return Vector3(vector.x,0,vector.z)



func rootMoveFunc(delta):
	var col : KinematicCollision = null
	var par = get_parent()
	var velocity = get_parent().velocity
	var initialXY = XZ(get_parent().translation)
	
	

	var colliders = isOnGround()
	var sliceSize = 1
	
	for i in sliceSize:
		
		if slopeSpeed == SLOPESPEED.NO_COMPENSATION:
			col = moveCollide(parVelo()*delta,delta)
		else:
			col = moveCollide(parVeloSloped()*delta,delta)
		

	
	if col != null:
		if !colliders.has(col.collider):
			colliders.append(col.collider)
		var normalDeg = normalToDegree(col.normal)

		if normalDeg > 89:
			hitStair(normalDeg,col.position,col,get_parent().onGround)
		
		for i in 2:
			if col == null:
				break
				
			col = moveCollide(col.remainder,delta)
			

	
	
	if wallSlide:
		if col != null and normalToDegree(col.normal) > slopeAngle:
			get_parent().velocity.x = parVelo().slide(col.normal).x
			get_parent().velocity.z = parVelo().slide(col.normal).z
			get_parent().velocity.y = parVelo().slide(col.normal).y
		
	
	var posDiff = initialXY-Vector3(get_parent().translation.x,0,get_parent().translation.z)
	touchEffects = {}

	
	return colliders
	

func moveCollide(velo,delta):
	
	var par = get_parent()
	var col = par.move_and_collide(velo)
	
	var veloXZ = parXZ()
	
	
	if abs(veloXZ.x) < 0.001: par.velocity.x = 0
	if abs(veloXZ.z) < 0.001: par.velocity.z = 0
		
	
	if col == null:
		return null

	return col

func isOnGround():
	
	var colliders = []
	
	get_parent().pOnGround = get_parent().onGround
	get_parent().onGround = null
	groundAngle = null
	groundNormal = null
	
	$footCast.force_shapecast_update()

	for i in $footCast.get_collision_count():
		#print($movement/footCast.get_collider(i))
		var norm = normalToDegree($footCast.get_collision_normal(i))
		var h = $footCast.get_collision_point(i).y - get_parent().global_translation.y

		colliders.append($footCast.get_collider(i))
		norm = stepify(norm,0.01)
		
		if h <= get_parent().height/2.0 and h > -0.1:
			if norm < slopeAngle:
				groundAngle = norm
				groundNormal = $footCast.get_collision_normal(i)
				#groundNormal =angleToVector(ceil(groundAngle))
				get_parent().onGround = true
				
				break
				
				

	return colliders

func pushBack(col : KinematicCollision,delta):
	
	return
	var normalDeg = normalToDegree(col.normal)
	var veloXZ = XZ(get_parent().velocity)
	var par = get_parent()
	
	var normalProj = XZ(par.velocity.project(col.normal))

	if normalProj.length() < 0.001:
		return
	
	normalProj = XZ(par.velocity.project(col.normal))*0.1
	
	
	par.velocity.x -= normalProj.x
	par.velocity.z -= normalProj.z
	

func parXZ():
	return(XZ(get_parent().velocity))

func parVelo():
	return(get_parent().velocity)

func parVeloSloped():
	
	
	
	var origLength = parVelo().length()
	var orignalXZlen = parXZ().length()
	
	if groundNormal != null:
		
		var velocityProjection = parVelo().project(groundNormal)
		
		var diff = parVelo() - velocityProjection
		
		var final = diff.normalized()*origLength
		
		if slopeSpeed == SLOPESPEED.PRESEVERE_TOTAL_VELOCITY:
			return final
		
		var t =  parXZ().normalized() * orignalXZlen
		var final2 = Vector3(t.x,final.y,t.z)

		return final2
		
	return parVelo()
	

