tool
extends Control


export var gap = 5 setget gap
export var length = 5 setget length
export var thickness = 1
export(Color, RGBA) var color = Color(1,1,0,1)

var right #= $"right"
var left #= $"left"
var up #= $"up"
var down #= $"down"
# Called when the node enters the scene tree for the first time.


func _ready():
	right = $"right"
	left = $"left"
	up = $"up"
	down = $"down"
	gap(gap)
	#position = get_viewport_rect().size / 2


func _physics_process(delta):
	#gap()
	color()
	thickness()

func gap(g):
	if right == null: return
	
	gap = g
	right.points[0].x =  gap
	right.points[1].x =  gap+length
	
	left.points[0].x =  -gap
	left.points[1].x =  -(gap+length)
	
	up.points[1].y = -gap
	up.points[0].y = -(gap+length)
	
	down.points[1].y =  gap
	down.points[0].y = gap+length
	
func length(l):
	if right == null: return
	length = max(l,0)
	right.points[0].x =  gap
	right.points[1].x =  gap+length
	
	left.points[0].x =  -gap
	left.points[1].x =  -(gap+length)
	
	up.points[1].y = -gap
	up.points[0].y = -(gap+length)
	
	down.points[1].y =  gap
	down.points[0].y = gap+length
	
	
func color():
	right.default_color = color
	left.default_color = color
	down.default_color = color
	up.default_color = color

func thickness():
	right.width = thickness
	left.width = thickness
	down.width = thickness
	up.width = thickness
