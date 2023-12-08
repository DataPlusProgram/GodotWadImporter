tool
extends Node


export var disabled = false
var loadedRes = []


var categoryToWeaponNode = {}
var weaponNameToCategory = {}
var weaponToUI = {}
var curGun = null
var maxCat = 0

onready var shooter = get_parent()
onready var weapons = $weapons

#func _init():
#	connect("child_entered_tree",self,"setShooter")
	

func _ready():
	

	
	for i in weapons.get_children():
		pickup(i)
		
	
	#if weapons.get_child_count() > 0:
	#	changeTo(weapons.get_child(0))
	
	if get_node_or_null("..") != null:
		if "thickness" in $"..":
			$"shootCast".translation.z =  -$"../".thickness
	
	if disabled:
		set_process(false)
		return
	
	var start = OS.get_system_time_msecs()
	

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
			

	


func _physics_process(delta):
	

	if Engine.editor_hint: 
		return
	
	if "processInput" in get_parent():
		if get_parent().processInput == false:
			return
	
	
	if !InputMap.has_action("weaponSwitchCategory0"):InputMap.add_action("weaponSwitchCategory0")
	if !InputMap.has_action("weaponSwitchCategory1"):InputMap.add_action("weaponSwitchCategory1")
	if !InputMap.has_action("weaponSwitchCategory2"):InputMap.add_action("weaponSwitchCategory2")
	if !InputMap.has_action("weaponSwitchCategory3"):InputMap.add_action("weaponSwitchCategory3")
	if !InputMap.has_action("weaponSwitchCategory4"):InputMap.add_action("weaponSwitchCategory4")
	if !InputMap.has_action("weaponSwitchCategory5"):InputMap.add_action("weaponSwitchCategory5")
	if !InputMap.has_action("weaponSwitchCategory6"):InputMap.add_action("weaponSwitchCategory6")
	if !InputMap.has_action("weaponSwitchCategory+"):InputMap.add_action("weaponSwitchCategory+")
	if !InputMap.has_action("weaponSwitchCategory-"):InputMap.add_action("weaponSwitchCategory-")
	
	
	
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
	
	if Input.is_action_just_released("weaponSwitchCategory+"):
		
		nextWeapon()
		
	if Input.is_action_just_released("weaponSwitchCategory-"):
		nextWeapon()
			

func initWeapons():
	for weapon in loadedRes:
		var res = weapon["res"]
		var categoryIdx = res.category
		
		if !categoryToWeaponNode.has(categoryIdx): 
			categoryToWeaponNode[categoryIdx] = []
		
		
		weaponNameToCategory[res.weaponName] = [categoryIdx,categoryToWeaponNode[categoryIdx].size()]
		categoryToWeaponNode[categoryIdx].append(weapon["node"])
		
	breakpoint
	



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
	var weaponName = node.weaponName
	
	if node!= curGun:
		changeTo(node)


func bringDown():
	if curGun!= null: 
		if hasAnim(curGun,curGun.bringdownAnim):
			curGun.anims.play(curGun.bringdownAnim)
			curGun.state = curGun.BRINGUP
			yield(curGun.anims,"animation_finished")
			
			curGun.visible = false#cur gun no longer visible
			curGun.set_physics_process(false)#cur gun no longer processes

func changeTo(node):
	
	if node == null:
		return
	
	if curGun == node:
		return
	
	if curGun!= null: 
		if hasAnim(curGun,curGun.bringdownAnim):
			curGun.anims.play(curGun.bringdownAnim)
			curGun.state = curGun.BRINGUP
			yield(curGun.anims,"animation_finished")
			
			curGun.visible = false#cur gun no longer visible
			curGun.set_physics_process(false)#cur gun no longer processes
	
	curGun = node
	
	curGun.visible = true
	curGun.state = curGun.BRINGUP
	
	
	if hasAnim(curGun,curGun.bringupAnim):
		curGun.anims.play(curGun.bringupAnim)

	
	curGun.set_physics_process(true)



func hasAnim(node,animName):
	if animName == null:
		print("looking for animation name that is null")
		return false
	
	if node.anims == null:
		return false
		
	if node.anims.has_animation(animName):
		return true
	else:
		print("anim:",animName," not found")
		return false
		

func getGunNodeFromName(nameStr):
	for i in weapons.get_children():
		if "weaponName" in i:
			if i.weaponName == nameStr:
				return i
	
func pickup(node):
	
	
	if node == null:
		return
		
	$"../UI/ColorOverlay/AnimationPlayer".play("itemPickup")
	
	if "pickupAmmo" in node:
		var t =node.ammoType
		if !$"../".inventory.has(node.ammoType):
			$"../".inventory[node.ammoType] = {}
			$"../".inventory[node.ammoType]["count"]  = 0
		
		$"../".inventory[node.ammoType]["count"] += node.pickupAmmo
	
	for i in $weapons.get_children():
		if "weaponName" in i:
			if i.weaponName == node.weaponName:
				node.shooter = get_parent()
				return
	
	
	
	
	$weapons.add_child(node)
	
	
	node.shooter = get_parent()
	
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
			image.flags = 0
			weaponToUI[node.weaponName] = image
		
	changeTo(node)
	
func setShooter(node):
	if "shooter" in node:
		node.shooter = get_parent()

func getWeaponFromKey(key):
	var cat = categoryToWeaponNode[key[0]]
	return cat[key[1]]

func nextWeapon():
	
	var list = weaponsAsList()
	
	if list.empty():
		return
	
	var c = list.find(curGun)
	
	c = (c+1)%list.size()
	changeTo(list[c])
	
func prevWeapon():
	
	var list = weaponsAsList()
	var c = list.find(curGun)
	
	c = WADG.indexCircular(list,c-1)
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

func getWeaponNodes():
	return weapons.get_children()
