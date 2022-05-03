extends Area

var sectorTag = -1


func _ready():
	sectorTag = get_meta("sectorTag")
	connect("body_entered",self,"_body_entered")

func _body_entered(body):
	if body.get_class() != "StaticBody":
		var t = $"../../../../"
		var tPos = Vector2(t.translation.x,t.translation.z)
		var tScale = Vector2(t.scale.x,t.scale.z)
		var a = (get_meta("lineStart")+tPos)*tScale
		var b = (get_meta("lineEnd")+tPos)*tScale
		get_parent().body_entered(body,sectorTag,a,b)
	
