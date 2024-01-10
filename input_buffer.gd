extends RefCounted
class_name InputBuffer

var max_length : int 
var buffer : Array = []
var start_index : int = 0 

#asdfasdfasdf
func _init(starting_input : OrderedInput, length : int = 4):
	self.set_max_length(length)

func set_max_length(length : int) -> void:
	self.max_length = length

func add(new_input : OrderedInput) -> void:
	if new_input.order < self.buffer[-1].order:
		return
	else:
		self.buffer.append(new_input)
		self.buffer.sort_custom(func(a:OrderedInput, b:OrderedInput): return a.order > b.order)
		if len(self.buffer) > self.max_length:
			self.buffer.pop_back()
		

func take() -> OrderedInput:
	return self.buffer[-1]

