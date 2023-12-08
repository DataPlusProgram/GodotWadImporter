class_name SETTINGS

extends Node



static func initSettings(tree):
	var dict = {}
	dict["fov"] = 70
	dict["mouseSens"] = 0.25
	
	tree.set_meta("settings",dict)


static func getSetting(tree,settingName):
	
	if !tree.has_meta("settings"):
		initSettings(tree)
	
	return tree.get_meta("settings")[settingName]
	

static func setSetting(tree,settingName,value):
	if !tree.has_meta("settings"):
		initSettings(tree)
	
	tree.get_meta("settings")[settingName] = value

