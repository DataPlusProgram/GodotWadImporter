@tool
extends Window


@onready var left : ItemList = $TabBar/treeMeta/hSplit/listLeft
@onready var mid : ItemList= $TabBar/treeMeta/hSplit/listMiddle
@onready var right : ItemList = $TabBar/treeMeta/hSplit/listRight 
@onready var column4 : ItemList = $TabBar/treeMeta/hSplit/ItemList4 

func _on_Tabs_tab_selected(tab):
	if tab == 0 and left != null:
		left.clear()
		mid.clear()
		for key in get_tree().get_meta_list():
			left.add_item(key)
		
		
		var groups = get_tree().get_nodes_in_group("entityCache")
	
		if !groups.is_empty():
			left.add_item("entityCache groups")
	


func _ready():
	_on_Tabs_tab_selected(0)

func _on_listTop_item_selected(index):
	
	mid.clear()
	var x = get_tree().get_meta_list().size()
	
	if get_tree().get_meta_list().size()-1 < index:
		var leftIndex = left.get_selected_items()[0]
		var treeMetaKey = left.get_item_text(leftIndex)
		if treeMetaKey == &"entityCache groups":
			var groups = get_tree().get_nodes_in_group("entityCache")
			for cacheNode in groups:
				mid.add_item(cacheNode.name + " - " + String(cacheNode.get_path()))
				
				
		return
	
	column4.visible = false
	
	var dataKey = get_tree().get_meta_list()[index]
	var data =  get_tree().get_meta(dataKey)
	
	
	mid.clear()
	
	
	populateMid(data)
	
	
	


func populateMid(data):
	
	right.clear()
	mid.clear()
	
	var dataType = typeof(data)
	
	if dataType == TYPE_DICTIONARY:
		for i in data.keys():
			var valueType = typeof(data[i])
			mid.add_item(var_to_str(i).replace('"',"") + "   (" + typeToString(valueType) +")")
	
	elif dataType == TYPE_ARRAY:
		for i in data:
			if typeof(i) == TYPE_OBJECT:
				mid.add_item(i.name + "   (Orphan Node)")
				
	
	elif dataType == TYPE_OBJECT:
		mid.add_item(data.name + "   (" + data.get_class() + ")" )
		
		
	
	
	
	


func _on_entityDebugDialog_about_to_show():
	_on_Tabs_tab_selected($TabBar.current_tab)




func _on_listMiddle_item_selected(index):
	var leftIndex = left.get_selected_items()[0]
	var treeMetaKey = left.get_item_text(leftIndex)
	var midValue = mid.get_item_text(index).split("   ")[0]
	
	
	right.clear()
	
	
	if midValue.find("(Orphan Node)") != -1:
		var originalNodeName = midValue.replace(" (Orphan Node)","")
		var nodeArr = get_tree().get_meta(treeMetaKey)
		
		for i in nodeArr:
			right.max_columns = 1
			
			if i.name == originalNodeName:
				for child in i.get_children():
					right.add_item(child.name)
					
					
		
		return
	
	
	if treeMetaKey == &"entityCache groups":
		var groups = get_tree().get_nodes_in_group("entityCache")
		var targetPath = midValue.split(" - ")[1]
		#print("rfind:",targetPath.rfind("/"))
		#targetPath = targetPath.substr(0,targetPath.rfind("/"))
		
		
		
		for i in groups:
			right.max_columns = 1
			
			if String(i.get_path()) == targetPath:
				for c in i.get_children():
					right.add_item(c.name)
					right.set_item_metadata(right.item_count-1,"cachedEntity")
					
					
		return
	
	var keyToData =  get_tree().get_meta(treeMetaKey)
	
	if typeof(keyToData) == TYPE_OBJECT:
		return
	
	if typeof(keyToData) == TYPE_ARRAY:
		for i in keyToData:
			right.add_item(i.name)
		return
	
	var data = get_tree().get_meta(treeMetaKey)[midValue]
	
	
	var isSingleLineData = false
	
	isSingleLineData = typeof(data) == TYPE_OBJECT or typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT
	
	if typeof(data) == TYPE_OBJECT:
		if "name" in data: 
			right.max_columns = 1
			right.add_item(data.name)
		if !is_instance_valid(data):
			right.add_item("(freed object)")
	
	elif typeof(data) == TYPE_DICTIONARY:
		right.max_columns = 2
		for i in data.keys():
			right.add_item(i)
			right.add_item(var_to_str(data[i]))
	
	elif isSingleLineData:
		right.max_columns = 1
		right.add_item(var_to_str(data))
		
	
func typeToString(typeValue: int) -> String:
	var typeMap = {
		TYPE_NIL: "Null",
		TYPE_BOOL: "Bool",
		TYPE_INT: "Int",
		TYPE_FLOAT: "Float",
		TYPE_STRING: "String",
		TYPE_VECTOR2: "Vector2",
		TYPE_VECTOR2I: "Vector2i",
		TYPE_RECT2: "Rect2",
		TYPE_RECT2I: "Rect2i",
		TYPE_VECTOR3: "Vector3",
		TYPE_VECTOR3I: "Vector3i",
		TYPE_TRANSFORM2D: "Transform2D",
		TYPE_VECTOR4: "Vector4",
		TYPE_VECTOR4I: "Vector4i",
		TYPE_PLANE: "Plane",
		TYPE_QUATERNION: "Quaternion",
		TYPE_AABB: "AABB",
		TYPE_BASIS: "Basis",
		TYPE_TRANSFORM3D: "Transform3D",
		TYPE_PROJECTION: "Projection",
		TYPE_COLOR: "Color",
		TYPE_STRING_NAME: "StringName",
		TYPE_NODE_PATH: "NodePath",
		TYPE_RID: "RID",
		TYPE_OBJECT: "Object",
		TYPE_CALLABLE: "Callable",
		TYPE_SIGNAL: "Signal",
		TYPE_DICTIONARY: "Dictionary",
		TYPE_ARRAY: "Array",
		TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
		TYPE_PACKED_INT32_ARRAY: "PackedInt32Array",
		TYPE_PACKED_INT64_ARRAY: "PackedInt64Array",
		TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array",
		TYPE_PACKED_FLOAT64_ARRAY: "PackedFloat64Array",
		TYPE_PACKED_STRING_ARRAY: "PackedStringArray",
		TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
		TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array",
		TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
		TYPE_PACKED_VECTOR4_ARRAY: "PackedVector4Array",
		TYPE_MAX: "Max"
	}
	
	return typeMap.get(typeValue, "Unknown")

func _on_close_requested():
	hide()


func _on_list_right_item_selected(index: int) -> void:
	var meta = right.get_item_metadata(index)
	
	column4.clear()
	
	if meta != "cachedEntity":
		column4.visible = false
		return
	
	column4.visible = true
	var item = right.get_item_text(index)
	var midValue = mid.get_item_text(mid.get_selected_items()[0])
	var cachePathStr = midValue.split(" - ")[1]
	var cachedEntityName = right.get_item_text(index)
	cachePathStr = cachePathStr + "/" + cachedEntityName
	
	
	
	var cachedEntity = get_node(cachePathStr)
	var cachedEntityMeta = cachedEntity.get_meta_list()
	for metaKey in cachedEntityMeta:
		column4.add_item(metaKey)
		column4.set_item_metadata(column4.item_count-1,cachedEntity.get_meta(metaKey))
	


func _on_item_list_4_item_selected(index: int) -> void:
	print(column4.get_item_metadata(index))
