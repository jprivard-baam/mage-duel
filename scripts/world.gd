extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

@onready var voxel: VoxelWorld = $VoxelMap
@onready var player: Player = $Player
@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var enemies_root: Node3D = $Enemies
@onready var fill_light: DirectionalLight3D = $FillLight

var _spawn_acc := 2.0
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


func _physics_process(delta: float) -> void:
	Game.tick_survival(delta)
	_update_sky()
	if Game.is_dead:
		return
	if Game.is_night:
		_spawn_acc += delta
		if _spawn_acc >= 3.2:
			_spawn_acc = 0.0
			_try_spawn_enemy()


func _on_night_changed(night: bool) -> void:
	if night:
		_spawn_acc = 0.0
		for i in 4:
			_try_spawn_enemy()


func _try_spawn_enemy() -> void:
	if enemies_root.get_child_count() >= 6:
		return
	for _i in 16:
		var x := randi_range(5, VoxelWorld.SIZE - 6)
		var z := randi_range(5, VoxelWorld.SIZE - 6)
		var y := voxel.surface_y(x, z)
		if y < 2:
			continue
		var pos := Vector3((x + 0.5) * VoxelWorld.CELL, (y + 1) * VoxelWorld.CELL + 0.2, (z + 0.5) * VoxelWorld.CELL)
		if pos.distance_to(player.global_position) < 7.0:
			continue
		var e: Enemy = ENEMY_SCENE.instantiate()
		enemies_root.add_child(e)
		e.global_position = pos
		e.player = player
		return


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
