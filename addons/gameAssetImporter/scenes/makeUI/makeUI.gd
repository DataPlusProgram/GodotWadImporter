@tool
extends Window


signal instance
signal diskInstance
signal import

@onready var paths = $h/v1/paths/v/v
@onready var cats = $h/v2/cats
@onready var previewNode = $h/v3/preview
@onready var previewWorld = $h/v3/preview/SubViewportContainer/SubViewport
@onready var previewWorld2DContainer = $h/v3/preview/SubViewportContainer2D
@onready var previewWorld2D = $h/v3/preview/SubViewportContainer2D/SubViewport
@onready var previewWorldContainer = $h/v3/preview/SubViewportContainer
@onready var texturePreview = $h/v3/preview/texturePreview
@onready var gameList : ItemList = $h/v1/Panel/gameList
@onready var initialRot = Vector2(0,0)
@onready var editedNode = null
@onready var nameLabel = $h/v1/paths/v/h/gameNameEdit

@onready var optionsPanel = $h/v3/options
@onready var creditsButton =$h/v1/paths/v/HBoxContainer/creditsButton
@export var playMode = false

var pathScenePacked : PackedScene = preload("res://addons/gameAssetImporter/scenes/makeUI/path.tscn")

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
var midiPlayer = null
var curGameName = ""
const destPath = "res://game_imports/"
var inspector = null




func _ready():
	
	
	
	
	if playMode:
		$h/v2.visible = false
		$h/v3.visible = false
		$h/v1/paths/v/HBoxContainer/loadButton.visible = false
		$h/v1/paths/v/HBoxContainer/playButton.visible = true
		$h/v1/paths/v/HBoxContainer/playButton.grab_focus()
		$h/v1/paths/v/VBoxContainer/LoaderOptions.visible = true
	else:
		$h/v2.visible = true
		$h/v3.visible = true
		$h/v1/paths/v/VBoxContainer/LoaderOptions.visible = false
		$h/v1/paths/v/HBoxContainer/loadButton.visible = true
		$h/v1/paths/v/HBoxContainer/playButton.visible = false

	$h/v3/preview/sondFontPath.pathSet.connect(soundFontSet)
	
	gameList.clear()
	var preLoadLoader = false
	
	var loaders : Array[String] = getLoaders(preLoadLoader)
	
	if preLoadLoader:#use threaded loading
		
		var breakFlag = false
		var loaderWait = loaders.duplicate()
		
		while !loaders.size() != 0:
			for i in loaderWait:
				if ResourceLoader.load_threaded_get_status(i) == ResourceLoader.THREAD_LOAD_LOADED:
					loaderWait.erase(i)
				OS.delay_msec(1)
		
		var loadersLoaded : Array[PackedScene]= []
		for i in loaders:
			loadersLoaded.append(ResourceLoader.load_threaded_get(i))
		
		instantiateLoadersPreloaded(loadersLoaded)
	else:
		instantiateLoaders(loaders)
	
	var a = Time.get_ticks_msec()
	makeHistoryFile()
	
	if gameList.get_selected_items().is_empty():
		if gameList.get_item_count() > 0:
			gameList.select(0)
			_on_gameList_item_selected(0)
	
	
	
	previewWorld.get_node("CameraTopDown").current = false
	previewWorld.get_node("Camera3D").current = true


	
	
	if texturePreview.texture == null:
			texturePreview.texture = ImageTexture.new()
			
			
	$h/v3/preview/sondFontPath.setPathText(SETTINGS.getSetting(get_tree(),"soundFont"))
	
	

func instantiateLoaders(loaders : Array[String]):
	for i : String in loaders:
		
		var a= Time.get_ticks_msec()
		var loaded = load(i)
		var h = Time.get_ticks_msec() - a
		
		var inst = loaded.instantiate()
		
		for gameName in inst.getConfigs():
			initGame(gameName,i)
			
			gameToHistory[gameName] = []
			
			var reqs = inst.getReqs(gameName)
			
			if reqs != null:
				for reqIdx in reqs.size():
					var req = reqs[reqIdx]
					gameToHistory[gameName].append([req["UIname"],"",[]])
			else:
				var dir = DirAccess.open("res://")
				dir.remove("history.cfg")
				gameToHistory.erase(gameName)

func instantiateLoadersPreloaded(loaders : Array[PackedScene]):
	for i : PackedScene in loaders:
		var inst = i.instantiate()
		
		for gameName in inst.getConfigs():
			initGame(gameName,i)
			
			gameToHistory[gameName] = []
			
			var reqs = inst.getReqs(gameName)
			
			if reqs != null:
				for reqIdx in reqs.size():
					var req = reqs[reqIdx]
					gameToHistory[gameName].append([req["UIname"],"",[]])
			else:
				var dir = DirAccess.open("res://")
				dir.remove("history.cfg")
				gameToHistory.erase(gameName)

