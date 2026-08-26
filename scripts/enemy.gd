extends CharacterBody3D
class_name Enemy

const CritterVoxelsScript := preload("res://scripts/critter_voxels.gd")

var kind: String = ""
var hp: float = 1.0
var player: Player
var _spec: Dictionary = {}
var _attack_cd: float = 0.0
var _slow: float = 0.0
var _burn: float = 0.0
var _alert: float = 0.0
var _wander_t: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _anim: float = 0.0
var _leg_nodes: Array[Node3D] = []
var _leg_base: Array[Vector3] = []
var _dead: bool = false

@onready var model: Node3D = $Model
@onready var col: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("ennemis")
	collision_layer = 4
	collision_mask = 1 | 2
	floor_snap_length = 0.2
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED


func setup(p_kind: String) -> void:
	kind = p_kind
	if not Game.CREATURES.has(kind):
		kind = "slime"
	_spec = Game.CREATURES[kind]
	hp = float(_spec["hp"])
	if model == null:
		model = get_node("Model")
	if col == null:
		col = get_node("CollisionShape3D")
	CritterVoxelsScript.build(kind, model)
	_cache_legs()
	var box := BoxShape3D.new()
	box.size = _spec["hitbox"]
	col.shape = box
	col.position = Vector3(0.0, box.size.y * 0.5, 0.0)


func is_hostile() -> bool:
	return bool(_spec.get("hostile", true))


func burns_in_sun() -> bool:
	return bool(_spec.get("burns_sun", true))


func look_horizontal(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() < 0.05 or model == null:
		return
	dir = dir.normalized()
	model.rotation.y = atan2(dir.x, dir.z)
	_wander_dir = dir
	_wander_t = 2.4


func take_damage(amount: float) -> void:
	if hp <= 0.0 or amount <= 0.0:
		return
	hp -= amount
	_alert = 6.0
	if hp <= 0.0:
		_die()


func hit(bolt: SpellBolt, mul: float = 1.0) -> void:
	if hp <= 0.0:
		return
	hp -= bolt.damage * mul
	_alert = 6.0
	if bolt.kind == "glace":
		_slow = 2.6
	elif bolt.kind == "foudre":
		_slow = 0.45
	elif bolt.kind == "feu":
		_burn = 1.6
	if hp <= 0.0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	hp = 0.0
	var food := float(_spec.get("faim", 0.0))
	var nom := str(_spec.get("nom", "Créature"))
	if food > 0.0:
		Game.heal_hunger(food)
	if kind == "chevreuil":
		Game.toasted.emit("Viande de chevreuil (+%d faim)" % int(food))
	else:
		Game.toasted.emit("%s terrassé" % nom)
	queue_free()


func _physics_process(delta: float) -> void:
	if kind == "" or _spec.is_empty():
		return
	if player == null or not is_instance_valid(player) or Game.is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return
	if global_position.y < -8.0:
		queue_free()
		return

	_slow = maxf(0.0, _slow - delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_alert = maxf(0.0, _alert - delta)
	if _burn > 0.0:
		_burn -= delta
		hp -= 8.0 * delta
		if hp <= 0.0:
			_die()
			return

	if burns_in_sun() and not Game.is_night:
		hp -= Game.SUN_DPS * delta
		if hp <= 0.0:
			if not Game.dawn_burn_announced:
				Game.dawn_burn_announced = true
				Game.toasted.emit("Les morts brûlent au soleil")
			queue_free()
			return

	_apply_gravity(delta)
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var speed := float(_spec.get("vitesse", 2.4)) * (0.38 if _slow > 0.0 else 1.0)
	var dir := Vector3.ZERO

	if is_hostile():
		var aggro := float(_spec.get("aggro", 14.0))
		if dist < aggro or _alert > 0.0:
			if dist > 0.12:
				dir = to_player.normalized()
		else:
			dir = _wander(delta)
	else:
		var fear := float(_spec.get("aggro", 8.5))
		if dist < fear or _alert > 0.0:
			if dist < 0.15:
				dir = Vector3(1.0, 0.0, 0.0)
			else:
				dir = -to_player.normalized()
			speed *= 1.0 if _alert > 0.0 else 0.92
		else:
			dir = _wander(delta)
			speed *= 0.42

	if dir.length() > 0.08:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		model.rotation.y = atan2(dir.x, dir.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 3.0 * delta)

	if is_hostile():
		var reach := float(_spec.get("portee", 1.5))
		var dmg := float(_spec.get("degats", 0.0))
		if dmg > 0.0 and dist < reach and _attack_cd <= 0.0:
			player.take_hit(dmg)
			_attack_cd = float(_spec.get("cooldown", 1.0))

	_animate_legs(delta, dir.length() > 0.08)
	move_and_slide()
	if is_on_floor() and is_on_wall():
		velocity.y = 4.6


func _wander(delta: float) -> Vector3:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(1.2, 2.8)
		if randf() < 0.35:
			_wander_dir = Vector3.ZERO
		else:
			var a := randf() * TAU
			_wander_dir = Vector3(sin(a), 0.0, cos(a))
	return _wander_dir


func _cache_legs() -> void:
	_leg_nodes.clear()
	_leg_base.clear()
	if model == null:
		return
	for n in model.get_children():
		if str(n.name).begins_with("Leg"):
			_leg_nodes.append(n)
			_leg_base.append(n.position)


func _animate_legs(delta: float, moving: bool) -> void:
	if _leg_nodes.is_empty():
		return
	_anim += delta * (10.0 if moving else 2.0)
	for i in _leg_nodes.size():
		var node := _leg_nodes[i]
		var base := _leg_base[i]
		var phase := 0.0 if i % 2 == 0 else PI
		var bob := sin(_anim + phase) * (0.045 if moving else 0.01)
		node.position = base + Vector3(0.0, bob, 0.0)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
