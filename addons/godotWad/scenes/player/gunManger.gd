extends Node


export var disabled = false
var loadedRes = []


var categoryToWeaponNode = {}
var weaponNameToCategory = {}
var curGun = null

func _ready():
	
	
	if get_node_or_null("../..") != null:
		if "thickness" in $"../..":
			$"shootCast".translation.z =  -$"../..".thickness
	
	if disabled:
		set_process(false)
		return
	
	var start = OS.get_system_time_msecs()
	

	for g in get_children():
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
	
	if !InputMap.has_action("weaponSwitchCategory0"):InputMap.add_action("weaponSwitchCategory0")
	if !InputMap.has_action("weaponSwitchCategory1"):InputMap.add_action("weaponSwitchCategory1")
	if !InputMap.has_action("weaponSwitchCategory2"):InputMap.add_action("weaponSwitchCategory2")
	if !InputMap.has_action("weaponSwitchCategory3"):InputMap.add_action("weaponSwitchCategory3")
	if !InputMap.has_action("weaponSwitchCategory4"):InputMap.add_action("weaponSwitchCategory4")
	if !InputMap.has_action("weaponSwitchCategory5"):InputMap.add_action("weaponSwitchCategory5")
	if !InputMap.has_action("weaponScrollDown"):InputMap.add_action("weaponScrollDown")
	
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
	
	if Input.is_action_pressed("weaponScrollDown"):
		print("")

func initWeapons():
	for weapon in loadedRes:
		var res = weapon["res"]
		var categoryIdx = res.category
		
		if !categoryToWeaponNode.has(categoryIdx): 
			categoryToWeaponNode[categoryIdx] = []
		
		
		weaponNameToCategory[res.weaponName] = [categoryIdx,categoryToWeaponNode[categoryIdx].size()]
		categoryToWeaponNode[categoryIdx].append(weapon["node"])
		
	breakpoint
	

func getCurWeaponCategory():
	 return weaponNameToCategory[curGun.weaponName]

func categorySwitch(categoryIdx):
	var cat = getCurWeaponCategory()
	if cat[0] == categoryIdx:
		var curIndex = cat[1]
		var inc = cat[1] + 1
		var catSize = categoryToWeaponNode[cat[0]].size()
		var nextIndex = inc%catSize
		
		changeWeaponByCategory(categoryIdx,nextIndex)
	else:
		changeWeaponByCategory(categoryIdx,0)

func changeWeaponByCategory(cat,index):
	if !categoryToWeaponNode.has(cat): 
		return
	var node = categoryToWeaponNode[cat][index]
	
	if node!= curGun:
		changeTo(node)


func changeTo(node):
	
	if curGun == node:
		return
	
	if hasAnim(curGun,curGun.bringdownAnim):
		curGun.anims.play(curGun.bringdownAnim)
		curGun.state = curGun.BRINGUP
		yield(curGun.anims,"animation_finished")
		
		
	
	if curGun!= null: 
		curGun.visible = false#cur gun no longer visible
		curGun.set_physics_process(false)#cur gun no longer processes
	
	curGun = node
	
	curGun.visible = true
	curGun.state = curGun.BRINGUP
	
	
	if hasAnim(curGun,curGun.bringupAnim):
		curGun.anims.play(curGun.bringupAnim)
	#if curGun.anims!= null:
	#	if curGun.bringupAnim != "":
	#		if(curGun.anims.has_animation(curGun.bringupAnim)):
	#			curGun.anims.play(curGun.bringupAnim)
#			else:
#				print("bringUpAnim not found:",curGun.bringupAnim)
	
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
		
