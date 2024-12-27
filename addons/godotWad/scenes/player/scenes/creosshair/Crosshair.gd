
extends Control


@export var gap = 5: set = setGap
@export var length = 5: set = setLength
@export var thickness = 1
@export var color = Color(1,1,0,1) # (Color, RGBA)

var right #= $"right"
var left #= $"left"
var up #= $"up"
var down #= $"down"
var radius = 50
# Called when the node enters the scene tree for the first time.


func _ready():
	right = $"right"
	left = $"left"
	up = $"up"
	down = $"down"
	setGap(gap)
	#position = get_viewport_rect().size / 2


func _physics_process(delta):
	#gap()
	setColor()
	setThickness()
	#update()

func setGap(g):
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
	
func setLength(l):
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
	
	
func setColor():
	if right == null: return
	right.default_color = color
	left.default_color = color
	down.default_color = color
	up.default_color = color

func setThickness():
	if right == null: return
	right.width = thickness
	left.width = thickness
	down.width = thickness
	up.width = thickness



#func _draw():
#	var spread = ($"../../gunManager/pistol3".maxSpread.x/2.0)
#	radius = tan(deg2rad(spread))*360
#	draw_arc(Vector2.ZERO,radius,0,2*PI,600,Color.yellow)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
