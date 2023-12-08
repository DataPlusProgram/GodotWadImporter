tool
extends Node


export(Resource) var sprites
export(String) var idle = ""
export(String) var chase = ""
export(String) var attack = ""
export(String) var melee = ""
export(String) var hurt = ""
export(String) var dying = ""
export(String) var gib = ""
export(String) var heal = ""


export(Array,String) var deathSounds = ["DSPODTH1","DSPODTH2","DSPODTH3"]
export(Array,String) var painSounds = ["DSPOPAIN"]
export(Array,String) var attackSounds = ["DSPISTOL"]
export(Array,String) var meleeSounds = []
export(Array,String) var alertSounds = ["DSPOSIT1","DSPOSIT2","DSPOSIT3"]
export var scaleFactor = Vector3.ONE
export(Array,String) var entityDepends  = []
export(Array,String) var bloodSplatter

var animationPlayer 
var animatedSprite
var seneTree
var loader = null
var entityLoader



func initialize() -> void:
	if loader == null:
		queue_free()
		return

	animationPlayer =  $"../AnimationPlayer"
	animatedSprite = $"../AnimatedSprite3D"
	animatedSprite.frameList = {}
	
	
	var to = animatedSprite.frames
	if animationPlayer == null:
		breakpoint
	
	var t0 = get_parent().thickness
	
	get_parent().setHeight(get_parent().height*scaleFactor.y)
	get_parent().setThickness(get_parent().thickness*scaleFactor.x)
	get_parent().meleeRange *= scaleFactor.y
	$"../AnimatedSprite3D".scaleFactor = scaleFactor

	var allLetters = chase+attack+melee+hurt+dying+gib+heal
	var uniqueLetters = getUniqueLetters(allLetters)

		
	var dict = {"s":[],"sw":[],"w":[],"nw":[],"n":[],"ne":[],"e":[],"se":[]}
		
		
		
	for letter in uniqueLetters:
		var t = sprites.getRow(letter)
		if  t.has("nw") and !t.has("ne"): t["ne"] = t["nw"] + "_flipped"
		if !t.has("nw") and t.has("ne"): t["nw"] = t["ne"] + "_flipped"

		if  t.has("sw") and !t.has("se"): t["se"] = t["sw"] + "_flipped"
		if !t.has("sw") and t.has("se"): t["sw"] = t["se"] + "_flipped"

		if  t.has("e") and !t.has("w"): t["w"] = t["e"] + "_flipped"
		if !t.has("e") and t.has("w"): t["e"] = t["w"] + "_flipped"
			
			
		for key in t.keys():
			dict[key].append(t[key])
	
	
	addSprites(dict["s"],"front")
	addSprites(dict["sw"],"frontLeft")
	addSprites(dict["w"],"left")
	addSprites(dict["nw"],"backLeft")
	addSprites(dict["n"],"back")
	addSprites(dict["ne"],"backRight")
	addSprites(dict["e"],"right")
	addSprites(dict["se"],"frontRight")
		
	var delta  = (1.0/35.0)
	createAnim("idle",toIndices(idle,uniqueLetters),0.5,true)
	createAnim("die",toIndices(dying,uniqueLetters),0.5,false)
	createAnim("walk",toIndices(chase,uniqueLetters),0.5,true)
	createAnim("melee",toIndices(melee,uniqueLetters),0.5,false)
	createAnim("hurt",toIndices(hurt,uniqueLetters),0.5,false)
	createAnim("fire",toIndices(attack,uniqueLetters),0.5,false)
	

	if !gib.empty():
		createAnim("gib",toIndices(gib,uniqueLetters),delta*idle.length(),false)
			
	if !heal.empty():
		createAnim("heal",toIndices(heal,uniqueLetters),delta*idle.length(),false)

	animatedSprite.curAnimation = "front"
	animatedSprite.setMat([0])

	
	for entityStrId in entityDepends:
		ENTG.fetchEntity(entityStrId,entityLoader.get_tree(),loader.get_parent().gameName,entityLoader.get_parent().toDisk).queue_free()
		
		var t = entityLoader.entitiesOnDisk
		
		
		
		get_parent().projectile = entityStrId

	
	
	if !attackSounds.empty() or !entityDepends.empty():
		#createAnim("attack",idleFront.size(),attackFront.size(),0.5,false)
		addMethodTrack("AudioStreamPlayer3D","fire","playAttack")
		addMethodTrack(".","fire","fire")
	

	if !deathSounds.empty():
		addMethodTrack("AudioStreamPlayer3D","die","playDeath")
	
	if !meleeSounds.empty():
		addMethodTrack("AudioStreamPlayer3D","melee","playMelee")

	if !bloodSplatter.empty():
		var t = loader.fetchAnimatedSimple(bloodSplatter[0]+"_anim",bloodSplatter)
		get_parent().hitDecal = t
		
	get_parent().hitDecalSize = scaleFactor.x
	initSounds()
	queue_free()
	
	
	for i in get_parent().get_children():
		if i.get_name().find("_") != -1:
			if i.get_name().split("_")[0] == "projectileSpawn":
				i.translation *= scaleFactor
				

