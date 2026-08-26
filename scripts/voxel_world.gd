extends Node3D
class_name VoxelWorld

## Monde voxel 96×96 : terre, roche, arbres. Cubes 0,5 (moitié d'un proto 48 « chunky »).

const AIR := 0
const DIRT := 1
const ROCK := 2
const WOOD := 3
const LEAF := 4

const SIZE := 96
const HEIGHT := 24
const CELL := 0.5

var _blocks: PackedByteArray = PackedByteArray()
var _mesh_instance: MeshInstance3D
var _body: StaticBody3D
var _collision: CollisionShape3D


func _ready() -> void:
	add_to_group("voxel_world")
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TerrainMesh"
	add_child(_mesh_instance)
	_body = StaticBody3D.new()
	_body.name = "TerrainBody"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_collision = CollisionShape3D.new()
	_body.add_child(_collision)


func build_world() -> Vector3:
	_generate()
	_rebuild_meshes()
	return spawn_position()


func in_bounds(x: int, y: int, z: int) -> bool:
	return x >= 0 and y >= 0 and z >= 0 and x < SIZE and y < HEIGHT and z < SIZE


func get_block(x: int, y: int, z: int) -> int:
	if not in_bounds(x, y, z):
		return AIR
	return _blocks[_index(x, y, z)]


func is_solid(x: int, y: int, z: int) -> bool:
	var b := get_block(x, y, z)
	return b == DIRT or b == ROCK or b == WOOD


func is_tree(x: int, y: int, z: int) -> bool:
	var b := get_block(x, y, z)
	return b == WOOD or b == LEAF


func surface_y(x: int, z: int) -> int:
	for y in range(HEIGHT - 1, -1, -1):
		if is_solid(x, y, z):
			return y
	return -1


func cell_center(x: int, y: int, z: int) -> Vector3:
	return Vector3((float(x) + 0.5) * CELL, (float(y) + 0.5) * CELL, (float(z) + 0.5) * CELL)


func world_to_cell(p: Vector3) -> Vector3i:
	return Vector3i(floori(p.x / CELL), floori(p.y / CELL), floori(p.z / CELL))


func spawn_position() -> Vector3:
	var cx := SIZE / 2
	var cz := SIZE / 2
	var best := Vector3((cx + 0.5) * CELL, 4.0, (cz + 0.5) * CELL)
	var best_score := -999.0
	for z in range(cz - 8, cz + 9):
		for x in range(cx - 8, cx + 9):
			var y := surface_y(x, z)
			if y < 2:
				continue
			if get_block(x, y + 1, z) == WOOD or get_block(x, y + 1, z) == LEAF:
				continue
			var score := float(y) - Vector2(x - cx, z - cz).length() * 0.12
			if score > best_score:
				best_score = score
				best = Vector3((x + 0.5) * CELL, (y + 1) * CELL + 0.02, (z + 0.5) * CELL)
	return best


func count_solids() -> int:
	var n := 0
	for i in _blocks.size():
		var b := _blocks[i]
		if b == DIRT or b == ROCK or b == WOOD:
			n += 1
	return n


func raycast_tree(origin: Vector3, dir: Vector3, max_dist: float) -> Vector3i:
	if dir.length() < 0.001:
		return Vector3i(-1, -1, -1)
	dir = dir.normalized()
	var best := Vector3i(-1, -1, -1)
	var best_d := max_dist + 0.05
	var reach := max_dist + CELL * 2.0
	var minc := world_to_cell(origin - Vector3(reach, 1.4, reach))
	var maxc := world_to_cell(origin + Vector3(reach, 2.6, reach))
	minc.x = clampi(minc.x, 0, SIZE - 1)
	maxc.x = clampi(maxc.x, 0, SIZE - 1)
	minc.y = clampi(minc.y, 0, HEIGHT - 1)
	maxc.y = clampi(maxc.y, 0, HEIGHT - 1)
	minc.z = clampi(minc.z, 0, SIZE - 1)
	maxc.z = clampi(maxc.z, 0, SIZE - 1)
	for y in range(minc.y, maxc.y + 1):
		for z in range(minc.z, maxc.z + 1):
			for x in range(minc.x, maxc.x + 1):
				if not is_tree(x, y, z):
					continue
				var p := cell_center(x, y, z)
				var to := p - origin
				var dist := to.length()
				if dist > max_dist or dist < 0.05:
					continue
				var align := to.normalized().dot(dir)
				if align < 0.25:
					continue
				if dist < best_d:
					best_d = dist
					best = Vector3i(x, y, z)
	return best


