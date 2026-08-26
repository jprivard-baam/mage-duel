extends CharacterBody3D
class_name Player

const SPEED := 3.35
const JUMP_VELOCITY := 6.3
const LOOK_SENS := 0.22
const PITCH_MIN := -1.15
const PITCH_MAX := 0.42
const CHOP_RANGE := 5.0
const STRIKE_RANGE := 1.95
const STRIKE_DAMAGE := 22.0
const STRIKE_CD := 0.48

@onready var model: Node3D = $Model
@onready var cam_pivot: Node3D = $CamPivot
@onready var camera: Camera3D = $CamPivot/SpringArm/Camera3D

var _look_yaw := 0.0
var _look_pitch := -0.28
var _look_touch_id := -1
var _hit_flash := 0.0
var _chop_cd := 0.0
var _strike_cd := 0.0
var _voxel: VoxelWorld

const SPELL_SCENE := preload("res://scenes/spell.tscn")


func _ready() -> void:
	floor_snap_length = 0.12
	floor_max_angle = deg_to_rad(50.0)
	collision_layer = 2
	collision_mask = 1 | 4
	cam_pivot.rotation.x = _look_pitch
	camera.current = true
	_voxel = get_tree().get_first_node_in_group("voxel_world") as VoxelWorld
	_apply_class_look()
	_face_look()


func facing() -> Vector3:
	return Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, _look_yaw)


func _apply_class_look() -> void:
	var robe := Game.class_robe()
	var tip := Game.class_couleur()
	for path in ["Model/Body", "Model/ArmL", "Model/ArmR"]:
		var mesh := get_node_or_null(path) as MeshInstance3D
		if mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = robe
			mat.roughness = 0.62
			mesh.material_override = mat
	var hat_tip := get_node_or_null("Model/HatTip") as MeshInstance3D
	if hat_tip:
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = tip
		tmat.emission_enabled = true
		tmat.emission = tip
		tmat.emission_energy_multiplier = 0.8
		hat_tip.material_override = tmat


func _face_look() -> void:
	model.rotation.y = _look_yaw
	cam_pivot.rotation.y = _look_yaw
	cam_pivot.rotation.x = _look_pitch


func _unhandled_input(event: InputEvent) -> void:
	if Game.is_dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			Game.queue_cast()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F:
			Game.queue_strike()
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _is_look_region(st.position) and _look_touch_id < 0:
				_look_touch_id = st.index
				get_viewport().set_input_as_handled()
		elif st.index == _look_touch_id:
			_look_touch_id = -1
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _look_touch_id or (_look_touch_id < 0 and _is_look_region(sd.position)):
			if _look_touch_id < 0:
				_look_touch_id = sd.index
			_apply_look(sd.relative)
			get_viewport().set_input_as_handled()


func _is_look_region(pos: Vector2) -> bool:
	var vp := get_viewport().get_visible_rect().size
	if pos.x < vp.x * 0.42:
		return false
	if pos.y > vp.y - 160.0:
		return false
	return true


func _apply_look(relative: Vector2) -> void:
	_look_yaw -= relative.x * LOOK_SENS * 0.015
	_look_pitch -= relative.y * LOOK_SENS * 0.015
	_look_pitch = clampf(_look_pitch, PITCH_MIN, PITCH_MAX)
	_face_look()


func _physics_process(delta: float) -> void:
	if Game.is_dead:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if global_position.y < -6.0:
		Game.apply_damage(999.0)
		return

	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= g * delta

	var stick := Game.move_stick
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		stick.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		stick.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		stick.y += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		stick.y -= 1.0
	if stick.length() > 1.0:
		stick = stick.normalized()

	var jump := Game.jump_queued or Input.is_physical_key_pressed(KEY_SPACE)
	Game.jump_queued = false
	if jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var fwd := facing()
	var right := Vector3(1.0, 0.0, 0.0).rotated(Vector3.UP, _look_yaw)
	var wish := right * stick.x + fwd * stick.y
	if wish.length() > 0.08:
		wish = wish.normalized()
		velocity.x = wish.x * SPEED
		velocity.z = wish.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 4.0 * delta)

	_face_look()
	move_and_slide()

	_chop_cd = maxf(0.0, _chop_cd - delta)
	_strike_cd = maxf(0.0, _strike_cd - delta)
	_update_targets()
	if Game.strike_queued:
		Game.strike_queued = false
		_try_strike()
	if Game.cast_queued:
		Game.cast_queued = false
		_cast_class_spell()

	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)


func _update_targets() -> void:
	Game.can_chop = false
	Game.can_strike = false
	var origin := global_position + Vector3(0.0, 1.05, 0.0)
	var face := facing()
	if _voxel:
		var cell := _voxel.raycast_tree(origin, face, CHOP_RANGE)
		Game.can_chop = cell.x >= 0
	for node in get_tree().get_nodes_in_group("ennemis"):
		if node is Enemy and is_instance_valid(node):
			var to: Vector3 = (node as Enemy).global_position - global_position
			to.y = 0.0
			if to.length() <= STRIKE_RANGE and to.normalized().dot(face) > 0.12:
				Game.can_strike = true
				break


func _try_strike() -> void:
	if _strike_cd > 0.0 or Game.is_dead:
		return
	_strike_cd = STRIKE_CD
	var face := facing()
	var hit_any := false
	for node in get_tree().get_nodes_in_group("ennemis"):
		if not (node is Enemy) or not is_instance_valid(node):
			continue
		var enemy := node as Enemy
		var to := enemy.global_position - global_position
		to.y = 0.0
		if to.length() <= STRIKE_RANGE and to.normalized().dot(face) > 0.12:
			enemy.take_damage(STRIKE_DAMAGE)
			hit_any = true
	if hit_any:
		return
	_try_chop()


func _try_chop() -> void:
	if _voxel == null or _chop_cd > 0.0 or Game.is_dead:
		return
	var origin := global_position + Vector3(0.0, 1.05, 0.0)
	var cell := _voxel.raycast_tree(origin, facing(), CHOP_RANGE)
	if cell.x < 0:
		Game.toasted.emit("Rien à frapper")
		return
	var gained := _voxel.chop_tree_at(cell)
	_chop_cd = 0.35
	if gained <= 0:
		Game.toasted.emit("Rien à frapper")
		return
	Game.add_bois(gained)
	Game.toasted.emit("Bois +%d" % gained)


func _cast_class_spell() -> void:
	if not Game.has_class():
		return
	var kind := Game.player_class
	if not Game.SPELLS.has(kind):
		return
	var spec: Dictionary = Game.SPELLS[kind]
	if not Game.try_spend_mana(float(spec["cout"])):
		Game.toasted.emit("Pas assez de mana")
		return
	var look := facing()
	var origin := global_position + Vector3(0.0, 1.05, 0.0) + look * 0.55
	var bolt: SpellBolt = SPELL_SCENE.instantiate()
	get_tree().current_scene.add_child(bolt)
	bolt.setup(kind, spec, origin, look)


func take_hit(amount: float) -> void:
	_hit_flash = 0.18
	Game.apply_damage(amount)
