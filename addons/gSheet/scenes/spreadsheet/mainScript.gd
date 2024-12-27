@tool
extends Control
signal dictChangedSignal
signal fileLoadedSignal
@export var sheetStyle : Resource
@export var autoGrow = false

var customStyle = null
var customStyleSide= null
var saveFlag = false
var serializeFlag = true
var updateSizingsFlag = false

@export var initialColumns = 15
@export var initialRows = 20

@export var headingTitles : Array[String]= []

var numRows = 0
var numCols = 0
var data = {}
var cols = []
var rows = []
var cells = []
var cellW
var cellH
var nodePool = []
var root
var top = null
var side = null
var corner = null

var curRow = -1
var curCol = -1
var undoStack = []
var needsSaving = false


var initialTopX 
@onready var marginLeft = sheetStyle.marginLeft
@onready var marginRight = sheetStyle.marginRight
@onready var marginTop = sheetStyle.marginTop
@onready var marginBottom = sheetStyle.marginBottom
@onready var scrollContainer = $ScrollContainer

var colsTop = []
var rowsSide = []
var baseSplit : HSplitContainer = null

func _ready():
	
	root = get_node_or_null("../../../../")
	
	if root != null:
		await root.ready
		
		top = root.get_node("%upperBox")
		side =  root.get_node("%sideBox")
		corner =  root.get_node("%corner")
	
	

	get_viewport().size_changed.connect(viewportChanged)
	var windowRes = get_viewport().size

	instanceStylesFromRes()
	
	if customStyle != null:
		cellW = 48 + marginLeft + marginRight
		cellH = 14 + marginTop + marginBottom
	else:
		cellW = 58
		cellH = 24
	
	
	
	var neededColumns = ceil(windowRes.x / (cellW+marginLeft+marginRight))
	var neededRows = ceil(windowRes.y / (cellH+marginTop + marginBottom))
	
	if !autoGrow:
		neededColumns = initialColumns
		neededRows = initialRows
	
	
	for i in neededColumns:
		if i == 0:
			addColumn("",false,i)
		else:
			addColumn("",false,i)
	
	
	
	if side != null:
		var hSplit = get_node_or_null("../../side")
	
		if hSplit == null:
			return
	
	
		$"../../".set("theme_override_constants/separation",(marginLeft+marginRight)/2.0)
	
		var vBox = VBoxContainer.new()
		side = vBox
		side.set("theme_override_constants/separation",marginBottom+marginTop-1)
		
		hSplit.add_child(vBox)
	
		side.custom_minimum_size.x = marginLeft+marginRight+48 


	
	if top != null:
		

		initialTopX = top.get_parent().position.x
		top.set("theme_override_constants/separation",0)
		
		
		corner.set("theme_override_styles/read_only",customStyleSide)
		top.get_parent().custom_minimum_size = Vector2(cellW,cellH+15)
	
	
	for i in neededRows:
		addRow(false,i)
	

func _process(delta):
	
	
	if saveFlag:
		data = serializeData()
		emit_signal("dictChangedSignal",data)
		saveFlag = false
	
	
	if updateSizingsFlag:
		updateSizings(false)
		updateSizingsFlag = false
	
	if top == null:
		return 
	
	if serializeFlag:
		emit_signal("dictChangedSignal",serializeData())
		serializeFlag = false
	
	
	#top.position.x = -scrollContainer.scroll_horizontal+(1.5*(marginLeft+marginRight)+48) - 3 + side.get_parent().custom_minimum_size.x
	top.position.x = -scrollContainer.scroll_horizontal+(1.5*(marginLeft+marginRight)+48) - 62 + side.get_parent().custom_minimum_size.x
	side.position.y = -scrollContainer.scroll_vertical

	
	call_deferred("poolTick")


	
func addColumn(title : String,emitSignal : bool = true,idx : int = -1,addToUndoStack : bool= false) -> LineEdit:
	var hSplit = HSplitContainer.new()
	var vBox = VBoxContainer.new()
	var initial = false
	var ret = null
	if numCols == 0:
		initial = true
		
	
	hSplit.set_script(load("res://addons/gSheet/scenes/spreadsheet/hSplitSignal.gd"))
	
	#hSplit.set_meta("index",numCols)
	hSplit.set_meta("index",idx)
	#hSplit.connect("hDraw",self,"hDrawMain")
	hSplit.hDraw.connect(hDrawMain)
	hSplit.add_child(vBox)
	#hSplit.connect("hDrag",self,"hDragged")
	hSplit.hDrag.connect(hDragged)
	hSplit.name = "col " + str(numCols)
	hSplit.set("theme_override_constants/separation",marginLeft+marginRight-1)
	vBox.set("theme_override_constants/separation",marginBottom+marginTop-1)
	
	
	if sheetStyle.customGrabber != null:
		hSplit.set("theme_override_icons/grabber",sheetStyle.customGrabber)
	
	
	if idx == -1:
		idx = 0
	
	if top != null:
		if title == "":
			if idx == -1:
				addHeadingColumn(numCols,idx)
			else:
				addHeadingColumn(numCols,idx)
		else:
			if idx==-1:
				addHeadingColumn(title,idx)
			else:
				addHeadingColumn(title,idx)
		
	if initial:
		baseSplit = hSplit
		scrollContainer.add_child(hSplit)
		hSplit.show_behind_parent = true
		scrollContainer.move_child(hSplit,0)
		
		
	else:
		if idx ==-1:
			addToLatestHSplit(scrollContainer,hSplit)
		else:
			addToIdxHSplit(scrollContainer,hSplit,idx-1,0)
	
	
		
	if idx == -1:
		cols.append(vBox)
		cells.append([])#new column so new entry in cells
	else:
		cols.insert(idx,vBox)
		cells.insert(idx,[])#new column so new entry in cells
		

		
	for i in numRows:#for each row
		var cellNode : LineEdit= createRowCell(numCols,i)#create the row cell
		ret = cellNode
		
		if idx == numCols or idx == -1:
			cellNode.size_flags_horizontal = 0
		
		if idx == -1:
			cells[numCols].append(cellNode)#add to end of vbox
			
		else:
			cells[idx].append(cellNode)#add to idx +1 of vbox
		
		vBox.add_child(cellNode)#add vbox to node
	
	numCols += 1

	if (idx != -1 and idx-1 > 0) or (idx == -1 and numCols > 1):
		if idx != -1:
			for i in cols[idx-1].get_children():
				i.size_flags_horizontal = 1
		if idx == -1:
			for i in cols[numCols-2].get_children():
				i.size_flags_horizontal = 1
				
				
	if idx != -1:
		
		for x in range(idx-1,numCols):#for each column
			if colsTop.size() > 0:
				colsTop[x].get_child(0).set_meta("index",x)
			
			for yIdx in cols[x].get_children().size():
				var y = cols[x].get_children()[yIdx]
				y.set_meta("cellId",[x,yIdx])
	
	
	if addToUndoStack:
		undoStack.append({"action":"deleteCol","id":idx })
	
	updateSizingsFlag = true
	if emitSignal:
		serializeFlag = true
		#emit_signal("dictChanged",serializeData())
	
	return ret
		

