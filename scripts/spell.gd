extends Area3D
class_name SpellBolt

var kind: String = "feu"
var damage: float = 20.0
var velocity: Vector3 = Vector3.ZERO
var life: float = 2.4
var _exploded: bool = false


func setup(p_kind: String, spec: Dictionary, origin: Vector3, dir: Vector3) -> void:
	kind = p_kind
	damage = float(spec["degats"])
	var col: Color = spec["couleur"]
	var radius := float(spec["rayon"])
	global_position = origin
	velocity = dir.normalized() * float(spec["vitesse"])
	collision_layer = 8
	collision_mask = 1 | 4
	monitorable = true
	monitoring = true
	var shape := SphereShape3D.new()
	shape.radius = radius
	$CollisionShape3D.shape = shape
	var mesh: SphereMesh = $MeshInstance3D.mesh
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	$MeshInstance3D.material_override = mat
	$OmniLight3D.light_color = col
	$OmniLight3D.light_energy = 1.6
	$OmniLight3D.omni_range = 4.5
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	global_position += velocity * delta
	life -= delta
	rotate_y(delta * 8.0)
	if kind == "foudre":
		global_position.y += sin(life * 40.0) * 0.01
	if life <= 0.0:
		_explode(false)


func _on_body_entered(body: Node) -> void:
	if _exploded:
		return
	if body is Player:
		return
	if body is Enemy:
		(body as Enemy).hit(self)
		_explode(true)
		return
	_explode(kind == "feu")


func _on_area_entered(area: Area3D) -> void:
	if _exploded:
		return
	var p := area.get_parent()
	if p is Enemy:
		(p as Enemy).hit(self)
		_explode(true)


func _explode(aoe: bool) -> void:
	if _exploded:
		return
	_exploded = true
	if aoe and kind == "feu":
		for node in get_tree().get_nodes_in_group("ennemis"):
			if node is Enemy and global_position.distance_to(node.global_position) < 2.2:
				(node as Enemy).hit(self, 0.45)
	queue_free()
