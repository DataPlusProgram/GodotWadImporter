@tool
extends Node3D

signal weaponPickupSignal
signal gunChangeSignal
signal gunChangeFailSignal

@export var disabled = false
@onready var shooter = get_parent().get_parent()
@onready var weapons = $weapons
@onready var cast = $"shootCast"



var loadedRes = []
var categoryToWeaponNode = {}
var weaponNameToCategory = {}
var weaponToUI = {}
var curGun = null : set = curGunSet
var maxCat = 0
var entityName = ""
var entityGame = ""
var angle = 1.5708
var parHasVelo = true
func _ready():
	
	
	var a = Time.get_ticks_msec()
	
	cast.enabled = true
	checkWeaponCategoryInputs(["0","1","2","3","4","5","6","7","+","-"])
	
	
	
	
	for i in weapons.get_children():
		pickup(i,true)
		
	if "velocity" in shooter:
		parHasVelo = true
	else:
		parHasVelo = false

	if disabled:
		set_process(false)
		return
	
	var start = Time.get_ticks_msec()
	

	for g in weapons.get_children():
		if !"category" in g: continue
		
		var categoryIdx = g.category
		
		if !categoryToWeaponNode.has(categoryIdx): 
			categoryToWeaponNode[categoryIdx] = []
		
		
		weaponNameToCategory[g.weaponName] = [categoryIdx,categoryToWeaponNode[categoryIdx].size()]
		categoryToWeaponNode[categoryIdx].append(g)
		
		if curGun == null:
			curGun = g
		else:
			if hasAnim(g,g.bringdownAnim):
				g.anims.play(g.bringdownAnim)
			g.visible = false
			g.set_physics_process(false)
	
	var rangle = deg_to_rad(angle)


	weapons.position.y = abs((0.018 * sin(rangle))) - 0.02
	weapons.position.x = (0.013 * cos(rangle))
	
	if curGun != null:
		if hasAnim(curGun,curGun.bringupAnim):
			curGun.anims.play(curGun.bringupAnim)

	return

func checkWeaponCategoryInputs(strs : Array):
	for i in strs:
		if !InputMap.has_action("weaponSwitchCategory" + i):
			InputMap.add_action("weaponSwitchCategory" + i)
	


func _process(delta: float) -> void:
	var speed = 0
	if parHasVelo:
		speed =  Vector2(shooter.velocity.x,shooter.velocity.z).length()
	
	if speed > 2.2:
		angle += delta *speed * 20
		angle = fmod(angle,360.0)
		
		
		var rangle = deg_to_rad(angle)
		
	else:
		angle = fmod(angle,360.0)
		
		if angle <= 90: angle =lerp(angle,90.0,delta*4)
		elif angle <=180 : angle = lerp(angle,90.0,delta*4)
		elif angle <=270 : angle = lerp(angle,270.0,delta*4)
		elif angle <=315 : angle = lerp(angle,270.0,delta*4)
		elif angle <=(360+60) : angle = lerp(angle,360.0+90,delta*4)
		
	if curGun != null:
		if "isFiring" in curGun:
			if curGun.isFiring:
				angle = 90
	
	var rangle = deg_to_rad(angle)
	
	var bob = true

	if curGun!= null: 
		if hasAnim(curGun,curGun.bringdownAnim):
			if curGun.anims.current_animation == curGun.bringdownAnim:
				bob = false
				
			elif curGun.anims.current_animation == curGun.bringupAnim:
				bob = false
	
	if bob:
		weapons.position.y = abs((0.018 * sin(rangle))) - 0.017
		weapons.position.x = (0.013 * cos(rangle))

func _physics_process(delta):
	
	if Engine.is_editor_hint(): 
		return
	
	
	#print(rotation)
	if "processInput" in get_parent():
		if get_parent().processInput == false:
			return
	
	if shooter.processInput == false:
		return

	#print(global_transform.basis.get_scale())
	
	if Input.is_action_just_pressed("weaponSwitchCategory0"):
		categorySwitch(0)
	
	if Input.is_action_just_pressed("weaponSwitchCategory1"):
		categorySwitch(1)
	
	if Input.is_action_just_pressed("weaponSwitchCategory2"):
		
		categorySwitch(2)
	
	if Input.is_action_just_pressed("weaponSwitchCategory3"):
		categorySwitch(3)
		
	if Input.is_action_just_pressed("weaponSwitchCategory4"):
		categorySwitch(4)
		
	if Input.is_action_just_pressed("weaponSwitchCategory5"):
		categorySwitch(5)
	
	if Input.is_action_just_pressed("weaponSwitchCategory6"):
		categorySwitch(6)
	
	if Input.is_action_just_pressed("weaponSwitchCategory7"):
		categorySwitch(7)
	
	if Input.is_action_just_released("weaponSwitchCategory+"):
		nextWeapon()
		
	if Input.is_action_just_released("weaponSwitchCategory-"):
		prevWeapon()
	
	if curGun != null:
		if curGun.shooter == null:
			curGun.shooter = get_parent().get_parent()
		
		if curGun.getCurAmmo() == 0 and curGun.magSize > -1:
			noAmmoSwitch()
	
	#weaponBarTick()
			

