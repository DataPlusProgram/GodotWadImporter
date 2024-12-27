extends Node
var wadLoader = null
@export var modeName : String = "mainMode"
@export var mapPath = ""
@export var firstMap = "MAP01"
@export var intermissionMusic = "D_INTER"
@onready var mainMenu = $mainMenu
@export var characterEntity = "Playerguy"

var player = null
var midiPlayer =  null
var theme = null
var isPaused = false
@export var configName = ""
@onready var loader = $WadLoader
@onready var  matManager = loader.get_node("MaterialManager")
#@onready var inputPrompt = get_node_or_null()
func _ready():
	
	process_mode = PROCESS_MODE_ALWAYS
	
	get_tree().add_user_signal("entityCreated", [
		{ "name": "entity", "type": TYPE_OBJECT,"hint":17,"class_name":&"Node"},
	])

	
	get_tree().connect("entityCreated",self.entityCreated)

	$WadLoader.initialize($WadLoader.wads,configName,$WadLoader.gameName)
	
	matManager.instancedUICanvasItemCache.append(get_tree().get_root())
	
	if mapPath.is_empty():
		$WadLoader.loadWads()
	
	
	$mainMenu.quitGame.connect(Callable(self, "quit"))
	$mainMenu.newGame.connect(Callable(self, "newGame"))
	$mainMenu.gameLoadedSignal.connect(Callable(self, "gameLoaded"))
	$mainMenu.retryLevel.connect(Callable(self, "retryLevel"))

	var resourceManager = $WadLoader.get_node("ResourceManager")
	var tp = scene_file_path
	var menuMusic = $"mainMenu".titleSong
	midiPlayer = ENTG.fetchMidiPlayer(get_tree())
	

	var musData = resourceManager.fetchMidiOrMus(menuMusic)
	
	if !musData.is_empty():
		ENTG.setMidiPlayerData(midiPlayer,musData)
		midiPlayer.ready.connect(midiPlayer.play)
		midiPlayer.loop = false
	
	mainMenu.videoOptions.materialManager = loader.get_node("MaterialManager")
	

func entityCreated(ent):
	for i in ent.get_children():
		if i is Sprite3D:
			matManager.registerSprite3D(i)

func quit():
	get_tree().quit()

func _unhandled_input(event):
#func _input(event):
	
	
	if Input.is_action_just_pressed("openMenu"):
		
		if mainMenu.get_node("SaveLoadUi").visible:
			mainMenu.get_node("SaveLoadUi").visible = false
			return
		
		if mainMenu.inputPrompt != null:
			if mainMenu.inputPrompt.visible:
				return
		
		if mainMenu.options.visible:
			mainMenu.options.visible = false
			return
		
		if get_tree().get_nodes_in_group("player").size() == 0:
			return
			
		if mainMenu.options.visible == false:
			if mainMenu.visible == false:
				pause()
			else:
				unpause()
		else:
			mainMenu.options.visible = false


func pause(pauseTime = true):
	if pauseTime:
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	
	var root = get_tree().get_root()
	mainMenu.mainMode = self
	mainMenu.get_parent().remove_child(mainMenu)
	root.add_child(mainMenu)
	
	mainMenu.visible = true
	mainMenu.get_node("SaveLoadUi").getImage()
	
	
	
	disableInput()
	isPaused = true


func disableInput():
	for i in get_tree().get_nodes_in_group("player"):
		if "processInput" in i:
			i.processInput = false
			
		if i.has_method("disableInput"):
			i.disableInput()
			
		if "camera" in i:
			var cam = i.camera
			if "processInput" in cam:
				cam.processInput = false

func enableInput():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for i in get_tree().get_nodes_in_group("player"):
		if "processInput" in i:
			i.processInput = true
			
		if i.has_method("enableInput"):
			i.enableInput()
		
		if "camera" in i:
			var cam = i.camera
			if "processInput" in cam:
				cam.processInput = true

func unpause():
	get_tree().paused = false
	mainMenu.hide()
	#mainMenu.visible = false
	
	enableInput()
	isPaused = false

