extends Node
class_name Serializer

static var mandatory_transmits : Array[StringName] = []
static var optional_transmits : Array[StringName] = []

static func _static_init():
	pass

static func serialize(data : Dictionary) -> PackedByteArray:
	var var_array = []
	
	for key in mandatory_transmits:
		if data.has(key):
			var_array.append(data[key])
		else:
			print("Error, can't serialize data due to missing information")
			return PackedByteArray()
		
	var optional_vars = []
	var optional_vars_bits : int = 0
	var i : int = 0
	for key in optional_transmits:
		if data.has(key):
			optional_vars_bits = optional_vars_bits ^ (2**i)
			i += 1
			optional_vars.append(data[key])
		else:
			pass
	var_array.append(optional_vars_bits)
	var_array += optional_vars
	#print("Var_array: ", var_array, " Optional vars: ", optional_vars, " Bit-field: ", optional_vars_bits)
	return var_to_bytes(var_array)

static func interpret_deserialized_packet(packet : Array) -> Dictionary:
	#print("packet: ", packet)
	var new_data : Dictionary = {}
	var index : int = 0
	
	for key in mandatory_transmits:
		new_data[key] = packet[index]
		index += 1
	
	var optional_var_bits = packet[index]
	index += 1
	var i = 0
	var included_keys := []
	for key in optional_transmits:
		if optional_var_bits & (2**i):
			included_keys.append(key)
		i += 1
	
	
	for key in included_keys:
		new_data[key] = packet[index]
		index += 1
	
	return new_data