func addToLatestHSplit(par,node):
	
	
	
	for i in par.get_children():
		if i.get_class() == "HSplitContainer":
			if i.get_child_count() == 1:#if we only have one child on hsplit
				i.add_child(node)
			else:
				addToLatestHSplit(i,node)
				
func addToIdxHSplit(par,node,idx,count):

	
		

	if idx == -1:
		#var hs = HSplitContainer.new()
		var scroll = baseSplit.get_parent()
		scroll.remove_child(baseSplit)
		var hs = node
		scroll.add_child(hs)
		scroll.move_child(hs,0)
		hs.add_child(baseSplit)
		
		
		
		baseSplit = hs
		
		#hs.add_child(node)
		return
		

	for i in par.get_children():
		if i.get_class() == "HSplitContainer":
			if i.get_child_count() == 1 or idx == count:#if we only have one child on hsplit
				
				if i.get_child_count() == 1:
					i.add_child(node)
				else:
					var oldCol = i.get_child(1)
					i.remove_child(oldCol)
					i.add_child(node)
					node.add_child(oldCol)
			else:
				addToIdxHSplit(i,node,idx,count+1)

func poolTick():
	if nodePool.size() < 10000:
		for i in 5:
			nodePool.append(createLineEdit("",true,true))


func ensureControlVisible(cell):
	scrollContainer.ensure_control_visible(cell)

func fetchLineEdit(content="",grow=false,editable=false) -> LineEdit:
	if !nodePool.is_empty():
		var node : LineEdit = nodePool.pop_front()
		node.text = str(content)
		return node
		
	return createLineEdit(content,grow,editable)

func createLineEdit(content=null,grow=false,editable=false) -> LineEdit:
	
	

	var edit : LineEdit = lineEditNew()
	edit.sheet = self
	
	#edit.align = edit.ALIGN_CENTER
	
	if !grow:
		edit.size_flags_horizontal = 0

	edit.expand_to_text_length = true
		
	if customStyle != null:
		edit.set("theme_override_styles/normal",customStyle)
		
		

	if content != null:
		edit.text = str(content)
		
	
	return edit
	
func createColRow(cur):
	
	var arr = []
	
	if cur.get_child_count() == 0:
		return arr
	
	for i in cur.get_children():
		if i.get_class() == "HSplitContainer":
			arr.append(i)
			
		if i.get_class() == null:
			pass
	pass

func _on_addCategory_pressed():
	addColumn("")
	

func _on_Button_pressed():
	addRow()

func areRowsNumericalProgression(start = 0, end = -1):
	
	if end == -1:
		end = rowsSide.size()
	
	for i in end:
		if rowsSide[i].text != str(i):
			return false
			
	return true



func areColsNumericalProgression(start = 0, end = -1):
	
	if end == -1:
		end = colsTop.size()
	
	for i in end:
		if colsTop[i].get_child(0).text != str(i):
			return false
		
	return true




var lineDuper : LineEdit = load("res://addons/gSheet/scenes/typedLineEdit/typedLineEdit.tscn").instantiate()

func lineEditNew() -> LineEdit:

	#var line : LineEdit = load("res://addons/gSheet/scenes/typedLineEdit/typedLineEdit.tscn").instance()
	var line : LineEdit = lineDuper.duplicate()
	
	#line.connect("update",self,"cellChanged")
	#line.connect("updateRowHeight",self,"updateRowHeight")
	#line.connect("focusEntered",self,"focusCell")
	#line.connect("focusExit",self,"exitFocusCell")
	#line.connect("focusExit",self,"exitFocusCell")
	
	#
	line.update.connect(cellChanged)
	line.updateRowHeight.connect(updateRowHeight)
	line.focusEntered.connect(focusCell)
	line.focusExit.connect(exitFocusCell)

	
	line.set("theme_override_colors/font_color",sheetStyle.fontColor)
	line.set("theme_override_colors/cursor_color",sheetStyle.cursorColor)
	line.hoverColor = sheetStyle.optionButtonHoverFontColor
	line.par = self
	return line

func addRow(emitSignal : bool = true,idx : int =-1,addToUndoStack : bool = false,colToGrab :int = 0) -> LineEdit:
	
	var ret : LineEdit  = null
	var sideCell : LineEdit
	
	if side != null:#this creates the side cellth
		sideCell = createSideCell(idx)
		side
		rowsSide.erase(sideCell)
		rowsSide.insert(max(idx,0),sideCell)
		sideCell.set_meta("index",max(idx,0))
		side.move_child(sideCell,max(idx,0))
		
		for i in side.get_child_count():
			side.get_child(i).set_meta("index",i)
	
	
	if addToUndoStack:
		if idx == -1:
			undoStack.append({"action":"deleteRow","id":0 })
		else:
			undoStack.append({"action":"deleteRow","id":idx})
	
		if sideCell != null:
				rowsSide.erase(sideCell)
				rowsSide.insert(max(idx,0),sideCell)
				sideCell.set_meta("index",max(idx,0))
	
	for c in cols.size():#for each column vbox
		var col : VBoxContainer = cols[c]
		var lineEdit : LineEdit = createRowCell(c,numRows)
		if c == colToGrab:
			ret = lineEdit
		
		if idx == -1:#we just add lineEdit to vbox
			
			col.add_child(lineEdit)
			cells[c].insert(0,lineEdit)
			col.move_child(lineEdit,0)
		else:
			col.add_child(lineEdit)
			smartText(lineEdit,cells[c],idx)
			col.move_child(lineEdit,idx)
			
			cells[c].insert(idx,lineEdit)

		
		if c == cols.size()-2:
			lineEdit.size_flags_horizontal = 1

		if c == cols.size()-1:
			lineEdit.size_flags_horizontal = 0
			
		if cols[c].has_meta("enum"):
			var enumval = cols[c].get_meta("enum")
			var enumPrefix = cols[c].get_meta("enumPrefix")
			
			var enumStr = enumPrefix+"@DUMMY"
			lineEdit.setData({"type":"enum","data":enumval,"enumStr":enumStr})
			
			
	
	
	
	#if idx != -1 and idx != 0:
	for cIdx in cols.size():
		var colo = cols[cIdx]
		for y in range(max(idx,0),numRows+1):
			colo.get_child(y).set_meta("cellId",[cIdx,y])
			

	
	numRows += 1
	
	if emitSignal:
		serializeFlag = true
		
		
	if addToUndoStack:
		pass
	
	var scrollY =  $ScrollContainer.scroll_vertical
	#updateScrollManual(get_viewport().gui_get_focus_owner())
	
	return ret
	
#func updateScrollManual(curSelected):
	#if curSelected != null:
		#var scroll : ScrollContainer = $ScrollContainer
		#var end = scroll.size.y + scroll.scroll_vertical
		#var cur = curSelected.position.y
			#
		#if cur +  curSelected.size.y > end:
			#scroll.scroll_vertical += (cur+(curSelected.size.y*2)) -end
			
		#if cur - curSelected.size.y < start:
		#	scroll.scroll_vertical += (cur-curSelected.size.y) -start
	
