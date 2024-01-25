extends Node3D
class_name TeleportDevice

var victim : TeleportableCharacterBody
var active_teleporters : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	self.victim = get_parent()
	victim.teleporter_entered.connect(_on_teleporter_entered)
	victim.teleporter_exited.connect(_on_teleporter_exited)
	self.set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		self._on_movement()

func _on_teleporter_entered(tele : Teleporter) -> void:
	if not (self.active_teleporters.has(tele)):
		#print(active_teleporters)
		#print("tele added")
		self.active_teleporters[tele] = self._get_current_angle(tele)
	
func _on_teleporter_exited(tele : Teleporter) -> void:
	#print("teleporter removed")
	active_teleporters.erase(tele)

func _on_movement() -> void:
	for tele in self.active_teleporters.keys():
		if signf(active_teleporters[tele]) != signf(_get_current_angle(tele)):
			self.teleport(tele)
			self.active_teleporters.erase(tele)

func _get_current_angle(tele : Teleporter) -> float:
	var own_position = self.global_position - tele.global_position
	var tele_basis = tele.global_transform.basis.x
	return own_position.signed_angle_to(tele_basis, Vector3(0,1,0))

func teleport(tele : Teleporter) -> void:
	#print("active teleporters: ", active_teleporters)
	#print("teleporting!")
	#if victim is TankInterface:
		#%tele.play()
	var new = tele.teleport_transform(victim.global_transform, victim.velocity)
	victim.global_transform = new[0]
	victim.velocity = new[1]