func setStyles():
	var bgStyle : StyleBoxFlat = Panel.new().get_theme_stylebox("panel").duplicate()
	
	if get_tree().has_meta("baseControl"):
		bgStyle = get_tree().get_meta("baseControl").get_theme_stylebox("panel").duplicate()
	
	
	if bgStyle.bg_color.v < 0.5:
		bgStyle.bg_color.v += 0.13
	else:
		bgStyle.bg_color.v -= 0.1
	
	#$h/v1/paths.set("theme_override_styles/panel",bgStyle)
	#$h/v1/Panel.set("theme_override_styles/panel",bgStyle)
	#$h/v1/paths.modulate
	$Panel.set("theme_override_styles/panel",bgStyle)
	
	
	var lineEditStyle = get_tree().get_meta("baseControl").get_theme_stylebox("panel").duplicate()
	

func getLoaders(loadThem = false) -> Array[String]:
	
	var loadersPaths : Array[String] = []
	
	if !ENTG.doesDirExist("res://addons"):
		return loadersPaths
	
	for i in ENTG.getDirsInDir("res://addons"):
		
		var ret : Array[String] = []
		var dir = DirAccess.open("res://addons/"+i)
	
		var files = dir.get_files()
	
		for filePath : String in files:
			if filePath.find("_Loader") != -1:
				filePath = filePath.replace(".remap","")
				
				loadersPaths.append("res://addons/"+ i +"/" +filePath)
				
				if loadThem:
					ResourceLoader.load_threaded_request("res://addons/"+ i +"/" +filePath)
		 
	return loadersPaths


func getFromConfig(path):
	var f : FileAccess = FileAccess.open(path,FileAccess.READ)
	var ret = f.get_as_text()
	
	if ret.is_empty(): return null
	return ret
	


func initGame(gameName,gameParam):
	gameList.add_item(gameName)
	gameList.set_item_metadata(gameList.get_item_count()-1,gameParam)

	

func _process(delta: float) -> void:
	
	
	
	if playMode:
		size = (get_parent().get_viewport().size)
		borderless =true
	#size.y -= 8
	#size = DisplayServer.window_get_size()
	
	#for i in get_children():
	#	if "size" in i:
	#		i.size = get_viewport().get_visible_rect().size

func _on_loadButton_pressed():
	loaderInit()
	if cur != null and is_instance_valid(cur):
		if inspector == null:
			inspector = Inspector.new()
			inspector.theme = load("res://addons/object-inspector/inspector_theme.tres")
			inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
			optionsPanel.add_child(inspector)
			
		inspector.set_object(cur)
		


func loaderInit(fast = false):
	var param = []
	
	for i in paths.get_children():
		if i.required == true and i.getPath().is_empty():
			i.setErrorText("*required")
			return
	
	
	
	for i in paths.get_children():
		param.append(i.getPath())
	
	
	if cur == null:
		return
	
	
	if !playMode:
		
		cur.initialize(param,curGameName,(nameLabel.text).to_lower())
		ENTG.createEntityCacheForGame(get_tree(),false,nameLabel.text,cur,editedNode)
	else:
		cur.initialize(param,curGameName,(nameLabel.text).to_lower())
		ENTG.createEntityCacheForGame(get_tree(),false,nameLabel.text,cur,editedNode)
	
	
	for i in paths.get_children().size():
		var child = paths.get_child(i)
		
		if gameToHistory[curName].size() == i:
			gameToHistory[curName].append([])
		
		
		gameToHistory[curName][i] =[child.getLabelText(),child.getPath(),gameToHistory[curName][i-1][2]]
		
		var historyTriple : Array = gameToHistory[curName][i]
		
		if !historyTriple[2].has(child.getPath()):
			if historyTriple[2].size() > 3:
				historyTriple[2].resize(3)
				historyTriple[2].pop_front()
			historyTriple[2].append(child.getPath())
	updateHistoryFile()
	
	
	if fast:
		return

	if is_instance_valid(curTree):
		curTree.queue_free()
	
	var all = cur.getAllCategories()
	var tree = createTree()
	curTree = tree
	
	
	var meta
	
	if all.has("meta"):
		meta = all["meta"]
		all.erase("meta")
	
	for i in all:
		populateTree(tree,i,[],meta)
	

func initializeThreaded(arr):
	var cur = arr[0]
	var param = arr[1]
	var gameName = arr[2]
	
	cur.initialize(param,nameLabel.text.to_lower())

func createTree():
	var tree = Tree.new()
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.set_hide_root(true)
	var root = tree.create_item()
	tree.create_item(root)
	cats.add_child(tree)
	
	tree.connect("item_selected", Callable(self, "itemSelected"))
	
	tree.item_collapsed.connect(collapseOrExpand)
	return tree

