@tool
extends Node

var file : FileAccess
var fileDict = {}

func _ready():
	set_meta("hidden",true)
	
func getStreamFromWAV(path):
	file = FileAccess.open(path,FileAccess.READ)
	
	if file != null:
		print("error opening file:",path)
		return AudioStreamWAV.new()
		
	fileDict["magic"] = file.get_buffer(4).get_string_from_ascii()
	fileDict["chunkSize"] = file.get_32()
	fileDict["format"] = file.get_buffer(4).get_string_from_ascii()
	
	parseFmt()
	file.seek(fileDict["dataChunkOffset"])
	parseData()
	var stream = createStream()
	
	
	if file.eof_reached():
		return stream
	
	var cueArr = []
	
	while !file.eof_reached():
		var pos = file.get_position()
		if (pos + 4) >= file.get_length():	
			break
			
		var chunkId = file.get_buffer(4).get_string_from_ascii()
		if chunkId == "LIST":
			parseList()
		
		if chunkId == "CUE ":
			cueArr = parseCue()
			break
	
	stream.loop_end = stream.data.size()
	
	if cueArr.size()>0:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = cueArr[0]
		
	if cueArr.size()>1:
		stream.loop_end = cueArr[1]
	
	return stream
	

func parseFmt():
	fileDict["fmtId"] = file.get_32()
	fileDict["fmtSize"] = file.get_32()
	fileDict["dataChunkOffset"] = fileDict["fmtSize"] + file.get_position()
	fileDict["audioFormat"] = file.get_16()
	fileDict["numChannels"] = file.get_16()
	fileDict["sampleRate"] = file.get_32()
	fileDict["byteRate"] = file.get_32()
	fileDict["blocksAlign"] = file.get_16()
	fileDict["bitsPerSample"] = file.get_16()

func parseData():
	fileDict["dataId"] = file.get_buffer(4).get_string_from_ascii()
	fileDict["dataSize"] = file.get_32()
	
func createStream():
	var stream = AudioStreamWAV.new()
	stream.mix_rate = fileDict["sampleRate"]
	if fileDict["numChannels"] > 1:
		stream.stereo = true
		
	if fileDict["bitsPerSample"] == 8: 
		stream.format = AudioStreamWAV.FORMAT_8_BITS
	if fileDict["bitsPerSample"] == 16: 
		stream.format = AudioStreamWAV.FORMAT_16_BITS
	
	var dataSize = fileDict["dataSize"]
	var data = []
	var size = fileDict["bitsPerSample"]/8
	
	if fileDict["bitsPerSample"] == 8:
		for i in range(0,dataSize):
			
			var sample = file.get_8()
			sample = (sample - 128)/2.0
			data.append(sample)

	if fileDict["bitsPerSample"] == 16:
		for i in range(0,dataSize):
			var sample = file.get_8()
			data.append(sample)

	if !file.eof_reached():
		while(file.get_position())%4 != 0:
			file.get_8()#all files that had another chunk after the data chunk had a single byte of padding
			if file.eof_reached():
				break
	stream.data = data
	
	var audioOutFile = FileAccess.open("res://dbg/raw.dat", FileAccess.WRITE)
	
	for i in stream.data:
		audioOutFile.store_real(i)

		
	
	audioOutFile.close()
	return stream

func parseList():
	
	var listDict = {}
	listDict["dataSize"] = file.get_32()
	var endPos = file.get_position() + listDict["dataSize"]
	listDict["chunkType"] = file.get_buffer(4).get_string_from_ascii()
	file.seek(endPos)
	
func parseCue():
	var curDict = {}
	var cueOffsets = []
	curDict["dataSize"] = file.get_32()
	curDict["numCues"] = file.get_32()
	
	for n in curDict["numCues"]:
		curDict["id"] = file.get_32()
		curDict["position"] = file.get_32()
		curDict["fccChunk"] = file.get_32()
		curDict["chunkStart"] = file.get_32()
		curDict["blockStart"] = file.get_32()
		curDict["sampleOffset"] =file.get_32()
		cueOffsets.append(curDict["position"])
	return cueOffsets
	
