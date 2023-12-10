tool
extends WindowDialog


signal instance
signal diskInstance
signal import

onready var paths = $h/v1/paths/v/v
onready var cats = $h/v2/cats
onready var previewWorld = $h/v3/preview/ViewportContainer/Viewport
onready var previewWorldContainer = $h/v3/preview/ViewportContainer
onready var texturePreview = $h/v3/preview/texturePreview
onready var gameList : ItemList = $h/v1/Panel/gameList
onready var initialRot = Vector2(0,0)
onready var editedNode = null
onready var nameLabel = $h/v1/paths/v/h/gameNameEdit
onready var optionsPanel = $h/v3/options
export var playMode = false


var cur = null
var curName = ""
var curTree : Tree = null
var pEnt = null
var curEntTxt = ""
var curMeta = ""
var cat = ""
var loaders = []
var editorInterface = null
var gameToLoaderNode ={}
var gameToLoaderNodeDisk ={}
var gameToHistory = {}
var runTailImport = false
var tailEntStr = ""
var previousFiles = {}


const destPath = "res://game_imports/"

func _ready():
	
	
	if playMode:
		$h/v2.visible = false
		$h/v3.visible = false
		$h/v1/paths/v/HBoxContainer/loadButton.visible = false
		$h/v1/paths/v/HBoxContainer/playButton.visible = true
	else:
		$h/v2.visible = true
		$h/v3.visible = true
		$h/v1/paths/v/HBoxContainer/loadButton.visible = true
		$h/v1/paths/v/HBoxContainer/playButton.visible = false

		
	cachedPaths()
	
	gameList.clear()
	
	getLoaders()
	
	
	for i in loaders:
		var inst = load(i).instance()
		var configs = inst.getConfigs()
		
		for gameName in configs:
			initGame(gameName,i)
			
			gameToHistory[gameName] = []
			
			var reqs = inst.getReqs(gameName)
			
			if reqs != null:
				for req in reqs.size():
					gameToHistory[gameName].append("")
			else:
				breakpoint
				
	
	makeHistoryFile()
	
	
	if gameList.get_selected_items().empty():
		if gameList.get_item_count() > 0:
			gameList.select(0)
	
	
	
	previewWorld.get_node("CameraTopDown").current = false
	previewWorld.get_node("Camera").current = true


	
	
	if texturePreview.texture == null:
			texturePreview.texture = ImageTexture.new()
			
			


func getLoaders():
	if !ENTG.doesDirExist("res://addons"):
		return
	
	
	
	for i in ENTG.getDirsInDir("res://addons"):
		var target = "res://addons/"+i+"/loader.txt"
		if ENTG.doesFileExist(target):
			var loaderPath = getFromConfig(target)
			if loaderPath == null:
				continue
			
			loaders.append("res://addons/"+i+"/"+loaderPath)

				


func getFromConfig(path):
	var f : File = File.new()
	f.open(path,File.READ)
	var ret = f.get_as_text()
	
	if ret.empty(): return null
	return ret
	


func initGame(gameName,gameParam):
	gameList.add_item(gameName)
	gameList.set_item_metadata(gameList.get_item_count()-1,gameParam)

	


func _on_loadButton_pressed():
	loaderInit()



func loaderInit():
	var param = []
	
	for i in paths.get_children():
		if i.required == true and i.getPath().empty():
			i.setErrorText("*required")
			return
	
	
	
	for i in paths.get_children():
		param.append(i.getPath())
	
	
	
	for i in paths.get_children().size():
		var child = paths.get_child(i)
		#gameToHistory[curName][i].append(child.getPath())
		var t = gameToHistory[curName]
		gameToHistory[curName][i] =child.getPath()
	
	#for i in paths.get_children():
	#	print(i.name)
	
	#gameToHistory[curName] = paths.get_children()[0].getPath()
	
	updateHistoryFile()
	
	if cur == null:
		return
	
	cur.initialize(param,(nameLabel.text+"_preview").to_lower())
	

	if is_instance_valid(curTree):
		curTree.queue_free()
	
	var all = cur.getAll()
	var tree = createTree()
	curTree = tree
	
	
	var meta
	
	if all.has("meta"):
		meta = all["meta"]
		all.erase("meta")
	
	for i in all:
		populateTree(tree,i,all[i],meta)
	

