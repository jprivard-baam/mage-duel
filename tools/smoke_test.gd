extends SceneTree

func _init() -> void:
	var failed: PackedStringArray = PackedStringArray()
	var game_script: GDScript = load("res://autoload/game.gd")
	var game: Node = game_script.new()
	game.reset()
	var voxel := VoxelWorld.new()
	voxel._ready()
	var spawn: Vector3 = voxel.build_world()
	if voxel.count_solids() < 800:
		failed.append("monde trop vide (%d solides)" % voxel.count_solids())
	if spawn.y < 0.5:
		failed.append("spawn sous le terrain %s" % spawn)
	if VoxelWorld.SIZE != 96:
		failed.append("SIZE devrait être 96")
	if not is_equal_approx(VoxelWorld.CELL, 0.5):
		failed.append("CELL devrait être 0.5")
	var tree_cell := Vector3i(-1, -1, -1)
	for z in range(10, VoxelWorld.SIZE - 10):
		for x in range(10, VoxelWorld.SIZE - 10):
			for y in range(VoxelWorld.HEIGHT - 1, 2, -1):
				if voxel.get_block(x, y, z) == VoxelWorld.WOOD:
					tree_cell = Vector3i(x, y, z)
					break
			if tree_cell.x >= 0:
				break
		if tree_cell.x >= 0:
			break
	if tree_cell.x < 0:
		failed.append("aucun arbre à couper")
	else:
		var center: Vector3 = voxel.cell_center(tree_cell.x, tree_cell.y, tree_cell.z)
		var origin := center + Vector3(0.0, 0.0, 1.6)
		var hit: Vector3i = voxel.raycast_tree(origin, Vector3(0, 0, -1), 3.6)
		if hit.x < 0:
			failed.append("raycast_tree rate un tronc proche")
		var chopped := voxel.chop_tree_at(tree_cell)
		if chopped <= 0:
			failed.append("chop_tree_at n'a rien donné")
		else:
			game.add_bois(chopped)
			if int(game.bois) != chopped:
				failed.append("inventaire Bois incorrect")
	game.apply_damage(250.0)
	if not bool(game.is_dead):
		failed.append("la mort ne se déclenche pas")
	game.pick_class("glace")
	game.reset()
	if str(game.player_class) != "glace":
		failed.append("Rejouer doit garder la classe")
	if not bool(game.has_class()):
		failed.append("has_class faux après pick")
	if failed.is_empty():
		print("SMOKE_OK solides=%d spawn=%s bois=%d" % [voxel.count_solids(), spawn, game.bois])
		quit(0)
	else:
		printerr("SMOKE_FAIL: ", ", ".join(failed))
		quit(1)
