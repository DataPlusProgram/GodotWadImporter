@tool
extends Node



func parse(path):
	var file = FileAccess#.new()
	#var err = file.open(path, FileAccess.READ)
	var content = file.get_file_as_string(path)
	var ret = {}
	var nl = content.split("\n")
	
	for i in nl.size():
		var line = nl[i]
		var idx = line.find("enum ")
		if idx != -1 and idx == 0:
			var e = enumFound(nl,i)
			ret[e[0]] = e[1]

	
	
	return guessTypes(ret)
	



func enumFound(arr,idx):
	var enumDict = {}
	var token = []
	var enumName = arr[idx].split(" ")[1]
	
	enumName=enumName.replace("{","")
	
	for i in range(idx+1,arr.size()):
		var string = arr[i]
		
		
		if string == "}":
			break
		
		string = string.replace("\n","")
		string = string.replace(" ","")
		string = string.replace("\t","")
		string = string.replace(",","")
		if string != "":
			token.append(string)
		
		
			
			
	
	var count = 0
	for i in token:
		if i.find("=") != -1:
			var operands = i.split("=")
			enumDict[operands[0]] = operands[1]
		else:
			enumDict[i] = count
			count += 1
			
	return [enumName,enumDict]

func guessTypes(dict):
	var typeDict = {}
	
	for i in dict.keys():
		typeDict[i] = {}
		for key in dict[i].keys():
			var string = dict[i][key]
			if typeof(string) == TYPE_STRING:
				typeDict[i][key] = stringToType(string)
			else:
				typeDict[i][key] = string
			

	return typeDict

func stringToType(string):
	var value
	
	if string.is_valid_int():
		value = string.to_int()
	elif string.is_valid_float(): 
		value = string.to_float()
	elif string.is_valid_html_color():
		value = Color(string)
	elif string.to_lower() == "true":
		value = true
	elif string.to_lower() == "false":
		value = false
	elif string.is_valid_hex_number(true):
		value = string.hex_to_int()
	#elif string.is_abs_path():
	#	parsePath(string)
	else:
		value = string
		
	return value