func collapseOrExpand(item):
	var itemText : String = item.get_text(0)
	
	if !itemText.is_empty():
		if cur.getAllCategories().has(itemText):
			itemSelected(item)
			
func populateSection(tree : Tree,item : TreeItem,subItems,meta):
	var itemName = item.get_text(0)
	tree.release_focus()
	for i in subItems:
		var subItem = tree.create_item(item)
		subItem.set_meta("cat",itemName)
		subItem.set_text(0,i)
		
		if meta != null:
			if meta.has(i):
				for m in meta[i].keys():
					subItem.set_meta(m,meta[i][m])
		subItem.collapsed = true
		
		if itemName == "fonts" or itemName == "themes":
			subItem.set_meta("info",subItems[i])
			continue
		
		if typeof(subItems) == TYPE_DICTIONARY :
			
			##if typeof(subItems[i]) == TYPE_DICTIONARY:
			#	breakpoint
			if typeof(subItems[i]) != TYPE_STRING:
				for j in subItems[i]:
					var subItem2 = tree.create_item(subItem)
					#subItem2.set_meta("cat",itemName)
					subItem2.set_meta("cat",itemName + "/" + i )
					subItem2.set_text(0,j)
	

func populateTree(tree : Tree,itemName,subItems,meta):
	var root = tree.get_root()
	var item = tree.create_item(root)
	
	
	item.collapsed = true
	item.set_text(0,itemName)
	
	var dummyItem = tree.create_item(item)

	
	for i in subItems:
		
		
		var subItem = tree.create_item(item)
		subItem.set_meta("cat",itemName)
		subItem.set_text(0,i)
		
		if meta != null:
			if meta.has(i):
				for m in meta[i].keys():
					subItem.set_meta(m,meta[i][m])
		subItem.collapsed = true
		
		if itemName == "fonts" or itemName == "themes":
			subItem.set_meta("info",subItems[i])
			continue
		
		if typeof(subItems) == TYPE_DICTIONARY :
			
			##if typeof(subItems[i]) == TYPE_DICTIONARY:
			#	breakpoint
			if typeof(subItems[i]) != TYPE_STRING:
				for j in subItems[i]:
					var subItem2 = tree.create_item(subItem)
					#subItem2.set_meta("cat",itemName)
					subItem2.set_meta("cat",itemName + "/" + i )
					subItem2.set_text(0,j)
				
				
