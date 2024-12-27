extends Control
var cur = null : set = curSetter
var prev = null
@onready var list = $v
var titleSong : String
var previousFocus = null
signal newGame
signal quitGame
signal gameLoadedSignal
signal retryLevel

var pFocus = null
var retryHover = false
var options = null
@onready var inputPrompt = get_node_or_null("options/VBoxContainer/TabContainer/Input/prompt")
@onready var mainMode = get_parent()
@onready var videoOptions = $options/VBoxContainer/TabContainer/Video/Video

func _ready():
	
	process_mode = PROCESS_MODE_ALWAYS
	
		
	var loader = get_parent().get_node("WadLoader").get_node("MaterialManager")
	$SaveLoadUi.gameName =  get_parent().get_node("WadLoader").gameName
	#var arr = [$v/newGame,$v/options,$v/saveGame,$v/loadGame,$v/quit]
	#for i in arr:
	#	loader.instancedUICanvasItemCache.append(i)
	
	
	#if !materialManager.instancedUITextureCache.has(texture):
	#	materialManager.instancedUITextureCache.append(texture) 
	
	for i in list.get_child_count():
		var nextIdx = (i+1)%list.get_child_count()
		var prevIdx = (i-1)
		
		if prevIdx == -1:
			prevIdx = list.get_child_count()-1
		
		list.get_child(i).focus_neighbor_bottom = list.get_child(i).get_path_to(list.get_child(nextIdx))
		list.get_child(i).focus_neighbor_top = list.get_child(i).get_path_to(list.get_child(prevIdx))
		
	for i in list.get_children():
		i.connect("mouse_entered", Callable(self, "mouseIn").bind(i))


	options = $options
	#add_child(options)
	options.visible = false
	
	
	var styleBox = SETTINGS.getSetting(get_tree(),"styleBox")
	
	$SaveLoadUi.set("theme_override_styles/panel",styleBox)
	$options.set("theme_override_styles/panel",styleBox)
	$SaveLoadUi.gameLoadedSignal.connect(_on_save_load_ui_game_loaded_signal)
	
	

func _on_newGame_pressed():
	$select.play()
	$v/retry.visible = false
	emit_signal("newGame")
	


func _on_quit_pressed():
	$move.play()
	emit_signal("quitGame")

func mouseIn(caller):
	if cur != caller:
		caller.grab_focus()
		prev = cur
		cur = caller
		cur.grab_focus()
		cur.grab_click_focus()

func _process(delta):
	
	
	if options.visible == true:
		return
	
	if $SaveLoadUi.visible == true:
		return
		
	if visible:
		if get_viewport().gui_get_focus_owner() !=null and pFocus != null and get_viewport().gui_get_focus_owner() != pFocus:
			$move.play()
	
	for i in $v.get_children():
		if i == get_viewport().gui_get_focus_owner():
			if cur != i:
				prev = cur
				cur = i
	
	if cur == null:
		cur = $v/newGame
		cur.grab_focus()
		cur.grab_click_focus()
		$target.position.y = cur.global_position.y + $target.size.x - 18
	
	
	pFocus = get_viewport().gui_get_focus_owner()
	updateTargetPos(delta)

	
func _physics_process(delta):
	updateTargetPos(delta)

func updateTargetPos(delta):
	
	if cur == null:
		return
	
	$target.position.x  = cur.global_position.x - $target.size.x - 18
	
	if cur == $v/retry:
		$target.position.x = $v/newGame.global_position.x - $target.size.x - 18
	
	if prev != null:
		$target.position.y = lerp($target.position.y ,cur.global_position.y,delta*20)
	
	$v/saveGame.visible = $SaveLoadUi.canSave()
func _on_options_pressed():
	$select.play()
	options.visible = true


func _on_save_game_pressed():
	
	$SaveLoadUi.mode = $SaveLoadUi.MODE.SAVE
	$SaveLoadUi.visible = true



func _on_save_load_ui_game_loaded_signal():
	emit_signal("gameLoadedSignal")


func _on_load_game_pressed():
	
	$SaveLoadUi.mode = $SaveLoadUi.MODE.LOAD
	$SaveLoadUi.visible = true

func hide():
	
	if inputPrompt.visible:
		breakpoint
	
	visible = false
	$SaveLoadUi.visible = false


func retryVisible(vis):
	$v/retry.visible = vis

func _on_visibility_changed():
	
	if !$v.is_inside_tree():
		return
		
	if visible:
		var cFocus = get_viewport().gui_get_focus_owner()
		if cFocus != null:
			if is_instance_valid(cFocus):
				previousFocus = cFocus
	else:
		if previousFocus != null:
			if is_instance_valid(previousFocus):
				previousFocus.grab_focus()
				previousFocus.grab_click_focus()
	
		
	if visible == false:
		return
	
	
	
	
	getFocus()



func getFocus():
	var hasSelected = false
	
	for i in $v.get_children():
		
		if get_viewport().gui_get_focus_owner() == i:
			i.grab_focus()
			i.grab_click_focus()
			hasSelected = true
			break
	
	if hasSelected == false:
		var v = $v.get_child(0)
		v.grab_focus()
		v.grab_click_focus()

	


func _on_retry_mouse_entered() -> void:
	$v/retry.grab_click_focus()
	$v/retry.grab_focus()
	retryHover = true


func _on_retry_mouse_exited() -> void:
	retryHover = false


func _on_retry_gui_input(event: InputEvent) -> void:
	
	if !retryHover:
		return
	
	if !event is InputEventMouseButton:
		return
	
	var pressed = event.is_released() and !event.is_echo()
	
	if pressed and event.button_index == 1:
		emit_signal("retryLevel")

func curSetter(newCur):
	if cur != null:
		cur.modulate = Color.WHITE
	
	if newCur != null:
		newCur.modulate = Color.WHITE*1.5
	
	cur = newCur
	
