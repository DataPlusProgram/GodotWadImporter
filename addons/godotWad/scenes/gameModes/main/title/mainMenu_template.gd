extends Control
var cur = null
onready var list = $v


signal newGame
signal quitGame

var pFocus = null
var optionsPath = preload("res://addons/godotWad/scenes/gameModes/main/options/options_template.tscn")
var options = null

func _ready():
	for i in list.get_child_count():
		var nextIdx = (i+1)%list.get_child_count()
		var prevIdx = (i-1)
		
		if prevIdx == -1:
			prevIdx = list.get_child_count()-1
		
		list.get_child(i).focus_neighbour_bottom = list.get_child(i).get_path_to(list.get_child(nextIdx))
		list.get_child(i).focus_neighbour_top = list.get_child(i).get_path_to(list.get_child(prevIdx))
		
	for i in list.get_children():
		i.connect("mouse_entered",self,"mouseIn",[i])
	
	options = optionsPath.instance()
	add_child(options)
	options.visible = false

func _on_newGame_pressed():
	$select.play()
	emit_signal("newGame")
	


func _on_quit_pressed():
	$move.play()
	emit_signal("quitGame")

func mouseIn(caller):
		caller.grab_focus()
		cur = caller


func _physics_process(delta):
	
	if get_focus_owner() !=null and pFocus != null and get_focus_owner() != pFocus:
		$move.play()
	
	for i in $v.get_children():
		if i == get_focus_owner():
			cur = i
	
	if cur == null:
		cur = $v/newGame
		cur.grab_focus()
		cur.grab_click_focus()
	
	
	pFocus = get_focus_owner()
	$target.rect_position = cur.rect_global_position
	$target.rect_position.x -= $target.rect_size.x + 10


func _on_options_pressed():
	$select.play()
	options.visible = true