func chop_tree_at(cell: Vector3i) -> int:
	if not is_tree(cell.x, cell.y, cell.z):
		return 0
	var stack: Array[Vector3i] = [cell]
	var seen := {}
	var gained := 0
	var dirs := [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	while not stack.is_empty() and seen.size() < 160:
		var c: Vector3i = stack.pop_back()
		if seen.has(c):
			continue
		if not is_tree(c.x, c.y, c.z):
			continue
		seen[c] = true
		gained += 1
		_set_block(c.x, c.y, c.z, AIR)
		for d in dirs:
			var n: Vector3i = c + d
			if not seen.has(n) and is_tree(n.x, n.y, n.z):
				stack.append(n)
	if gained > 0:
		_rebuild_meshes()
	return gained


func _index(x: int, y: int, z: int) -> int:
	return (y * SIZE + z) * SIZE + x


func _set_block(x: int, y: int, z: int, b: int) -> void:
	if in_bounds(x, y, z):
		_blocks[_index(x, y, z)] = b


func _hashf(x: float, z: float) -> float:
	var n := sin(x * 127.1 + z * 311.7) * 43758.5453
	return n - floorf(n)


func _noise(x: float, z: float) -> float:
	var xi := floori(x)
	var zi := floori(z)
	var xf := x - float(xi)
	var zf := z - float(zi)
	var u := xf * xf * (3.0 - 2.0 * xf)
	var v := zf * zf * (3.0 - 2.0 * zf)
	var a := _hashf(xi, zi)
	var b := _hashf(xi + 1, zi)
	var c := _hashf(xi, zi + 1)
	var d := _hashf(xi + 1, zi + 1)
	return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v


func _fbm(x: float, z: float) -> float:
	return _noise(x, z) * 0.52 + _noise(x * 2.03, z * 2.03) * 0.31 + _noise(x * 4.1, z * 4.1) * 0.17


func _generate() -> void:
	_blocks.resize(SIZE * HEIGHT * SIZE)
	_blocks.fill(AIR)
	var cx := 47.5
	var cz := 47.5
	for z in SIZE:
		for x in SIZE:
			var dist := Vector2(x - cx, z - cz).length()
			var fall := 0.0
			if dist <= 32.0:
				fall = 1.0
			elif dist < 44.0:
				fall = (44.0 - dist) / 12.0
			if fall <= 0.0:
				continue
			var n := _fbm(x * 0.055, z * 0.055)
			var hill := exp(-((x - 58.0) * (x - 58.0) + (z - 34.0) * (z - 34.0)) / 152.0)
			var knoll := exp(-((x - 28.0) * (x - 28.0) + (z - 62.0) * (z - 62.0)) / 88.0)
			var h := 3.0 + fall * (5.5 + n * 7.5 + hill * 10.0 + knoll * 5.0)
			var hi := clampi(int(floorf(h)), 1, HEIGHT - 6)
			var rocky := hill > 0.45 or (n > 0.62 and hi >= 12)
			for y in hi:
				var t := DIRT
				if y == 0 or (rocky and y >= hi - 3) or (y < hi - 1 and _hashf(x * 3.0, z + y * 7) > 0.82):
					t = ROCK
				if rocky and y >= hi - 1:
					t = ROCK
				_set_block(x, y, z, t)
	_plant_trees()


func _plant_trees() -> void:
	var trees: Array[Vector2i] = []
	var tries := 0
	while trees.size() < 28 and tries < 420:
		tries += 1
		var x := 10 + int(_hashf(tries, 9) * float(SIZE - 20))
		var z := 10 + int(_hashf(tries, 21) * float(SIZE - 20))
		var top := -1
		for y in range(HEIGHT - 1, -1, -1):
			if get_block(x, y, z) == DIRT:
				top = y
				break
		if top < 3 or top > 14:
			continue
		var ok := true
		for t in trees:
			if Vector2(t.x - x, t.y - z).length() < 6.5:
				ok = false
				break
		if not ok:
			continue
		var th := 4 + int(_hashf(x, z) * 3.0)
		for i in range(1, th + 1):
			_set_block(x, top + i, z, WOOD)
		var ly := top + th
		for ox in range(-2, 3):
			for oz in range(-2, 3):
				if abs(ox) == 2 and abs(oz) == 2:
					continue
				if ox == 0 and oz == 0:
					continue
				_set_block(x + ox, ly, z + oz, LEAF)
				if abs(ox) + abs(oz) <= 2:
					_set_block(x + ox, ly + 1, z + oz, LEAF)
		_set_block(x, ly + 1, z, LEAF)
		_set_block(x, ly + 2, z, LEAF)
		trees.append(Vector2i(x, z))


func _face_color(t: int, ny: float, x: int, y: int, z: int) -> Color:
	var jitter := _hashf(x * 1.7, z * 2.3 + y) * 0.16 - 0.08
	var shade := 0.78
	if ny > 0.5:
		shade = 1.0
	elif ny < -0.5:
		shade = 0.55
	var c := Color(0.22, 0.72, 0.32)
	if t == DIRT:
		if ny > 0.5:
			c = Color(0.36, 0.72, 0.28)
		elif ny < -0.5:
			c = Color(0.42, 0.28, 0.14)
		else:
			c = Color(0.55, 0.38, 0.20)
	elif t == ROCK:
		c = Color(0.55, 0.57, 0.62)
	elif t == WOOD:
		c = Color(0.42, 0.26, 0.12)
	c.r = clampf(c.r * shade + jitter, 0.0, 1.0)
	c.g = clampf(c.g * shade + jitter * 0.7, 0.0, 1.0)
	c.b = clampf(c.b * shade + jitter * 0.4, 0.0, 1.0)
	return c


func _rebuild_meshes() -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var cverts := PackedVector3Array()
	var cnorms := PackedVector3Array()
	var faces := [
		[Vector3(0, 1, 0), [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)]],
		[Vector3(0, -1, 0), [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)]],
		[Vector3(0, 0, 1), [Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)]],
		[Vector3(0, 0, -1), [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)]],
		[Vector3(1, 0, 0), [Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]],
		[Vector3(-1, 0, 0), [Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1)]],
	]
	for y in HEIGHT:
		for z in SIZE:
			for x in SIZE:
				var t := get_block(x, y, z)
				if t == AIR:
					continue
				for f in faces:
					var n: Vector3 = f[0]
					var nx := x + int(n.x)
					var ny := y + int(n.y)
					var nz := z + int(n.z)
					var nb := get_block(nx, ny, nz)
					var visible := nb == AIR or (t != LEAF and nb == LEAF)
					if t == LEAF and nb == LEAF:
						visible = false
					if not visible:
						continue
					var quad: Array = f[1]
					var col := _face_color(t, n.y, x, y, z)
					var o := Vector3(x, y, z) * CELL
					var a: Vector3 = o + quad[0] * CELL
					var b: Vector3 = o + quad[1] * CELL
					var c: Vector3 = o + quad[2] * CELL
					var d: Vector3 = o + quad[3] * CELL
					_push_tri(verts, norms, cols, a, b, c, n, col)
					_push_tri(verts, norms, cols, a, c, d, n, col)
					if t != LEAF:
						_push_tri(cverts, cnorms, null, a, b, c, n, col)
						_push_tri(cverts, cnorms, null, a, c, d, n, col)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.88
	mat.metallic = 0.0
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = mat
	if cverts.size() >= 3:
		var carr := []
		carr.resize(Mesh.ARRAY_MAX)
		carr[Mesh.ARRAY_VERTEX] = cverts
		carr[Mesh.ARRAY_NORMAL] = cnorms
		var cmesh := ArrayMesh.new()
		cmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, carr)
		_collision.shape = cmesh.create_trimesh_shape()
	print("VoxelWorld: %d tris visuels, %d solides" % [verts.size() / 3, count_solids()])


func _push_tri(verts: PackedVector3Array, norms: PackedVector3Array, cols, a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color) -> void:
	verts.push_back(a)
	verts.push_back(b)
	verts.push_back(c)
	norms.push_back(n)
	norms.push_back(n)
	norms.push_back(n)
	if cols != null:
		cols.push_back(col)
		cols.push_back(col)
		cols.push_back(col)
