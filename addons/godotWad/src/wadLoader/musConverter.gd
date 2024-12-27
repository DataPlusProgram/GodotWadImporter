@tool
extends Node

enum MusEvent {
	RELEASE = 0x00,
	PRESS = 0x10,
	PITCH_WHEEL = 0x20,
	SYS_EVENT = 0x30,
	CTRL_CHANGE = 0x40,
	END = 0x60
}

enum MidiEvent {
	RELEASE = 0x80,
	PRESS = 0x90,
	AFTERTOUCH = 0xA0,
	CTRL_CHANGE = 0xB0,
	PATCH_CHANGE = 0xC0,
	AFTERTOUCH_CHANNEL = 0xD0,
	PITCH_WHEEL = 0xE0
}

const MUS_PERCUSSION = 15
const MIDI_PERCUSSION = 9

const magicMus: PackedByteArray = [0x4D, 0x55, 0x53, 0x1A]
const controllerMap = [0xFF, 0, 1, 7, 10, 11, 91, 93, 64, 67, 120, 123, 126, 127, 121]
const midiHeader : PackedByteArray = [
		0x4D, 0x54, 0x68, 0x64, # chunk ID
		0, 0, 0, 6, # header size
		0, 0, # format
		0, 1, # number of tracks
		0, 70, # time division
		0x4D, 0x54, 0x72, 0x6B, # track chunk ID
		#0, 0, 0, 0, # space for size
		0, 255, 81, 3, 0x07, 0xA1, 0x20, # Set tempo to 500,000 microsec/quarter note
		0 # lil time byte
	]

func readMessages(stream: StreamPeerBuffer, volumes: PackedByteArray) -> PackedByteArray:
	var data
	var last
	var musChannel
	var time = 0
	var event: PackedByteArray = []

	data = stream.get_u8()
	last = data & 0x80
	musChannel = data & 0xF

	var eventType = data & 0x70
	match eventType:
		MusEvent.RELEASE:
			event.append(MidiEvent.RELEASE)
			event.append(stream.get_u8() & 0x7f)
			event.append(0)

		MusEvent.PRESS:
			event.append(MidiEvent.PRESS)
			data = stream.get_u8()
			event.append(data & 0x7F)
			if data & 0x80:
				event.append(stream.get_u8())
				volumes[musChannel] = event[2]
			else:
				event.append(volumes[musChannel])

		MusEvent.PITCH_WHEEL:
			var d = stream.get_u8()
			event.append(MidiEvent.PITCH_WHEEL)
			event.append((d & 0x01) << 6)
			event.append(d >> 1)

		MusEvent.SYS_EVENT:
			event.append(MidiEvent.CTRL_CHANGE)
			event.append(controllerMap[stream.get_u8()])
			event.append(0x7F)

		MusEvent.CTRL_CHANGE:
			data = stream.get_u8()
			if data == 0:
				event.append(MidiEvent.PATCH_CHANGE)
				event.append(stream.get_u8())
			else:
				event.append(MidiEvent.CTRL_CHANGE)
				event.append(controllerMap[data & 0xF])
				event.append(stream.get_u8())

		MusEvent.END:
			return [0xFF, 0x2F, 0x00]

		_:
			return []

	if musChannel == MUS_PERCUSSION:
		event[0] |= MIDI_PERCUSSION
	else:
		event[0] |= musChannel

	var ret = []

	# time to read the time
	if last:
		while true:
			data = stream.get_u8()
			time = (time * 128 + data & 127)
			if !(data & 128):
				break

	ret.append_array(event)
	ret.append(time)

	return ret


# Little Endian to Big
func intToBytes(value: int, length: int = 4) -> PackedByteArray:
	var bytes_array: PackedByteArray = []

	# Convert the integer to bytes
	for i in range(length - 1, -1, -1):  # Loop from the most significant byte to the least
		bytes_array.append((value >> (i * 8)) & 0xFF)

	return bytes_array


func loadHeader(stream: StreamPeerBuffer) -> bool:
	var id = stream.get_data(4)[1]
	if id != magicMus:
		push_error("failed to read magic\nid: ", id, " magic: ", magicMus)
		return false

	var scoreLen = stream.get_u16()
	var scoreStart = stream.get_u16()
	var streamSize = stream.get_size()

	if streamSize != scoreStart + scoreLen:
		push_error(
			"header reporting incorrect size, real: ",
			streamSize,
			" reported: ",
			scoreStart + scoreLen
		)
		return false
	stream.seek(scoreStart)

	return true


func convertMusToMidi(mus: PackedByteArray) -> PackedByteArray:
	var stream = StreamPeerBuffer.new()
	var midiData: PackedByteArray = []

	stream.set_data_array(mus)

	if !loadHeader(stream):
		push_error("failed to convert mus to midi")
		return []

	midiData.append_array(midiHeader)

	var volumes: PackedByteArray = []
	volumes.resize(16)
	volumes.fill(0)

	while stream.get_position() != mus.size():
		var messages = readMessages(stream, volumes)
		midiData.append_array(messages)

	var len_bytes = intToBytes(midiData.size() - 0x12)
	for i in range(4):
		midiData.insert(0x12 + i, len_bytes[i])

	return midiData
