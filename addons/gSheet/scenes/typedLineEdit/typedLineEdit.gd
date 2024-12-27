@tool
extends LineEdit

signal update
signal updateRowHeight
signal focusEntered
signal focusExit
signal indexPressedSignal

@export var value = ""
const maxDisplayChar = 80
var menu : PopupMenu
var inFocus = false
var preview = null
@onready var optionButton : OptionButton = null
var dataFromTexDialog : ConfirmationDialog = null
var hoverColor : Color
var optionMode = false
var expressionMode = false
#var previousText = ""
var sheet = null
var arrayPopup = null
var par
var waitForFocus = 0

func _ready():
	
	text_changed.connect(_on_typedLineEdit_text_changed)

func getOptionRectSize():
	return optionButton.size

func activateOptionMode(enumValues,enumStr):
	
	if is_instance_valid(optionButton):
		optionButton.queue_free()
	
	var valueIndex = {}
	
	
	
	optionButton = OptionButton.new()
	#optionButton.rect_min_size.x = rect_min_size.x
	optionButton.custom_minimum_size.x = custom_minimum_size.x
	optionButton.anchor_right = 1
	optionButton.anchor_bottom = 1
	optionButton.visible = true
	
	#optionButton.connect("item_selected",self,"_on_OptionButton_item_selected")
	#optionButton.connect("focus_entered",self,"_on_typedLineEdit_focus_entered")
	#optionButton.connect("focus_exited",self,"_on_typedLineEdit_focus_exited")
	
	optionButton.item_selected.connect(_on_OptionButton_item_selected)
	optionButton.focus_entered.connect(_on_typedLineEdit_focus_entered)
	optionButton.focus_exited.connect(_on_typedLineEdit_focus_exited)

	
	add_child(optionButton)

	
	
	var curStyle = get("theme_override_styles/normal")
	optionButton.set("theme_override_styles/normal",curStyle)
	optionButton.set("theme_override_styles/hover",curStyle)
	
	var fontColor = get("theme_override_colors/font_color")
	var cursorColor = get("theme_override_colors/cursor_color")

	
	
	
	optionButton.set("theme_override_colors/font_color",fontColor)
	optionButton.set("theme_override_colors/font_focus_color",fontColor)
	optionButton.set("theme_override_colors/cursor_color",cursorColor)
	optionButton.set("theme_override_colors/font_hover_color",hoverColor)
	
	var t = optionButton.get("theme_override_styles/normal")
	
	set_meta("enumStrToValue",enumValues)
	#var test = values.keys() #values wont get placed in their correct order unless keys is sorted by mapped index instead of alphanumeric order
	
	var valueSorted = {}
	var keysSorted = enumValues.values()
	keysSorted.sort()
	
	#for i in values.values():
	#	valueSorted[]
	
	for i in keysSorted:
		for key in enumValues.keys():
			if enumValues[key] == i:
				var tuple = [key,i]
				
				if key != "@DUMMY":
					optionButton.add_item(key)
				else:
					optionButton.add_item("")
					
				#valueIndex[key] = i
				valueIndex[key] = optionButton.get_item_count()-1
				

	var existingText = enumStr
	var keys = enumValues.keys()
	text = ""
	
	if existingText.find(".") == -1:
		
		if valueIndex.has(existingText):
			optionButton.select(valueIndex[existingText])
			value = enumValues[existingText]
			
		else:
			optionButton.select(valueIndex["@DUMMY"])
			value = enumValues["@DUMMY"]
		
		if existingText.is_valid_int():
			optionButton.queue_free()
			_on_typedLineEdit_text_changed(existingText)
			
		return
	
	
	var post = existingText.split(".")[1]
	
	if keys.has(post):
		
		#var index = keys.find(post)
		var index = valueIndex[post]
		optionButton.select(index)
		text = post
		value = enumValues[post]
	#	print("set indexa to:",index)
		
	else:
		var index = valueIndex["@DUMMY"]
		optionButton.select(index)
		value = enumValues["@DUMMY"]
		
	#	print("set indexb to:",index)
		
	
	sheet.updateSizingsFlag = true
	#breakpoint

func deactivateOptionMode():
	if is_instance_valid(optionButton):
		optionButton.queue_free()

func createLineEdit():
	var ret = LineEdit.new()
	var curStyle = get("theme_override_styles/normal")
	
	ret.set("theme_override_styles/normal",curStyle)
	return ret
	
	
func inputGui(event):
	breakpoint