func itemSelected(itemOveride = null):
	await get_tree().physics_frame
	var item : TreeItem= curTree.get_selected()
	
	if itemOveride != null:
		item = itemOveride
	
	cat = "misc"
	var txt = item.get_text(0)
	
	
	#populateTree(curTree,txt,[],)
	
	previewWorldContainer.visible = false
	$h/v3/preview/sondFontPath.visible = false
	$h/v3/preview/fontPreview.visible = false
	curEntTxt = txt
	curMeta = {}
	
	
	if item.has_meta("cat"):
		cat = item.get_meta("cat")
	
	var categoryHierarchy = cat.split("/")

	for key in item.get_meta_list():
		if key != "__focus_rect":
			curMeta[key] = item.get_meta(key)
	
	
	
	
	if item.get_child_count() > 0:
		var cText = item.get_child(0).get_text(0)
		if cText == "":
			var allEntries = getAllInCategory(item.get_text(0))
			item.remove_child(item.get_child(0))
			populateSection(curTree,item,allEntries,curMeta)
	
	if categoryHierarchy.has("entities"):
		previewWorldContainer.visible = true
		clearEnt()
		

		var ent  = ENTG.spawn(cur.get_tree(),txt,Vector3.ZERO,Vector3.ZERO,nameLabel.text.to_lower(),previewWorld,false,false,get_tree().root)

		pEnt = ent
		
		if ent is Node2D:
			ent.ready.connect(ent.reparent.bind(previewWorld2D))
			#ent.reparent(previewWorld2D)
			previewWorld2DContainer.visible = true
			previewWorld2D.get_node("Camera2D").make_current()
			
			
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			previewWorld.get_node("CameraTopDown").current = false
			previewWorld.get_node("Camera3D").current = true
	
	elif cat == "maps":
		previewWorldContainer.visible = true
		clearEnt()

		previewWorld.get_node("CameraTopDown").current = true
		previewWorld.get_node("Camera3D").current = false
		
		var mapNode = null
		
		if cur.has_method("createMapPreview"):
			mapNode = cur.createMapPreview(txt,curMeta,false,get_tree().get_root())
			
			
		else:
			mapNode = cur.createMap(txt,curMeta,false,get_tree().get_root())
		
		if mapNode.get_parent() != null:
			mapNode.get_parent().remove_child(mapNode)
		
		if mapNode != null:
			pEnt = mapNode
			previewWorld.add_child(mapNode)
			
		

	elif cat == "sounds":
		var sound = cur.createSound(txt,curMeta)
		
		#var player = AudioStreamPlayer.new()
		var player = get_node("h/v3/preview/audioPreview")
		clearEnt()
		
		player.stream = cur.createSound(txt,curMeta)
		player.play()
		player.volume_db = -10
		
	elif cat == "textures":
		clearEnt()
		if !cur.has_method("createTexture"):
			return
		
		var x =  cur.createTexture(curEntTxt,curMeta)
		
		if x == null:
			return
		
		if "textureFiltering" in cur:
			if cur.textureFiltering == false:
				texturePreview.texture_filter  = DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
			else:
				texturePreview.texture_filter  = DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		
		
		if x.get_class() == "AnimatedTexture":
			texturePreview.texture = x
			return

		
		
		if texturePreview.texture == null:
			texturePreview.texture = ImageTexture.new()
		texturePreview.texture.image = x
	elif cat == "game modes":
		clearEnt()
		if cur.has_method("createGameModePreview"):
			var x = cur.createGameModePreview(txt,curMeta)
			texturePreview.texture = cur.createGameModePreview(txt,curMeta)
	
	elif cat == "fonts":
		#curMeta["info"]["disableToDiskdisableToDisk"] = true
		var pToDisk = cur.toDisk
		cur.toDisk = false
		var font = cur.fetchFont(txt,curMeta["info"])
		cur.toDisk = pToDisk
		$h/v3/preview/fontPreview.visible = true
		#$h/v3/preview/fontPreview.add_theme_font_size_override("font",19)
		$h/v3/preview/fontPreview.set("theme_override_font_sizes/font_size",16)
		$h/v3/preview/fontPreview.add_theme_font_override("font",font)
		
	elif categoryHierarchy.has("mus") or categoryHierarchy.has("midi"):
		
		
			
		if midiPlayer == null:
				
			midiPlayer = ENTG.createMidiPlayer(SETTINGS.getSetting(get_tree(),"soundFont"))
			previewNode.add_child(midiPlayer)
				
		
		if categoryHierarchy.has("mus"):
			var midiData :  PackedByteArray= cur.createMidi(txt)
			ENTG.setMidiPlayerData(midiPlayer,midiData)
			midiPlayer.play()
			$h/v3/preview/sondFontPath.visible = true
		
		elif categoryHierarchy.has("midi"):
			var midiData : PackedByteArray= cur.createMidi(txt)
			ENTG.setMidiPlayerData(midiPlayer,midiData)
			midiPlayer.play()
			$h/v3/preview/sondFontPath.visible = true
			
			
		

func fetchLoader(loaderPath):
	pass

func _on_gameList_item_selected(index: int):#game selected
	
	if gameList == null:
		return
	
	
	clearEnt()
	$h.get_node("%playButton").text = "Play"
	$h.get_node("%playButton").disabled = false
	
	var gameLoader  = gameList.get_item_metadata(index)
	var gameName : String = gameList.get_item_text(index)
	curGameName = gameName
	curName = gameName
	nameLabel.text = gameName.to_lower()
	
	if !gameToLoaderNode.has(gameName):
		var loader = gameLoader
		
		if loader is not PackedScene:
			loader = load(loader).instantiate()
		else:
			loader = loader.instantiate()
			
		add_child(loader)
		gameToLoaderNode[gameName] = loader

	
	
	for i : Node in cats.get_children():
		i.queue_free()
	
	clearEnt()
		
	
	cur = gameToLoaderNode[gameName]
	
	for i in paths.get_children():
		i.queue_free()
	
	
	var reqs : Array = cur.getReqs(gameName)
	
	if gameToHistory.has(gameName):
		var initReqs : Array = reqs.duplicate(true)
		reqs = []
		for savedReq : Array in gameToHistory[gameName]:
			var uiName : String = savedReq[0]
			
			for reqDef : Dictionary in initReqs:
				var thisReqDef : Dictionary = reqDef.duplicate(true)
				
				if reqDef["UIname"] == uiName:
					reqs.append(thisReqDef)
					
					if reqDef["required"] == false:
						var count : int = 0
						for i in reqs:
							if i["UIname"] == uiName:
								count +=1
								if count > 1:
									thisReqDef["extra"] = true
				
				
	
	var i : int = 0
	
	for rIdx in reqs.size():
		var r : Dictionary = reqs[i]
		var UIname : String = "path"
		var required : bool= true
		var ext : Array= [""]
		var multi : bool = false 
		var fileNames : Array= []
		var hints : Array = []
		var extra : bool = false
		if r.has("UIname") : UIname = r["UIname"]
		if r.has("required") : required = r["required"]
		if r.has("ext") : ext = r["ext"]
		if r.has("multi") : multi = r["multi"]
		if r.has("fileNames"): fileNames = r["fileNames"]
		if r.has("hints"): hints = r["hints"]
		if r.has("extra"): extra = r["extra"]
		
		
		var node : Node = pathScenePacked.instantiate()
		node.signalNewPathCreated.connect(newPathCreated)
		node.removedSignal.connect(pathRemoved)
		node.enterPressed.connect(_on_playButton_pressed)
		node.required = required
		node.many = multi
		paths.add_child(node)
		node.setText(UIname)
		
		
		if extra:
			node.showDeleteButton()
			
		if ext.is_empty():
			node.setAsDir()
		else:
			node.setExt(ext)
			
		
		if !fileNames.is_empty():
			
			var exts = []
			
			for e in ext:
				exts.append(e.replace("*.",""))
			
			node.popupStrings = findFiles(fileNames,hints,exts)

			
		i+=1
		
		if gameToHistory.has(gameName):
			if !gameToHistory[gameName].is_empty():
				var savedPaths : Array = gameToHistory[gameName]
				
				if rIdx < savedPaths.size():
				
					var historyPath : String = gameToHistory[gameName][rIdx][1]
						
					if historyPath.find(".") != -1:
						if doesFileExist(historyPath):
							node.setPathText(historyPath)
							
					elif ENTG.doesDirExist(historyPath):
						node.setPathText(historyPath)
				
				for path in savedPaths:
					
					if node.getLabelText() != path[0]:
						continue
					
					for recentPath in path[2]:
						if !node.popupStrings.has(recentPath) and node.getPath() != recentPath:
							node.popupStrings.append(recentPath)
					
					if path[1] == "":
						if node.getPathCount() > 0:
							node.setPathText(node.popupStrings[0])
					else:
						break

			else:
				breakpoint 
		
	if cur.has_method("getCredits"):
		creditsButton.visible = true
	else:
		creditsButton.visible = false

				





