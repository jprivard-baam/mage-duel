extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const MAX_CREATURES := 12
const CAPS := {
	"chevreuil": 4,
	"loup": 2,
	"slime": 3,
	"zombie": 3,
	"squelette": 2,
}

@onready var voxel: VoxelWorld = $VoxelMap
@onready var player: Player = $Player
@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var enemies_root: Node3D = $Enemies
@onready var fill_light: DirectionalLight3D = $FillLight

var _spawn_acc := 1.2
var _sky_mat: ProceduralSkyMaterial


func _ready() -> void:
	if not Game.has_class():
		get_tree().change_scene_to_file("res://scenes/home.tscn")
		return
	Game.reset()
	var spawn := voxel.build_world()
	player.global_position = spawn
	var env: Environment = world_env.environment
	if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
		_sky_mat = env.sky.sky_material
	Game.night_changed.connect(_on_night_changed)
	_update_sky()
	_spawn_ahead("chevreuil", 6.8, -0.42)
	_spawn_ahead("chevreuil", 7.6, 0.48)
	_spawn_ahead("loup", 10.5, 0.22)


func _physics_process(delta: float) -> void:
	Game.tick_survival(delta)
	_update_sky()
	if Game.is_dead:
		return
	_spawn_acc += delta
	if Game.is_night:
		if _spawn_acc >= 3.4:
			_spawn_acc = 0.0
			_try_spawn_night()
	elif _spawn_acc >= 6.5:
		_spawn_acc = 0.0
		if randf() < 0.7:
			_try_spawn_kind("chevreuil", 10.0)
		else:
			_try_spawn_kind("loup", 13.0)


func _on_night_changed(night: bool) -> void:
	if night:
		_spawn_acc = 0.0
		_try_spawn_kind("slime", 8.0)
		_try_spawn_kind("zombie", 8.0)
		_try_spawn_kind("zombie", 9.0)
		_try_spawn_kind("squelette", 8.0)
		_try_spawn_kind("slime", 10.0)
		_try_spawn_kind("loup", 12.0)


func _try_spawn_night() -> void:
	var roll := randf()
	if roll < 0.34:
		_try_spawn_kind("zombie", 8.0)
	elif roll < 0.58:
		_try_spawn_kind("slime", 8.0)
	elif roll < 0.82:
		_try_spawn_kind("squelette", 8.0)
	else:
		_try_spawn_kind("loup", 12.0)


func _spawn_ahead(kind: String, dist: float, yaw_off: float) -> void:
	if not is_instance_valid(player):
		return
	var dir := player.facing().rotated(Vector3.UP, yaw_off)
	var hint := player.global_position + dir * dist
	var cell := voxel.world_to_cell(hint)
	var x := clampi(cell.x, 6, VoxelWorld.SIZE - 7)
	var z := clampi(cell.z, 6, VoxelWorld.SIZE - 7)
	var y := voxel.surface_y(x, z)
	if y < 2:
		_try_spawn_kind(kind, dist)
		return
	var pos := Vector3((x + 0.5) * VoxelWorld.CELL, float(y + 1) * VoxelWorld.CELL + 0.12, (z + 0.5) * VoxelWorld.CELL)
	var e: Enemy = ENEMY_SCENE.instantiate()
	enemies_root.add_child(e)
	e.setup(kind)
	e.global_position = pos
	e.player = player
	## Profil 3/4 : pattes, museau, queue visibles depuis la caméra.
	e.look_horizontal(dir.rotated(Vector3.UP, 1.15))


func _count_kind(kind: String) -> int:
	var n := 0
	for node in enemies_root.get_children():
		if node is Enemy and (node as Enemy).kind == kind:
			n += 1
	return n


func _try_spawn_kind(kind: String, min_dist: float) -> bool:
	if enemies_root.get_child_count() >= MAX_CREATURES:
		return false
	if _count_kind(kind) >= int(CAPS.get(kind, 2)):
		return false
	for _i in 18:
		var x := randi_range(6, VoxelWorld.SIZE - 7)
		var z := randi_range(6, VoxelWorld.SIZE - 7)
		var y := voxel.surface_y(x, z)
		if y < 2:
			continue
		var pos := Vector3((x + 0.5) * VoxelWorld.CELL, (y + 1) * VoxelWorld.CELL + 0.12, (z + 0.5) * VoxelWorld.CELL)
		if pos.distance_to(player.global_position) < min_dist:
			continue
		if pos.distance_to(player.global_position) > 28.0:
			continue
		var e: Enemy = ENEMY_SCENE.instantiate()
		enemies_root.add_child(e)
		e.setup(kind)
		e.global_position = pos
		e.player = player
		return true
	return false


func _update_sky() -> void:
	var f := Game.day_factor()
	var t := Game.world_time / Game.DAY_LENGTH
	sun.rotation.x = deg_to_rad(-35.0) - t * TAU
	sun.light_energy = lerpf(0.06, 1.18, f)
	sun.light_color = Color(1.0, 0.93, 0.82).lerp(Color(0.28, 0.34, 0.72), 1.0 - f)
	sun.shadow_enabled = f > 0.35
	fill_light.light_energy = lerpf(0.04, 0.22, f)
	if _sky_mat:
		_sky_mat.sky_top_color = Color(0.30, 0.52, 0.88).lerp(Color(0.03, 0.04, 0.12), 1.0 - f)
		_sky_mat.sky_horizon_color = Color(0.78, 0.72, 0.62).lerp(Color(0.12, 0.08, 0.22), 1.0 - f)
		_sky_mat.ground_bottom_color = Color(0.12, 0.09, 0.06).lerp(Color(0.02, 0.02, 0.05), 1.0 - f)
		_sky_mat.ground_horizon_color = Color(0.42, 0.38, 0.30).lerp(Color(0.08, 0.06, 0.12), 1.0 - f)
		_sky_mat.sun_angle_max = 30.0
	var env: Environment = world_env.environment
	env.ambient_light_energy = lerpf(0.10, 0.48, f)
	env.ambient_light_color = Color(0.62, 0.72, 0.9).lerp(Color(0.18, 0.16, 0.35), 1.0 - f)
	env.fog_light_color = Color(0.58, 0.74, 0.95).lerp(Color(0.04, 0.03, 0.10), 1.0 - f)
	env.fog_density = lerpf(0.010, 0.018, 1.0 - f)
	env.background_energy_multiplier = lerpf(0.22, 1.0, f)