func _on_typedLineEdit_text_changed(new_text : String) -> void:

	if expressionMode:
		doExpression(new_text)
		return

	if new_text == &"--expression ":
		expressionMode = true
		set("theme_override_colors/font_color",Color.CHARTREUSE)
		text = ""
		return

	
	if is_instance_valid(preview):
		setChildrenVisible(false)
		preview.queue_free()
		
	new_text = new_text.strip_edges()
	
	var vari = str_to_var(new_text)
	

	if typeof(vari) == TYPE_INT:
		if(new_text.find(" ") != -1):
			vari = new_text
			
		if !new_text.is_valid_int():
			vari = new_text
	value = vari
	

	if typeof(vari) != TYPE_COLOR:
		self_modulate = Color.WHITE
	elif typeof(vari) == TYPE_COLOR:
		#var button = Button.new()
		#initHboxMode()
		#get_parent().add_child(button)
		#button.size_flags_horizontal = Control.SIZE_EXPAND
		#button.size_flags_vertical = Control.SIZE_EXPAND
		
		
		#button.anchor_bottom = 1
		self_modulate = value
	
	if value == null:
		value = new_text
		
	if typeof(value) == TYPE_STRING:
		
		if new_text.length() > 1:
			if new_text[0] == "{":
				parseDict(new_text)
		
		if new_text.find("http") == 0:
			if new_text.find(".png") or new_text.find(".jpg") or new_text.find(".bmp") or new_text.find(".tga") or new_text.find(".svg") or new_text.find(".webp"):
				texturefromURL(new_text)
		
		elif new_text.is_absolute_path():
			parsePath(new_text)
			
		value = new_text
		
		emit_signal("update",self)#without this changes won't take effect
		return
	
	
	#if typeof(value) == TYPE_STRING:
		#var exp = Expression.new()
		#var ret = exp.parse(value)
		#if ret == 0:
			#var err =exp.execute()
			#var t = exp.has_execute_failed()

			
	#text = new_text
	emit_signal("update",self)#without this changes won't take effect

func doExpression(expressionStr):
	var expression = Expression.new()
	var err = expression.parse(expressionStr)
	
	var ret = expression.execute()



func gotImage(img:ImageTexture):
	
	if img == null:
		return
	
	if img.get_image() == null:
		return

	var spr = TextureRect.new()
	spr.texture = img
	spr.visible = true
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.size = Vector2(150,60)
	
	add_child(spr)
	sheetGlobal.getChildOfClass(self,"HTTPRequest").queue_free()
	preview = spr
	updateMeta()

func updateMeta():
	if inFocus:
		if has_meta("text"):
			text = get_meta("text")
			set_meta("text",null)
		
		setChildrenVisible(false)
	else:
		if is_instance_valid(preview):
			set_meta("text",text)
			text = ""
		setChildrenVisible(true)
			
	
	if is_instance_valid(par):
		par.updateSizingsFlag = true

func texturefromURL(url):
	var http = HTTPRequest.new()
	

	http.set_script(load("res://addons/gSheet/scenes/typedLineEdit/HTTPRequest.gd"))
	http.gotImage.connect(gotImage)

	
	add_child(http)
	http.fetch(url)

func parsePath(path):
	path = path.replace("\\","/")
	
	if path.find("res://")!=-1:
		parseRes(path,"res://")
	elif path.find(":/")!=-1:
		parseRes(path,":/")
	
func parseRes(path,pre):
	var post = path.split(pre)[1]
	var extension = post.get_extension()
	var fileName = post.get_file()
	
	if is_instance_valid(preview):#if we already have a preview delete it
		setChildrenVisible(false)
		preview.queue_free()
	
	var tex = null
	
	
#	if extension == "gd":
#		text = fileName
#		tex = createLineEdit()

	if isInternalSupportedImage(extension):
		tex = loadImageFromPath(path)
		
	if isInternalSupportedAudio(extension):
		tex = loadAudioFromPath(path)
	

	if tex == null:
		return false
		
	
	preview = tex
	
	#if preview.has_method("setText"):
	#	preview.setText(text)
	#elif "text" in preview:
	#	preview.text = text
	
	
	
	add_child(tex)
	setChildrenVisible(true)
	
func loadImageFromPath(path):
	var img = Image.new()
	var tex = ImageTexture.new()
	
	var err = img.load(path)
	
	
	
	if err != 0:
		return null
	tex = tex.create_from_image(img)

	
	var spr : TextureRect= TextureRect.new()

	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.size = Vector2(150,60)
	spr.texture = tex
	spr.visible = true
	return spr
	
	
func loadAudioFromPath(path):
	var stream
	#var file = FileAccess #File.new()
	var file = FileAccess.open(path, FileAccess.READ)
	
	#if err != 0: 
	#	return null
	
	var data = file.get_buffer(file.get_length())
	var ext = path.get_extension().to_lower()
	
	file.close()
	
	if ext == "mp3": 
		stream = AudioStreamMP3.new()
		stream.data = data
	elif ext == "ogg": 
		stream.data = data
		stream = AudioStreamOggVorbis.new()
	elif ext == "wav": 
		var script = load("res://addons/gSheet/scenes/typedLineEdit/wavLoad.gd").new()
		stream = script.getStreamFromWAV(path)
	else:
		return null
		
	var audioPlayer = load("res://addons/gSheet/scenes/typedLineEdit/scenes/audioPreview.tscn").instantiate()
	audioPlayer.setAudio(stream)
	audioPlayer.setText(path)
	

	return audioPlayer
	

func _on_typedLineEdit_focus_entered():
	inFocus = true

	if typeof(value) == TYPE_STRING:
		text = value
	
	updateMeta()
	if typeof(value) == TYPE_ARRAY and arrayPopup == null:
		activateArrayMode(value)
	
	emit_signal("focusEntered",self)


