class_name PlayerInputBuffer
extends InputBuffer

func _init(starting_input : PlayerInput=PlayerInput.new(), length : int=4):
	self.set_max_length(length)
	self.buffer.append(starting_input)

func add(new_input : OrderedInput) -> void:
	assert(new_input is PlayerInput, "Error: non-player input placed in PlayerInputBuffer")
	super(new_input)

func _push_out_input() -> void:
	var one = self.buffer[0]
	var two = self.buffer[1]
	
	two.jumped = (one.jumped or two.jumped)
	two.shot_fired = (one.shot_fired or two.shot_fired)
	
	self.buffer.pop_back()

func take() -> PlayerInput:
	return super()
