extends HBoxContainer


var iconMinHeight : float = 40.0
var slotDict = []
var maxIconW = 200

var fadeOutTimeSec = 2.5
var fadeOutTimer = fadeOutTimeSec
var trackedInputs = []
var redFlickers = []

func _ready() -> void:
	$"../..".gunChangeSignal.connect(gunChange)
	$"../..".gunChangeFailSignal.connect(gunChangeFail)
	trackedInputs = getInputs() + ["weaponSwitchCategory+","weaponSwitchCategory-"]

func updateSizings():
	var num = get_child_count()
	var resX = get_viewport_rect().size.x - 220
	
	for i in get_children():
		
		if i.get_child_count() == 0:
			continue
		
		if !i.get_child(0).visible:
			custom_minimum_size = Vector2(0,0)
			return
		i.custom_minimum_size = Vector2(min(resX/num,maxIconW),0)
	pass # Replace with function body.

func _process(delta: float) -> void:
	for i in get_children():
		
		if !i is VBoxContainer:
			continue
			
		if i.get_child_count() == 1:
			i.get_child(0).visible = false
			continue
		
		var a = i.get_child(0)
		var b = i.get_child(1)
		
		if b == null:
			a.visible = false
			continue
		
		a.visible = b.visible
	
	
	for i in redFlickers:
		var numberIcon = i.get_child(0)
		numberIcon.modulate = Color(max(0.21950101852417,numberIcon.modulate.r -delta), 0.21950101852417, 0.2195009291172, 0.82352942228317)
		if is_equal_approx(numberIcon.modulate.r,0.21950101852417):
			redFlickers.erase(i)
		#if numberIcon.modulate.r == 0.21950101852417:
			
	
	updateSizings()
		

func _physics_process(delta: float) -> void:
	fadeOutTimer -= delta
	
	if fadeOutTimer <0 and modulate.a > 0:
		$AnimationPlayer.play("fadeOut") 
	
	var weapons = $"../..".weapons.get_children()
	
	if weapons.is_empty():
		return
	
	var slots = get_children()
	
	
	for i in weapons:
		if !slotDict.has(i):
			addWeaponSlot(i)
	
	for vbox in slots:
		for node in vbox.get_children():
			if node is MarginContainer:
				ammoCheck(node)

func addWeaponSlot(node):
	var icon = load("res://addons/godotWad/scenes/player/scenes/weaponManager/weaponIcon.tscn").instantiate()
	var slotNumber = node.category
	
	var slot = get_node(str(slotNumber))
	slot.add_child(icon)
	icon.text = node.weaponName
	icon.iconMinHeight = iconMinHeight
	icon.weaponNode = node
	#position.y = iconMinHeight
	
	if node.worldSprite != null:
		icon.texture = node.worldSprite
	
	slotDict.append(node)
	
func ammoCheck(weaponIcon : Control):
	
	if !"weaponNode" in weaponIcon:
		return
	var weap = weaponIcon.weaponNode

	var count = weap.shooter.inventory[weap["ammoType"]]["count"]
	if weap.magSize >= 0 and count <= 0:
		var children = weaponIcon.get_parent().get_children()
		for i in children:
			
			var numberIcon = i.get_parent().get_child(0)
			
			if !redFlickers.has(weaponIcon.get_parent()):
				i.modulate = Color.DIM_GRAY#gun icon texture
				numberIcon.modulate = Color(0.21950101852417, 0.21950101852417, 0.2195009291172, 0.82352942228317)#number texture
		#	else:
				#i.modulate = Color.RED
		#		numberIcon.modulate = Color.RED

	else:
		for i in weaponIcon.get_parent().get_children():
			i.modulate = Color.WHITE
			i.get_parent().get_child(0).modulate = Color.WHITE
		
	
	
	if weaponIcon.weaponNode == $"../..".curGun:
		weaponIcon.get_node("%Label").visible = true
	else:
		weaponIcon.get_node("%Label").visible = false
		
	if weaponIcon.get_node("%TextureRect").texture == null:
		weaponIcon.get_node("%TextureRect").visible = false
		weaponIcon.get_node("%Label").visible = true
	else:
		weaponIcon.get_node("%TextureRect").visible = true
		

func gunChange(gun):
	var slots = get_children()
	
	if modulate.a == 0:
		$AnimationPlayer.play("fadeIn")
	fadeOutTimer = fadeOutTimeSec
	
	for vbox in slots:
		for node in vbox.get_children():
			
			if !"weaponNode" in node:
				continue
			
			if node.weaponNode == gun:
				node.grab_focus()
				return

func gunChangeFail(category):
	var slots = get_children()
	
	if slots.size() <= category:
		return
	
	
	var targetNumberNode = slots[category-1]
	
	
	targetNumberNode.get_child(0).modulate.r = 1.0
	
	if !redFlickers.has(targetNumberNode):
		redFlickers.append(targetNumberNode)
	
	fadeOutTimer = fadeOutTimeSec
	
	


func _input(event: InputEvent) -> void:
	
	if modulate.a != 0:
		return
				
	for i in trackedInputs:
		if Input.is_action_just_pressed(i):
			$AnimationPlayer.play("fadeIn")
			fadeOutTimer = fadeOutTimeSec
			
func getInputs():
	var ret = []
	
	for i in get_children():
		if i.get_child_count() == 0:
			continue
			
		var x = i.get_child(0)
		if "path" in i.get_child(0):
			ret.append(i.get_child(0).path)
			
			
	return ret