func initializeThreaded(var arr):
	var cur = arr[0]
	var param = arr[1]
	var gameName = arr[2]
	
	cur.initialize(param,nameLabel.text.to_lower())

func createTree():
	var tree = Tree.new()
	tree.size_flags_horizontal = SIZE_EXPAND_FILL
	tree.size_flags_vertical = SIZE_EXPAND_FILL
	tree.set_hide_root(true)
	var root = tree.create_item()
	tree.create_item(root)
	cats.add_child(tree)
	
	tree.connect("item_selected",self,"itemSelected")
	
	return tree

func populateTree(tree : Tree,itemName,subItems,meta):
	var root = tree.get_root()
	var item = tree.create_item(root)
	
	
	item.collapsed = true
	item.set_text(0,itemName)
	
	for i in subItems:
		
		
		var subItem = tree.create_item(item)
		subItem.set_meta("cat",itemName)
		subItem.set_text(0,i)
		
		if meta.has(i):
			for m in meta[i].keys():
				subItem.set_meta(m,meta[i][m])
		subItem.collapsed = true
		
		if typeof(subItems) == TYPE_DICTIONARY:
			if typeof(subItems[i]) != TYPE_STRING:
				for j in subItems[i]:
					var subItem2 = tree.create_item(subItem)
					subItem2.set_meta("cat",itemName)
					subItem2.set_text(0,j)
				
				
func itemSelected():
	var item = curTree.get_selected()
#	
	cat = "misc"
	var txt = item.get_text(0)
	
	previewWorldContainer.visible = false
	
	curEntTxt = txt
	curMeta = {}
	
	for key in item.get_meta_list():
		if key != "__focus_rect":
			curMeta[key] = item.get_meta(key)
	
	if item.has_meta("cat"):
		cat = item.get_meta("cat")
	
	if cat == "entities":
		previewWorldContainer.visible = true
		clearEnt()
		
		var ent  = ENTG.spawn(cur.get_tree(),txt,Vector3.ZERO,Vector3.ZERO,(nameLabel.text+"_preview").to_lower(),previewWorld)

		
		pEnt = ent

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		previewWorld.get_node("CameraTopDown").current = false
		previewWorld.get_node("Camera").current = true
	
	elif cat == "maps":
		previewWorldContainer.visible = true
		clearEnt()

		previewWorld.get_node("CameraTopDown").current = true
		previewWorld.get_node("Camera").current = false
		
		var mapNode = null
		
		if cur.has_method("createMapPreview"):
			mapNode = cur.createMapPreview(txt,curMeta)
			
			
		else:
			mapNode = cur.createMap(txt,curMeta)
		
		if mapNode.get_parent() != null:
			mapNode.get_parent().remove_child(mapNode)
		
		if mapNode != null:
			pEnt = mapNode
			previewWorld.add_child(mapNode)
		
	elif cat == "sounds":
		var sound = cur.createSound(txt,curMeta)
		var player = AudioStreamPlayer.new()
		
		clearEnt()
		
		player.stream = cur.createSound(txt,curMeta)
		player.play()
		player.volume_db = -10
		previewWorld.add_child(player)
		pEnt = player
	elif cat == "textures":
		var x =  cur.createTexture(curEntTxt,curMeta)
		texturePreview.texture.image = x
	elif cat == "game modes":
		if cur.has_method("createGameModePreview"):
			var x = cur.createGameModePreview(txt,curMeta)
			texturePreview.texture = cur.createGameModePreview(txt,curMeta)
		 
	
#	if cat == "game modes":
#		$h/v2/ui/instanceButton.text = "play"
#	else:
#		$h/v2/ui/instanceButton.text = "instance"


func fetchLoader(loaderPath):
	pass