func createRowCell(colNum : int,rowNum : int) -> LineEdit:
	
	var lineEdit : LineEdit = fetchLineEdit("",true,true)
	lineEdit.set_meta("cellId",[colNum,rowNum])
	lineEdit.set_name("row " + str(numRows))
	
	return lineEdit
	

func hDragged(amt,caller):
	var totalSize = size
	var wos = getWidthOfCells()
	var diff =  amt - caller.lastAmount
	
	#baseSplit.rect_min_size.x = max(0,baseSplit.rect_size.x+diff)
	baseSplit.custom_minimum_size.x = max(0,baseSplit.size.x+diff)
	caller.lastAmount = amt
	
	
	for i in colsTop.size()-1:#for each heading cell
		var topSize = colsTop[i].size
		var cellSize = cols[i].get_child(0).size
			
		colsTop[i].custom_minimum_size = cols[i].get_child(0).size
		
	updateSizingsFlag = true
	serializeFlag = true
	

func getWidthOfCells():
	var running = 0
	for i in cols.size():
		running += cols[i].size.x
		
	return running
		

	
func hDrawMain(caller):
	if colsTop.is_empty():
		return
	
	
	var colIdx = caller.get_meta("index")
	
	if !colsTop.has(colIdx):
		return

	var col = colsTop[colIdx]
	col.custom_minimum_size.x = cols[colIdx].size.x 
	
func cellChanged(caller):
	saveFlag = true
	updateSizingsFlag = true
	
	serializeFlag = true
#	if !caller.has_meta("cellId"):
#		if rowsSide.has(caller):
#			var count = 0
#			for i in rowsSide:
#				count+=1
#				if i!= caller:
#					if i.text == caller.text:
#						caller.text += "_duplicate" + String(count)
	
	if !caller.has_meta("cellId"):
		return
	
	var id = caller.get_meta("cellId")
	
	
	if id == null:
		if get_node("../../").name == "side":
			topCellChanged(caller)
		return
	
	
	
	var col = id[0]
	var row = id[1]
	
	
	if col == cols.size()-1:
		updateLastColWidth()

	if !autoGrow:
		return
	
	
		
	if col == cols.size()-1:
		addColumn("")
		
	if row == cells[0].size()-1:
		for i in range(0,1):
			addRow()
			
	
	

func topCellChanged(cell):
	var col = cell.get_meta("index")
	
	var a = cell.size.x
	var b = cols[col].size.x
	
	cols[col].custom_minimum_size = cell.size


func focusCell(cell):
	
	if !cell.has_meta("cellId"):
		return
		
	var id = cell.get_meta("cellId")
	
	if id == null:
		return
		
	if id[1] > numRows-1: return 
	if id[0] > numCols-1: return 
	
	curCol = id[0]
	curRow = id[1]
	
	
	
	if rowsSide.is_empty():
		return
		
	rowsSide[curRow].modulate = Color.LIGHT_GRAY
	colsTop[curCol].modulate = Color.LIGHT_GRAY
	

		
func addHeadingColumn(text,idx=-1):
		var hSplit = HSplitContainer.new()
		var vBox = VBoxContainer.new()
		
		hSplit.name = "col " + str(colsTop.size())
		hSplit.name = "col " +  str(colsTop.size())
		
		var root 
		
		if colsTop.is_empty():
			root = top
		else:
			root = colsTop.back().get_parent()
		
		
		if idx != -1:
			if idx == 0:
				root = top
			else:
				root = colsTop[idx-1].get_parent()
		
		hSplit.set_script(load("res://addons/gSheet/scenes/spreadsheet/hSplitSignal.gd"))
		#hSplit.connect("hDrag",self,"hDragged")
		hSplit.hDrag.connect(hDragged)
		hSplit.set("theme_override_constants/separation",marginLeft+marginRight-1)
		
		var heading = fetchLineEdit(text,true,false)
		heading.value = text
		
		#heading.set("custom_styles/normal",customStyleSide)
		
		heading.set("theme_override_styles/normal",customStyleSide)
		
		heading.set_meta("index",text)
		
		vBox.add_child(heading) 
		
		if idx == -1:
			colsTop.append(vBox)
			
		hSplit.add_child(vBox)
		
		if idx !=-1:
			var oldChild = sheetGlobal.getChildOfClass(root,"HSplitContainer")
			colsTop.insert(idx,vBox)
			
			if oldChild != null:
				root.remove_child(oldChild)
				hSplit.add_child(oldChild)
			
			for i in range(idx+1,colsTop.size()):
				colsTop[i].get_child(0).set_meta("index",i+1)
			
		root.add_child(hSplit)
		top.newChild(heading)
		root = hSplit
		
		return hSplit
	

func createSideCell(txt : int,autoAdd : bool = true) -> LineEdit:
	var text = str(txt)

#	for i in rowsSide:
#		if i.text == text:
#			text += "_duplicate"
#			break
	
	var heading : LineEdit = fetchLineEdit(text,true,false)
	heading.value = text
	#heading.connect("focus_entered",self,"sideFocusCellFocus")
	heading.focus_entered.connect(sideFocusCellFocus)
	#heading.set("custom_styles/normal",customStyleSide)
	heading.set("theme_override_styles/normal",customStyleSide)
	heading.set_meta("index",txt)
	
	if autoAdd:
		side.add_child(heading) 
		rowsSide.append(heading)
	return heading

func exitFocusCell(cell):
	
	if !cell.has_meta("cellId"):
		return
	
	var id = cell.get_meta("cellId")
	
	if id == null:
		return
	
	var col = id[0]
	var row = id[1]
	
	
	if rowsSide.is_empty(): return
	if row < numRows:
		rowsSide[row].modulate = Color.WHITE
		
	if col < numCols:
		colsTop[col].modulate = Color.WHITE
		
	updateSizingsFlag = true

func updateRowHeight(id,size):
	var row = getRow(id[1])
	
	for i in row:
		i.custom_minimum_size.y = size.y
	

func updateSizingsSignal():
	updateSizingsFlag = true

func _on_Save_pressed():
	sheetGlobal.saveNodeAsScene(self)

func getRow(idx):
	var ret = []
	
	for i in cells:
		ret.append(i[idx])
	
	return ret


func splitChange():
	pass


