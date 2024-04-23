extends Node
class_name StateManager

@onready var game_manager = get_node("/root/game")
var victim : Node
var managed_states : Array[StringName]
var state_dictionary : Dictionary = {}
var start_tick : int = 0
var end_tick : int = 9999999999


func _init(new_victim : Node, states : Array[StringName],current_tick : int = 0):
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
		print_debug("restoring to nothing!")
		pass
		'''var i = start_tick
		self._restore(i)
		while not (i in state_dictionary):
			i += 1
			victim.simulate()
			preserve(i)'''


func preserve(tick_num : int=game_manager.active_tick, new_record : Dictionary=self.get_state()) -> void:
	var current_record = state_dictionary.get(tick_num)
	
	if current_record:
		self.state_dictionary[tick_num].merge(new_record, true)
	else:
		self.state_dictionary[tick_num] = new_record
	
	#TODO move to _physics_process()
	var ticks = state_dictionary.keys()
	for tick in ticks:
		if (game_manager.current_tick - tick) > Shared.num_states_stored:
			state_dictionary.erase(tick)


func set_state(state_dictionary : Dictionary) -> void:
	for key in state_dictionary.keys():
		var property = state_dictionary[key]
		if not (property is Array):
			victim.set(key, property)
		else:
			victim.set(key, property.duplicate())


func get_state(property_list : Array[StringName]=self.managed_states) -> Dictionary:
	var new_record = {}
	
	for property in property_list:
		var new_var = victim.get(property)
		if (new_var is Array) or (new_var is Dictionary):
			new_record[property] = new_var.duplicate(true) 
		else:
			new_record[property] = new_var
	
	return new_record
