@tool
extends HTTPRequest
signal gotImage

var imageType = ""

func _ready():
	connect("request_completed", Callable(self, "_http_request_completed"))


func fetch(url):
	var http_error = request(url)
	
	imageType = url.get_extension()
	if http_error != OK:
		print("An error occurred in the HTTP request.")
		

func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error
	
	if imageType == "png": image_error =image.load_png_from_buffer(body)
	if imageType == "jpg": image_error =image.load_jpg_from_buffer(body)
	if imageType == "bmp": image_error =image.load_bmp_from_buffer(body)
	if imageType == "tga": image_error =image.load_tga_from_buffer(body)
	if imageType == "svg": image_error =image.load_svg_from_buffer(body)
	if imageType == "webp": image_error =image.load_webp_from_buffer(body)
	
	
	#if imageType == "webp":  image_error =image.load_webp_from_buffer(body)
	
	if image_error != OK:
		print("An error occurred while trying to display the image.")

	var textureImg = ImageTexture.new()
	textureImg = textureImg.create_from_image(image)
	emit_signal("gotImage",textureImg)
	