func instanceStylesFromRes():
	customStyle = StyleBoxFlat.new()
	customStyle.bg_color = sheetStyle.cellColor
	customStyle.border_color = sheetStyle.cellBorderColor
	customStyle.border_width_top = sheetStyle.borderThickness
	customStyle.border_width_left = sheetStyle.borderThickness
	customStyle.border_width_right = sheetStyle.borderThickness
	customStyle.border_width_bottom = sheetStyle.borderThickness
	
	customStyle.expand_margin_left = sheetStyle.marginLeft
	customStyle.expand_margin_right = sheetStyle.marginRight 
	customStyle.expand_margin_top = sheetStyle.marginTop 
	customStyle.expand_margin_bottom = sheetStyle.marginBottom
	
	customStyle.content_margin_left = marginLeft
	customStyle.content_margin_right = marginRight 
	customStyle.content_margin_top = marginTop 
	customStyle.content_margin_bottom = marginBottom
	
	
	customStyleSide = StyleBoxFlat.new()
	
	customStyleSide.bg_color = sheetStyle.headingColor
	customStyleSide.border_color = sheetStyle.headingBorderColor
	customStyleSide.border_width_top = sheetStyle.borderThickness
	customStyleSide.border_width_left = sheetStyle.borderThickness
	customStyleSide.border_width_right = sheetStyle.borderThickness
	customStyleSide.border_width_bottom = sheetStyle.borderThickness
	
	customStyleSide.expand_margin_left = sheetStyle.marginLeft
	customStyleSide.expand_margin_right = sheetStyle.marginRight 
	customStyleSide.expand_margin_top = sheetStyle.marginTop 
	customStyleSide.expand_margin_bottom = sheetStyle.marginBottom
	
	customStyleSide.content_margin_left = sheetStyle.marginLeft
	customStyleSide.content_margin_right = sheetStyle.marginRight 
	customStyleSide.content_margin_top = sheetStyle.marginTop 
	customStyleSide.content_margin_bottom = sheetStyle.marginBottom


func viewportChanged():
	
	if !autoGrow:
		return
	var windowRes = get_viewport().size
	var neededColumns = ceil(windowRes.x / (cellW+marginLeft+marginRight))
	var neededRows = ceil(windowRes.y / (cellH+marginTop + marginBottom))
	
	
	for i in range(0,max(0,neededColumns-numCols+1)):
		addHeadingColumn(numCols+i)

	
	for i in range(0,max(0,neededColumns-numCols+1)):
		addColumn("")
		
		
	for i in range(0,max(0,neededRows-numRows+1)):
		addRow()
	
	updateSizingsFlag = true

func textToDataConfirm(caller,text):
	blankSheet()
	#if text[0] == "{": text.erase(0,1)
	text = filterComments(text)
	text = text.replace("\n","")
	text = text.replace("\t","")
	
	#var x = JSON.parse(text)
	
	var data = recu2(text)
	
		
	
	var cats = getCategories(data)
	var values = getValuesForCategories(cats,data)
	
	var nCols = values.size()
	var nRows = values[values.keys()[0]].size()
	
	setNumCols(nCols)
	setNumRows(nRows)
	
	for i in cats.size():
		colsTop[i].get_child(0).text = cats[i]

	for idx in data.keys().size():
		var stripped = data.keys()[idx]
		
		while stripped[0] == " ":
			stripped = stripped.substr(1,-1)
			
		rowsSide[idx].text = stripped
	
	for i in values.size():
		var key = values.keys()[i]
		var colDat = values[key]
		for j in colDat.size():
			cells[i][j].text = String(colDat[j])
			cells[i][j]._on_typedLineEdit_text_changed(String(colDat[j]))


	cells[0][0].grab_focus()
	updateSizingsFlag = true
	undoStack.clear()


func getCategories(data):
	var cats = []
	for entry in data.keys():
		var entryCats = data[entry].keys()
		for i in entryCats:  
			if !cats.has(i):
				cats.append(i)
	
	for idx in cats.size():
		
		if cats[idx][0] == "\"":
			cats[idx] = cats[idx].substr(1,-1)
			
		if cats[idx][cats[idx].length()-1] == "\"":
			cats[idx] = cats[idx].substr(0,cats[idx].length()-1)
	return cats
	
func getValuesForCategories(cats,data):
	var dict = {}
	var flag = false
	#dict["id"] = []
	for i in cats:
		dict[i] = []
	
	for entry in data.keys():
		
		var values = data[entry]
		#dict["id"].append(entry)
		for i in dict.keys():
			
			
			var values2 = {}
			for keyo in values.keys():
				var key = keyo.replace("\"","")
				key = key.replace("'","'")
				values2[key]=values[keyo]
		
			
			if i == "id":
				continue
			if values2.has(i):
				dict[i].append(values2[i])
			else:
				dict[i].append("")
	
	
	return dict
	



func recu2(text):
	var find = text.find("{")
	var pre = text.substr(0,find)
	var post = text.substr(find,-1)
	
	if post[0] != "{":
		return 
	
	return process2(post)




func process2(text):
	#{"type":LTYPE.FLOOR,"str":"stair"}
	if text[0] == "{":
		var i = 1
		var dict = {}
		while i < text.length():
			var dividerIdx = text.find(": ",i)
			if dividerIdx == -1:
				dividerIdx = text.find(":",i)
			
			var id = text.substr(i,dividerIdx-i)
			
			if dividerIdx == -1:
				return dict
				
			var remaining = text.substr(dividerIdx+1,-1)
			var value 
			#var idStr = id.replace("\"","")
			#idStr = idStr.replace("\"","")
			var idStr = id
			
			if remaining[0] == " ": 
				remaining = remaining.substr(1,-1)
			
			if remaining[0] == "{":
				value = getOuter(remaining,"{","}")
				
				
				i+=id.length() + value.length()+2
				var ret = value
				var idStrAgain = id.replace("\"","")
				
				dict[idStrAgain] = process2(value)
				continue
			
			if remaining[0] == "[":
				
				value = getOuter(remaining,"[","]")
				
				
				dict[idStr] = value
				i+=id.length() + value.length()+2
				continue
				
			if remaining[0] == "\"":
				value = getStringOuter(remaining)
				
				
					#value = value.substr(1,-1)
				#value = value.substr(1,value.length()-2)#remove first and last \"
				dict[idStr] = value
				i+=id.length() + value.length()+2
				continue
			
			else:
				value = getValue(remaining)
				
				i+=id.length() + value.length()+2
				dict[idStr] = value

				
			#return dict

		return dict
		
	
func getValue(text):
	var runningStr = ""
	
	
	
	for ii in text.length():
		var i = text[ii]
		
		if sheetGlobal.isInternal(runningStr):
		#if runningStr == "Vector2":
			var t  = getOuter(text.substr(ii,-1),"(",")")
			return runningStr + t
		
		if i == "}" or i == ",":
			return runningStr
		
		runningStr+= i
		
	return runningStr
	
	
func getTuples(text):

	var ret = []
	
	var sub = text.split(":","")
	
	var arr = []
	var content = strToArray(text)
	
	
	for i in content:
		var split = i.split(":")
		arr.append(split[0])
		arr.append(split[1])
	
#
	if arr.size() % 2 != 0:
		return []
#
	for i in arr.size()/2:

		var a = arr[(i*2)]
		var b = arr[(i*2)+1]

		a = a.replace('"',"")
		a = a.replace("'","")
		b = b.replace("}","")
		ret.append([a,b])

	return ret

