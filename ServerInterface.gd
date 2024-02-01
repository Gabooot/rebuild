extends NetworkInterface
class_name ServerInterface


func _ready():
	self.initialize()

func update_state(state_dict : Dictionary) -> void:
	super(state_dict)
	game_manager.queue_for_output(state_manager.get_state())

func _on_simulate() -> void:
	self.victim.simulate()
