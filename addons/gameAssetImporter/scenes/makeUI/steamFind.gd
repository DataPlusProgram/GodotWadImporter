extends Node
class_name steamUtil



static func findSteamDir():
	return optimisitcFind()
	
	#breakpoint


static func optimisitcFind():
	var t = "C:/Program Files (x86)/Steam"
	var ret = []
	if doesDirExist(t):
		return parseSteamDir(t)
		
	return []

static func doesFileExist(path : String) -> bool:
	var f : File = File.new()
	var ret = f.file_exists(path)
	f.close()
	return ret
	
static func doesDirExist(dirPath):
	var d = Directory.new();
	return d.dir_exists(dirPath)


static func parseSteamDir(path):
	
	var ret = []
	var vdfPath = path + "/config/libraryfolders.vdf"
	if !doesFileExist(vdfPath):
		return ret
		
	var file = File.new()
	var paths = []
	file.open(vdfPath,File.READ)
	
	if file.open(vdfPath, File.READ) == OK:
		while !file.eof_reached():
			var line = file.get_line()
			if line.find('"path"') != -1:
				var p = line.replace('"path',"")
				paths.append(clean(p)+ "/steamapps/common/")
				
				
	
	var validPaths = []
	
	for i in paths:
		if ENTG.doesDirExist(i):
			validPaths.append(i)
	
	return validPaths
	
static func clean(string):
	
	var clean = ""
	var valid = " :abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_./\\()"
	
	for i in string:
		if valid.find(i) != -1:
			clean += i

	return clean.replace("\\\\","/")
