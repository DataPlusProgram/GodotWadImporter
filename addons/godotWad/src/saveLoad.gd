extends Node

var isSaving = false
var isLoading = false
const savePath = "user://gameSaves/"

signal loadFinishedSignal

func _input(event):
	
	if !event is InputEventKey:
		return
	var loader = get_node("../../").mainMode.get_node("WadLoader")
	
	if Input.is_action_just_pressed("quickSave"):
		
		saveJ(loader.params,loader.config,"quick save")
	#if event.keycode == KEY_F3 and event.is_pressed and !event.echo:
		#saveJ("quick save")
	
	if Input.is_action_just_pressed("quickLoad"):
		if !Input.is_key_pressed(KEY_ALT):
			loadJ(get_node("../../").mainMode.get_node("WadLoader"),savePath+loader.params[1]+"/quick save.save")
	
	#if  event.keycode == KEY_F4 and event.is_pressed and !event.echo:
		#loadJ(savePath+"quick save.save")


func canSave():
	if get_tree().get_nodes_in_group("level").size() == 0:
		return false
		
	return true

func saveJ(params,config,saveFileName : String = "",img = null):

	if isSaving:
		return
	
	
	isSaving = true
	
	
	var runningStr : String = ""
	var jsonStr = ""
	var levelNodes = get_tree().get_nodes_in_group("level")
	var entities : Array[Node] = []
	
	
	var paramDict = {"saveType":"loaderParams","params":params[0],"gameName":params[1],"config":config}
	runningStr += JSON.stringify(paramDict) + "\n"
	
	if img == null:
		img = getSavePictureData()
	
	
	
	var imgDict = {}
	var meta = {}
	
	
	

	imgDict = img
	imgDict["saveType"] = "saveImage"
	jsonStr = JSON.stringify(imgDict)
	runningStr+= jsonStr + "\n"
	
	if saveFileName.is_empty():
		if levelNodes.size() > 0:
			
			var time = Time.get_datetime_dict_from_system()
			var timeStr = str(time["year"]) + "-"+ str("%02d" % time["month"])+"-" + str("%02d" % time["day"])
			timeStr += " "
			timeStr += str(time["hour"]) + "-"+ str(time["minute"])+"-" + str(time["second"])
			
			saveFileName = timeStr
	
	
	if get_tree().get_nodes_in_group("player").size() > 0:
		for player in get_tree().get_nodes_in_group("player"):
			if !entities.has(player):
				entities.append(player)
	
	if levelNodes.size() > 0:
		var levelNode = levelNodes[0]
		var dataStr = levelNode.serializeSave()
		jsonStr = JSON.stringify(dataStr)
		runningStr+= jsonStr + "\n"

		if "mapName" in levelNode:
			meta["mapName"] = levelNode.mapName
		
		for i in get_tree().get_nodes_in_group("levelObject"):
			var dict = saveLevelObject(i)
			dict["saveType"] = "levelObject"
			dict["path"] = levelNode.get_path_to(i)
			jsonStr = JSON.stringify(dict)
			runningStr+= jsonStr + "\n"
			#saveFile.store_line(jsonStr)
			
		if levelNode.get_node_or_null("Entities") != null:
			entities += (levelNode.get_node("Entities").get_children())
	
	
	if !meta.is_empty():
		meta["saveType"] = "saveMeta"
		jsonStr = JSON.stringify(meta)
		runningStr+= jsonStr + "\n"
		
		#saveFile.store_line(jsonStr)
	
	if get_tree().get_first_node_in_group("gameMode") != null:
		var dict = get_tree().get_first_node_in_group("gameMode").serializeSave()
		dict["saveType"] = "gameMode"
		jsonStr = JSON.stringify(dict)
		runningStr+= jsonStr + "\n"
		#saveFile.store_line(jsonStr)
	
	runningStr = saveEntities(entities,runningStr)
	
	var dest = savePath+params[1]+"/"+saveFileName+".save"
	var x = savePath+params[1]
	DirAccess.make_dir_absolute(savePath)
	var dir = DirAccess.open(savePath)
	
	if !dir.dir_exists(params[1]):
		var err = dir.make_dir_recursive(params[1])
		if err != OK:
			print("Error creating directory")
			return  # Stop if the directory couldn't be created

		var t = 3
	
	
	
	var saveFile = FileAccess.open(dest, FileAccess.WRITE)
	saveFile.store_string(runningStr)
	isSaving = false



