tool
extends Node

export(Resource) var sprites

var loader
var scaleFactor 
export var spawnWeapons = ["pistol","fists"]
var entityLoader

export(String) var idle = ""
export(String) var chase = ""
export(String) var attack = ""
export(String) var melee = ""
export(String) var hurt = ""
export(String) var dying = ""
export(String) var gib = ""
export(String) var heal = ""

export(Array,String) var hurtSounds = ["DSPLPAIN"]
export(Array,String) var deathSounds = ["DSPLDETH"]
export(String) var gruntSound = ""
var animationPlayer
var animatedSprite
export var numberChars = ["STTNUM0","STTNUM1","STTNUM2","STTNUM3","STTNUM4","STTNUM5","STTNUM6","STTNUM7","STTNUM8","STTNUM9","STTMINUS","STTPRCNT"]
var headSprites80 = ["STFST01","STFST00","STFST02","STFTL00","STFTR00","STFOUCH0","STFEVL0","STFKILL0"]
var headSprites60 = ["STFST11","STFST10","STFST12","STFTL10","STFTR10","STFOUCH1","STFEVL1","STFKILL1"]
var headSprites40 = ["STFST21","STFST20","STFST22","STFTL20","STFTR20","STFOUCH2","STFEVL2","STFKILL2"]
var headSprites20 = ["STFST31","STFST30","STFST32","STFTL30","STFTR30","STFOUCH3","STFEVL3","STFKILL3"]
var headSprites1 = ["STFST41","STFST40","STFST42","STFTL40","STFTR40","STFOUCH4","STFEVL4","STFKILL4"]
var keySprites = ["BKEY","YKEY","RKEYA0"]



var headDead = ["STFDEAD0"]

func initialize():
	
	for i in spawnWeapons:
		var ent = ENTG.fetchEntity(i,entityLoader.get_tree(),entityLoader.get_parent().gameName,entityLoader.get_parent().toDisk)
		
		
		get_node("../gunManager/weapons").add_child(ent)
	
		ent.owner  = get_parent()
		
	animationPlayer =  $"../AnimationPlayer"
	animatedSprite = $"../AnimatedSprite3D"
	
	

	var allLetters = chase+attack+melee+hurt+dying+gib+heal
	var uniqueLetters = getUniqueLetters(allLetters)
	
	get_parent().height*= scaleFactor.y
	get_parent().thickness*= scaleFactor.z
	get_parent().gravity*= scaleFactor.y
	get_parent().maxSpeed*= scaleFactor.z
	get_parent().acc*= scaleFactor.z
	$"../AnimatedSprite3D".scaleFactor = scaleFactor
	$"../movement/ShapeCastL".translation.x *= scaleFactor.x
	$"../movement".forwardSpeed *= scaleFactor.z / 0.031
	$"../movement".sideSpeed *= scaleFactor.x / 0.031
	$"../movement".gravity *= scaleFactor.y / 0.031
	
	var sh = WADG.getShapeHeight($"../movement/ShapeCastL")
	

	#WADG.setCollisionShapeHeight($"../movement/ShapeCastL",sh*scaleFactor.y)
	#WADG.setCollisionShapeHeight($"../movement/ShapeCastH",sh*scaleFactor.y)
	
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
	
	
	if !hurtSounds.empty():
		addMethodTrack("AudioStreamPlayer3D","hurt","playHurth")
		
	if !deathSounds.empty():
		addMethodTrack("AudioStreamPlayer3D","die","playDeath")
	
	for i in hurtSounds:
		$"../AudioStreamPlayer3D".hurtSounds.append(loader.fetchSound(i))
		
	for i in deathSounds:
		$"../AudioStreamPlayer3D".deathSounds.append(loader.fetchSound(i))
	
	if !gib.empty():
		createAnim("gib",toIndices(gib,uniqueLetters),delta*idle.length(),false)
			
	if !heal.empty():
		createAnim("heal",toIndices(heal,uniqueLetters),delta*idle.length(),false)

	
	if !gruntSound.empty():
		$"../AudioStreamPlayer3D".gruntSound = loader.fetchSound(gruntSound)
		
	animatedSprite.curAnimation = "front"
	animatedSprite.setMat([0])
	
	if !numberChars.empty():
		loader.fetchBitmapFont(numberChars)
	#loader.createBitmapFont(numberChars)
	#createBitmapFont()
	
	
	
	#createFace(headSprites80,"head80")
	#createFace(headSprites60,"head60")
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
		

	for i in range(ord(firstLetter),ord(lastLetter)+1):
		var t = sprites.getRow(char(i))
		if !t.empty():
			uniqueLetters.append(char(i))
			
	return uniqueLetters

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
		
		
func toIndices(string,uniqueLetters):
	var ret = []
	
	for letter in string:
		var t = uniqueLetters.find(letter)
		ret.append(t)

	
	return ret

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
	for s in indices.size():
		var index = indices[s]
		addMethodTrackKey(animName,0,delta*s,{"method":"setMat","args":[index]})
	
	return anim