func getUniqueLetters(allLetters : String) -> Array:
	var firstLetter = "]"
	var lastLetter = "A"
	var uniqueLetters = []
		
	for letter in allLetters:
		if letter > lastLetter:
			lastLetter = letter
				
		if letter < firstLetter:
			firstLetter = letter
		

	for i in range(ord(firstLetter),ord(lastLetter)+1):
		var t = sprites.getRow(char(i))
		if !t.empty():
			uniqueLetters.append(char(i))
			
	return uniqueLetters

func toIndices(string,uniqueLetters):
	var ret = []
	
	for letter in string:
		var t = uniqueLetters.find(letter)
		ret.append(t)
		#ret.append(ord(letter)-65)
	
	return ret

func addSprites(spriteNames,set = "default"):
	
	for s in spriteNames.size():
		var sprite : Texture = loader.fetchDoomGraphic(spriteNames[s])
		
		if sprite == null:
			
			print("missing sprite (enemyGenerator):",spriteNames[s])
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
	
		
		
		if !animatedSprite.has_animation(set):
			animatedSprite.add_animation(set)
	
		var mat = loader.fetchSpriteMaterial(spriteNames[s])
		animatedSprite.add_frame(set,mat,s)
		
	
	
func createAnim(animName,indices,dur:float,loop=false):
	
	
	var anim = Animation.new()
	var id = anim.get_track_count()
	anim.length = dur

	anim.set_loop(loop)
	
	var delta = 0
	
	if indices.size() > 0:
		delta = max(dur / indices.size(),0.001)

	
	var e = animationPlayer.add_animation(animName,anim)
	
	
	
	addMethodTrackOnly("AnimatedSprite3D",animName,"setMat")
	
	anim.add_track(Animation.TYPE_VALUE,1)
	anim.length = dur
	anim.track_set_path(1,"AnimatedSprite3D:offset")
	anim.value_track_set_update_mode(1,Animation.UPDATE_DISCRETE)
	
	for s in indices.size():
		var index = indices[s]
		addMethodTrackKey(animName,0,delta*s,{"method":"setMat","args":[index]})
		anim.track_insert_key(1,0,Vector3(0,0,0))
	
	return anim
	
	

func addMethodTrack(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,1)
	anim.track_set_path(1,nodeName)
	anim.track_insert_key(1,0,{"method":methodName,"args":args})
	

func addMethodTrackKey(var animName , var trackIdx,var time,var funcDict) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.track_insert_key(trackIdx,time,{"method":funcDict["method"],"args":[funcDict["args"]]})
	

func addMethodTrackOnly(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,0)
	anim.track_set_path(0,nodeName)
	
func initSounds():
	
	for i in deathSounds:
		$"../AudioStreamPlayer3D".deathSounds.append(loader.fetchSound(i))
	
	for i in painSounds:
		$"../AudioStreamPlayer3D".painSounds.append(loader.fetchSound(i))
		
	for i in attackSounds:
		$"../AudioStreamPlayer3D".attackSounds.append(loader.fetchSound(i))
		
	for i in alertSounds:
		$"../AudioStreamPlayer3D".alertSounds.append(loader.fetchSound(i))
		
	for i in meleeSounds:
		$"../AudioStreamPlayer3D".meleeSounds.append(loader.fetchSound(i))

func getSpriteList() -> Dictionary:
	
	var list = []
	var allLetters : String = chase+attack+melee+hurt+dying+gib+heal
	var uniqueLetters : Array = getUniqueLetters(allLetters)
	
	for letter in uniqueLetters:
		var t : Dictionary = sprites.getRow(letter)
		
		if t.has("s") : list.append(t["s"])
		if t.has("sw") : list.append(t["sw"])
		if t.has("w") : list.append(t["w"])
		if t.has("nw") : list.append(t["nw"])
		if t.has("n") : list.append(t["n"])
		if t.has("ne") : list.append(t["ne"])
		if t.has("e") : list.append(t["e"])
		if t.has("se") : list.append(t["se"])
		
		if  t.has("nw") and !t.has("ne"): t["ne"] = list.append(t["nw"] + "_flipped")
		if !t.has("nw") and t.has("ne"): t["nw"]  = list.append(t["ne"] + "_flipped")

		if  t.has("sw") and !t.has("se"): t["se"] = list.append(t["sw"] + "_flipped")
		if !t.has("sw") and t.has("se"): t["sw"]  = list.append(t["se"] + "_flipped")

		if  t.has("e") and !t.has("w"): t["w"] = list.append(t["e"] + "_flipped")
		if !t.has("e") and t.has("w"): t["e"]  = list.append(t["w"] + "_flipped")
		
		
	list += bloodSplatter
	
	var animatedSprites = {}
	
	if !bloodSplatter.empty():
		animatedSprites.merge({bloodSplatter[0]+"_anim":bloodSplatter})
	
	
	return {"sprites":list,"animatedSprites":animatedSprites}

#func getAnimatedSpriteList() -> Dictionary:
#	if bloodSplatter.empty():
#		return {}
#
#	return  {bloodSplatter[0]+"_anim":bloodSplatter}

