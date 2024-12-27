extends Node
class_name sheetGlobal




static func saveNodeAsScene(node,path = "res://dbg/"):
	
	recursiveOwn(node,node)
	var packedScene = PackedScene.new()
	packedScene.pack(node)
	
	if path.find(".tscn") != -1:
		#print("saving as:",path)
		ResourceSaver.save(path,packedScene)
	else:
		#print("saving as:",path+node.name+".tscn")
		ResourceSaver.save(packedScene,path+node.name+".tscn")
		
		
static func recursiveOwn(node,newOwner):
	
	# node.get_filename() == "":
	
	for i in node.get_children():
		recursiveOwn(i,newOwner)
	
	if node != newOwner:#you get error if you set something as owning itself
		node.owner = newOwner



static func getChildOfClass(node,type):
	for c in node.get_children():
		if c.get_class() == type:
			return c
			
	return null


static func isInternal(string):
	var internalTypes = [
	"Vector2",
	"Vector3",
	"Rect2",
	]
	
	if internalTypes.has(string):
		return true
	return false
	
	
	
