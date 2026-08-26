extends SceneTree

func _init() -> void:
	var failed: PackedStringArray = PackedStringArray()
	var game_script: GDScript = load("res://autoload/game.gd")
	var game: Node = game_script.new()
	game.reset()
	if not is_equal_approx(float(game.MAX_HP), 1000.0):
		failed.append("PV joueur devrait être 1000")
	if not is_equal_approx(float(game.STRIKE_DAMAGE), 25.0):
		failed.append("frappe devrait être 25")
	if not is_equal_approx(float(game.SPELLS["feu"]["degats"]), 40.0):
		failed.append("Feu devrait faire 40")
	if not is_equal_approx(float(game.SPELLS["glace"]["degats"]), 28.0):
		failed.append("Glace devrait faire 28")
	if not is_equal_approx(float(game.SPELLS["foudre"]["degats"]), 35.0):
		failed.append("Foudre devrait faire 35")
	if not is_equal_approx(float(game.CREATURES["loup"]["hp"]), 220.0):
		failed.append("loup PV 220")
	if not is_equal_approx(float(game.CREATURES["loup"]["degats"]), 55.0):
		failed.append("loup dmg 55")
	if not is_equal_approx(float(game.CREATURES["slime"]["hp"]), 150.0):
		failed.append("slime PV 150")
	if not is_equal_approx(float(game.CREATURES["slime"]["degats"]), 35.0):
		failed.append("slime dmg 35")
	if bool(game.CREATURES["chevreuil"]["hostile"]):
		failed.append("chevreuil doit être passif")
	if bool(game.CREATURES["chevreuil"]["burns_sun"]):
		failed.append("chevreuil survit à l'aube")
	if bool(game.CREATURES["loup"]["burns_sun"]):
		failed.append("loup survit à l'aube")
	if not bool(game.CREATURES["zombie"]["burns_sun"]):
		failed.append("zombie brûle au soleil")
	if not bool(game.CREATURES["squelette"]["burns_sun"]):
		failed.append("squelette brûle au soleil")

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
	if bool(game.is_dead):
		failed.append("250 dégâts ne doivent pas tuer un joueur à 1000 PV")
	game.apply_damage(2000.0)
	if not bool(game.is_dead):
		failed.append("la mort ne se déclenche pas")
	game.pick_class("glace")
	game.reset()
	if str(game.player_class) != "glace":
		failed.append("Rejouer doit garder la classe")
	if not bool(game.has_class()):
		failed.append("has_class faux après pick")

	var CV: GDScript = load("res://scripts/critter_voxels.gd")
	var holder := Node3D.new()
	root.add_child(holder)
	var wolf_model := Node3D.new()
	holder.add_child(wolf_model)
	CV.build("loup", wolf_model)
	for part in ["Body", "Snout", "EarL", "EarR", "Tail", "LegFL", "LegFR", "LegBL", "LegBR"]:
		if wolf_model.get_node_or_null(part) == null:
			failed.append("loup sans %s" % part)
	if _count_meshes(wolf_model) < 12:
		failed.append("loup trop peu de cubes (%d)" % _count_meshes(wolf_model))
	var deer_model := Node3D.new()
	holder.add_child(deer_model)
	CV.build("chevreuil", deer_model)
	if deer_model.get_node_or_null("AntlerL") == null:
		failed.append("chevreuil sans bois")
	if deer_model.get_node_or_null("Tail") == null:
		failed.append("chevreuil sans queue")
	var skel_model := Node3D.new()
	holder.add_child(skel_model)
	CV.build("squelette", skel_model)
	if skel_model.get_node_or_null("Sword") == null:
		failed.append("squelette sans épée")
	if skel_model.get_node_or_null("Bow") != null:
		failed.append("squelette ne doit pas avoir d'arc")
	var zom_model := Node3D.new()
	holder.add_child(zom_model)
	CV.build("zombie", zom_model)
	if zom_model.get_node_or_null("RotPatch") == null:
		failed.append("zombie sans pourriture")
	game.hunger = 20.0
	game.heal_hunger(float(game.CREATURES["chevreuil"]["faim"]))
	if float(game.hunger) < 60.0:
		failed.append("viande de chevreuil doit nourrir")

	if failed.is_empty():
		print("SMOKE_OK solides=%d spawn=%s bois=%d" % [voxel.count_solids(), spawn, game.bois])
		quit(0)
	else:
		printerr("SMOKE_FAIL: ", ", ".join(failed))
		quit(1)


func _count_meshes(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c
