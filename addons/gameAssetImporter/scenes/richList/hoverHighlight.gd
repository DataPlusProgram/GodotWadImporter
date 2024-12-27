extends RichTextLabel

@onready var modulateInitial = modulate

@export_color_no_alpha var regularColor : Color = Color.GRAY
@export_color_no_alpha var textColor : Color = Color.GRAY
@export_color_no_alpha var hoverColor : Color = Color.BLACK
@export_color_no_alpha var borderColor : Color = Color.GRAY
@export var selectedBorderThicknes = 1
@export var selectedBorderCorner = 1

signal selectedSignal

var isMouseOver = false
var hoverStyleBox :  StyleBoxFlat = null
var regularStyleBox :  StyleBoxFlat = null



func _ready():
	
	set("theme_override_colors/normal",textColor)
	set("theme_override_styles/normal",getStyleBoxRegular())
	set("theme_override_styles/focus",getStyleBoxHover())
	
	mouse_entered.connect(mouseIn)
	mouse_exited.connect(mouseOut)
	
	focus_mode =Control.FOCUS_ALL
	

func _input(event):
	if !isMouseOver:
		return
	
	if !event is InputEventMouseButton:
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
		grab_focus()
	
	

func mouseIn():
	isMouseOver = true
	set("theme_override_styles/normal",getStyleBoxHover())
	set("theme_override_styles/focus",getStyleBoxHover())
	
	
func mouseOut():
	isMouseOver = false
	set("theme_override_styles/normal",getStyleBoxRegular())
	set("theme_override_styles/focus",getStyleBoxHover())
	
	
func getStyleBoxHover():
	
	
	if hoverStyleBox == null:
		hoverStyleBox= StyleBoxFlat.new()
		hoverStyleBox.bg_color = hoverColor
		hoverStyleBox.content_margin_left = selectedBorderThicknes + 2
		hoverStyleBox.content_margin_right = selectedBorderThicknes+ 2
		hoverStyleBox.content_margin_top = selectedBorderThicknes+ 2
		hoverStyleBox.content_margin_bottom = selectedBorderThicknes+ 2
		
	
	return hoverStyleBox

func getStyleBoxRegular():
	
	if regularStyleBox == null:
		regularStyleBox= StyleBoxFlat.new()
		regularStyleBox.bg_color = regularColor
		
		regularStyleBox.content_margin_left = selectedBorderThicknes+ 2
		regularStyleBox.content_margin_right = selectedBorderThicknes+ 2
		regularStyleBox.content_margin_top = selectedBorderThicknes+ 2
		regularStyleBox.content_margin_bottom = selectedBorderThicknes+ 2
	
	return regularStyleBox

func select(value):
	breakpoint
	

func _on_focus_entered():
	var theme = get("theme_override_styles/focus")

	if theme != null:
	
		theme.border_color = borderColor
		
		
		theme.border_width_left = selectedBorderThicknes
		theme.border_width_right = selectedBorderThicknes
		theme.border_width_top = selectedBorderThicknes
		theme.border_width_bottom = selectedBorderThicknes
		
		theme.corner_radius_top_left = selectedBorderCorner
		theme.corner_radius_top_left = selectedBorderCorner
		theme.corner_radius_bottom_left = selectedBorderCorner
		theme.corner_radius_bottom_right = selectedBorderCorner
	
	emit_signal("selectedSignal")
