tool
extends LineEdit

signal update
signal updateRowHeight
signal focusEntered
signal focusExit
signal index_pressed

export var value = ""

var menu : PopupMenu
var inFocus = false
var preview = null
onready var optionButton : OptionButton = null
var dataFromTexDialog : ConfirmationDialog = null
var hoverColor : Color
var optionMode = false
#var previousText = ""
var sheet = null
var par

func _ready():
	if has_meta("index"):
		for i in get_children():
			if i.get_class() == "PopupMenu":
				menu=i
				i.connect("index_pressed",self,"index_pressed")
	
	

	connect("text_changed",self,"_on_typedLineEdit_text_changed")



func getOptionRectSize():
	return optionButton.rect_size

func activateOptionMode(enumValues,enumStr):
	
	if is_instance_valid(optionButton):
		optionButton.queue_free()
	
	var valueIndex = {}
	
	
	
	optionButton = OptionButton.new()
	optionButton.rect_min_size.x = rect_min_size.x
	optionButton.anchor_right = 1
	optionButton.anchor_bottom = 1
	optionButton.visible = true
	
	optionButton.connect("item_selected",self,"_on_OptionButton_item_selected")
	optionButton.connect("focus_entered",self,"_on_typedLineEdit_focus_entered")
	optionButton.connect("focus_exited",self,"_on_typedLineEdit_focus_exited")
	add_child(optionButton)

	
	
	var curStyle = get("custom_styles/normal")
	optionButton.set("custom_styles/normal",curStyle)
	optionButton.set("custom_styles/hover",curStyle)
	
	var fontColor = get("custom_colors/font_color")
	var cursorColor = get("custom_colors/cursor_color")

	
	
	
	optionButton.set("custom_colors/font_color",fontColor)
	optionButton.set("custom_colors/font_color_focus",fontColor)
	optionButton.set("custom_colors/cursor_color",cursorColor)
	optionButton.set("custom_colors/font_color_hover",hoverColor)
	
	var t = optionButton.get("custom_styles/normal")
	
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
				
#	for i in values.keys():
#
#		var optionButtonItemCount = optionButton.get_item_count()
#
#		if i == "@DUMMY":
#			valueIndex[i] = optionButtonItemCount
#			i = ""
#		else:
#			valueIndex[i] = optionButtonItemCount
#		optionButton.add_item(i)
		

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
		
		if existingText.is_valid_integer():
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
	var curStyle = get("custom_styles/normal")
	
	ret.set("custom_styles/normal",curStyle)
	return ret
	


func _on_typedLineEdit_text_changed(new_text : String) -> void:
#	print(new_text)
	
	#if new_text == previousText:
	#	text = new_text
	#	print("boop")
	#	return
	
	#previousText = new_text
	
	if is_instance_valid(preview):
		setChildrenVisible(false)
		preview.queue_free()
		
	new_text = new_text.strip_edges()
	
	var vari = str2var(new_text)
	
	if typeof(vari) == TYPE_INT:
		if(new_text.find(" ") != -1):
			vari = new_text
	value = vari
	
	#if new_text.find("deathSounds") != -1:
	#	breakpoint
	
	#if typeof(vari) != TYPE_COLOR:
	#	self_modulate = Color.white
	#elif typeof(vari) == TYPE_COLOR:
	#	self_modulate = value
	
	
	if typeof(vari) == TYPE_STRING:
		
		if new_text.length() > 1:
			if new_text[0] == "{":
				parseDict(new_text)
		
		if new_text.find("http") == 0:
			if new_text.count("png") or new_text.count("jpg") or new_text.count("bmp") or new_text.count("tga"):
				texturefromURL(new_text)
		
		elif new_text.is_abs_path():
			parsePath(new_text)
			
		value = new_text
#	if new_text.is_valid_integer():
#		value = new_text.to_int()
#	elif new_text.is_valid_float(): 
#		value = new_text.to_float()
#	elif new_text.is_valid_html_color():
#		value = Color(new_text)
#		self_modulate = value
#	elif new_text.to_lower() == "true":
#		value = true
#	elif new_text.to_lower() == "false":
#		value = false
#		#activateOptionMode(["true","false"])
#	elif new_text.is_abs_path():
#		parsePath(new_text)
#	elif new_text[0] == "[":
#		parseArrayPre(new_text)
#	else:
#		value = new_text
	
	
	
	emit_signal("update",self)

func gotImage(img):

	var spr = TextureRect.new()
	spr.texture = img
	spr.visible = true
	
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
	http.connect("gotImage",self,"gotImage")
	
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
	setChildrenVisible(false)
	
func loadImageFromPath(path):
	var img = Image.new()
	var tex = ImageTexture.new()
	
	var err = img.load(path)
	
	if err != 0:
		return null
	tex.create_from_image(img)
	
	var spr = TextureRect.new()
	spr.texture = tex
	spr.visible = true
	
	return spr
	
	
func loadAudioFromPath(path):
	var stream
	var file = File.new()
	var err = file.open(path, File.READ)
	
	if err != 0: 
		return null
	
	var data = file.get_buffer(file.get_len())
	var ext = path.get_extension().to_lower()
	
	file.close()
	
	if ext == "mp3": 
		stream = AudioStreamMP3.new()
		stream.data = data
	elif ext == "ogg": 
		stream.data = data
		stream = AudioStreamOGGVorbis.new()
	elif ext == "wav": 
		var script = load("res://addons/gSheet/scenes/typedLineEdit/wavLoad.gd").new()
		stream = script.getStreamFromWAV(path)
	else:
		return null
		
	var audioPlayer = load("res://addons/gSheet/scenes/typedLineEdit/scenes/audioPreview.tscn").instance()
	audioPlayer.setAudio(stream)
	audioPlayer.setText(path)
	

	return audioPlayer
	

func _on_typedLineEdit_focus_entered():
	inFocus = true
	
	updateMeta()
	emit_signal("focusEntered",self)


func _on_typedLineEdit_focus_exited():
	inFocus = false
	updateMeta()

	

	
	emit_signal("focusExit",self)
	

func setChildrenVisible(isVisible):
	
	if is_instance_valid(preview):
		if isVisible:
			preview.visible = true
			var t = preview.rect_size
			rect_size = preview.rect_size
			rect_min_size = preview.rect_size
		else:
			preview.visible = false
			rect_min_size = Vector2.ZERO
		
		emit_signal("updateRowHeight",get_meta("cellId"),rect_min_size)
	


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
	emit_signal("index_pressed",self,index,get_meta("index"))
	
 

func _on_OptionButton_item_selected(index):
	var txt = optionButton.get_item_text(index)
	var enumStrToValue = get_meta("enumStrToValue")
	
	print(txt)
	
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