func _on_gameList_item_selected(index):#game selected
	
	if gameList == null:
		return
	
	#gameToHistory["selIndex"] = index
	
	get_node("%playButton").text = "play"
	get_node("%playButton").disabled = false
	
	var gameLoader = gameList.get_item_metadata(index)
	var gameName = gameList.get_item_text(index)
	
	nameLabel.text = gameName.to_lower()
	
	if !gameToLoaderNode.has(gameName):
		var loader = gameLoader
		loader = load(loader).instance()
		add_child(loader)
		gameToLoaderNode[gameName] = loader

	
	
	for i in cats.get_children():
		i.queue_free()
	
	clearEnt()
		
	
	cur = gameToLoaderNode[gameName]
	
	if "options" in cur:
		if optionsPanel.get_child_count() > 0:
			optionsPanel.remove_child(optionsPanel.get_child(0))
		optionsPanel.add_child(cur.options)
	else:
		print("options not in cur")
	
	
	
	for i in paths.get_children():
		i.queue_free()
	
	
	var reqs = cur.getReqs(gameName)
	
	
	curName = gameName
	
	var i = 0
	
	for rIdx in reqs.size():
		var r = reqs[i]
		var UIname = "path"
		var required = true
		var ext = ""
		var multi = false 
		var fileNames = []
		var hints = []
		
		if r.has("UIname") : UIname = r["UIname"]
		if r.has("required") : required = r["required"]
		if r.has("ext") : ext = r["ext"]
		if r.has("multi") : multi = r["multi"]
		if r.has("fileNames"): fileNames = r["fileNames"]
		if r.has("hints"): hints = r["hints"]
		
		
		
		var node = load("res://addons/gameAssetImporter/scenes/makeUI/path.tscn").instance()
		
		node.required = required
		node.many = multi
		paths.add_child(node)
		node.setText(UIname)
		
		if ext.empty():
			node.setAsDir()
		else:
			node.setExt([ext])
			
		
		if gameToHistory.has(gameName):
			if !gameToHistory[gameName].empty():
				var savedPaths = gameToHistory[gameName]
				
				if rIdx < savedPaths.size():
				
					var historyPath = gameToHistory[gameName][rIdx]
						
					if historyPath.find(".") != -1:
						if doesFileExist(historyPath):
							node.setPathText(historyPath)
							
					elif ENTG.doesDirExist(historyPath):
						node.setPathText(historyPath)
		
		if !fileNames.empty():
			node.popupStrings = findFiles(fileNames,hints,ext.replace("*.",""))
			
		i+=1
				





func _on_Button_pressed():
	var l = load("res://addons/godotWad/scenes/entityDebugDialog.tscn").instance()
	add_child(l)
	l.popup_centered_ratio(0.4)


func clearEnt():
	if pEnt != null and is_instance_valid(pEnt):
		pEnt.queue_free()
		pEnt = null
	
	texturePreview.texture  = null

	

func findFiles(files,hints,ext):
	
	var filesLower = []
	var ret = []
	var found = []
	
	
	for f in files:
		filesLower.append(f.to_lower())
	
	var allFiles = getAllFlat("res://",ext)
	
	for f in allFiles:
		var fn = f.get_file().to_lower()
		if files.has(fn):
			ret.append(f)
			found.append(fn)
	
	
	for i in hints:
		var target = i.split(",")[0]
		var postFix = i.split(",")[1]
		
		if target == "steam":
			var steamDirs = steamUtil.findSteamDir()
			
			for dir in steamDirs:
				var path = dir + postFix
				if !steamUtil.doesDirExist(path):
					continue
				
				for f in files:
					if doesFileExist(path+ "/" + f):
						if found.has(f.to_lower()):
							continue
						ret.append(path+ "/" + f)
						found.append(f.to_lower())
						
						
						if found.size() == files.size():
							return ret
						
		
	
	for i in ret.size():
		ret[i] = ProjectSettings.localize_path(ret[i])
	
	return ret



static func getAllFlat(path,filter = null):
	var ret = []
	var all = allInDirectory(path,filter)
	
	for i in all:
		if i.find(".") == -1:
			ret += getAllFlat(path + "/" + i,filter)
		
		else:
			ret.append(path + "/" + i)
			
	return ret
	
	
