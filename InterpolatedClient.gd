extends SimulatedClient
class_name InterpolatedClient

var latest_reliable_tick : int = 0
var latest_reliable_state : Transform3D

func _ready():
	game_manager.simulate.connect(_on_simulate)

func update_state(state_dict : Dictionary) -> void:
	super(state_dict)
	var update_tick = state_dict.order
	if update_tick > self.latest_reliable_tick:
		self.latest_reliable_tick = update_tick
		if state_dict.has("global_transform"):
			self.latest_reliable_state = state_dict.global_transform

func _on_simulate() -> void:
	super()
	
	if latest_reliable_state:
		victim.global_transform = victim.global_transform.interpolate_with(latest_reliable_state, 0.3)