func _on_debugButton_pressed():
	var l = load("res://addons/gameAssetImporter/scenes/entityDebug/entityDebugDialog.tscn").instantiate()
	add_child(l)
	l.popup_centered_ratio(0.4)


func clearEnt() -> void:
	if pEnt != null and is_instance_valid(pEnt):
		pEnt.queue_free()
		pEnt = null
	
	if midiPlayer != null:
		midiPlayer.stop()
	
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
		
	
		if filesLower.has(fn):
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
		
		if target == "program files":
			var dirs = findProgramFilesDir()
			for j in dirs:
				for f in files:
					if ENTG.doesDirExist(j + postFix + "/" + f):
						ret.append(j + postFix + "/" + f)
						
						found.append(f.to_lower())
						
						if found.size() == files.size():
							return ret
			
		
	
	for i in ret.size():
		ret[i] = ProjectSettings.localize_path(ret[i])
	
	return ret

static func findProgramFilesDir() -> Array[String]:
	var ret : Array[String] = []
	var drives : Array[String] = getDrives()
	
	for i : String in drives:
		if ENTG.doesDirExist(i + "/Program Files (x86)/"):
			ret.append(i + "/Program Files (x86)/")
		
	return ret

static func getDrives() -> Array[String]:
	var ret : Array[String] = []
	
	for i in DirAccess.get_drive_count():
		ret.append(DirAccess.get_drive_name(i))
		
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
	
	
static func allInDirectory(path,filter=[]):
	var files = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		return []
		
	dir.list_dir_begin()  # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547# TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			
			if file.find(".") == -1:
				files.append(file)
			else:
				#if filter != null:
				if !filter.is_empty():
					for i in filter:
						var ext = file.split(".")
						ext = ext[ext.size()-1].to_lower()
						if ext.find(i)!= -1:
							files.append(file)
				else:
					files.append(file)
					

	dir.list_dir_end()

	return files
	