func _on_typedLineEdit_focus_exited():
	inFocus = false
	updateMeta()

	if arrayPopup != null:
		
		var i = getViewport()
			
			
		if i != null:
			var focusOwner : Control = i.gui_get_focus_owner()
			if focusOwner == null:
				createFocusCheckTimer()
				
				
				
				
			elif !is_ancestor_of(focusOwner) and arrayPopup != focusOwner:
				arrayPopup.queue_free()
				arrayPopup = null
	
	
	#shortenText()
	emit_signal("focusExit",self)
	

func shortenText():
	if text.length() > maxDisplayChar:
		text = text.substr(0,maxDisplayChar-3) + "..."

func setChildrenVisible(isVisible):
	
	if is_instance_valid(preview):
		if isVisible:
			preview.visible = true
			var t = preview.size
			#rect_size = preview.rect_size
			#rect_min_size = preview.rect_size
			size = preview.size
			custom_minimum_size = preview.size
		else:
			preview.visible = false
			#rect_min_size = Vector2.ZERO
			custom_minimum_size = Vector2.ZERO
		
		emit_signal("updateRowHeight",get_meta("cellId"),custom_minimum_size)
	


func isInternalSupportedImage(ext):
	var fmts = ["png","dds","jpg","jpeg","bmp","svg","svgz","webp","tga","hdr"]
	for i in fmts:
		if ext == i: 
			return true
			
	return false
	
func isInternalSupportedAudio(ext):
	var fmts = ["wav","mp3","ogg"]
	
	for i in fmts:
		if ext == i: 
			return true
			
	return false

func index_pressed(index):
	
	emit_signal("indexPressedSignal",self,menu.get_item_text(index),get_meta("index"))
	
 

func _on_OptionButton_item_selected(index):
	var txt = optionButton.get_item_text(index)
	var enumStrToValue = get_meta("enumStrToValue")
	

	if txt == "":
		value = enumStrToValue["@DUMMY"]
		text = ""
		return
	#if enumStrToValue[txt] == index: 
	#	value = ""
		text = ""
		return
	
	value = enumStrToValue[txt]
	#text = ""
	text = txt
	par.serializeFlag = true


func setData(dict : Dictionary) -> void:
	var type : String = dict["type"]
	var data = dict["data"]
	
	if type == "str":
		text = data
		_on_typedLineEdit_text_changed(text)
		
	if dict["type"] == "enum":
		activateOptionMode(data,dict["enumStr"])
	return
	
func getData(dict):
	var type
	var data = dict["data"]
	
	
	
	if type == "str":
		text = data
		_on_typedLineEdit_text_changed(text)
		
		
	if dict["type"] == "enum":
		activateOptionMode(data,text)
	return


func parseDict(dstr):
	pass

func getViewport():
	var i = self
		
	while !(i is Viewport): 
		i = i.get_node_or_null("../")
		if i == null:
			return null
	
	if i == self:
		return null
	
	return i
func _on_child_entered_tree(node):
	if node.get_class() != &"PopupMenu":
		
		return
	
	
	if !node.has_meta("uiPopup"):
		var enumPopupIndex = node.get_item_count()
		node.add_item("set ENUM type")
		menu = node
		
		node.index_pressed.connect(index_pressed)
		return
		


func _on_text_submitted(new_text):
	if typeof(value) == TYPE_ARRAY:
		activateArrayMode(value)
	pass # Replace with function body.

func activateArrayMode(data : Array):
	
	
	arrayPopup = load("res://addons/gSheet/scenes/typedLineEdit/arrayDisplay.tscn").instantiate()
	arrayPopup.set_meta("uiPopup",true)
	arrayPopup.focus_exited.connect(arrayListElementLoseFocus)
	arrayPopup.position = Vector2(global_position.x,global_position.y+size.y+5)
	arrayPopup.size.x = 200
	arrayPopup.size.y = 200
	arrayPopup.setArrToList(data)
	add_child(arrayPopup)
	
	
	#gui_input.connect(inputGui)
	

func initHboxMode():
	if get_parent().get_class() == "HBoxContainer":
		return
	
	var myChildIndex = -1
	
	for i in get_parent().get_child_count():
		if get_parent().get_child(i) == self:
			myChildIndex = i
			break
	
	var hbox = HBoxContainer.new()
	
	hbox.custom_minimum_size.x = custom_minimum_size.x
	#button.anchor_right = 1
	
	get_parent().add_child(hbox)
	get_parent().move_child(hbox,myChildIndex)
	reparent(hbox)

func createFocusCheckTimer():
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.05
	timer.autostart = true
	timer.timeout.connect(focusCheck)
	add_child(timer)

func arrayListElementLoseFocus():
	createFocusCheckTimer()
	

func focusCheck():
	
	if arrayPopup == null:
		return
	
	if !is_instance_valid(arrayPopup):
		return
	
	
	var focusOwner = getViewport().gui_get_focus_owner()
	
	if !is_ancestor_of(focusOwner) and arrayPopup != focusOwner and focusOwner != self:
		arrayPopup.queue_free()
		arrayPopup = null
	
