tool
extends EditorPlugin
var editorInterface
var editorSceneTree
var scriptEditor
var dock
var curObj = null
var thread 
var waiting = false
var runTail = false
var count = 0
var reimportFiles = []
var tryingToCollapse = false
var waitingOnCharacterCreation = false
var characterControllerThread = Thread.new()


func _enter_tree():
	dock = load("res://addons/gameAssetImporter/scenes/toolbar.tscn").instance()
	dock.get_node("createAll").connect("pressed", self, "openMaker")
	
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	dock.visible = false

	


func handles(object):
	return object

func make_visible(visible: bool) -> void:
	if dock:
		dock.set_visible(visible)

func _exit_tree():
	
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	if dock != null:
		dock.free()



func edit(object):
	if waiting:
		return
		
	curObj = object

func waitOverFlag():
	runTail = true


func _physics_process(delta):
	
	if tryingToCollapse:
		collpaseUnderScriptName("mapNode.gd")
		tryingToCollapse = false
		
		
	
	if runTail:
		runTail = false
		
		curObj.createMapTail()
		
		
		recursiveOwn(curObj.mapNode,get_tree().edited_scene_root)

		
		waiting = false
		dock.get_node("createMap").disabled = false
		dock.get_node("createCharacterController").disabled = false
		curObj.editorFileSystem = get_editor_interface().get_resource_filesystem()
		tryingToCollapse = true
		
		



func recursiveOwn(node,newOwner):
	for i in node.get_children():
		if !i.has_meta("hidden"):
			recursiveOwn(i,newOwner)
	
	node.owner = newOwner

func recursiveOwn2(node,newOwner):
	for i in node.get_children():
		if !i.has_meta("hidden"):
			recursiveOwn2(i,newOwner)
	
	if node.owner != null:
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

	
func collpaseUnderScriptName(scriptName):
	var baseNode = get_editor_interface().get_base_control() #return base panel
	var sceneTreeEditor = findNodeByClass(baseNode,"SceneTreeEditor")
	var treeNode = findNodeByClass(sceneTreeEditor,"Tree")
	

	var item = findItemInTreeByScriptName(treeNode.get_root(),scriptName)
	if item == null:
		return false

	collapseAllUnderItem(item)
	return true
	#print(item.get_text(0))
	
func findItemInTreeByScriptName(node,scriptName):
	#print(node.get_meta_list())
	var actualNode = get_tree().get_root().get_node(node.get_metadata(0))
	if actualNode.get_script() != null:
		var sName = actualNode.get_script().get_path().get_file()

		if sName ==  scriptName:
			return node

	var child = node.get_children()
	
	if child != null:#if we have children itterate through them
		actualNode = get_tree().get_root().get_node(child.get_metadata(0))
		if actualNode.get_script() != null:
			var sName = actualNode.get_script().get_path().get_file()
			if sName ==  scriptName:
				return node

		
		while(child.get_next()!= null):
			child = child.get_next()
			var ret = findItemInTreeByScriptName(child,scriptName)
			if ret != null:
				return ret

func collapseAllUnderItem(item):
	item.collapsed = true
	var child = item.get_children()
	
	if child != null:#if we have children itterate through them
		child.collapsed = true

		
		while(child.get_next()!= null):
			child.collapsed = true
			child = child.get_next()
			child.collapsed = true



func findNodeByClass(node,className):
	
	if node.get_class() == className:
		return node
	
	for i in node.get_children():
		var ret = findNodeByClass(i,className)
		if ret != null:
			return ret
			

var m = null
func openMaker():
	if m == null:
		m = load("res://addons/gameAssetImporter/scenes/makeUI/makeUI.tscn").instance()
		m.connect("instance",self,"makeInstanced")
		m.connect("diskInstance",self,"diskInstanced")
		get_tree().get_root().add_child(m)
		m.editorInterface = get_editor_interface()
		m.editedNode = get_tree().edited_scene_root
		
	m.popup_centered_ratio(0.9)


func makeInstanced(entity,cache):
	print("make instanced")
	if cache != null:
		if typeof(cache) == TYPE_ARRAY:
			for i in cache:
				recursiveOwn(i,get_tree().edited_scene_root)
				
		else:
			recursiveOwn(cache,get_tree().edited_scene_root)
	
	if curObj != null:
		
		if entity.get_parent() != null:
			entity.get_parent().remove_child(entity)
		
		#curObj.get_parent().add_child(entity)
		curObj.add_child(entity)
		recursiveOwn(entity,get_tree().edited_scene_root)
		
	
func diskInstanced(entity):

	if curObj != null:
		if entity.get_parent() != null:
			entity.get_parent().remove_child(entity)
		
		print(entity)
		curObj.add_child(entity)
		entity.owner = get_tree().edited_scene_root
		
