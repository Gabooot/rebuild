extends RefCounted

var result : Bullet 
var synchronizer : SynchronizationManager

func _init(synchronization_manager : SynchronizationManager, transform : Transform3D, velocity : Vector3) -> void:
	self.synchronizer = synchronization_manager
	self.synchronizer.register_network_action(self)
	result = self.perform(transform, velocity)


func perform(transform : Transform3D, velocity : Vector3) -> Bullet:
	var bullet_data = NetworkObjects.create("bullet", "simulated client", -1)
	synchronizer.register_network_interface(bullet_data.pop_back(), -1)
	return bullet_data.pop_back()


func restore(old_state : Bullet = result) -> void:
	old_state.queue_free()