func strToArray(txt):#copy input
	var runningArr = []
	var runningString = ""
	
	if txt.find("Player 2 start") != -1:
		breakpoint
	
	var i = 0
	while i < txt.length():
		var cur = txt[i]
		
		if cur == "\"":
			var t = getStringOuter(txt.substr(i,-1))
			runningString += t

			i += t.length()


			continue
			
		
		if cur == ",":
			runningArr.append(runningString)
			runningString = ""
		elif cur == "[":
			var outer = getOuter(txt.substr(i,-1),"[","]")
			runningArr.append(runningString  + outer)
			runningString = ""
			i+=outer.length()
		else:
			runningString += cur
			
		i+=1
		
	return runningArr
	pass
	

func getOuter(txt,open,close):
	var count = 0
	var runningTxt = ""
	
	for i in txt:
		if i == open:
			count += 1
			
			
		if i == close:
			count -=1
			
		
		runningTxt += i
		if count == 0:
			return runningTxt
			
	return null



func getStringOuterSimple(txt):
	var runningTxt = ""
	
	for i in txt.length():
		var chara = txt[i]
		
		if chara == "\"":
			return runningTxt
		else:
			runningTxt+=chara
		
	return runningTxt
		

func getStringOuter(txt):
	var count = 0
	var runningTxt = ""
	txt = txt.substr(0,txt.rfind("\"")+1)
	
	for i in txt.length():
		var chara = txt[i]
		if chara == "\"":#we have reached terminator
			if i+1 >= txt.length():
				runningTxt += chara
				return runningTxt
			
			var nextChar = txt[i+1]
			
			if nextChar != "," and nextChar != ":" and nextChar != "[":#if next char is not , keep string  going 
				runningTxt  += chara
			else:
				runningTxt  += chara#
				return runningTxt
				
		
		else:
			runningTxt += chara
	return runningTxt
		


func findCloserIndex(txt,opener,closer):
	var count = 1
	for i in txt.length():
		if txt[i] == closer:
			count -= 1
			
		
		elif txt[i] == opener:
			count += 1
			
			
		if count == 0:
			return i
			
	return -1

var a 
var b

var loadThread
func csvImport(path,headings=false,delimeter = ","): 
	blankSheet()
	a = Time.get_ticks_msec()
	var file = FileAccess.open(path,FileAccess.READ)
	var cats = []
	var data = []
	#file.
	
	var i = 0
	
	data = CSVparse(file,delimeter)
	
	
	var numRows : int = data.size()
	var numCols : int = data[0].size()
	
	if headings==true:
		numRows-=1
		cats = data.pop_front()
		
	a = Time.get_ticks_msec()
	resize(numRows,numCols)
	for idx in cats.size():
		colsTop[idx].get_child(0).setData({"type":"str","data":cats[idx]})
		
	for idx in numRows:
		rowsSide[idx].text = str(idx)
		#rowsSide[idx].data = str(idx)
	
	#loadThread = Thread.new()
	#loadThread.start(self,"threadAdd",[numRows,numCols,data])
	
	threadAdd([numRows,numCols,data])
	#print(b-a)
	undoStack.clear()
	cells[0][0].grab_focus()
	updateSizings()
	



func CSVparse(file,delimeter = ","):
	var data = []
	var headingCount = 0
	var input = getLineAlt(file)
	while input!=null:
		var line = input
		var runningString = ""
		var row = []
		
		
		if line == "":
			input = getLineAlt(file)
			continue

		var i = 0

		while i < line.length():
			var chara = line[i]
			
			if chara != delimeter:
				if chara == "\"":
					var outer = getStringOuterSimple(line.substr(i+1,-1))
					runningString += outer
					i += outer.length()+2
					
				else:
					runningString+=chara
					i+=1
			else:
				row.append(runningString)
				runningString = ""
				i+=1
		
		if runningString != "":
			row.append(runningString)
		
		if data.size() == 0:
			headingCount = row.size()
			
		if row.size() < headingCount:
			for j in headingCount - row.size():
				row.append("")
		
		data.append(row)
		
		input = getLineAlt(file)
		
			
			
	return data
	

func getLineAlt(file:FileAccess):
	var runningStr = ""
	
	while true:
		if file.eof_reached() and runningStr != "":
			return runningStr
		elif file.eof_reached():
			return null
		var c = char(file.get_8())
		
		if c == "\n":
			break
			breakpoint
			
		runningStr += c
	
	return runningStr
	

func _on_Control_draw():
	updateSizings()

func threadAdd(arr : Array) -> void:
	resize(arr[0],arr[1])
	
	var entries : Array = arr[2]

	for row in arr[0]:
		for col in arr[1]:
			cells[col][row].setData({"type":"str","data":entries[row][col]})


	b = Time.get_ticks_msec()
	

func updateSizings( delay = true):
	
	var biggestLast = 0
	for i in cols[numCols-1].get_children():
		#if i.rect_size.x > biggestLast:
		if i.size.x > biggestLast:
			biggestLast = i.size.x
		i.size_flags_horizontal = 0

#	for i in cols[numCols-1].get_children():
#		i.rect_size.x = biggestLast
#		i.rect_min_size.x = biggestLast

	for i in colsTop.size():
		#var topSize = colsTop[i].rect_size
		#var cellSize = cols[i].get_child(0).rect_size
		
		var topSize = colsTop[i].size
		var cellSize = cols[i].get_child(0).size
		
		#top.rect_size.x = getWidthOfCells()# * 2
	#	top.size.x = getWidthOfCells()
#
#
		for c in colsTop:
			c.get_child(0).expand_to_text_length = false
		
		colsTop[i].size = cols[i].get_child(0).size
		colsTop[i].custom_minimum_size = cols[i].get_child(0).size
		


	var widestSideCell =  62
	
	if root == null:
		return
		
	
	var defaultFont = rowsSide[0].get_theme_default_font()
	
	#if root.defualtFont != null:
	#	defaultFont = root.defualtFont

	
	
	#var editorTheme = EditorInterface.get_base_control().theme
	
	for rowIdx in rowsSide.size():
		
		var row = rowsSide[rowIdx]
		
		#rowsSide[rowIdx].size.y = cells[0][rowIdx].size.y
		row.custom_minimum_size.y = cells[0][rowIdx].size.y
		#row.custom_minimum_size.x = 
			
		#if row.size.x  > widestSideCell:
		#	widestSideCell =row.size.x
			
		if  defaultFont.get_string_size(row.text ).x > widestSideCell:
			widestSideCell =defaultFont.get_string_size(row.text).x

	corner.size.x = widestSideCell + 10
	
	for i in rowsSide:
		i.size.x = widestSideCell
	
	side.get_parent().custom_minimum_size.x = widestSideCell
	
	#if top != null:
	#	top.get_parent().position.x = initialTopX# + widestSideCell# - 62
		#top.get_parent().position.x = initialTopX + widestSideCell# - 50
		#position.x = initialTopX + widestSideCell# - 50
		#top.position.x = position.x
	
	#get_parent().position.x = widestSideCell+7
	
	
	
	updateLastColWidth()

	

func setNumRows(num : int,changeSingal : bool = true):
	var diff : int= num - numRows
	
	for i in diff:
		addRow(changeSingal)
	
	if diff >=0:
		return
		
	for i in abs(diff):#negative diff so we reomve rows
		pass