func _on_instanceButton_pressed():
	
	if curEntTxt.is_empty():
		return
		
	
	var targetTree = get_tree()
	
	var returnCache = ENTG.fetchEntityCaches(targetTree,nameLabel.text,true)
	
	if returnCache == null:
		return
	
	if cat == "game modes":
		var mode = cur.createGameMode(curEntTxt,curMeta)
		emit_signal("instance",mode,null)
		
	
	if cat ==  "maps":
		var pGameName = cur.gameName
		cur.gameName = curName
		#ENTG.createEntityCacheForGame(targetTree,false,nameLabel.text,cur,editedNode)
		var map = cur.createMap(curEntTxt,curMeta,returnCache)
		
		cur.gameName = pGameName
		
		
		returnCache = copyDependentEntitiesToCacheAuto(targetTree)
		return emit_signal("instance",map,returnCache)
	
	if cat == "textures":
		var image = cur.createTexture(curEntTxt,curMeta)
		
		if image == null:
			return
			
		var type : String = image.get_class()
		var texture = null
		
		if type == "Image":
			texture = ImageTexture.new()
			texture.image = image
			
		if type == "AnimatedTexture":
			texture = image
		
		
		var ret = Sprite2D.new()
		
		ret.texture = texture
		
		if "textureFiltering" in cur:
			if cur.textureFiltering == false:
				ret.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			else:
				ret.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		
		return emit_signal("instance",ret,returnCache)
	
	
	ENTG.updateEntitiesOnDisk(targetTree)
	
	
	
	#if e.empty():
	#	print("create enitty cache for game")
	#ENTG.createEntityCacheForGame(targetTree,false,nameLabel.text,cur,editedNode)


	var ent = ENTG.fetchEntity(curEntTxt,targetTree,nameLabel.text,false,false,targetTree.get_root())
	var depends = []
	

	if ent.has_meta("entityDepends"):
		depends = ent.get_meta("entityDepends")
		returnCache = copyDependentEntitiesToCache(targetTree,ent,depends)
		
		
	emit_signal("instance",ent,returnCache)
	

func copyDependentEntitiesToCacheAuto(targetTree):
	var cacheSrc =  ENTG.fetchEntityCaches(targetTree,"",false,get_tree().get_root())[0]
	var cacheDest = ENTG.fetchEntityCaches(targetTree,"",false,editedNode)[0]
	var visited = []
	var procArray : PackedStringArray = []
	
	for ent in cacheSrc.get_children():
		if ent.has_meta("entityDepends"):
			for depEnt in ent.get_meta("entityDepends"):
				if !procArray.has(depEnt):
					procArray.append(depEnt)
	
	
	recursiveMove(cacheSrc,cacheDest,procArray,visited)
	return cacheDest
		#copyDependentEntitiesToCache(visited)
	
	


func copyDependentEntitiesToCache(targetTree,ent,depends,visited = []):
	var cacheSrc =  ENTG.fetchEntityCaches(targetTree,"",false,get_tree().get_root())[0]
	var cacheDest = ENTG.fetchEntityCaches(targetTree,"",false,editedNode)[0]

	
	if ent.has_meta("entityDepends"):
		depends = ent.get_meta("entityDepends")
		recursiveMove(cacheSrc,cacheDest,depends,visited)
	
	return cacheDest
	

func recursiveMove(source : Node,dest : Node,entStrArr,visited = []):
	
	
	
	
	for entStr in entStrArr:
		entStr = entStr.to_lower()
		if visited.has(entStr):
			continue
		
		var entity = source.get_node_or_null(entStr)
		
		if entity == null:
			continue

		if !dest.has_node(entStr):
			entity.reparent(dest)
		
		visited.append(entStr)
		
		if entity.has_meta("entityDepends"):
			var depends = entity.get_meta("entityDepends")
			recursiveMove(source,dest,depends,visited)
		
	

	
func getTree():
	if  editedNode != null:
		return editedNode
	
	return get_tree()
		
		

func getSettingsAsText() -> String:
	
	var selectedGame : String = ""
	
	if !gameList.get_selected_items().is_empty():
		selectedGame = gameList.get_item_text(gameList.get_selected_items()[0])
	
	var settingsDict : Dictionary = {
		
		"savedToPath":gameToHistory,
		"selectedGame": selectedGame,
		"previousFiles": previousFiles
	}
	return var_to_str(settingsDict)

func makeHistoryFile() -> void:
	
	if !doesFileExist("history.cfg"):
		var f : FileAccess = FileAccess.open("history.cfg",FileAccess.WRITE)
		f.store_string(getSettingsAsText())
		f.close()
	
	var f : FileAccess= FileAccess.open("history.cfg",FileAccess.READ_WRITE)
	var savedSettingsDict =  str_to_var(f.get_as_text())
	
	
	
	if typeof(savedSettingsDict) != TYPE_DICTIONARY:
		f.store_string(getSettingsAsText())
		f.close()
		return

	var gameHistoryDict : Dictionary = savedSettingsDict["savedToPath"]
	
	for gameName : String in gameHistoryDict.keys():
		for pathIdx : int in gameHistoryDict[gameName].size():
			
			var curGameHistory : Array = gameHistoryDict[gameName]
			var pathStr : String = curGameHistory[pathIdx][1]
			
			if pathStr.is_empty():
				continue
			
			var labelText : String = curGameHistory[pathIdx][0]
			var recents : Array = curGameHistory[pathIdx][2]
			

			if pathStr.find(".") != -1:
				if doesFileExist(pathStr):
					if gameToHistory[gameName].size() == pathIdx:
						gameToHistory[gameName].append(["","",[]])
					
					
					gameToHistory[gameName][pathIdx][0]= labelText
					gameToHistory[gameName][pathIdx][1]= pathStr
					gameToHistory[gameName][pathIdx][2] = recents
					
			else:
				if ENTG.doesDirExist(pathStr):
					gameToHistory[gameName][pathIdx][0]= labelText
					gameToHistory[gameName][pathIdx][1]= pathStr
					gameToHistory[gameName][pathIdx][2] = recents
					
	
	
	
	if !savedSettingsDict["selectedGame"].is_empty():
		var target : String = savedSettingsDict["selectedGame"]
		for i : int in gameList.get_item_count():
			if gameList.get_item_text(i)== target:
				gameList.select(i)
				_on_gameList_item_selected(i)
				break
			
		
		
	f.close()
	
