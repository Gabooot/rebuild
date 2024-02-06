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
	#self.preserve(current_tick)


func _ready():
	game_manager.restore.connect(_restore)
	game_manager.preserve.connect(preserve)
	self.preserve(start_tick)


func _restore(tick_num : int) -> void:
	
	if tick_num <= start_tick:
		victim.queue_free()
		return
	elif tick_num in state_dictionary:
		set_state(state_dictionary[tick_num])
		if "global_transform" in managed_states:
			victim.force_update_transform()
	else:
		pass
		'''var i = start_tick
		self._restore(i)
		while not (i in state_dictionary):
			i += 1
			victim.simulate()
			preserve(i)'''


func preserve(tick_num : int=game_manager.active_tick, new_record : Dictionary=self.get_state()) -> void:
	self.state_dictionary[tick_num] = new_record
	
	var ticks = state_dictionary.keys()
	for tick in ticks:
		if (game_manager.current_tick - tick) > 20:
			state_dictionary.erase(tick)


func set_state(state_dictionary : Dictionary) -> void:
	for property in state_dictionary.keys():
			victim.set(property, state_dictionary[property])


func get_state() -> Dictionary:
	var new_record = {}
	
	for state in self.managed_states:
		var new_var = victim.get(state)
		if (new_var is Array) or (new_var is Dictionary):
			new_record[state] = new_var.duplicate(true) 
		else:
			new_record[state] = victim.get(state)
	
	return new_record
