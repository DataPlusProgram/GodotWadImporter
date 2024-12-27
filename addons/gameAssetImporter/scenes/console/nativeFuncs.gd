extends Node
@onready var console = $"../.."
@onready var consoleRoot =  $"../../../"


func close():
	consoleRoot.hide()


func clear():
	%logText.text = ""

func cls():
	clear()

func quit():
	get_tree().quit()

func clearhistory():
	$"../..".history.clear()

func getg():
	
	for i in %execute.scripts:
		breakpoint

func loader():
	var node = load("res://addons/gameAssetImporter/scenes/makeUI/makeUI.tscn").instantiate()
	get_tree().get_root().add_child(node)



func spawn(entStr,gameStr = ""):
	entStr = entStr.to_lower()
	var players = get_tree().get_nodes_in_group("player")
	
	for i in players:
		if i.get_node_or_null("gunManager/shootCast") != null:
			var cast : RayCast3D = i.get_node_or_null("gunManager/shootCast")
			var point = cast.get_collision_point()
			
			var ent = ENTG.spawn(get_tree(),entStr,point,Vector3.ZERO,gameStr)
			if ent == null:
				print('Failed to spawn ' + entStr)
			return
	
	print('Failed to spawn ' + entStr)


func getentitylist(gameStr) -> String:
	gameStr = gameStr.to_lower()
	var dict = ENTG.getEntityDict(get_tree(),gameStr)
	var runningStr = ""
	
	for str in dict.keys():
		print(str)
		runningStr += str + "\n"
		
	return runningStr



func kill():
	for i in get_tree().get_nodes_in_group("player"):
		if i.has_method("takeDamage"):
			i.takeDamage({"amt":99999})


func getinputs():
	var retStr = ""
	var inputs = Input.get_connected_joypads()
	
	for i in inputs:
		retStr += str(i) + ": " + Input.get_joy_name(i) + "\n"
		#var t3 = 3
		#retStr + Input.get_joy_info(i)["raw_name"] + "\n"
	
	return retStr

func entdbg():
	var entDebugMenu = load("res://addons/gameAssetImporter/scenes/entityDebug/entityDebugDialog.tscn").instantiate()
	add_child(entDebugMenu)

func orphans():
	print("--------")
	print_orphan_nodes()

func map(mapName:String):
	var map = ENTG.createMap(mapName,get_tree(),"")
	
	if map == null:
		return
	
	for cMap in get_tree().get_nodes_in_group("level"):
		cMap.queue_free()
	
func maplist():
	return mapnames()
func mapnames():
	return ENTG.printMapNames(get_tree(),"")

func clearentitycache():
	ENTG.clearEntityCaches(get_tree())
	
