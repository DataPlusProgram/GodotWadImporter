@tool
extends Node

@export var sprites: Resource

var loader
var scaleFactor 
@export var spawnWeapons = ["pistol","fists"]
var depends
var entityLoader

@export var idle: String = "A"
@export var chase: String = "ABCD"
@export var attack: String = "EF"
@export var melee: String = ""
@export var hurt: String = "GG"
@export var dying: String = "HJKLMN"
@export var gib: String = "OPQRSTUVW"
@export var heal: String = ""
@export var jumping : String = ""
@export var running: String = ""

@export var hurtSounds = ["DSPLPAIN"] # (Array,String)
@export var deathSounds = ["DSPLDETH"] # (Array,String)
@export var gruntSound: String = ""

var animationPlayer
var animatedSprite
var animationLibrary
var headSprites80 = ["STFST01","STFST00","STFST02","STFTL00","STFTR00","STFOUCH0","STFEVL0","STFKILL0"]
var headSprites60 = ["STFST11","STFST10","STFST12","STFTL10","STFTR10","STFOUCH1","STFEVL1","STFKILL1"]
var headSprites40 = ["STFST21","STFST20","STFST22","STFTL20","STFTR20","STFOUCH2","STFEVL2","STFKILL2"]
var headSprites20 = ["STFST31","STFST30","STFST32","STFTL30","STFTR30","STFOUCH3","STFEVL3","STFKILL3"]
var headSprites1 = ["STFST41","STFST40","STFST42","STFTL40","STFTR40","STFOUCH4","STFEVL4","STFKILL4"]
var keySprites = ["BKEY","YKEY","RKEYA0"]



var headDead = ["STFDEAD0"]


func initialize():
	var toDisk : bool = entityLoader.get_parent().toDisk
	
	for i in spawnWeapons:
		var ent = ENTG.fetchEntity(i,entityLoader.get_tree(),entityLoader.get_parent().gameName,toDisk)
		
		get_node("../visual/gunManager/weapons").add_child(ent)
		#ENTG.recursiveOwn(ent,get_node("../visual/gunManager/weapons"))
		#ENTG.recursiveOwn(ent,owner)
		if ent.scene_file_path.is_empty():
			ent.owner = get_node("../visual/gunManager/weapons")
		elif toDisk:
			ent.owner = get_parent()
		else:
			#ent.owner = get_node("../visual/gunManager/weapons")
			ent.set_meta("keepPath",true)
		#ent.get_child(0).owner = ent
	
	animationLibrary = AnimationLibrary.new()
	animationPlayer =  $"../AnimationPlayer"
	animationPlayer.add_animation_library("",animationLibrary)
	animatedSprite = $"../visual/AnimatedSprite3D"
	

	var f = loader.fetchBitmapFont("default")

	var allLetters = chase+attack+melee+hurt+dying+gib+heal
	var uniqueLetters = getUniqueLetters(allLetters)
	
	get_parent().height*= scaleFactor.y
	get_parent().thickness*= scaleFactor.z
	get_parent().maxSpeed*= scaleFactor.z
	#get_parent().acc*= scaleFactor.z
	