func updateHistoryFile():
	if !doesFileExist("history.cfg"):
		var f = FileAccess.open("history.cfg",FileAccess.WRITE)
		f.close()
	
	var f = FileAccess.open("history.cfg",FileAccess.WRITE)
	f.store_string(getSettingsAsText())
	f.close()


func createHistDict():
	var dict = {}
		
	for i in gameToLoaderNode.keys():
		dict[i] = ""
	
	
	return dict

static func doesFileExist(path : String) -> bool:
	var ret = FileAccess.file_exists(path)
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

	
	for i in map.get_children():
		#if i.name == "Entities":
		#	i.get_parent().remove_child(i)
		
		#if i.name == "SectorSpecials":
		#	i.get_parent().remove_child(i)
			
		#if i.name == "Geometry":
		#	i.get_parent().remove_child(i)
		
		#if i.name == "Interactables":
		#	i.get_parent().remove_child(i)
		
		pass
	
	
	ps.pack(map)

	var destPath = "res://game_imports/"+cur.gameName+"/maps/"+curEntTxt+".tscn"
	
	
	for i in map.get_children():#this is needed to stop ghost nodes
		map.remove_child(i)
	

	
	#OS.delay_msec(2000)
	ResourceSaver.save(ps,destPath)
	
	#OS.delay_msec(2000)
	
	map.queue_free()
	#
	emit_signal("diskInstance",ResourceLoader.load(destPath).instantiate())
	

var headThread = null

func _on_importButton_pressed():
	oldName = cur.gameName
	
	
	if curEntTxt.is_empty():
		return
	
	
	if "toDisk" in cur:#legacy
		pToDisk  = cur.toDisk
		cur.toDisk = true
		
	cur.gameName = oldName.split("_")[0]
	
	var addSignal = true
	
	for sig in cur.get_signal_connection_list("fileWaitDoneSignal"):

		if sig["callable"].get_object() == self:
			addSignal = false
	
	if addSignal == true:
		cur.connect("fileWaitDoneSignal", Callable(self, "importTailFlagSet"))
		
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
	var categoryHierarchy = cat.split("/")
	
	if cat == "maps":
		cur.createMapResourcesOnDisk(curEntTxt,curMeta,editorInterface)
	elif cat == "game modes":
		curMeta["destPath"] = "res://game_imports/"+cur.gameName
		cur.createGameModeResourcesOnDisk(curEntTxt,curMeta,editorInterface)
	elif categoryHierarchy.has("midi") or categoryHierarchy.has("mus"):
		cur.createMidiOnDisk(curEntTxt,curMeta,editorInterface)
		importTailFlagSet()
	elif cat == "textures":
		cur.createTextureDisk(curEntTxt,curMeta,editorInterface)
		importTailFlagSet()
	elif cat == "fonts":
		var font = cur.fetchFont(curEntTxt,curMeta)
	elif cat == "themes":
		curMeta["destPath"] = "res://game_imports/"+cur.gameName +"/themes/"
		var theme = cur.createThemeDisk(curEntTxt,curMeta)
	else:
		cur.createEntityResourcesOnDisk(curEntTxt,curMeta,editorInterface)
	

	
	
	
var mapThread = Thread.new()

func _physics_process(delta):
	
	if texturePreview != null:
		texturePreview.visible = false
	
		if texturePreview.texture != null:
			var t = texturePreview.texture.get_class()
			if texturePreview.texture.get_class() != "AnimatedTexture":
				if texturePreview.texture.image != null:
					texturePreview.visible = true
			else:
				texturePreview.visible = true
	
	
	if cats != null:
		if cats.get_child_count() > 0:
			setOptionsVisibility(true)
				
		else:
			setOptionsVisibility(false)
	else:
		setOptionsVisibility(false)
	
	$h/v3/preview/SubViewportContainer/SubViewport/StaticBody3D.visible = previewWorld.get_node("Camera3D").current

		

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
	var cats = cat.split("/")
	ENTG.updateEntitiesOnDisk(get_tree())
	
	if cats.has("entities"):
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

