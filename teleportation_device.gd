extends Node3D
class_name TeleportDevice

var detector : HackyArea3D
var victim : TeleportableCharacterBody
var old_position : Vector3 = Vector3(0,0,0)
var active_teleporters : Array[Array] = []
var can_teleport : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	self.victim = get_parent()
	detector = HackyArea3D.new()
	self.add_child(detector)
	self.set_notify_transform(true)
	var game_manager = get_node("/root/game")
	game_manager.before_simulation.connect(_before_simulation)
	game_manager.after_simulation.connect(_after_simulation)


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

func _before_simulation() -> void:
	var teles = self._get_teles()
	for tele in teles:
		self.active_teleporters.append([tele, _get_angle(tele)])


func _after_simulation() -> void:
	for tele in active_teleporters:
		if signf(_get_angle(tele[0])) != signf(tele[1]):
			self.teleport(tele[0])
	self.active_teleporters = []

func _get_teles() -> Array[Teleporter]:
	var bodies = self.detector.get_overlapping_bodies()
	var teles : Array[Teleporter] = []
	for body in bodies:
		if body is Teleporter:
			teles.append(body)
	#if teles and (not multiplayer.is_server()): 
		#print(teles)
	return teles