static func allInDirectory(path,filter=null):
	var files = []
	var dir = Directory.new()
	var res = dir.open(path)
	
	if res != 0:
		return []
		
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			
			if file.find(".") == -1:
				files.append(file)
			else:
				if filter != null:
					var ext = file.split(".")
					ext = ext[ext.size()-1].to_lower()
					if ext.find(filter)!= -1:
						files.append(file)
				else:
					files.append(file)

	dir.list_dir_end()

	return files
	
	

static func cachedPaths():
	return





func _on_instanceButton_pressed():
	
	if curEntTxt.empty():
		return
		
	
	var targetTree = get_tree()
	
	
	if cat == "game modes":
		var mode = cur.createGameMode(curEntTxt,curMeta)
		emit_signal("instance",mode,null)
		
	
	if cat ==  "maps":
		var pGameName = cur.gameName
		print("curNAme is:",curName)
		cur.gameName = curName
		ENTG.createEntityCacheForGame(targetTree,false,nameLabel.text,cur.getCreatorScript(),editedNode)
		var map = cur.createMap(curEntTxt,curMeta)
		
		cur.gameName = pGameName
		
		var returnCache = ENTG.fetchEntityCaches(targetTree,nameLabel.text,true)
		
		return emit_signal("instance",map,returnCache)
	
	if cat == "textures":
		var texture = cur.createTexture(curEntTxt,curMeta)
		return
	
	var info = cur.getEntityInfo(curEntTxt)
	
	if info == null:
		return
	ENTG.updateEntitiesOnDisk(targetTree)
	
	var e = ENTG.fetchEntityCaches(targetTree,"")
	
	#if e.empty():
	#	print("create enitty cache for game")
	ENTG.createEntityCacheForGame(targetTree,false,nameLabel.text,cur.getCreatorScript(),editedNode)


	var ent = ENTG.fetchEntity(curEntTxt,targetTree,nameLabel.text+"_preview",false)
	

	if info.has("depends"):
		if typeof(info["depends"]) == TYPE_STRING:
			ENTG.fetchEntity(info["depends"],targetTree,nameLabel.text,false).queue_free()
		else:
			for i in info["depends"]:
				ENTG.fetchEntity(i,targetTree,nameLabel.text,false).queue_free()
			
			
		
	var returnCache = null
	if info.has("depends"):
		returnCache = ENTG.fetchEntityCaches(targetTree,nameLabel.text,true)
	
	
	emit_signal("instance",ent,returnCache)
	


func getTree() -> SceneTree:
	
	if  editedNode != null:
		return editedNode
	
	return get_tree()
		
		

func getSettingsAsText():
	
	var selectedGame = ""
	
	if !gameList.get_selected_items().empty():
		selectedGame = gameList.get_item_text(gameList.get_selected_items()[0])
	
	var settingsDict = {
		
		"savedToPath":gameToHistory,
		"selectedGame": selectedGame,
		"previousFiles": previousFiles
	}
	return var2str(settingsDict)

func makeHistoryFile():
	
	if !doesFileExist("history.txt"):
		var f = File.new()
		f.open("history.txt",File.WRITE)
		f.store_string(getSettingsAsText())
		f.close()
	
	var f = File.new()
	f.open("history.txt",File.READ_WRITE)
	var savedSettingsDict =  str2var(f.get_as_text())
	
	
	
	if typeof(savedSettingsDict) != TYPE_DICTIONARY:
		f.store_string(getSettingsAsText())
		f.close()
		return

	var gameHistoryDict = savedSettingsDict["savedToPath"]
	
	for gameName in gameHistoryDict.keys():
		for pathIdx in gameHistoryDict[gameName].size():
			var pathStr = gameHistoryDict[gameName][pathIdx]
			
			
			if pathStr.empty():
				continue
			
				
			if pathStr.find(".") != -1:
				if doesFileExist(pathStr):
					
					gameToHistory[gameName][pathIdx]= pathStr
			else:
				if ENTG.doesDirExist(pathStr):
					
					gameToHistory[gameName][pathIdx]= pathStr
					
					
	if !savedSettingsDict["selectedGame"].empty():
		var target = savedSettingsDict["selectedGame"]
		for i in gameList.get_item_count():
			if gameList.get_item_text(i)== target:
				gameList.select(i)
				_on_gameList_item_selected(i)
			
		
		
	f.close()
	