func addMethodTrackOnly(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,0)
	anim.track_set_path(0,nodeName)
	
func addMethodTrackKey(var animName , var trackIdx,var time,var funcDict) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.track_insert_key(trackIdx,time,{"method":funcDict["method"],"args":[funcDict["args"]]})


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
		
		
	list.append("STBAR")
	list += numberChars + headSprites80 + headSprites60 + headSprites40 + headSprites20 + headSprites1 + headDead
	
	var aninmatedSprites = {}
	
	aninmatedSprites.merge({"head80":headSprites80})
	aninmatedSprites.merge({"head60":headSprites60})
	aninmatedSprites.merge({"head40":headSprites40})
	aninmatedSprites.merge({"head40":headSprites20})
	aninmatedSprites.merge({"head1":headSprites1})
	aninmatedSprites.merge({"headDead":headDead})
	
	print("animatedSprites:",aninmatedSprites)
	
	return {"sprites":list,"animatedSprites":aninmatedSprites,"bitmapFont":numberChars}


func addMethodTrack(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,1)
	anim.track_set_path(1,nodeName)
	anim.track_insert_key(1,0,{"method":methodName,"args":args})
	



func setUI():
	var fontPath = WADG.destPath+loader.get_parent().gameName+"/fonts/bm.tres"
	
	print("fontPath:",fontPath)
	
	if get_node_or_null("../UI/HUDS/HUD2") == null:
		return
		
	var hpLabel = getChilded($"../UI/HUDS/HUD2","hp")
	var armorLabel = getChilded($"../UI/HUDS/HUD2","armor")
	var ammoLabel= getChilded($"../UI/HUDS/HUD2","ammo")
	
	if hpLabel != null:hpLabel = hpLabel.get_node_or_null("Control/Label")
	if ammoLabel != null: ammoLabel = ammoLabel.get_node_or_null("Control/Label")
	if armorLabel != null: armorLabel = armorLabel.get_node_or_null("Control/Label")
	
	var font = loader.fetchBitmapFont(numberChars)
	
	
	print("fetched font:",font)
	
	if hpLabel != null: hpLabel.add_font_override("font",font)
	if armorLabel != null: armorLabel.add_font_override("font",font)
	if ammoLabel != null: ammoLabel.add_font_override("font",font)
	
	#if hpLabel != null: hpLabel.add_font_override("font",load(fontPath))
	#if armorLabel != null: armorLabel.add_font_override("font",load(fontPath))
	#if ammoLabel != null: ammoLabel.add_font_override("font",load(fontPath))
	
	
	
	var head = getChilded($"../UI/HUDS/HUD2","head")	
	var x = loader.fetchAnimatedSimple("head80",headSprites80,0)
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
		
	ResourceSaver.save(WADG.destPath+loader.get_parent().gameName+"/textures/animated/"+ nom + ".tres",animTexture)


func getChilded(node,nameStr):
	for i in node.get_children():
		if i.name == nameStr:
			return i
		else:
			var r = getChilded(i,nameStr)
			if r != null:
				return r
