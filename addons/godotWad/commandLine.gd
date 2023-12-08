extends Node



func print_hello(name = ''):
	Console.write_line('Hello ' + name + '!')
	


func spawn(entStr,gameStr = "Doom"):
	entStr = entStr.to_lower()
	var ent = ENTG.spawn(get_tree(),entStr,Vector3.ZERO,Vector3.ZERO,gameStr)
	
	if ent == null:
		Console.write_line('Failed to spawn ' + entStr)


func spawnHere(entStr,gameStr = ""):
	entStr = entStr.to_lower()
	var players = get_tree().get_nodes_in_group("player")
	
	for i in players:
		if i.get_node_or_null("Camera/gunManager/shootCast") != null:
			var cast : RayCast = i.get_node_or_null("Camera/gunManager/shootCast")
			var point = cast.get_collision_point()
			
			var ent = ENTG.spawn(get_tree(),entStr,point,Vector3.ZERO,gameStr)
			if ent == null:
				Console.write_line('Failed to spawn ' + entStr)
			return
	
	Console.write_line('Failed to spawn ' + entStr)


func getEntityList(entStr):
	entStr = entStr.to_lower()
	var dict = ENTG.getEntityDict(get_tree(),entStr)
	for entStr in dict.keys():
		Console.write_line(entStr)

func closeConsole():
	Console.toggle_console()
	
func clearConsole():
	Console.clear()

func _ready():
	return
	Console.connect("toggled",self,"consoleVis")
	
	Console.add_command('sayHello', self, 'print_hello')\
		.set_description('Prints "Hello %name%!"')\
		.add_argument('name', TYPE_STRING)\
		.register()
	
	Console.add_command('spawn', self, 'spawn')\
		.set_description('Spawns entity"')\
		.add_argument('entStr', TYPE_STRING)\
		.add_argument('gameStr', TYPE_STRING)\
		.register()
		
	
	Console.add_command('spawnHere', self, 'spawnHere')\
		.set_description('Spawns entity where player is looking"')\
		.add_argument('entStr', TYPE_STRING)\
		.add_argument('gameName', TYPE_STRING)\
		.register()
	
	Console.add_command('getEntityList', self, 'getEntityList')\
		.set_description('Gets entity list"')\
		.add_argument('gameName', TYPE_STRING)\
		.register()
	
	Console.add_command('close', self, 'closeConsole')\
		.set_description('Closes the console')\
		.register()
	
	Console.add_command('c', self, 'closeConsole')\
		.set_description('Closes the console')\
		.register()
	
	Console.add_command('cls', self, 'clearConsole')\
		.set_description('Clears the console')\
		.register()
	
	pass # Replace with function body.


func consoleVis(vis):
	if vis == true:
		for i in get_tree().get_nodes_in_group("player"):
			i.disableInput()
	else:
		for i in get_tree().get_nodes_in_group("player"):
			i.enableInput()
		
		
		