func setNumCols( num : int, changeSignal : bool = true) -> void:
	var diff : int = num - numCols
	
	for i in diff:
		addColumn("",changeSignal)


func save():
	var data = serializeData()
	var file : FileAccess
	var json = JSON
	file.open("res://test.gsheet",FileAccess.WRITE)
	
	file.store_line(json.stringify(data))

func loadFromFile(path:String) -> void:
	
	var filePathLabel = $"../../../pathLabel"
	
	filePathLabel.text = path
	
	var data = ResourceLoader.load(path).data
	#var numR = data.size()-1
	#var numC = -1#data[0].size()
	
	#for k in data.keys():
	#	if k != "meta":
	#		numC = data[k].size()
	#		break
	
	
	dataIntoSpreadsheet(data)
	emit_signal("fileLoadedSignal",path)

func getDim():
	return Vector2(numRows,numCols)

func serializeData():
	var dict = {"meta":{"hasId":false,"rowOrder":[],"enumColumns":{},"enumColumnsPrefix":{}}}
	
	
	if colsTop.size() == 0:
		return
	
	var heading1 = colsTop[0].get_child(0).text.to_lower()
	
	if heading1 == "id":
		dict["meta"]["hasId"] = true
	for i in numRows:
		dict["meta"]["rowOrder"].append(rowsSide[i].text)
	
	if rowsSide.size() != numRows:
		print_debug("row side != numRows")
		breakpoint
	
	var colNames = []
	for x in numCols:
		colNames.append(colsTop[x].get_child(0).text)
	
	dict["meta"]["colNames"] = colNames
	dict["meta"]["splitSize"] = {} 
	#dict["meta"]["sheetWidth"] = baseSplit.rect_size.x
	dict["meta"]["sheetWidth"] = baseSplit.size.x
	
	for idx in cols.size():
		var col = cols[idx]
		if col.has_meta("enum"):#if column is enum
			var enums = col.get_meta("enum")
			var enumPrefix = col.get_meta("enumPrefix")
			dict["meta"]["enumColumns"][idx] = enums
			dict["meta"]["enumColumnsPrefix"][idx] = enumPrefix
		
		
		dict["meta"]["splitSize"][idx] = col.get_parent().split_offset
		
	for y in numRows:
		var rowDict = {}
		for x in numCols:
			var cell =cells[x][y]
			
			var columnName = colsTop[x].get_child(0).text
			var theValue = cell.value
			rowDict[columnName] = cell.value

		dict[rowsSide[y].text] = rowDict#if there a duplicate row keys a problem will occur here
			
	
	if dict["meta"]["rowOrder"].size() != rowsSide.size():
		breakpoint
	
	needsSaving = true
	return dict



func dataIntoSpreadsheet(arr : Dictionary) -> void:
	
	blankSheet()
	needsSaving = false
	
	var meta : Dictionary = arr["meta"]
	var cat : Array = meta["colNames"]#arr.pop_front()# getCategories(dict)
	
	
	var numCat : int = cat.size()
	#var numRow : int= max(5,arr.size()-1)#don't this, this will corrupt
	var numRow : int= arr.size()-1#exclude meta
#
	
	resize(numRow,numCat)

	var rowOrder : Array = meta["rowOrder"]
	var enumCols : Dictionary = meta["enumColumns"]
	var enumColsPrefix : Dictionary = meta["enumColumnsPrefix"]
	
	setNumCols(numCat,false)
	setNumRows(numRow,false)
	
	
	var a =  rowsSide.size()
	var b = rowOrder.size()
	
	
	
	var runningSplit = 0
	
	
	for key in enumCols.keys():
		cols[key].set_meta("enum",enumCols[key])
		cols[key].set_meta("enumPrefix",enumColsPrefix[key])
		#breakpoint
	
	for i in cat.size():
		colsTop[i].get_child(0).text = String(cat[i])
		colsTop[i].get_child(0).value = String(cat[i])
	
	
	var areSideRowsNumeric = true
	var pSide = null
	for i in min(rowOrder.size(),rowsSide.size()):#settting side rows
		rowsSide[i].text = rowOrder[i]
		rowsSide[i].value = rowOrder[i]
		rowsSide[i].set("theme_override_colors/font_color",sheetStyle.fontColor)
		if pSide == null:
			pSide = rowOrder[i]
			
		if !rowOrder[i].is_valid_int():
			areSideRowsNumeric = false
			
			
	
	if areSideRowsNumeric:
		rowOrderBreakHighlight(rowsSide)
	#if rowOrder.size() < rowsSide.size():
		#print_debug("row order missing")
		#breakpoint
		#rowOrderAttemptFix(rowOrder,rowsSide)
	
	
	for x in cat.size():#for each category(column)
		#for y in rowOrder.size(): sometimes rowOrder becomes bigger than rowsside 
		for y in rowsSide.size():
			var cell : LineEdit = cells[x][y]
			var t1 = cat[x]
			var t2 = rowOrder[y]
			var vari = arr[t2][t1]
			
			if typeof(vari) != TYPE_STRING:
				#vari = str(vari)
				vari =var_to_str(vari)
				
			var oldText = arr[t2][t1]
			var newText
			
			if typeof(vari) == TYPE_STRING:
				newText = vari
				if vari.length() > 0:
					if vari[0] == "\"" and vari[vari.length()-1] == "\"": 
						newText = vari.substr(1,vari.length()-2)
			else:
				newText = str(oldText)
			
			
			
			
			var wasEnum = false
			
			var textAsEnum = "@DUMMY"
			
			
			
			if enumCols.has(x):#if an enum col
				if newText != "":
					for key in enumCols[x].keys():#for each key of enum
						if enumCols[x][key] == oldText:#if enum for column x of geven key is equal to text
							textAsEnum = enumColsPrefix[x] + "." + key
							break
				
				cell.setData({"type":"enum","data":enumCols[x],"enumStr":textAsEnum})
				wasEnum = true
				
		
			if !wasEnum:
				cell.setData({"type":"str","data":newText})
				
			baseSplit.queue_redraw()
			
			if y == 0:
				if meta["splitSize"].has(x):
					cols[x].get_parent().set_split_offset( meta["splitSize"][x])
					baseSplit.custom_minimum_size.x += baseSplit.size.x+meta["splitSize"][x]
					cols[x].get_parent().queue_redraw()
				else:
					cols[x].get_parent().set_split_offset(0)#temp
					cols[x].get_parent().custom_minimum_size.x = 0
					cols[x].get_parent().queue_redraw()

	
	if meta.has("sheetWidth"):
		baseSplit.custom_minimum_size.x = meta["sheetWidth"]

	undoStack.clear()
	updateSizingsFlag=true
	serializeFlag = true
	
	

