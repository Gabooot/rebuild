extends RefCounted
class_name InputBuffer

var max_length : int 
var buffer : Array[Dictionary] = []

func _init(starting_input : Dictionary, length : int = 4):
	self.set_max_length(length)
	self.buffer.append(starting_input)

func set_max_length(length : int) -> void:
	self.max_length = length

func add(new_input : Dictionary) -> void:
	if new_input.order < self.buffer[-1].order:
		return
	else:
		self.buffer.append(new_input)
		#self.buffer.sort_custom(func(a:OrderedInput, b:OrderedInput): return a.order > b.order)
		
		if len(self.buffer) > self.max_length:
			self._push_out_input()
		

func _push_out_input() -> void:
	self.buffer[-2].shot_fired = (self.buffer[-1].shot_fired or self.buffer[-2].shot_fired)
	self.buffer.pop_back()


func take() -> Dictionary:
	return self.buffer[-1]

