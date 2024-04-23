extends Serializer
class_name ClientSerializer

static func _static_init():
	mandatory_transmits = ["is_shooting", "is_jumping"]
	optional_transmits = ["speed_input", "steering_input"]
