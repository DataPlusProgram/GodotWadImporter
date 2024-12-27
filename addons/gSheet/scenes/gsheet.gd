@tool
extends Resource
class_name gsheet


@export var data : Dictionary = {"meta":{"hasId":false,"rowOrder":["0"],"enumColumns":{},"colNames":[],"enumColumnsPrefix":{}},"0":{"0":""}}


func get_data():
	var dat = data.duplicate()
	dat.erase("meta")
	return dat

func getRowKeys():
	return data["meta"]["rowOrder"]

func getRow(rowKey : String) -> Dictionary:
	var retDict := {}
	
	if !data.has(rowKey):
		return retDict
	
	var entry : Dictionary= data[rowKey]
	var keys : Array = data["meta"]["colNames"]
	
	for i in keys:
		if entry.has(i):
			if typeof(entry[i]) == TYPE_STRING:
				if entry[i] == "":
					continue
		
			retDict[i] = entry[i]
		
	return retDict


func hasKey(rowKey):
	return data.has(rowKey)

func getColumn(colKey):
	var ret = []
	
	for key in data.keys():
		if data[key].has(colKey):
			if data[key][colKey] != "":
				ret.append(data[key][colKey])
			
			
	return ret

func getRowsAsArray() -> Array[Dictionary]:
	var ret : Array[Dictionary]= []

		
	for i in data["meta"]["rowOrder"]:
		if i!="meta":
			ret.append(data[i])
		
	return ret

func getRowsAsArrayExcludeEmptyColumns() -> Array:
	var ret : Array = []
	
	for key in data.keys():
		if key!="meta":
			
			var line : Dictionary = data[key]
			var minDict : Dictionary = {}
			
			
			for value in line:
				var d = line[value]
				
				if d != null:
					if typeof(d) == TYPE_STRING:
						if line[value].is_empty():
							continue
							
					minDict[value] = line[value]
			ret.append(minDict)
			#ret.append(data[key])
		
		
	return ret
	
func getAsDict(forceColumnInt =false) -> Dictionary:
	var ret = data.duplicate()
	ret.erase("meta")
	var ret2 = {}
	
	#for key in ret.keys():
	for key in data["meta"]["rowOrder"]:
		var key2 = key
		
		if forceColumnInt:
			key2 = int(key)
		

		
		var retEntry = {}
		var empty = true
		for column in ret[key]:
			var value = ret[key][column]
			
			if typeof(value) == TYPE_STRING:
				if !ret[key][column].is_empty():
					if !ret2.has(key2):
						ret2[key2] = {}
					
					ret2[key2][column] = value
					empty = false
			else:
				if !ret2.has(key2):
					ret2[key2] = {}
					
				ret2[key2][column] = value
				empty = false
			
		if empty:
			ret.erase(key)
	
	return ret2
	
