class_name CritterVoxels
extends RefCounted

## Silhouettes en cubes (même langage visuel que le terrain voxel).


static func build(kind: String, parent: Node3D) -> void:
	for child in parent.get_children():
		child.queue_free()
	match kind:
		"loup":
			_wolf(parent)
		"chevreuil":
			_deer(parent)
		"zombie":
			_zombie(parent)
		"squelette":
			_skeleton(parent)
		_:
			_slime(parent)


static func cube(parent: Node3D, nom: String, pos: Vector3, size: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nom
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mat.metallic = 0.0
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func _wolf(p: Node3D) -> void:
	var fur := Color(0.34, 0.26, 0.18)
	var dark := Color(0.16, 0.11, 0.08)
	var light := Color(0.52, 0.42, 0.32)
	var black := Color(0.07, 0.05, 0.04)
	cube(p, "Body", Vector3(0, 0.40, 0.02), Vector3(0.36, 0.30, 0.56), fur)
	cube(p, "Chest", Vector3(0, 0.42, 0.18), Vector3(0.40, 0.32, 0.22), fur)
	cube(p, "Head", Vector3(0, 0.50, 0.38), Vector3(0.26, 0.24, 0.26), fur)
	cube(p, "Snout", Vector3(0, 0.42, 0.56), Vector3(0.15, 0.13, 0.22), light)
	cube(p, "Nose", Vector3(0, 0.42, 0.68), Vector3(0.08, 0.07, 0.07), black)
	cube(p, "EarL", Vector3(-0.09, 0.68, 0.34), Vector3(0.08, 0.16, 0.08), dark)
	cube(p, "EarR", Vector3(0.09, 0.68, 0.34), Vector3(0.08, 0.16, 0.08), dark)
	cube(p, "EyeL", Vector3(-0.08, 0.54, 0.50), Vector3(0.05, 0.05, 0.04), Color(0.88, 0.58, 0.12), 1.4)
	cube(p, "EyeR", Vector3(0.08, 0.54, 0.50), Vector3(0.05, 0.05, 0.04), Color(0.88, 0.58, 0.12), 1.4)
	cube(p, "LegFL", Vector3(-0.13, 0.16, 0.18), Vector3(0.10, 0.32, 0.10), dark)
	cube(p, "LegFR", Vector3(0.13, 0.16, 0.18), Vector3(0.10, 0.32, 0.10), dark)
	cube(p, "LegBL", Vector3(-0.13, 0.16, -0.18), Vector3(0.10, 0.32, 0.10), dark)
	cube(p, "LegBR", Vector3(0.13, 0.16, -0.18), Vector3(0.10, 0.32, 0.10), dark)
	cube(p, "Tail", Vector3(0, 0.48, -0.38), Vector3(0.09, 0.09, 0.32), dark)


static func _deer(p: Node3D) -> void:
	var coat := Color(0.56, 0.36, 0.16)
	var belly := Color(0.82, 0.72, 0.52)
	var dark := Color(0.28, 0.16, 0.08)
	var bone := Color(0.55, 0.42, 0.28)
	var white := Color(0.93, 0.90, 0.84)
	cube(p, "Body", Vector3(0, 0.58, 0.0), Vector3(0.30, 0.26, 0.52), coat)
	cube(p, "Belly", Vector3(0, 0.48, 0.0), Vector3(0.24, 0.12, 0.40), belly)
	cube(p, "Neck", Vector3(0, 0.78, 0.22), Vector3(0.14, 0.28, 0.14), coat)
	cube(p, "Head", Vector3(0, 0.92, 0.32), Vector3(0.18, 0.16, 0.20), coat)
	cube(p, "Snout", Vector3(0, 0.88, 0.46), Vector3(0.10, 0.10, 0.16), belly)
	cube(p, "EarL", Vector3(-0.10, 1.04, 0.28), Vector3(0.07, 0.12, 0.06), dark)
	cube(p, "EarR", Vector3(0.10, 1.04, 0.28), Vector3(0.07, 0.12, 0.06), dark)
	cube(p, "AntlerL", Vector3(-0.08, 1.14, 0.28), Vector3(0.06, 0.22, 0.06), bone)
	cube(p, "AntlerL2", Vector3(-0.16, 1.20, 0.28), Vector3(0.14, 0.05, 0.05), bone)
	cube(p, "AntlerR", Vector3(0.08, 1.14, 0.28), Vector3(0.06, 0.22, 0.06), bone)
	cube(p, "AntlerR2", Vector3(0.16, 1.20, 0.28), Vector3(0.14, 0.05, 0.05), bone)
	cube(p, "LegFL", Vector3(-0.10, 0.24, 0.16), Vector3(0.08, 0.48, 0.08), dark)
	cube(p, "LegFR", Vector3(0.10, 0.24, 0.16), Vector3(0.08, 0.48, 0.08), dark)
	cube(p, "LegBL", Vector3(-0.10, 0.24, -0.16), Vector3(0.08, 0.48, 0.08), dark)
	cube(p, "LegBR", Vector3(0.10, 0.24, -0.16), Vector3(0.08, 0.48, 0.08), dark)
	cube(p, "Tail", Vector3(0, 0.62, -0.30), Vector3(0.08, 0.10, 0.10), white)


static func _zombie(p: Node3D) -> void:
	var flesh := Color(0.38, 0.46, 0.22)
	var rot := Color(0.22, 0.14, 0.08)
	var cloth := Color(0.28, 0.24, 0.18)
	var bone := Color(0.62, 0.58, 0.42)
	cube(p, "Torso", Vector3(0.02, 0.78, 0.0), Vector3(0.42, 0.48, 0.26), flesh)
	cube(p, "RotPatch", Vector3(-0.08, 0.70, 0.12), Vector3(0.16, 0.18, 0.10), rot)
	cube(p, "Hips", Vector3(0, 0.48, 0.0), Vector3(0.36, 0.18, 0.24), cloth)
	cube(p, "Head", Vector3(0.04, 1.14, 0.02), Vector3(0.26, 0.26, 0.26), flesh)
	cube(p, "Jaw", Vector3(0.04, 1.02, 0.10), Vector3(0.16, 0.08, 0.12), bone)
	cube(p, "EyeL", Vector3(-0.05, 1.18, 0.14), Vector3(0.06, 0.05, 0.04), Color(0.72, 0.85, 0.18), 0.7)
	cube(p, "EyeR", Vector3(0.12, 1.16, 0.14), Vector3(0.05, 0.04, 0.04), Color(0.45, 0.12, 0.08), 0.2)
	cube(p, "ArmL", Vector3(-0.32, 0.62, 0.04), Vector3(0.12, 0.52, 0.12), flesh)
	cube(p, "ArmR", Vector3(0.34, 0.78, 0.02), Vector3(0.12, 0.22, 0.12), flesh)
	cube(p, "Stump", Vector3(0.34, 0.62, 0.02), Vector3(0.10, 0.10, 0.10), bone)
	cube(p, "LegFL", Vector3(-0.12, 0.22, 0.02), Vector3(0.14, 0.44, 0.14), cloth)
	cube(p, "LegFR", Vector3(0.12, 0.18, -0.02), Vector3(0.14, 0.36, 0.14), rot)


static func _skeleton(p: Node3D) -> void:
	var bone := Color(0.86, 0.82, 0.66)
	var dark := Color(0.08, 0.07, 0.06)
	var iron := Color(0.52, 0.55, 0.60)
	var leather := Color(0.28, 0.16, 0.08)
	cube(p, "Pelvis", Vector3(0, 0.58, 0.0), Vector3(0.28, 0.12, 0.16), bone)
	cube(p, "Spine", Vector3(0, 0.82, 0.0), Vector3(0.10, 0.38, 0.10), bone)
	cube(p, "Ribs", Vector3(0, 0.88, 0.0), Vector3(0.34, 0.22, 0.16), bone)
	cube(p, "Skull", Vector3(0, 1.18, 0.02), Vector3(0.24, 0.24, 0.24), bone)
	cube(p, "SocketL", Vector3(-0.06, 1.20, 0.13), Vector3(0.07, 0.07, 0.04), dark)
	cube(p, "SocketR", Vector3(0.06, 1.20, 0.13), Vector3(0.07, 0.07, 0.04), dark)
	cube(p, "ArmL", Vector3(-0.24, 0.78, 0.0), Vector3(0.08, 0.46, 0.08), bone)
	cube(p, "ArmR", Vector3(0.24, 0.78, 0.10), Vector3(0.08, 0.42, 0.08), bone)
	cube(p, "LegFL", Vector3(-0.10, 0.26, 0.0), Vector3(0.09, 0.50, 0.09), bone)
	cube(p, "LegFR", Vector3(0.10, 0.26, 0.0), Vector3(0.09, 0.50, 0.09), bone)
	cube(p, "Handle", Vector3(0.28, 0.52, 0.18), Vector3(0.07, 0.07, 0.16), leather)
	cube(p, "Guard", Vector3(0.28, 0.52, 0.28), Vector3(0.18, 0.06, 0.06), iron)
	cube(p, "Sword", Vector3(0.28, 0.52, 0.56), Vector3(0.07, 0.07, 0.52), iron)


static func _slime(p: Node3D) -> void:
	var goo := Color(0.18, 0.58, 0.26)
	var dark := Color(0.08, 0.28, 0.12)
	cube(p, "Body", Vector3(0, 0.32, 0.0), Vector3(0.64, 0.52, 0.64), goo, 0.25)
	cube(p, "Blob", Vector3(0.08, 0.58, 0.04), Vector3(0.36, 0.22, 0.36), goo, 0.35)
	cube(p, "EyeL", Vector3(-0.14, 0.42, 0.30), Vector3(0.12, 0.12, 0.08), Color(0.95, 0.95, 0.7), 1.6)
	cube(p, "EyeR", Vector3(0.14, 0.42, 0.30), Vector3(0.12, 0.12, 0.08), Color(0.95, 0.95, 0.7), 1.6)
	cube(p, "PupilL", Vector3(-0.14, 0.42, 0.35), Vector3(0.05, 0.05, 0.03), dark)
	cube(p, "PupilR", Vector3(0.14, 0.42, 0.35), Vector3(0.05, 0.05, 0.03), dark)
