extends Node


var animMeshPath = []
export(Dictionary) var info
export var lightValue = 0

var arr = []
var matMap = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var mapNode = get_node("../../../")
	
	for path in info["targets"]:
		var n = mapNode.get_node(path)
		if n != null:
			var mat = n.mesh.surface_get_material(0)
			if !matMap.has(mat):
				matMap[mat] = mat.duplicate(true)
			n.mesh.surface_set_material(0,matMap[mat])
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)

func bodyIn(body):
	if "interactPressed" in body:
		on()

	
func on():
	for i in matMap.keys():
		var mat = matMap[i]
		mat.set_shader_param("tint",Color(lightValue/256.0,lightValue/256.0,lightValue/256.0))
