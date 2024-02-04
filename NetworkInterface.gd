extends Node
class_name NetworkInterface

@onready var game_manager = get_node("/root/game")
@onready var state_manager : StateManager = get_parent()
var victim : Node
var remote_properties : Array[String]
var transmitting_properties : Array[String]
var can_resimulate : bool = false
var id : int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	self.initialize()
	#game_manager.establish_state.connect("send_state")

func initialize() -> void:
	self.victim = get_parent().get_parent()

func update_state(state_dict : Dictionary) -> void:
	state_manager.set_state(state_dict)
	var current_state = state_manager.get_state()

func get_state() -> Variant:
	return state_manager.get_state()