func getImage(filePath : String) -> Image:
	
	if filePath.is_empty():
		return null
	
	var saveFile = FileAccess.open(filePath, FileAccess.READ)
	
	while saveFile.get_position() < saveFile.get_length():
		var jsonStr = saveFile.get_line()
		var json = JSON.new()
		json.parse(jsonStr)
		
		var data = json.get_data()
		var type = data["saveType"]
		
		
		if type == "saveImage":
			
			var img = Image.create_from_data(data["width"],data["height"],false,data["format"],data["data"].hex_decode())
			saveFile.close()
			return img
			
	
	saveFile.close()
	return null
	
func getMeta(filePath) -> Dictionary:
	
	if filePath.is_empty():
		return {}
	
	var saveFile : FileAccess = FileAccess.open(filePath, FileAccess.READ)
	
	while saveFile.get_position() < saveFile.get_length():
		var jsonStr = saveFile.get_line()
		var json = JSON.new()
		json.parse(jsonStr)
		
		var data = json.get_data()
		var type = data["saveType"]

		if type == "saveMeta":
			data["dateTime"] = Time.get_datetime_dict_from_unix_time(saveFile.get_modified_time(filePath))
			return data
	
	
	
	
	return {}

func loadJ(loader,path : String):
	var entReadyWaitList : Array = []
	if isLoading:
		return
	
	
	
	isLoading = true
	
	#deleteEverything()
	deletePlayers()
	
	var saveFile = FileAccess.open(path, FileAccess.READ)
	var levelNode = null

	
	if !get_tree().get_nodes_in_group("level").is_empty():
		levelNode = get_tree().get_nodes_in_group("level")[0]
	
	var game = loader.gameName
	
	while saveFile.get_position() < saveFile.get_length():
		var jsonStr = saveFile.get_line()
		var json = JSON.new()
		json.parse(jsonStr)
		
		var data = json.get_data()
		var type = data["saveType"]
	

		
		if type == "loaderParams":
			var new = [data["params"],data["config"],data["gameName"]]
			var old = [loader.params[0],loader.config,loader.gameName]
			
			if new != old:
				ENTG.removeEntityCacheForGame(get_tree(),loader.gameName)
				loader.initialize(data["params"],data["config"],data["gameName"])
				ENTG.createEntityCacheForGame(get_tree(),false,data["gameName"],loader)
			game = data["gameName"]
		
		if type == "gameMode":
			if get_tree().get_first_node_in_group("gameMode") != null:
				get_tree().get_first_node_in_group("gameMode").serializeLoad(data)
		
		if type == "level":
			if levelNode != null:
				if levelNode.gameName != data["gameName"] or levelNode.mapName != data["levelName"]:
					levelNode.queue_free()
					levelNode = ENTG.createMapBlank(data["levelName"],get_tree(),game)
					levelNode.serializeLoad(data)
					
					
				else:
					deleteLevelEntities(levelNode)
					deleteDecals()
					levelNode.serializeLoad(data)
			else:
				levelNode = ENTG.createMapBlank(data["levelName"],get_tree(),game)
				levelNode.serializeLoad(data)
			
		if levelNode != null:
			levelNode.isLoading = true
		if type == "levelObject" and levelNode != null:
			var levelObject = levelNode.get_node_or_null(data["path"])
			if levelObject == null:
				continue
			
			levelObject.serializeLoad(data)
		
		
		if type == "entity":
			
			var pos = Vector3(data["posX"],data["posY"],data["posZ"])
			var rot = Vector3(data["rotX"],data["rotY"],data["rotZ"])
			var parentNode = levelNode.get_node("Entities")
			
			#if data["entityName"] == "playerguy":
			#	breakpoint
			
			if data.has("desiredParent"):
				if get_node_or_null(data["desiredParent"] )!= null:
					parentNode = get_node(data["desiredParent"])
			
			
			
			var ent : Node= ENTG.spawn(get_tree(),data["entityName"],pos,rot,game,parentNode)
			entReadyWaitList.append(ent)
			
			
			if data.has("dependantChildren"):
				for childName in data["dependantChildren"].keys():
					var childNode = ent.get_node_or_null(childName)
					
					if childNode == null:
						continue
					
					childNode.ready.connect(childNode.serializeLoad.bind(data["dependantChildren"][childName]))

			if ent.has_method("serializeLoad"):
				ent.ready.connect(entSerializeLoadFunc.bind(ent,data))
				
			if levelNode != null:
				
				levelNode.isLoading = true
				ent.ready.connect(eraseSelf.bind(ent,entReadyWaitList,levelNode))
				
		
		if levelNode == null:
			isLoading = false
			emit_signal("loadFinishedSignal")
		
		

	
	
