class_name PlayerInputBuffer
extends InputBuffer

func _init(starting_input : PlayerInput=PlayerInput.new(), length : int=4):
	self.set_max_length(length)
	self.buffer.append(starting_input)

func add(new_input : OrderedInput) -> void:
	assert(new_input is PlayerInput, "Error: non-player input placed in PlayerInputBuffer")
	super(new_input)

func _push_out_input() -> void:
	#print("Nothing is happening here!!!!!")
	var one = self.buffer[-1]
	var two = self.buffer[-2]
	
	#two.jumped = (one.jumped or two.jumped)
	two.shot_fired = (one.shot_fired or two.shot_fired)
	
	self.buffer.pop_back()

func take() -> PlayerInput:
	#print("Returning... ", bytes_to_var(buffer[-1].to_byte_array()))
	return super()