#	$"../visual/AnimatedSprite3D".scaleFactor = scaleFactor
	$"../movement".forwardSpeed *= scaleFactor.z / 0.031
	$"../movement".sideSpeed *= scaleFactor.x / 0.031
	$"../movement".gravity *= scaleFactor.y / 0.031
	
	
	#$"../CollisionShape3D".shape.resource_local_to_scene = true
	#$"../CollisionShape3D".shape.resource_local_to_scene = true
	

	$"../movement/footCast".shape = $"../CollisionShape3D".shape.duplicate()
	$"../movement/ShapeCastH".shape = $"../CollisionShape3D".shape.duplicate()

	
	var dict = {"s":[],"sw":[],"w":[],"nw":[],"n":[],"ne":[],"e":[],"se":[]}
		
	
	var ret = WADG.getSpritesAndFrames( get_parent().states.getRowsAsArray(),loader.get_parent().flatTextureEntries)
	var frames : Dictionary = ret["frames"]

	
	var aabb = Vector2(-INF,-INF)
	
	for frameName in frames:
		var subAABB = addRow(frameName,frames[frameName])
		if subAABB.x > aabb.x: aabb.x =  subAABB.x
		if subAABB.y > aabb.y: aabb.y=  subAABB.y

		

	var delta  = (1.0/35.0)
	createAnim("idle",idle,0.5,true)
	createAnim("die",dying,0.5,false)
	createAnim("walk",chase,0.5,true)
	createAnim("melee",melee,0.5,false)
	createAnim("hurt",hurt,0.5,false)
	createAnim("fire",attack,0.5,false)
	
	if jumping.length() > 0:
		createAnim("jump",jumping,0.25,true)
	
	if running.length() > 0:
		createAnim("run",running,0.25,true)
	
	for i in deathSounds:
		$"../AudioStreamPlayer3D".deathSounds.append(loader.fetchSound(i))
	
	for i in hurtSounds:
		$"../AudioStreamPlayer3D".hurtSounds.append(loader.fetchSound(i))
	
	if !gruntSound.is_empty():
		$"../AudioStreamPlayer3D".gruntSound = loader.fetchSound(gruntSound)
		
	
	if loader.fetchSound("DSJUMP") != null:
		print("fetching jump sound")
		$"../jumpPlayer".stream = loader.fetchSound("DSJUMP")
		
	setUI()

func getUniqueLetters(allLetters : String) -> Array:
	var firstLetter = "]"
	var lastLetter = "A"
	var uniqueLetters = []
		
	for letter in allLetters:
		if letter > lastLetter:
			lastLetter = letter
				
		if letter < firstLetter:
			firstLetter = letter
		

#	for i in range(ord(firstLetter),ord(lastLetter)+1):
	for i in range(firstLetter.to_ascii_buffer()[0],lastLetter.to_ascii_buffer()[0]+1):
		var t = sprites.getRow(char(i))
		if !t.is_empty():
			uniqueLetters.append(char(i))
			
	return uniqueLetters

func addSprites(spriteNames,set = "default"):
	
	for s in spriteNames.size():
		var sprite : Texture2D = loader.fetchDoomGraphic(spriteNames[s])
		
		if sprite == null:
			
			print("missing sprite (enemyGenerator):",spriteNames[s])
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
	
		
		
		if !animatedSprite.has_animation(set):
			animatedSprite.add_animation_library(set)
	
		var mat = loader.materialManager.fetchSpriteMaterial(spriteNames[s],sprite,1)
		animatedSprite.add_frame(set,mat,s)
		
		
func toIndices(string,uniqueLetters):
	var ret = []
	
	for letter in string:
		var t = uniqueLetters.find(letter)
		ret.append(t)

	
	return ret

func createAnim(animName : String,frames : String,dur:float,loop=false):

	
	var anim = Animation.new()
	var id = anim.get_track_count()

	anim.length = dur
	if loop != false:
		anim.loop_mode = Animation.LOOP_LINEAR
	#anim.set_loop(loop)
	
	var delta = 0
	
	if frames.length() > 0:
		delta = max(dur / frames.length(),0.001)
	

	
	var e = animationLibrary.add_animation(animName,anim)

	addMethodTrackOnly("visual/AnimatedSprite3D",animName,"setMat")
	for s in frames.length():
		var index = frames[s]
		addMethodTrackKey(animName,0,delta*s,{"method":"setMat","args":index})
	
	return anim


func addMethodTrackOnly(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationLibrary.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,0)
	anim.track_set_path(0,nodeName)
	
func addMethodTrackKey(animName, trackIdx, time, funcDict) -> void:
	var anim : Animation = animationLibrary.get_animation(animName)
	anim.track_insert_key(trackIdx,time,{"method":funcDict["method"],"args":[funcDict["args"]]})


func getSpriteList() -> Dictionary:
	
	var list = WADG.getSpritesAndFrames(get_parent().states.getRowsAsArray(),loader.get_parent().flatTextureEntries)["sprites"]
		
	list.append("STBAR")
	list +=  headSprites80 + headSprites60 + headSprites40 + headSprites20 + headSprites1 + headDead
	
	var aninmatedSprites = {}
	
	aninmatedSprites.merge({"head80":headSprites80})
	aninmatedSprites.merge({"head60":headSprites60})
	aninmatedSprites.merge({"head40":headSprites40})
	aninmatedSprites.merge({"head40":headSprites20})
	aninmatedSprites.merge({"head1":headSprites1})
	aninmatedSprites.merge({"headDead":headDead})
	print("got sprite list")
	return {"sprites":list,"animatedSprites":aninmatedSprites,"fonts":["default","numbers","numbers-grayscale"]}


