extends Node
class_name StateManager

@onready var game_manager = get_node("/root/game")
var victim : Node
var managed_states : Array[String]
var state_dictionary : Dictionary = {}
var start_tick : int = 0
var end_tick : int = 9999999999

func _init(new_victim : Node,states : Array[String],current_tick : int = 0):
	self.victim = new_victim
	self.managed_states = states
	#print("Start tick on start: ", current_tick)
	self.start_tick = current_tick
	self.preserve(current_tick)

func _ready():
	game_manager.restore.connect(_restore)
	game_manager.preserve.connect(preserve)

func _restore(tick_num : int) -> void:
	if tick_num < start_tick:
		#print("Restoring to: ", tick_num, " Starting tick: ", start_tick)
		victim.queue_free()
		return
	elif tick_num in state_dictionary:
		var preserved_state = state_dictionary[tick_num]
		#print("Restoring to: ", tick_num, " position: ", preserved_state.global_position, " velocity: ", preserved_state.velocity)
		for property in preserved_state.keys():
			victim.set(property, preserved_state[property])
	else:
		var i = start_tick
		self._restore(i)
		while not (i in state_dictionary):
			i += 1
			victim.simulate()
			preserve(i)

func preserve(tick_num : int) -> void:
	var new_record = {}
	for state in self.managed_states:
		var new_var = victim.get(state)
		if (new_var is Array) or (new_var is Dictionary):
			new_record[state] = new_var.duplicate(true) 
		else:
			new_record[state] = victim.get(state)
	#print("Recorded ", tick_num, " at: ", new_record.global_position)
	self.state_dictionary[tick_num] = new_record
