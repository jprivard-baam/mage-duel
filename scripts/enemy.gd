extends CharacterBody3D
class_name Enemy

const SPEED := 3.35
const ATTACK_RANGE := 1.55
const ATTACK_DAMAGE := 11.0
const ATTACK_COOLDOWN := 0.95
const SUN_DPS := 18.0

var hp: float = 52.0
var player: Player
var _attack_cd: float = 0.0
var _slow: float = 0.0
var _burn: float = 0.0

@onready var model: MeshInstance3D = $Model
@onready var eyes: MeshInstance3D = $Eyes


func _ready() -> void:
	add_to_group("ennemis")
	collision_layer = 4
	collision_mask = 1 | 2
	floor_snap_length = 0.2
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED


func hit(bolt: SpellBolt, mul: float = 1.0) -> void:
	if hp <= 0.0:
		return
	hp -= bolt.damage * mul
	if bolt.kind == "glace":
		_slow = 2.6
	elif bolt.kind == "foudre":
		_slow = 0.45
	elif bolt.kind == "feu":
		_burn = 1.6
	if hp <= 0.0:
		_die()


func _die() -> void:
	Game.heal_hunger(16.0)
	Game.toasted.emit("Essence cubique")
	queue_free()


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or Game.is_dead:
		velocity.x = 0
		velocity.z = 0
		_apply_gravity(delta)
		move_and_slide()
		return
	if global_position.y < -8.0:
		queue_free()
		return

	_slow = maxf(0.0, _slow - delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	if _burn > 0.0:
		_burn -= delta
		hp -= 8.0 * delta
		if hp <= 0.0:
			_die()
			return

	if not Game.is_night:
		hp -= SUN_DPS * delta
		if hp <= 0.0:
			Game.toasted.emit("Les cubes brûlent au soleil")
			queue_free()
			return

	_apply_gravity(delta)
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var speed := SPEED * (0.38 if _slow > 0.0 else 1.0)
	if dist > 0.15:
		var dir := to_player.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		model.rotation.y = atan2(dir.x, dir.z)
		eyes.rotation.y = model.rotation.y
	if dist < ATTACK_RANGE and _attack_cd <= 0.0:
		player.take_hit(ATTACK_DAMAGE)
		_attack_cd = ATTACK_COOLDOWN
	move_and_slide()
	if is_on_floor() and is_on_wall():
		velocity.y = 5.2


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