func createDirectories(gameName, dirs = ["textures","materials","sounds","sprites","textures/animated","entities","fonts","maps","themes"]):

	
	var directory = DirAccess.open("res://")
	
	
	var split = (destPath+gameName).lstrip("res://")

	if split.length() > 0:
		var subDirs = split.split("/")
		
		for i in subDirs.size():
			var path = "res://"
			for j in i+1:
				directory = directory.open(path)
				path += subDirs[j] + "/"
				createDirIfNotExist(path,directory)
				
			directory =directory.open(path)
	
	
	directory.open(destPath+nameLabel.text)
	
	for i in dirs:
		var initDir = directory.get_current_dir()
		
		var subs = i.split("/")
		
		
		if subs.size() == 1:
			createDirIfNotExist(i,directory)
		else:
			createDirIfNotExist(subs[0],directory)
			createDirIfNotExist(i,directory)
		
		directory.open(initDir)
	

	
	if cur.has_method("getEntityDict"):
		var e = cur.getEntityDict()
		for ent in e:
			if "category" in e[ent]:
				createDirIfNotExist(destPath+nameLabel.text+"/entities/" + e[ent]["category"],directory)
	

	
	var directoriesToCreate : Array = []
	
	

	for dir in directoriesToCreate:
		createDirIfNotExist("entities/"+dir,directory)
	

	
func createDirIfNotExist(path : String,dir : DirAccess):
	var t = dir.get_current_dir()

	#if !dir.dir_exists_absolute(path):
	#	dir.make_dir(path)
	if !dir.dir_exists(path):
		dir.make_dir(path)
		


func waitForDirToExist(path):
	var waitThread = Thread.new()
	
	waitThread.start(Callable(self, "waitForDirToExistTF").bind(path))
	waitThread.wait_to_finish()
	
func waitForDirToExistTF(path):
	var dir = DirAccess.open(path)
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
		if i.required == true and i.getPath().is_empty():
			i.setErrorText("*required")
			return
			
	loaderInit()

	var all = cur.getAllGameModes()
	
	var noGameMode = false
	
	if all.is_empty():
		noGameMode = true
		
	if noGameMode:
		get_node("%playButton").text = "No game mode implemented"
		get_node("%playButton").disabled = true
		return
	var gamdeModeName = all.keys()[0]
	var gameMode = all[gamdeModeName]
	var meta = {"path":all[gamdeModeName]}
	meta["loader"]= cur
	var mode = cur.createGameMode(gamdeModeName,meta,curName,curGameName)
	
	get_tree().get_root().add_child(mode)
	
	queue_free()


func _on_close_requested():
	hide()

func soundFontSet(path):
	if midiPlayer != null:
		midiPlayer.soundfont = path
		
	SETTINGS.setSetting(get_tree(),"soundFont",path)
	
func newPathCreated(creator : Node,created : Node):
	pass
			
func pathRemoved(pathNode):
	var curEntry : Array = gameToHistory[curGameName]
	var targetPAth = pathNode.getPath()
	
	for i in paths.get_child_count():
		if paths.get_child(i) == pathNode:
			curEntry.remove_at(i)
			return

func getFilesInDir(dirPath : String) -> Array[String]:
	var ret : Array[String] = []
	var dir = DirAccess.open(dirPath)
	
	var files = dir.get_files()
	
	for filePath : String in files:
		if filePath.find("_Loader") != -1:
			return [filePath]

	
	return ret

func getAllInCategory(categoryName : String):
	
	if categoryName == "entities":
		return cur.getAllEntites()
	elif categoryName == "sounds":
		return cur.getAllSounds()
	elif categoryName == "maps":
		return cur.getAllMaps()
	elif categoryName == "music":
		return cur.getAllMusic()
	elif categoryName == "fonts":
		return cur.getAllFonts()
	elif categoryName == "textures":
		return cur.getAllTextures()
	elif categoryName == "game modes":
		return cur.getAllGameModes()
	elif categoryName == "themes":
		return cur.getAllThemes()
	


func _on_loader_options_pressed() -> void:
	ENTG.showObjectInspector(cur)


func _on_credits_button_pressed() -> void:
	
	if cur == null:
		return
		
	var creds = cur.getCredits()
	var credList: Window = load("res://addons/godotWad/scenes/credits/creditsWindow.tscn").instantiate()
	credList.get_child(0).values = creds
	get_tree().get_root().add_child(credList)
	credList.popup_centered_ratio()
	
func printCaches():
	for i in ENTG.fetchEntityCaches(cur.get_tree(),nameLabel.text.to_lower()):
		if i.is_inside_tree():
			print(i.get_path())
		else:
			print("orphan")
		
		i.print_tree_pretty()
	
	print("---")
