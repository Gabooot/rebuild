extends Node
class_name NetworkInterface

@onready var game_manager = get_node("/root/game")

var state_manager : StateManager 
var victim : Node
var state_properties : Array[StringName]
var input_properties : Array[StringName]
var can_resimulate : bool = false
var id : int = -1

# Called when the node enters the scene tree for the first time.
#func _ready():
	#self.initialize()
	#game_manager.establish_state.connect("send_state")

func _init(victim : Node, state_properties : Array[StringName], input_properties : Array[StringName]) -> void:
	self.victim = victim
	self.state_properties = state_properties
	self.input_properties = input_properties
	self.state_manager = StateManager.new(victim, (state_properties + input_properties))
	self.add_child(state_manager)
	victim.add_child(self)


func initialize() -> void:
	self.victim = get_parent().get_parent()

func update_state(state_dict : Dictionary) -> void:
	state_manager.set_state(state_dict)
	var current_state = state_manager.get_state()

func get_state() -> Variant:
	return state_manager.get_state()

