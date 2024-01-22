extends RefCounted
class_name StateManager

var victim : Node
var managed_states : Array[String]
var state_dictionary : Dictionary = {}

func _init(states : Array[String]):
	self.managed_states = states

func _restore()
