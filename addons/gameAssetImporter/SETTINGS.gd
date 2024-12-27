class_name SETTINGS

extends Node


static func initSettings(tree):
	var dict = {}
	dict["fov"] = 90
	dict["mouseSens"] = 0.25
	dict["textureFiltering"] = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST 
	dict["soundFont"] = "res://addons/godotWad/soundfonts/gzdoom.sf2"
	
	dict["textureFilteringGeometry"] = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST 
	dict["textureFilteringSprite"] = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST 
	dict["textureFilteringSky"] = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST 
	dict["textureFilteringFov"] = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST 
	dict["textureFilteringUI"] = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST 
	
	var styleBox = StyleBoxFlat.new()
	styleBox.bg_color = Color(12/255.0,0,0,228/255.0)
	
	dict["styleBox"] = styleBox
	
	tree.set_meta("settings",dict)



static func getSetting(tree : SceneTree,settingName : StringName):
	
	if !tree.has_meta("settings"):
		initSettings(tree)
	
	return tree.get_meta("settings")[settingName]
	

static func setSetting(tree,settingName,value):
	
	if tree == null:
		print("failed to set setting as tree is null")
		return
	
	if !tree.has_meta("settings"):
		initSettings(tree)
	
	tree.get_meta("settings")[settingName] = value

static func getSettingsDict(tree : SceneTree):
	if !tree.has_meta("settings"):
		initSettings(tree)
		
	return tree.get_meta("settings")

static func setTimeLog(tree : SceneTree, valName : String, startTime : int) -> void:
	if !tree.has_meta("timings"):
		tree.set_meta("timings",{})
	
	
	var dict = tree.get_meta("timings")
	dict[valName] = Time.get_ticks_msec() - startTime
	tree.set_meta("timings",dict)
	


static func incTimeLog(tree,valName,startTime):
	if !tree.has_meta("timings"):
		tree.set_meta("timings",{})
	
	
	
	var dict = tree.get_meta("timings")
	
	if !dict.has(valName):
		dict[valName] = 0
		
	
	var curValue = dict[valName] + Time.get_ticks_msec() - startTime
	dict[valName] = curValue
	
	
	tree.set_meta("timings",dict)


static func getTimeData(tree):
	if !tree.has_meta("timings"):
		return {}
		
	return tree.get_meta("timings")



static func addMusicBus():
	if AudioServer.get_bus_index("Music") == -1:
		
		var index = AudioServer.bus_count-1
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index,"Music")


static func injectAtStartAndEndOfFunction(targetNode : Node,targetFunc : String,startCode : String, endCode) -> Error:
	
	if Engine.is_editor_hint():
		return OK
		
	if OS.has_feature("standalone"):
		return OK
	var script : GDScript = targetNode.get_script()
	var sourceCode = script.source_code
	
	var funcNamePos = sourceCode.find("func " + targetFunc + "(") + targetFunc.length()
	
	var index : int = funcNamePos
	
	while sourceCode[index] != "\n":
		index += 1
	
	index += 1
	
	var pp = sourceCode.substr(index)
	
	
	var spacing = pp.substr(0, findFirstAlphabetic(pp))
	
	sourceCode = sourceCode.insert(index,spacing + startCode)
	
	var newPlaces = findFunctionsEnd(sourceCode.substr(index),spacing)
	
	var runningOffset = 0
	
	for i  in newPlaces:
		var curSpacing = i[1]
		var pos = i[0]+index+1
		var x= sourceCode.substr(0,pos)
		sourceCode = sourceCode.insert(pos+runningOffset,curSpacing+endCode)
		runningOffset += (curSpacing+endCode).length()
	
	script.source_code = sourceCode
	return script.reload(true)
	


static func injectTiming(targetNode : Node,targetFunc : String):
	if Engine.is_editor_hint():
		return
		
	if OS.has_feature("standalone"):
		return
		
	var a = Time.get_ticks_msec()
	
	var startCode = "var a = Time.get_ticks_msec()\n"
	var endCode = "print(\""+targetFunc+" time:\",Time.get_ticks_msec()-a)\n"
	injectAtStartAndEndOfFunction(targetNode,targetFunc,startCode,endCode)





static func injectLoggedTiming(targetNode : Node,targetFunc : String):
	
	if Engine.is_editor_hint():
		return
	
	if OS.has_feature("standalone"):
		return
	
	var a = Time.get_ticks_msec()
	
	var startCode = "var a = Time.get_ticks_msec()\n"
	var endCode = "SETTINGS.setTimeLog(get_tree(),\""+targetFunc+"\",a)\n"
	injectAtStartAndEndOfFunction(targetNode,targetFunc,startCode,endCode) 
	
static func injectLoggedTimingInc(targetNode : Node,targetFunc : String):
	
	if Engine.is_editor_hint():
		return
	
	if OS.has_feature("standalone"):
		return
	
	var a = Time.get_ticks_msec()
	
	var startCode = "var a = Time.get_ticks_msec()\n"
	
	var endCode = "SETTINGS.incTimeLog(get_tree(),\""+targetFunc+"\",a)"
	injectAtStartAndEndOfFunction(targetNode,targetFunc,startCode,endCode) 

static func findFirstAlphabetic(string: String) -> int:
	var idx : int = 0
	
	for char in string:
		if (char >= 'A' and char <= 'Z') or (char >= 'a' and char <= 'z'):
			return idx
		
		idx+= 1
	
	return -1

static func findFunctionsEnd(string : String,formatting : String):
	var idx : int = 0
	
	idx = string.find("func ")
	
	var allFuncSection = string.substr(0,idx)
	var lastFormattingInstance = allFuncSection.rfind(formatting)
	
	
	var lastNewline = allFuncSection.find("\n",lastFormattingInstance)
	#var returnPos = allFuncSection.rfind("return",allFuncSection.length())
	var numRets = allFuncSection.count("return")
	
	var retIndicies =[]
	var lastRet = 0
	
	
	
	
	for i in numRets:
		retIndicies.append( allFuncSection.find("return",lastRet+2)-1)
		lastRet = retIndicies.back()
	
	var indexAndSacing = []
	
	for i in retIndicies:
		var cPos = i
		
		while allFuncSection[cPos] != "\n":
			cPos -=1
		
		var oi = allFuncSection.substr(cPos)
		var spacing = allFuncSection.substr((cPos+1),(i)-(cPos))
		
		indexAndSacing.append([cPos,spacing])
		
		
	if indexAndSacing.size() == 0:
		return[[lastNewline,formatting]]

	if indexAndSacing.back()[0] >= lastNewline:
		return indexAndSacing
	else:
		indexAndSacing.append([lastNewline,formatting])
		return indexAndSacing
