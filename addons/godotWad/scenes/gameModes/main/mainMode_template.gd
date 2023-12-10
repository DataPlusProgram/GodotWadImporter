extends Node
var wadLoader = null
export var mapPath = ""
export var firstMap = "MAP01"

onready var mainMenu = $mainMenu

var player = null

func _ready():
	
	$mainMenu.connect("quitGame",self,"quit")
	$mainMenu.connect("newGame",self,"newGame")
	
	if !InputMap.has_action("pause"):InputMap.add_action("pause")




func quit():
	get_tree().quit()

func _input(event):
	
	
	if Input.is_action_just_pressed("pause"):
		if get_tree().get_nodes_in_group("player").size() == 0:
			return
			
		if mainMenu.options.visible == false:
			if mainMenu.visible == false:
				pause()
			else:
				unpause()
		else:
			#mainMenu.options.relaseFocusOwner()
			mainMenu.options.visible = false
			


func pause():
	mainMenu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	
	var root = get_tree().get_root()
	mainMenu.get_parent().remove_child(mainMenu)
	root.add_child(mainMenu)
	
	for i in get_tree().get_nodes_in_group("player"):
		if "processInput" in i:
			i.processInput = false
		
		if i.has_method("disableInput"):
			i.disableInput()
			

func unpause():
	mainMenu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for i in get_tree().get_nodes_in_group("player"):
		if "processInput" in i:
			i.processInput = true
			
		if i.has_method("enableInput"):
			i.enableInput()
			
	

func newGame():
	
	for i in get_tree().get_nodes_in_group("levels"):
		i.queue_free()
	
	
		if is_instance_valid(player):
			player.queue_free()
			
	
	if mapPath.empty():
		$WadLoader.initialize($WadLoader.wads)
		var maps = $WadLoader.maps
		$WadLoader.createMap(firstMap)
		player = $WadLoader.spawn("playerguy",Vector3.ZERO,0,self)
		player.connect("die",self,"pause")
	else:
		var mapExisting = ENTG.allInDirectory(mapPath,"tscn")
		
		for i in mapExisting.size():
			mapExisting[i] = mapExisting[i].replace(".tscn","")
		
		if mapExisting.has(firstMap):
			var loaded = load(mapPath + "/" + firstMap + ".tscn")
			add_child(loaded.instance())
			
			if is_instance_valid(player):
				player.queue_free()
			
			var playerScene = load("res://game_imports/doom/entities/character controllers/playerguy.tscn")
			
			if playerScene != null:
				player = load("res://game_imports/doom/entities/character controllers/playerguy.tscn").instance()
				player.connect("die",self,"pause")
				add_child(player)
	
	

	
	
	
	mainMenu.visible = false
	mainMenu.get_node("TextureRect").visible =false
	
