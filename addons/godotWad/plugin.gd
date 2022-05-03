tool
extends EditorPlugin
var editorInterface
var editorSceneTree
var scriptEditor
var dock
var curObj = null
var thread 
var waiting = false

func _enter_tree():
	
	
	dock = load("res://addons/godotWad/scenes/toolbar.tscn").instance()
	dock.get_node("create").connect("pressed", self, "loadWad")
	
	dock.get_node("createMap").connect("pressed", self, "createMap")
	dock.get_node("createCharacterController").connect("pressed", self, "createCharacterController")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	dock.visible = false
	dock.get_node("createMap").visible = false
	dock.get_node("createCharacterController").visible = false

func handles(object):
	
	return object is WAD_Map

func make_visible(visible: bool) -> void:
	if dock:
		dock.set_visible(visible)

func _exit_tree():
	remove_custom_type("WAD_Map")
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	if dock != null:
		dock.free()



func edit(object):
	
	if waiting:
		return
		
	curObj = object
	var dropdown = dock.get_node("dropdown")
	var addSignal = true
	
	for sig in object.get_signal_connection_list("wadChange"):
		if sig["target"] == self:
			addSignal = false
	
	#if addSignal:
	#	object.connect("wadChange", self, "wadChange")
	
	if "editorInterface" in curObj:
		curObj.editorInterface = get_editor_interface()
		curObj.editorFileSystem = get_editor_interface().get_resource_filesystem()
		
	if curObj.has_meta("maps") and !curObj.directories["MAPS"].empty():
		
		populateDropdown(dropdown,curObj.get_meta("maps"))
		dropdown.visible = true
		dock.get_node("createMap").visible = true
		dock.get_node("createCharacterController").visible = true
	else:
		dropdown.visible = false
		dock.get_node("createMap").visible = false
		dock.get_node("createCharacterController").visible = false


func loadWad():
	if curObj:
		var dropdown = dock.get_node("dropdown")
		var mapNames = curObj.pluginFetchNames()

		curObj.set_meta("mapNames",null)
		populateDropdown(dropdown,mapNames)
		curObj.set_meta("mapNames",mapNames)
		dropdown.visible = true
		dock.get_node("createMap").visible = true
		dock.get_node("createCharacterController").visible = true
		

func createMap():
	
	var dropdown = dock.get_node("dropdown")
	var mapName = dropdown.get_item_text(dropdown.get_selected_id())
	print("----creating map:", mapName)
	if curObj.get_node_or_null(mapName) == null:
		curObj.editorInterface = get_editor_interface()
		curObj.editorFileSystem = get_editor_interface().get_resource_filesystem()
		
		waiting = true
		dock.get_node("createMap").disabled = true
		dock.get_node("createCharacterController").disabled = true
		curObj.createMapThread(mapName)
		
		
		dock.get_node("loadingLabel").visible = false
	else:
		print("A map under that name already exists")

func createCharacterController():
	if curObj != null:
		
		if curObj.toDisk:
			
			curObj.connect("playerCreated", self, "createCharacterControllerTail")
			
			var ccThread = Thread.new()
			ccThread.start(curObj,"createPlayerController")

		else:
			var ret = curObj.createPlayerController()
			createCharacterControllerTail(ret)

		

func createCharacterControllerTail(ret):
	ret = load(ret).instance()
	
	curObj.get_parent().add_child(ret)
	recursiveOwn(ret,get_tree().edited_scene_root)
	
	for i in ret.get_children():
		i.queue_free()
	
	#print("adding ret as child")
	#curObj.get_parent().add_child(ret)
	#print("recursive onwning")
	#recursiveOwn(ret,get_tree().edited_scene_root)

func resDone():
	print("resDone")
	
	curObj.createMapTail()
	
func waitOver():
	
	print("wait over")
	curObj.createMapTail()
	recursiveOwn(curObj.mapNode,get_tree().edited_scene_root)
	#recursiveOwn(curObj,get_tree().edited_scene_root)
	waiting = false
	dock.get_node("createMap").disabled = false
	dock.get_node("createCharacterController").disabled = false


func _physics_process(delta):
	if curObj !=null:
		if is_instance_valid(curObj):
			if curObj.get_class() == "Spatial":
				if "tailPrimed" in curObj:
					if curObj.tailPrimed:
						curObj.tailPrimed = false
						waitOver()
			

func recursiveOwn(node,newOwner):
	for i in node.get_children():
		if !i.has_meta("hidden"):
			recursiveOwn(i,newOwner)
	
	node.owner = newOwner

func populateDropdown(dropdown,names):
	dropdown.clear()
	for n in names:
		dropdown.add_item(n)

func wadChange(caller):
	caller.set_meta("maps",null)
	var dropdown = dock.get_node("dropdown")
	dropdown.visible = false
	dock.get_node("createMap").visible = false
	dock.get_node("createCharacterController").visible = false

	

	