func eraseSelf(me,list : Array,levelNode : Node):
	list.erase(me)
	if list.is_empty():
		levelNode.isLoading = false
		if levelNode.has_method("loadFinished"):
			levelNode.loadFinished()
	
	isLoading = false
	emit_signal("loadFinishedSignal")
	

func entSerializeLoadFunc(ent : Node,data : Dictionary):
	ent.position.x = data["posX"]
	ent.position.y = data["posY"]
	ent.position.z = data["posZ"]
	
	ent.rotation.x = data["rotX"]
	ent.rotation.y = data["rotY"]
	ent.rotation.z = data["rotZ"]
	ent.name = data["name"]
	ent.serializeLoad(data)
	

func getSavePictureData():
	var img : Image= get_viewport().get_texture().get_image()
	img.resize(323,180)
	var baseDict = img.data
	var retDict = baseDict
	retDict["data"] = baseDict["data"].hex_encode()
	retDict["format"] = img.get_format()
	
	return retDict

func deleteLevelEntities(levelNode):
	if levelNode.get_node_or_null("Entities") == null:
		return
		
	
	for i in levelNode.get_node("Entities").get_children():
		i.queue_free()
		

func deleteDecals():
	for i in get_tree().get_nodes_in_group("decals"):
		i.queue_free()

func deleteEverything():
	deleteLevel()
	deletePlayers()
	
	

func deleteLevel():
	for i in get_tree().get_nodes_in_group("level"):
		i.queue_free()

func deletePlayers():
	for i in get_tree().get_nodes_in_group("player"):
		i.get_parent().remove_child(i)
		i.queue_free()
	

func saveLevelObject(object : Node):
	return object.serializeSave()
	

func saveEntities(entites : Array[Node],runningStr : String):
	
	#print("entites to save:",entites)
	
	for ent : Node in entites:
		
		var nameAndGame = getGameAndEntityName(ent)
		
		#print(nameAndGame)
		
		if nameAndGame == null:
			continue
		
		var entityName : String = nameAndGame["entityName"]
		var gameName : String = nameAndGame["gameName"]
		var position : Vector3 = ent.position
		var rotation : Vector3 = ent.rotation
		var ret:Dictionary = {"saveType":"entity","entityName":entityName,"gameName":gameName}
			
		ret["posX"] = position.x
		ret["posY"] = position.y
		ret["posZ"] = position.z
	
		ret["rotX"] = rotation.x
		ret["rotY"] = rotation.y
		ret["rotZ"] = rotation.z
		ret["name"] = ent.name
		
		
		recusriveSave(ent,ent,ret)
		
		#if ent.has_method("serializeSave"):
			#if is_instance_valid(ent):
				#ret.merge(ent.serializeSave())
#
		#for i in ent.get_children():
			#if i.has_method("serializeSave"):
				#if !ret.has("dependantChildren"):
					#ret["dependantChildren"] = {}
					#
				#ret["dependantChildren"][i.name] =i.serializeSave()
			

		var jsonStr = JSON.stringify(ret)
		runningStr += jsonStr + "\n"
		#saveFaile.store_line(jsonStr)
	
	return runningStr


func recusriveSave(root,node,ret):
	if node.has_method("serializeSave"):
		if is_instance_valid(node):
			ret.merge(node.serializeSave())

	for i in node.get_children():
		if i.has_method("serializeSave"):
			if !ret.has("dependantChildren"):
				ret["dependantChildren"] = {}
					
			ret["dependantChildren"][root.get_path_to(i)] =i.serializeSave()
			
		recusriveSave(root,i,ret)

func getGameAndEntityName(node : Node):
	var entityName : String = ""
	var gameName : String = ""
		
	if "entityName" in node and "gameName" in node:
		entityName = node.entityName
		gameName = node.gameName
			
	elif node.has_meta("entityName") and node.has_meta("gameName"):
		entityName = node.get_meta("entityName")
		gameName = node.get_meta("gameName")
		
	if entityName.is_empty() or gameName.is_empty():
		return null
	
	return {"gameName":gameName,"entityName":entityName}

func deleteSaveFile(path : String):
	DirAccess.remove_absolute(path)
	