func newGame(mapName = ""):
	
	for i in get_tree().get_nodes_in_group("level"):
		i.get_parent().remove_child(i)
		i.queue_free()
	
	
	for i in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(i):
			i.queue_free()
			
	
	if mapName.is_empty():
		mapName = firstMap
	
	if mapPath.is_empty():
		
		var maps = $WadLoader.maps
		$WadLoader.createMap(mapName)
		
		player = $WadLoader.spawn(characterEntity,Vector3.ZERO,0,self)
		#player.dieSignal.connect(Callable(self, "pause"))
		player.dieSignal.connect(pause.bind(false))
		player.dieSignal.connect(mainMenu.retryVisible.bind(true))
		
	else:
		var mapExisting = ENTG.allInDirectory(mapPath,"tscn")
		
		for i in mapExisting.size():
			mapExisting[i] = mapExisting[i].replace(".tscn","")
		
		if mapExisting.has(mapName):
			var loaded = load(mapPath + "/" + mapName + ".tscn")
			add_child(loaded.instantiate())
			
			if is_instance_valid(player):
				player.queue_free()
			
	

	mainMenu.retryVisible(false)
	enableInput()
	hideMainMenu()


func hideMainMenu():
	$meltRect.generate_offsets()
	$meltRect.transition()
	
	midiPlayer.loop = true
	mainMenu.visible = false
	mainMenu.get_node("TextureRect").visible =false
	
	

func getModeName():
	return modeName

func retryLevel():
	for i : Node in get_children():
		if i.is_in_group("level"):
			newGame(i.mapName)

func gameLoaded():
	var skip = false
	
	for playerNode : Node in get_tree().get_nodes_in_group("player"):
		for i in get_incoming_connections():
			if i["signal"].get_object() == playerNode:
				skip = true
		
		if !skip:
			playerNode.dieSignal.connect(Callable(self, "pause"))
			playerNode.dieSignal.connect(mainMenu.retryVisible.bind(true))
		
	hideMainMenu()
	
	if isPaused:
		unpause()
		
		
func nextMap(curMap : Node,secret = false):
	
	var killPercent : float = curMap.getKillPercent()
	var itemPercent = curMap.getItemPercent()
	var timeSec = curMap.timeSec
	var secretsPercent = curMap.getSecretPercent()
	
	$ScoreScreen.setImageForMap(curMap.mapName)
	$ScoreScreen.setKillPercent(killPercent * 100)
	$ScoreScreen.setItemPercent(itemPercent * 100)
	$ScoreScreen.setSecretPercent(secretsPercent * 100)
	$ScoreScreen.setTime(timeSec)
	$ScoreScreen.visible = true
	
	
	for i in curMap.get_children():
		i.queue_free()
	curMap.set_physics_process(false)
	
	
	for playerNode : Node in get_tree().get_nodes_in_group("player"):
		if playerNode.has_method("hideUI"):
			playerNode.hideUI()
			
		
	
	var musData = $WadLoader.get_node("ResourceManager").fetchMus(intermissionMusic)
	
	if !musData.is_empty():
		ENTG.setMidiPlayerData(midiPlayer,musData)
		ENTG.fetchMidiPlayer(get_tree()).play()
		
	await $ScoreScreen.goNext
	
	for playerNode : Node in get_tree().get_nodes_in_group("player"):
		if playerNode.has_method("showUI"):
			playerNode.showUI()
	
	ENTG.fetchMidiPlayer(get_tree()).stop()
	curMap.nextMap(secret)

func serializeSave():
	return {"scoreScreenVisible":$ScoreScreen.visible}
	
func serializeLoad(dict : Dictionary):
	$ScoreScreen.visible = dict["scoreScreenVisible"]
	


func _on_child_entered_tree(node: Node) -> void:
	
	
	if node.process_mode == PROCESS_MODE_INHERIT:
		if !node.is_inside_tree():
			return
		node.process_mode = Node.PROCESS_MODE_PAUSABLE
	pass # Replace with function body.