func cellsDebug():
	for i in cells.size():
		for j in cells[i].size():
			#cells[i][j].text = String(i) + "," + String(j)
			cells[i][j].text = String(cells[i][j].get_meta("cellId"))
	
	
	#for i in side.get_child_count():
	#	side.get_child(i).text = String(i)
	#	side.get_child(i).text =  side.get_child(
	
	for idx in colsTop.size():
		var cell = colsTop[idx].get_child(0)
		cell.text = str(colsTop[idx].get_child(0).get_meta("index"))#String(idx)
		#if colsTop[idx].get_child(0).has_meta("enum"):
		#	cell.text = var2str(colsTop[idx].get_child(0).get_meta("enum"))
		
	for idx in rowsSide.size():
		var cell = rowsSide[idx]
		cell.text = str(idx) + "j"
 
func deleteCurRow():
	if curRow != -1:
		cells[curCol][curRow].release_focus()
		deleteRow(curRow,true,true)


func deleteCurCol():
	if curCol != -1:
		deleteCol(curCol)


func deleteCol(cIdx,dictChange = true,addToRedoStack = true):
	if numCols <=1:
		return
	
	
	cols[cIdx].queue_free()
	
	var hsplit = cols[cIdx].get_parent()
	var childHsplit
	var parentHsplit =hsplit.get_parent()
	var actionDict = {"action":"addColumn","index":cIdx,"data":[],"name":"","colTitles":[]}
	
	for i in colsTop:
		actionDict["colTitles"].append(i.get_child(0).text)
	
	#var infoArr = []
	
	actionDict["name"] = colsTop[cIdx].get_child(0).text
	#infoArr.append(infoDict)
	
	
	for c in sheetGlobal.getChildOfClass(hsplit,"VBoxContainer").get_children():
		actionDict["data"].append(c.text)
	
	popHsplit(hsplit)
	popHsplit(colsTop[cIdx].get_parent())
	
	
	
	cols.remove_at(cIdx)
	colsTop.remove_at(cIdx)
	
	if addToRedoStack:
		undoStack.append(actionDict)
	
	
	for i in cells[cIdx]:
		i.queue_free()
	cells.remove_at(cIdx)

	
	
	for i in range(cIdx,numCols-1):
		var col = cols[i]
		
		colsTop[i].get_child(0).set_meta("index",i)
		
		if i != numCols-2:
			var next = colsTop[i+1].get_child(0).text
			if typeof(str_to_var(next)) == TYPE_INT:
				colsTop[i].get_child(0).text = str(i)
		else:
			if typeof(str_to_var(colsTop[i].get_child(0).text)) == TYPE_INT:
				colsTop[i].get_child(0).text = str(i)
		
		for c in col.get_children():#for each row in column
			var oldIdx = c.get_meta("cellId")
			c.set_meta("cellId",[oldIdx[0]-1,oldIdx[1]])
		
		

	
	numCols -=1
	
	
	if numCols == 0:
		return
	
	if curCol == numCols:
		curCol -= 1
		
	curCol=curCol%numCols
	cells[curCol%numCols][curRow].grab_focus()
	
	if dictChange:
		serializeFlag = true
		#emit_signal("dictChanged",serializeData())
	

func deleteRow(rIdx,dictChange,storeUndo):
	if numRows <= 1:
		return
	
	if rIdx == curRow:
		curRow = max(0,curRow-1)
	elif curRow >= rIdx:
		curRow = max(0,curRow-1)
	
	var actionDict = {"action":"addRow","index":rIdx,"data":[],"name":"","rowTitle":""}
	
	for cIdx in cols.size():
		var c = cols[cIdx]
		actionDict["data"].append(c.get_child(rIdx).text)
	
	if storeUndo:
		undoStack.append(actionDict)
	
	for cIdx in cols.size():
		var column :VBoxContainer = cols[cIdx]
		column.get_child(rIdx).queue_free()
		cells[cIdx][rIdx].queue_free()
		cells[cIdx].remove_at(rIdx)
		
		for i in range(rIdx+1,numRows):
			var oldIdx = column.get_child(i).get_meta("cellId")
			var stro = str(i-1)
			actionDict["rowTitle"] = rowsSide[i].text
			column.get_child(i).set_meta("cellId",[oldIdx[0],oldIdx[1]-1])
	
	
	numRows -= 1
	rowsSide[rIdx].queue_free()
	rowsSide[rIdx].get_parent().remove_child(rowsSide[rIdx])

	rowsSide.remove_at(rIdx)

	cols[0]
	if numRows == 0:
		return
	
	
	if dictChange:
		serializeFlag = true
	
	cells[curCol][curRow%numRows].grab_focus()
	

func popHsplit(hsplit):
	
	
	var childHsplit
	var parentHsplit =hsplit.get_parent()
	
	for i in hsplit.get_children():
		if i.get_class() == "HSplitContainer":
			childHsplit = i
			
	
	if childHsplit != null:
		hsplit.remove_child(childHsplit)
		parentHsplit.add_child(childHsplit)
	
	
	if hsplit == baseSplit:
		baseSplit = childHsplit
	
	hsplit.queue_free()
	
	
	
	
func resize(r : int,c : int) -> void:
	if numCols > c:
		var dif = numCols - c
		
		for i in dif:
			deleteCol(numCols-1,false)
	else:
		setNumCols(c,false)
	
	if numRows > r:
		var dif = numRows - r
		
		for i in dif:
			deleteRow(numRows-1,false,false)
	else:
		setNumRows(r,false)
		


func undo():
	
	if undoStack.is_empty():
		return
		
	var actionDict = undoStack.pop_back()
	var actionName = actionDict["action"]
	
	if actionName == "addColumn":
		actionAddColumn(actionDict["name"],actionDict["index"],actionDict["data"],actionDict["colTitles"])
	if actionName == "addRow":
		actionAddRow(actionDict["index"],actionDict["data"],actionDict["rowTitle"])
	if actionName == "moveColumnLeft":
		moveColRight(actionDict["from"],false)
	if actionName == "moveColumnRight":
		moveColLeft(actionDict["from"],false)
	if actionName == "deleteRow":
		deleteRow(actionDict["id"],true,false)
	if actionName == "deleteCol":
		deleteCol(actionDict["id"],true,false)
	
func actionAddColumn(colName,colIdx,oldData,colTitles):
	if oldData.is_empty():
		breakpoint
		
	insertColumn(colName,colIdx)
	for i in colTitles.size():
		colsTop[i].get_child(0).text = colTitles[i]
		
	for cIdx in oldData.size():
		cols[colIdx].get_child(cIdx).setData({"type":"str","data":oldData[cIdx]})

	

	
func insertColumn(title,id,addToUndoStack=false):
	addColumn(title,false,id,addToUndoStack)

func actionAddRow(index,data,rowTitle):
	addRow(false,index)
	
	for cIdx in cols.size():
		var c = cols[cIdx]
		c.get_child(index).text = data[cIdx]

	
func filterComments(txt) -> String:
	if txt.find("#") == -1:
		return txt
		
		
	var runningStr : String = ""
	var lines : String  = txt.split("\n")
	
	for line in lines:
		runningStr += line.substr(0,line.find("#"))
		
	return runningStr

func moveCurColRight():
	if curCol == numCols:
		return
	
	moveColRight(curCol)
	
	
	
