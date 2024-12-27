extends Node

@export_color_no_alpha var regularColor : Color = Color.GRAY
@export_color_no_alpha var textColor : Color = Color.GRAY
@export_color_no_alpha var hoverColor : Color = Color.BLACK

var isMouseOver = false
var hoverStyleBox :  StyleBoxFlat = null
var regularStyleBox :  StyleBoxFlat = null

@onready var initialStyle 

func _ready():
	
	#set("theme_override_colors/normal",textColor)
	#set("theme_override_styles/normal",getStyleBoxRegular())
	#initialStyle = get_parent().get_base_control()
	get_parent().mouse_entered.connect(mouseIn)
	get_parent().mouse_exited.connect(mouseOut)
	
	#focus_mode =Control.FOCUS_ALL


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func mouseIn():
	isMouseOver = true
	get_parent().set("theme_override_styles/normal",getStyleBoxHover())
	get_parent().set("theme_override_styles/focus",getStyleBoxHover())
	
	
func mouseOut():
	isMouseOver = false
	get_parent().set("theme_override_styles/normal",getStyleBoxRegular())
	get_parent().set("theme_override_styles/focus",getStyleBoxHover())
	
func getStyleBoxHover():
	
	if hoverStyleBox == null:
		hoverStyleBox= StyleBoxFlat.new()
		hoverStyleBox.bg_color = hoverColor
		#hoverStyleBox.content_margin_left = selectedBorderThicknes + 2
		#hoverStyleBox.content_margin_right = selectedBorderThicknes+ 2
		#hoverStyleBox.content_margin_top = selectedBorderThicknes+ 2
	#	hoverStyleBox.content_margin_bottom = selectedBorderThicknes+ 2
		
	
	return hoverStyleBox

func getStyleBoxRegular():
	
	if regularStyleBox == null:
		regularStyleBox= StyleBoxFlat.new()
		regularStyleBox.bg_color = regularColor
		
		#regularStyleBox.content_margin_left = selectedBorderThicknes+ 2
		#regularStyleBox.content_margin_right = selectedBorderThicknes+ 2
		#regularStyleBox.content_margin_top = selectedBorderThicknes+ 2
		#regularStyleBox.content_margin_bottom = selectedBorderThicknes+ 2
	
	return regularStyleBox
