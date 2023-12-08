tool
extends WindowDialog


onready var left = $Tabs/treeMeta/hSplit/listLeft
onready var mid = $Tabs/treeMeta/hSplit/listMiddle
onready var right = $Tabs/treeMeta/hSplit/listRight


func _on_Tabs_tab_selected(tab):
	if tab == 0:
		left.clear()
		mid.clear()
		for key in get_tree().get_meta_list():
			left.add_item(key)
		
		
		var groups = get_tree().get_nodes_in_group("entityCache")
	
		if !groups.empty():
			left.add_item("entityCache groups")
	




func _on_listTop_item_selected(index):
	
	mid.clear()
	var x = get_tree().get_meta_list().size()
	
	if get_tree().get_meta_list().size()-1 < index:
		var leftIndex = left.get_selected_items()[0]
		var treeMetaKey = left.get_item_text(leftIndex)
		if treeMetaKey == "entityCache groups":
			var groups = get_tree().get_nodes_in_group("entityCache")
			for cacheNode in groups:
				mid.add_item(cacheNode.name)
				
				
		return
	
	var dataKey = get_tree().get_meta_list()[index]
	var data =  get_tree().get_meta(dataKey)
	
	
	mid.clear()
	
	
	populateMid(data)
	
	
	


func populateMid(data):
	
	right.clear()
	mid.clear()
	
	if typeof(data) == TYPE_DICTIONARY:
		for i in data.keys():
			mid.add_item(var2str(i).replace('"',""))
	
	if typeof(data) == TYPE_ARRAY:
		for i in data:
			if typeof(i) == TYPE_OBJECT:
				mid.add_item(i.name + " (Orphan Node)")
		
	
	
	


func _on_entityDebugDialog_about_to_show():
	_on_Tabs_tab_selected($Tabs.current_tab)




func _on_listMiddle_item_selected(index):
	var leftIndex = left.get_selected_items()[0]
	var treeMetaKey = left.get_item_text(leftIndex)
	var midValue = mid.get_item_text(index)
	
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
	
	
	if treeMetaKey == "entityCache groups":
		var groups = get_tree().get_nodes_in_group("entityCache")
		for i in groups:
			right.max_columns = 1
			if i.name == midValue:
				for c in i.get_children():
					right.add_item(c.name)
					
					
		return
	
	var data = get_tree().get_meta(treeMetaKey)[midValue]
	
	
	var isSingleLineData = false
	
	isSingleLineData = typeof(data) == TYPE_OBJECT or typeof(data) == TYPE_INT
	
	if typeof(data) == TYPE_DICTIONARY:
		right.max_columns = 2
		for i in data.keys():
			right.add_item(i)
			right.add_item(var2str(data[i]))
	
	if isSingleLineData:
		right.max_columns = 1
		right.add_item(var2str(data))
		
	
