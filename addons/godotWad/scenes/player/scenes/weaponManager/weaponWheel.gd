@tool
extends Control


@export var radiusRatio = 0.85
@export var thickness = 4.0
@export var outlineColor = Color(1, 1, 1, 0.3)
@export var color = Color(1, 1, 1, 0.2)

var count = 8

# Called when the node enters the scene tree for the first time.
func _draw() -> void:
	var pos = size/2.0
	var radius = (min(size.y,size.x)/2.0) * radiusRatio
	#draw_circle(pos,radius+thickness,outlineColor)
	draw_circle(pos,radius,color)
	
	
	draw_arc(pos,radius+thickness/2.0,0,TAU,400,outlineColor,thickness,true)
	
	
	for i in count:
		var angle = TAU/count
		draw_circle(pos+Vector2(radius*0.8*cos(angle*i),radius*0.8*sin(angle*i)),radius*0.1,color)
		
	drawSlice(2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func drawSlice(idx):
	var coverage = TAU / count
	var angle = TAU/idx
	var pos = size/2.0
	var radius = (min(size.y,size.x)/2.0) * radiusRatio
	
	var poly = [pos]
	
	
	
	var itt = [-coverage,0,coverage]
	for i in itt:
		var v1 = pos + Vector2(radius*cos((i/2.0)*idx),radius*0.8*sin((i/2.0)*idx))
		poly.append(v1)
		#var v2 = pos + Vector2(radius*cos((i/2.0)*idx),radius*0.8*sin((i/2.0)*idx))
	
		draw_colored_polygon(poly,Color.RED)