func moveColRight(idx,addToUndo = true):
	if idx < 0:
		return
	
	if idx >= numCols-1:
		return

	
	
	var tmpTxt = []
	
	
	if numCols == 1:
		return
	
	
	
	var colNameA = colsTop[idx].get_child(0).text
	var colNameB = colsTop[idx+1].get_child(0).text
	var colsTitles = []

	for i in colsTop:
		colsTitles.append(i.get_child(0).text)

	for i in cols[idx+1].get_children():#temporaily store lables of col to be deleted
		tmpTxt.append(i.text)


	colsTitles[idx] = colNameB #swap titles
	colsTitles[idx+1] = colNameA #swap titles

	deleteCol(idx+1,false,false)# delete right column

	actionAddColumn(colNameA,idx,tmpTxt,colsTitles)#add it back again 
	if addToUndo:
		undoStack.append({"action":"moveColumnLeft","from":curCol})
	serializeFlag = true


func moveColLeft(idx,addToUndo=true):
	if idx <= 0:
		return
	
	
	var tmpTxt = []
	
	
	if numCols == 1:
		return
	
	
	
	var colNameA = colsTop[idx-1].get_child(0).text
	var colNameB = colsTop[idx].get_child(0).text
	var colsTitles = []

	for i in colsTop:
		colsTitles.append(i.get_child(0).text)

	for i in cols[idx].get_children():#temporaily store lables of col to be deleted
		tmpTxt.append(i.text)


	colsTitles[idx-1] = colNameB #swap titles
	colsTitles[idx] = colNameA #swap titles

	deleteCol(idx,false,false)# delete right column

	actionAddColumn(colNameA,idx-1,tmpTxt,colsTitles)#add it back again 
	
	if addToUndo:
		undoStack.append({"action":"moveColumnRight","from":curCol})
	serializeFlag = true

func blankSheet():
	
	
	serializeFlag = false
	
	for colIdx in cols.size():
		for m in cols[colIdx].get_meta_list():
			cols[colIdx].set_meta(m,null)
		
		for cell in cells[colIdx]:
			cell.text = ""
			cell.deactivateOptionMode()
			cell.size.y = 0#24
			cell.custom_minimum_size.y = 0
			
			
		cols[colIdx].get_parent().custom_minimum_size.x = 0
		cols[colIdx].get_parent().split_offset = 0 
		
		cols[colIdx].custom_minimum_size.x = 0
		colsTop[colIdx].custom_minimum_size.x = 0
		
		colsTop[colIdx].get_parent().split_offset = 0
		colsTop[colIdx].get_parent().custom_minimum_size.x = 0
	
	
	for i in rowsSide.size():
		rowsSide[i].text = str(i)
	
	for i in colsTop.size():
		colsTop[i].get_child(0).text = str(i)
	
	for y in numRows:
		for x in numCols:
			var cell =cells[x][y]
			cell.text = ""
			cell.value = ""
	
	undoStack.clear()
		
		
func getWidestColumn(cIdx) -> int:
	var widest = -INF
	
	var lastCol = cols[cIdx].get_children()
	#for i in lastCol:
		#if i.rect_size.x > widest:
			#widest = i.rect_size.x
	
	for i in lastCol:
		if i.size.x > widest:
			widest = i.size.x
	
	return widest

func setColumnWidth(cIdx,width):
	var lastCol = cols[cIdx].get_children()
	#for i in lastCol:
		#i.rect_min_size.x = width
		
	for i in lastCol:
		i.custom_minimum_size.x = width
	
func updateLastColWidth():
	var w = getWidestColumn(cols.size()-1)
	setColumnWidth(cols.size()-1,w)

func getArrayOfMatches(text : StringName,caseSensitive : bool):
	
	if text.is_empty():
		return []
	
	var matches = []
	
	if !caseSensitive:
		text = text.to_lower()
	
	
	for x in cells:
		for y in x:
			var txt = y.text
			
			if !caseSensitive:
				txt = txt.to_lower()
			
			if txt.find(text) != -1:
				matches.append(y)
				
	
	return matches
			
func sideFocusCellFocus():
	#var owner = get_focus_owner()
	var owner = get_viewport().gui_get_focus_owner()
	if !owner.has_meta("index"):
		return
	
	curCol = 0
	curRow = owner.get_meta("index")
	
func getColData(colIdx):
	
	var ret : Array = []
	
	for i in cols[colIdx].get_children():
		ret.append(i.value)
	
	return ret

func textChanged():
	breakpoint

func setSideLabelsToNumericProgression():
	for i in rowsSide.size():
		rowsSide[i].text = str(i)
		rowsSide[i].value = str(i)

func setColLabelsToNumericProgression():
	for i in colsTop.size():
		colsTop[i].get_child(0).text = str(i)
		colsTop[i].get_child(0).value = str(i)

func smartText(node : Node,column : Array,idx : int):
	if column.is_empty():
		return
	
	var searchDepth = 5
	var colLen : int = column.size()
	var start : int = max(0,idx - searchDepth) 
	
	if colLen - start < searchDepth:
		return
	
	var end = max(0,idx)
	var isMatch = true
	var isProgression = true
	var matchStr = column[start].text
	
	if matchStr.is_empty():
		return
	
	if start+1 == end:
		return
	
	
	
	for i in range(start+1,end):
		
		if !isMatch and !isProgression:
			return
		
		var test = column[i].text
		
		if column[i].text != matchStr:
			isMatch = false
			
		
		if !isProgression:
			continue
		
		var pValue = column[max(0,i-1)].value
		var value = column[i].value
		
		if typeof(value) != TYPE_INT or typeof(pValue) != TYPE_INT:
			isProgression = false
			continue
		
		if value != pValue + 1:
			isProgression = false
			continue
				
		
		
	
	if isProgression:
		var a = column[max(0,idx-1)].value
		var t = column[max(0,idx-1)].value+1
		node.text = str(column[max(0,idx-1)].value+1)
		node._on_typedLineEdit_text_changed(node.text)
		return
	
	if isMatch:
		node.text = matchStr
		node._on_typedLineEdit_text_changed(matchStr)
	
	
	
	
func rowOrderAttemptFix(rowOrder,rowsSide):
	var a = rowOrder.size()
	var b = rowsSide.size()-rowOrder.size()
	for i in range(b):
		rowOrder.append(str(a+i))
		
func rowOrderBreakHighlight(rows):
	
	if rows.size() <4:
		return
	
	var inc1 = 0
	var notInc1 = 0
	var pRow = null
	var notIncs = []
	
	for i in rows.size()-1:
		if pRow == null:
			pRow = int(rows[i].text)
			continue
		
		if pRow != int(rows[i].text)-1:#if previous row is not 1 less than next row
			notInc1 +=1
			notIncs.append(rows[i])
		else:
			inc1 += 1
			
		pRow = int(rows[i].text)
	
	if notInc1/max(1,inc1) > 0.5:
		return
	
	for i : LineEdit in notIncs:
		i.set("theme_override_colors/font_color",sheetStyle.fontColor * 0.5)
		

func forceKeysToInt():
	for i in rowsSide:
		var t = i.text
		var value = str_to_var(i.text)
		i.value = value
	
