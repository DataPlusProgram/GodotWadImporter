extends Control


@export_color_no_alpha var textColor = Color.GRAY
@export_color_no_alpha var regularColor = Color.BLACK
@export_color_no_alpha var hoverColor = Color.BLACK
@export_color_no_alpha var separatorColor = Color.GRAY
@export_color_no_alpha var borderColor = Color.GRAY
@export var borderThickness : int = 2
@export var useSeparators : bool = true
@export var selectionEnabled : bool = false
@onready var list = self.get_node("%list")

signal selectedSignal

var hoverStyleBox = null
var curItem = null
var regularStyleBox : StyleBoxFlat= null
var hSeperatorStyle : StyleBoxFlat = null
var isReady = false

var selectedItem : Node = null

func _ready():

	set("theme_override_styles/panel",getStyleBoxRegular())
	isReady = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func add_item(txt : String):
	var ext = txt.get_extension()
	
	if !ext.is_empty():
		txt = txt.split(".")[0]
	
	var rtl : RichTextLabel  =load("res://addons/gameAssetImporter/scenes/richList/scenes/highlightHoverRTL.tscn").instantiate()
	rtl.selection_enabled = selectionEnabled
	rtl.drag_and_drop_selection_enabled = selectionEnabled
	rtl.text = txt
	rtl.hoverColor = hoverColor
	rtl.textColor = textColor
	rtl.regularColor = regularColor
	rtl.selectedBorderThicknes = borderThickness
	rtl.borderColor = borderColor
	rtl.custom_minimum_size.y = 29
	rtl.fit_content = false
	list.add_child(rtl)
	
	rtl.focus_entered.connect(itemSelected.bind(rtl))
	rtl.selectedSignal.connect(itemSelected.bind(rtl))

	if useSeparators:
		list.add_child(createSeperator())
	
	setFocusNeighbours()
	
	return rtl

func setFocusNeighbours():
	var labels = []
	for i in list.get_children():
		if i is RichTextLabel:
			labels.append(i)
			
	for i in labels.size():
		labels[i].focus_neighbor_top = labels[i].get_path_to(labels[(i-1)%labels.size()])
		labels[i].focus_neighbor_bottom = labels[i].get_path_to(labels[(i+1)%labels.size()])
		

func getStyleBoxRegular():
	if regularStyleBox == null:
		regularStyleBox= StyleBoxFlat.new()
		regularStyleBox.bg_color = regularColor
	
	return regularStyleBox

func createSeperator():
	var h = HSeparator.new()
	
	if hSeperatorStyle == null:
		hSeperatorStyle= StyleBoxFlat.new()
		hSeperatorStyle.border_color = separatorColor
		hSeperatorStyle.border_width_top = 1
	
	h.set("theme_override_styles/separator",hSeperatorStyle)
	
	
	return h
func clear():
	for i in list.get_children():
		list.remove_child(i)
		i.queue_free()
	


func itemSelected(node):
	selectedItem = node
	selectedItem.grab_focus()
	selectedItem.grab_click_focus()

	emit_signal("selectedSignal",node)
	
func selectIdx(idx):
	
	if list.get_child_count() == 0:
		return
		
	selectedItem = list.get_child(idx)
	
	selectedItem.grab_focus()
	selectedItem.grab_click_focus()
	
	#if list.get_child(idx).has_method("_on_focus_entered"):
	#	list.get_child(idx) ._on_focus_entered()

func itemCount():
	return list.get_child_count()
