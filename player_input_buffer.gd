class_name PlayerInputBuffer
extends InputBuffer

var recent_inputs : Array[int] = []
var ordered_buffer : Array = []

var rolling_average : Array[int] = []
var rolling_average_size : int = 41
var index : int = 0
var buffer_size : int = 8
var counter : int = 0
var counter_max : int = 60


func _init(buffer_target_length : int=8):
	self.buffer_size = buffer_target_length
	self.ordered_buffer.resize(20)
	for i in range(20):
		ordered_buffer[i] = {"order" : i, "speed_input" : 0.0}
	#self.ordered_buffer[0] = {"order" : 0, "speed_input" : 0.0}
	self.rolling_average.resize(self.rolling_average_size)
	self.rolling_average.fill(0)

func add(new_input : Dictionary) -> void:
	#assert(new_input is PlayerInput, "Error: non-player input placed in PlayerInputBuffer")
	
	var order_diff = new_input.order - self.ordered_buffer[0].order
	if counter == counter_max:
		self._add_to_rolling_average(order_diff)
		counter = 0
	else:
		counter += 1
	if (order_diff >= 0) and (order_diff < len(ordered_buffer)):
		ordered_buffer[order_diff] = new_input
		return
	elif (order_diff >= len(ordered_buffer)):
		print_debug("This shouldn't happen! Did the server stop running? ", order_diff, " ", new_input.order, " ", len(ordered_buffer))
		var i = (order_diff - len(ordered_buffer)) + 1
		while i > 0:
			self._grab_input()
			i -= 1
		ordered_buffer[-1] = new_input
		return
	else:
		return

func take() -> Dictionary:
	var median_buffer_length = self._get_rolling_median()
	if (median_buffer_length > (self.buffer_size + 2)):
		print("tick speed difference +")
		for i in range(len(rolling_average)):
			rolling_average[i] -= 1
		self._grab_input()
		return self._grab_input()
	elif (median_buffer_length < (self.buffer_size - 2)):
		print("tick speed difference -")
		for i in range(len(rolling_average)):
			rolling_average[i] += 1
		return self.ordered_buffer[0]
	else:
		return self._grab_input()

func _grab_input() -> Dictionary:
	self.ordered_buffer.append(null)
	if self.ordered_buffer[1]:
		return self.ordered_buffer.pop_front()
	else:
		var return_input = self.ordered_buffer.pop_front()
		var copy = return_input.duplicate()
		self.ordered_buffer[0] = copy
		return return_input

func _add_to_rolling_average(new_diff : int) -> void:
	#print("new diff: ", new_diff, " buffer: ", rolling_average)
	self.rolling_average[index] = new_diff
	self.index += 1
	if self.index >= self.rolling_average_size:
		self.index = 0

func _get_rolling_median() -> float:
	var buffer_copy = self.rolling_average.duplicate()
	buffer_copy.sort()
	return buffer_copy[20]