func addMethodTrack(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationLibrary.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,1)
	anim.track_set_path(1,nodeName)
	anim.track_insert_key(1,0,{"method":methodName,"args":args})
	



func setUI():
	
	if get_node_or_null("../UI/HUDS/HUD2") == null:
		return
	
	var hpLabel = getChilded($"../UI/HUDS/HUD2","hp")
	var armorLabel = getChilded($"../UI/HUDS/HUD2","armor")
	var ammoLabel= getChilded($"../UI/HUDS/HUD2","ammo")
	
	
	if hpLabel != null:hpLabel = hpLabel.get_node_or_null("Label")
	if ammoLabel != null: ammoLabel = ammoLabel.get_node_or_null("Label")
	if armorLabel != null: armorLabel = armorLabel.get_node_or_null("Label")
	
	var font = loader.fetchBitmapFont("numbers")
	var fontArmor = loader.fetchBitmapFont("numbers-grayscale")
	var font2 = loader.fetchBitmapFont("default")


	if font != null:
		if hpLabel != null: hpLabel.add_theme_font_override("font",font)
		if armorLabel != null: 
			armorLabel.add_theme_font_override("font",fontArmor)
			armorLabel.modulate= Color("ffbc40")
		if ammoLabel != null: ammoLabel.add_theme_font_override("font",fontArmor)
	
	 
	$"../UI/PopupTxts/Label".add_theme_font_override("font",font2)
	
	var head = getChilded($"../UI/HUDS/HUD2","head")
	
	
	
	head.hp80 = loader.fetchAnimatedSimple("head80",headSprites80,0)
	head.hp60 = loader.fetchAnimatedSimple("head60",headSprites60,0)
	head.hp40 = loader.fetchAnimatedSimple("head40",headSprites40,0)
	head.hp20 = loader.fetchAnimatedSimple("head20",headSprites20,0)
	head.hp1 = loader.fetchAnimatedSimple("head1",headSprites1,0)
	head.dead =  loader.fetchAnimatedSimple("headDead",headDead,0)
	

func createFace(headSpr,nom):
	var animTexture : AnimatedTexture = AnimatedTexture.new()
	animTexture.frames = headSpr.size()
	animTexture.fps = 0
	
	for i in headSpr.size():
		animTexture.set_frame_texture(i,loader.fetchDoomGraphic(headSpr[i]))
		
	ResourceSaver.save(animTexture,WADG.destPath+loader.get_parent().gameName+"/textures/animated/"+ nom + ".tres")


func getChilded(node,nameStr):
	for i in node.get_children():
		if i.name == nameStr:
			return i
		else:
			var r = getChilded(i,nameStr)
			if r != null:
				return r


func addRow(rowName : String,spriteNames : Dictionary) -> Vector2:
	var rowSprite : Array[Texture2D] = []
	var aabb = Vector2(-INF,-INF)
	
	for sprName in spriteNames.values():
		if sprName == null:
			rowSprite.append(null)
		else:
			var tex : Texture2D = loader.fetchDoomGraphic(sprName)
			if tex != null:
				if tex.get_width()*scaleFactor.x > aabb.x: aabb.x = tex.get_width()*scaleFactor.x
				if tex.get_height()*scaleFactor.y > aabb.y: aabb.y = tex.get_height()*scaleFactor.y
			rowSprite.append(tex)
	
	var mat : Material 
	
	if spriteNames["All"] != null:
		mat = loader.materialManager.fetchSpriteMaterial(spriteNames["All"],rowSprite[0],Color.WHITE)
	else:
		rowSprite = rowSprite.slice(1)
		if rowName != "A2":
			mat = loader.materialManager.fetch8wayBillboardMaterial(spriteNames.values()[1],rowSprite,Color.WHITE)
		else:
			mat = loader.materialManager.fetch8wayBillboardMaterial(spriteNames["N"],rowSprite,Color.WHITE)

	animatedSprite.add_frame(rowName,mat)
	
	
	return aabb
