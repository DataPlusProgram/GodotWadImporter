extends Node

@export var scripts : Array[Script] = []

@onready var expression : Expression = Expression.new()

var childNodes : Array[Node]= []

func _ready():
	
	childNodes.append($nativeFuncs)
	
	for i in scripts:
		var node : Node = Node.new()
		node.set_script(i)
		add_child(node)
		childNodes.append(node)
	


func registerScript(script):
	for i in scripts:
		breakpoint
	
	var node : Node = Node.new()
	node.set_script(load(script))
	add_child(node)
	childNodes.append(node)
	

func execute(text:String) -> String:
	
	if text.is_empty():
		return ""
	
	text = text.to_lower()
	
	if text.split(" ").size() == 2:
		
		var funcName = text.split(" ")[0]
		var args = text.split(" ")[1]
		if args.is_valid_int():
			text = funcName + "(" + args + ")"
		else:
			text = funcName + "(\"" + args + "\")"
	
	elif text[text.length()-1] != ")":#if it doesn't end in a parenthesis we probably forgot to add them
		text += "()"
	
	
	
	for node : Node in childNodes:
		var checkText : String = checkFuncForNode(node,text)
		if checkText != "failed":
			return checkText
		
			
	
	return "[color=red]Command: "+ text +" not found.[/color]"
	


func checkFuncForNode(node : Node,text) -> String:
	var error = expression.parse(text)
	
	if error != OK:
		return ""
	
	var expressionReturn = expression.execute([],node)
	
	if expression.has_execute_failed():
		return "failed"
	
	if typeof(expressionReturn) == TYPE_DICTIONARY:
		return expressionReturn["str"]
	elif typeof(expressionReturn) == TYPE_STRING:
		return expressionReturn
		
	return ""
	
