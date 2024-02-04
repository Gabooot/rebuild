extends Node3D
class_name TeleportDevice

var detector : HackyArea3D
var victim : TeleportableCharacterBody
var active_teleporters : Dictionary = {}
var old_position : Vector3 = Vector3(0,0,0)
var old_teles : Array[Teleporter] = []
var can_teleport : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	self.victim = get_parent()
	detector = HackyArea3D.new()
	self.add_child(detector)
	self.set_notify_transform(true)
	get_node("/root/game").establish_state.connect(_on_establish_state)

func _notification(what):
	if not self.can_teleport:
		print("Stopped")
	if (what == NOTIFICATION_TRANSFORM_CHANGED) and self.can_teleport:
		pass
		#self._on_movement()

func _on_movement() -> void:
	var bodies = self.detector.get_overlapping_bodies()
	var teles = []
	for body in bodies:
		if body is Teleporter:
			teles.append(body)
	
	for tele in teles:
		if signf(_get_angle(tele, self.old_position)) != signf(_get_angle(tele)):
			print("Teleporting based on: ", old_position, " ", self.global_position, " victim: ", self.victim)
			self.can_teleport = false
			self.teleport(tele)

func _get_angle(tele : Teleporter, own_position : Vector3=self.global_position) -> float:
	var position_delta  := own_position - tele.global_position
	var tele_basis := tele.global_transform.basis.x
	return position_delta.signed_angle_to(tele_basis, Vector3(0,1,0))

func teleport(tele : Teleporter) -> void:
	#print("active teleporters: ", active_teleporters)
	#print("teleporting!")
	#if victim is TankInterface:
		#%tele.play()
	var new = tele.teleport_transform(victim.global_transform, victim.velocity)
	victim.global_transform = new[0]
	victim.velocity = new[1]

func _on_establish_state() -> void:
	if self.can_teleport:
		self._check_for_teleportation(self.old_teles)
	else:
		self.can_teleport = true
	
	self.old_teles = _get_teles()
	self.old_position = self.global_position

func _get_teles() -> Array[Teleporter]:
	var bodies = self.detector.get_overlapping_bodies()
	var teles : Array[Teleporter] = []
	for body in bodies:
		if body is Teleporter:
			teles.append(body)
	if len(teles) > 1:
		print("bad things happening")
	return teles

func _check_for_teleportation(teles : Array[Teleporter]) -> void:
	for tele in teles:
		if signf(_get_angle(tele, self.old_position)) != signf(_get_angle(tele)):
			#print("Teleporting based on: ", old_position, " ", self.global_position, " victim: ", self.victim)
			self.can_teleport = false
			self.teleport(tele)