func initWeapons():
	for weapon in loadedRes:
		var res = weapon["res"]
		var categoryIdx = res.category
		
		if !categoryToWeaponNode.has(categoryIdx): 
			categoryToWeaponNode[categoryIdx] = []
		
		
		weaponNameToCategory[res.weaponName] = [categoryIdx,categoryToWeaponNode[categoryIdx].size()]
		categoryToWeaponNode[categoryIdx].append(weapon["node"])
		
	breakpoint
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("weaponSwitchCategory1"):
		categorySwitch(1)

func getCurWeaponKey():
	if curGun == null:
		return
	return weaponNameToCategory[curGun.weaponName]
	
func getCurWeaponCategoryIndex():
	return weaponNameToCategory[curGun.weaponName][0]

func categorySwitch(categoryIdx):
	
	var curKey = getCurWeaponKey() 
	
	if curKey == null:
		return
	
	var curCat = curKey[0]
	var curIndex= curKey[1]
		
	if curCat == categoryIdx:
		var inc = curIndex + 1
		var catSize = categoryToWeaponNode[curCat].size()
		var nextIndex = inc%catSize
		changeWeaponByCategory(categoryIdx,nextIndex)
	else:
		changeWeaponByCategory(categoryIdx,0)

func changeWeaponByCategory(cat,index):
	if !categoryToWeaponNode.has(cat): 
		return
	
	
	var node = categoryToWeaponNode[cat][index]
	
	if node.getCurAmmo() <= 0 and node.magSize >= 0:
		emit_signal("gunChangeFailSignal",cat)
		return
	
	if node!= curGun:
		changeTo(node)


func bringDown():
	if curGun!= null: 
		if hasAnim(curGun,curGun.bringdownAnim):
			curGun.anims.play(curGun.bringdownAnim)
			emit_signal("gunChangeSignal",curGun)
			if "state" in curGun:
				curGun.state = curGun.BRINGUP
				await curGun.anims.animation_finished
			
			
			curGun.visible = false#cur gun no longer visible
			curGun.set_physics_process(false)#cur gun no longer processes

func changeTo(node, instant = false):
	
	if node == null:
		return
	
	
	
	if curGun == node:
		return
	
	
	if curGun!= null: 
		if hasAnim(curGun,curGun.bringdownAnim):
			
			emit_signal("gunChangeSignal",node)
			curGun.anims.play(curGun.bringdownAnim)
			if !instant:
				await curGun.anims.animation_finished
			
			curGun.visible = false#cur gun no longer visible
			curGun.set_physics_process(false)#cur gun no longer processes
	
	curGun = node
	
	curGun.set_physics_process(true)
	if hasAnim(curGun,curGun.bringupAnim):
		curGun.anims.play(curGun.bringupAnim)
		curGun.anims.advance(0.0)
		

	
	curGun.visible = true
	
	
	
	if curGun.get_node_or_null("AnimatedSprite3D"):
		curGun.get_node("AnimatedSprite3D")._physics_process(0)
	
	
func hasAnim(node,animName):
	if animName == null:
		print("looking for animation name that is null")
		return false
	
	if node.anims == null:
		return false
		
	if node.anims.has_animation(animName):
		return true
	else:
		#print("anim:",animName," not found")
		return false
		

func getGunNodeFromName(nameStr):
	for i in weapons.get_children():
		if "weaponName" in i:
			if i.weaponName == nameStr:
				return i
	
