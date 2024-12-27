@tool
extends HBoxContainer


var enumPopupIndex = -1

func _ready():
	
	$"../../../enumSelectorDialog".file_selected.connect(file_selected)
	$"enumPopup".selectedItem.connect(selectedItem)
	


func newChild(node):
	#if node.menu == null:
	#	return


	#var idx = node.get_meta("index")
	#enumPopupIndex = node.menu.get_item_count()
	#node.menu.add_item("set ENUM type")
	node.connect("indexPressedSignal", Callable(self, "index_pressed"))
	


func index_pressed(called,index,colIdx):
	if index == "set ENUM type":
		$"../../../enumSelectorDialog".set_meta("forCol",colIdx)
		$"../../../enumSelectorDialog".popup_centered()
	

func selectedItem(dict,colIdx,enumPrefix):
	var data = dict.values()[0]
	var t = $"../../../".mainSheet
	var col = t.cols[colIdx]
	col.set_meta("enum",dict)
	col.set_meta("enumPrefix",enumPrefix)
	for i in col.get_children():
		i.setData({"type":"enum","data":dict,"enumStr":i.text})
		
	t.serializeFlag = true
	
	
	
func file_selected(file):
	var coldId = $"../../../enumSelectorDialog".get_meta("forCol",null)
	$"../../../enumSelectorDialog".set_meta("forCol",null)
	
	if file.get_extension() != "gd":
		return
	
	var values = $enumParse.parse(file)
	
	values = addDummyEntryToEnumsDict(values)
	
	if values.is_empty():
		$AcceptDialog.popup_centered()
		return
		
	var itemList = $enumPopup/VBoxContainer/ItemList
	itemList.clear()
	
	for i in values.keys():
		itemList.add_item(i)
	
	
	
	$enumPopup.dict = values
	$enumPopup.forCol = coldId
	$enumPopup.dictNames = values.keys()
	$enumPopup.popup_centered_ratio()
	

func addDummyEntryToEnumsDict(dict):
	for keyStr in dict.keys():
		var i = 0
		while(true):
			if !dict[keyStr].values().has(i):
				break
			i += 1
		dict[keyStr]["@DUMMY"] = i
	
	return dict