func updateHistoryFile():
	if !doesFileExist("history.txt"):
		var f = File.new()
		f.open("history.txt",File.WRITE)
		f.close()
	
	var f = File.new()
	f.open("history.txt",File.WRITE)
	f.store_string(getSettingsAsText())
	f.close()


func createHistDict():
	var dict = {}
		
	for i in gameToLoaderNode.keys():
		dict[i] = ""
	
	
	return dict

static func doesFileExist(path : String) -> bool:
	var f : File = File.new()
	var ret = f.file_exists(path)
	f.close()
	return ret


var oldName = ""
var pToDisk = null



func createMapThread(arr):
	var mapName = arr[1]
	var cur = arr[0]
	#var map = mapThread.start(cur,"createMap",entStr,Thread.PRIORITY_HIGH)
	var map = cur.createMap(mapName,curMeta)
	
	ENTG.recursiveOwn(map,map)
	var ps = PackedScene.new()
	ps.pack(map)
	
	var destPath = "res://game_imports/"+cur.gameName+"/maps/"+curEntTxt+".tscn"
	ResourceSaver.save(destPath,ps)
	map.queue_free()
	
	emit_signal("diskInstance",ResourceLoader.load(destPath).instance())
	
	#emit_signal("diskInstance",map)

var headThread = null

func _on_importButton_pressed():
	oldName = cur.gameName
	
	if curEntTxt.empty():
		return
	
	print("import button pressed")
	

	if "toDisk" in cur:#legacy
		pToDisk  = cur.toDisk
		cur.toDisk = true
		
	cur.gameName = oldName.split("_")[0]
	
	var addSignal = true
	
	for sig in cur.get_signal_connection_list("fileWaitDone"):
		if sig["target"] == self:
			addSignal = false
	
	if addSignal == true:
		cur.connect("fileWaitDone",self,"importTailFlagSet")
		
	headThread = Thread.new()
	importHead()
	

func importHead():
	var tempCur = cur
	
	if cur.has_method("getReqDirs"):
		createDirectories(nameLabel.text,cur.getReqDirs())
	else:
		createDirectories(nameLabel.text)
		
	var targetTree = get_tree()
	
	
	tailEntStr = curEntTxt
	
	
	if cat == "maps":
		cur.createMapResourcesOnDisk(curEntTxt,curMeta,editorInterface)
	elif cat == "game modes":
		curMeta["destPath"] = "res://game_imports/"+cur.gameName
		cur.createGameModeResourcesOnDisk(curEntTxt,curMeta,editorInterface)
	else:
		var e = ENTG.fetchEntityCaches(targetTree,nameLabel.text)

		if e.empty():
			ENTG.createEntityCacheForGame(targetTree,false,nameLabel.text,cur.getCreatorScript(),editedNode)
		cur.createEntityResourcesOnDisk(curEntTxt,curMeta,editorInterface)

	
	
	
	
	
var mapThread = Thread.new()

func _physics_process(delta):
	
	
	
	if texturePreview != null:
		texturePreview.visible = false
	
		if texturePreview.texture != null:
			if texturePreview.texture.image != null:
				texturePreview.visible = true
	
	
	if cats != null:
		if cats.get_child_count() > 0:
			setOptionsVisibility(true)
				
		else:
			setOptionsVisibility(false)
	else:
		setOptionsVisibility(false)
	
	$h/v3/preview/ViewportContainer/Viewport/StaticBody.visible = previewWorld.get_node("Camera").current

		

	if runTailImport == true:
		runTailImport = false
		importTail(tailEntStr,cat)
		tailEntStr = ""
		
	if !is_instance_valid(curTree):
		$h/v2/ui/instanceButton.visible = false
		$h/v2/ui/importButton.visible = false
	else:
		$h/v2/ui/instanceButton.visible = true
		$h/v2/ui/importButton.visible = true
		