func pickup(node,silent = false,dontSwitch = false):
	
	if node == null:
		return
	
	
		
	if !silent:
		$"../../UI/ColorOverlay/AnimationPlayer".play("itemPickup")

	var inventory  = shooter.inventory
	
	if "pickupAmmo" in node:
		var t =node.ammoType
		if !inventory.has(node.ammoType):
			inventory[node.ammoType] = {}
			inventory[node.ammoType]["count"]  = 0
		
		var ammoEntry = inventory[node.ammoType]
		
		ammoEntry["count"] += node.pickupAmmo
		
		if ammoEntry.has("max"):
			if ammoEntry["count"] > ammoEntry["max"]:
				ammoEntry["count"] = ammoEntry["max"]
		
	for i in $weapons.get_children():
		if "weaponName" in i:
			if i.weaponName == node.weaponName:
				node.shooter = get_parent().get_parent()
				return
	
	
	
	
	$weapons.add_child(node)
	
	 
	emit_signal("weaponPickupSignal")
	
	if !silent:
		var sound = AudioStreamPlayer.new()
		sound.stream = node.pickupSound
		sound.autoplay = true
		add_child(sound)
		sound.finished.connect(sound.queue_free)
	
	var t = get_parent().get_parent()
	node.shooter
	node.shooter = get_parent().get_parent()
	
	if curGun == null:
		curGun = node
	else:
		node.visible = false
		node.set_physics_process(false)
	
	var categoryIdx = node.category
	
	if categoryIdx > maxCat:
		maxCat = categoryIdx
	
	if !categoryToWeaponNode.has(categoryIdx): 
		categoryToWeaponNode[categoryIdx] = []
	
	categoryToWeaponNode[categoryIdx].append(node)
	var idxInCate = categoryToWeaponNode[categoryIdx].size()-1
	
	var gunName = node.weaponName
	weaponNameToCategory[node.weaponName] = [categoryIdx,idxInCate]

	if "worldSprite" in node:
		if node.worldSprite != null:
			var image = node.worldSprite.duplicate()
			#image.flags = 0
			weaponToUI[node.weaponName] = image
	
	
	if !dontSwitch:
		changeTo(node)
	
func setShooter(node):
	if "shooter" in node:
		node.shooter = get_parent().get_parent()

func getWeaponFromKey(key):
	var cat = categoryToWeaponNode[key[0]]
	return cat[key[1]]

func nextWeapon():
	
	var list = weaponsAsList()
	
	if list.is_empty():
		return
	
	var c = list.find(curGun)
	
	
	c = (c+1)%list.size()
	
	
	while(!list.is_empty()):
		
		if  list[c].getCurAmmo() <= 0 and list[c].magSize >= 0:
			list.remove_at(c)
			c = (c)%list.size()
		else:
			break
	
	changeTo(list[c])
	
func prevWeapon():
	
	var list = weaponsAsList()
	var c = list.find(curGun)
	
	c = WADG.indexCircular(list,c-1)
	
	while(!list.is_empty()):
		
		
		if list[c].getCurAmmo() <= 0 and list[c].magSize >= 0:
			list.remove_at(c)
			c = WADG.indexCircular(list,c-1)
		else:
			break
	
	changeTo(list[c])

func weaponsAsList():
	var arr = []
	
	for i in getMaxCat()+1:
		if categoryToWeaponNode.has(i):
			for node in categoryToWeaponNode[i]:
				arr.append(node)
	
	return arr


func getMaxCat():
	var maxi = -INF
	for i in categoryToWeaponNode.keys():
		if i > maxi:
			maxi = i
	
	return maxi

func getUIsprite():
	
	if curGun == null:
		return
	
	if weaponToUI.has(curGun.weaponName):
		return weaponToUI[curGun.weaponName]
		
	return null

func serializeSave():
	
	var data = []
	
	for i in weapons.get_children():
		if !i.gameName.is_empty() and !i.entityName.is_empty():
			if i.has_meta("serializeSave"):
				i.serializeSave()
			data.append([i.gameName,i.entityName])
	
	
	var curWeaponName : String = ""
	
	if curGun != null:
		curWeaponName = curGun.weaponName
		
	return {"weapons":data,"curWeaponName":curWeaponName}
	

func serializeLoad(data : Dictionary):
	
	var oldWeaponList = data["weapons"]
	
	for weapToLoad in oldWeaponList:
		var weap = ENTG.fetchEntity(weapToLoad[1],get_tree(),weapToLoad[0],false)
		#add_child(weap)
		pickup(weap,true,true)
		
		
	var curWeaponName = data["curWeaponName"]
	
	
	
	
	for i in weapons.get_children():
		if i.weaponName == curWeaponName:
			#instantSwitch(i)
			changeTo(i)
		
		
		
		

	

func instantSwitch(node):
	curGun.anims.play(curGun.bringupAnim,-1,9999)

func getWeaponNodes():
	return weapons.get_children()




func noAmmoSwitch():
	prevWeapon()

func curGunSet(gun):
	curGun = gun
	emit_signal("gunChangeSignal",gun)

#func weaponBarTick():
#	for i in $ui/weaponBar.get_children():
		