#	var playVisible = true
##
#	if playMode:
#
#		if paths.get_child_count() == 0:
#			playVisible = false
#
#		for i in paths.get_children():
#			if i.required == true and i.getPath().empty():
#				playVisible = false
#
#
#		$h/v1/paths/v/HBoxContainer/playButton.disabled = !playVisible
#

func importTailFlagSet():#need to call it via physics_process because if I call it in a signal it will be threaded
	runTailImport = true

func gameListGrabFocus():
	gameList.grab_focus()

func importTail(entStr,cat):
	ENTG.updateEntitiesOnDisk(get_tree())
	if cat == "entities":
		var ent = ENTG.fetchEntity(curEntTxt,get_tree(),nameLabel.text,true)
		
		if ent != null:
			if ent.get_parent() != null:
				ent.get_parent().remove_child(ent)
		
		emit_signal("diskInstance",ent)
	elif cat == "maps":
		hide()
		createMapThread([cur,entStr])
	elif cat == "game modes":
		curMeta["destPath"] = "res://game_imports/"+nameLabel.text
		var node = cur.createGameModeDisk(curEntTxt,curMeta,get_tree(),nameLabel.text)
		emit_signal("diskInstance",node)
		
	
	cur.gameName = oldName
	if "toDisk" in cur:
		cur.toDisk = pToDisk

func createDirectories(var gameName,var dirs = ["textures","materials","sounds","sprites","textures/animated","entities","fonts","maps"]):

	
	var directory = Directory.new()
	
	directory.open("res://")
	
	
	var split = (destPath+gameName).lstrip("res://")

	if split.length() > 0:
		var subDirs = split.split("/")
		
		for i in subDirs.size():
			var path = "res://"
			for j in i+1:
				directory.open(path)
				path += subDirs[j] + "/"
				createDirIfNotExist(path,directory)
				
			directory.open(path)
	
	
	directory.open(destPath+nameLabel.text)
	
	for i in dirs:
		createDirIfNotExist(i,directory)
	

	
	
	var e = cur.getEntityDict()
	for ent in e:
		if "category" in e[ent]:
			createDirIfNotExist(destPath+nameLabel.text+"/entities/" + e[ent]["category"],directory)
	

	
	var directoriesToCreate : Array = []
	
	

	for dir in directoriesToCreate:
		createDirIfNotExist("entities/"+dir,directory)
	

	
func createDirIfNotExist(path,dir):
	if !dir.dir_exists(path):
		dir.make_dir(path)
		


func waitForDirToExist(path):
	var waitThread = Thread.new()
	
	waitThread.start(self,"waitForDirToExistTF",path)
	waitThread.wait_to_finish()
	
func waitForDirToExistTF(path):
	var dir = Directory.new()
	while !dir.dir_exists(path):

		OS.delay_msec(10)
	

func setOptionsVisibility(visible):
	if optionsPanel == null:
		return
		
	for i in optionsPanel.get_children():
		i.visible = visible


func _on_playButton_pressed():
	
	if cur == null:
		return
	
	for i in paths.get_children():
		if i.required == true and i.getPath().empty():
			i.setErrorText("*required")
			return
	
	loaderInit()

	var all = cur.getAll()
	
	var noGameMode = false
	
	if !all.has("game modes"):
		noGameMode = true
		
	if all["game modes"].size() == 0:
		noGameMode = true
		
	if noGameMode:
		get_node("%playButton").text = "No game mode implemented"
		get_node("%playButton").disabled = true
		return
	var gamdeModeName = all["game modes"].keys()[0]
	var gameMode = all["game modes"][gamdeModeName]
	var meta = all["meta"][gamdeModeName]
	var mode = cur.createGameMode(gamdeModeName,meta)
	get_tree().get_root().add_child(mode)
	queue_free()
