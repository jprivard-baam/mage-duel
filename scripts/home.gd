extends Control

@onready var play_btn: Button = $Center/VBox/PlayButton
@onready var btn_feu: Button = $Center/VBox/ClassRow/Feu
@onready var btn_glace: Button = $Center/VBox/ClassRow/Glace
@onready var btn_foudre: Button = $Center/VBox/ClassRow/Foudre

func _ready() -> void:
	btn_feu.pressed.connect(func() -> void: _pick("feu"))
	btn_glace.pressed.connect(func() -> void: _pick("glace"))
	btn_foudre.pressed.connect(func() -> void: _pick("foudre"))
	play_btn.pressed.connect(_on_play)
	_style_class(btn_feu, "feu")
	_style_class(btn_glace, "glace")
	_style_class(btn_foudre, "foudre")
	if Game.has_class():
		_refresh_class_visuals()
	else:
		play_btn.disabled = true
		play_btn.modulate.a = 0.45
	play_btn.grab_focus()


func _style_class(btn: Button, id: String) -> void:
	var col: Color = Game.CLASSES[id]["couleur"]
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.25)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.28)
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = col
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _pick(id: String) -> void:
	Game.pick_class(id)
	_refresh_class_visuals()


func _refresh_class_visuals() -> void:
	play_btn.disabled = not Game.has_class()
	play_btn.modulate.a = 1.0 if Game.has_class() else 0.45
	for pair in [[btn_feu, "feu"], [btn_glace, "glace"], [btn_foudre, "foudre"]]:
		var btn: Button = pair[0]
		var id := str(pair[1])
		var col: Color = Game.CLASSES[id]["couleur"]
		var sb := StyleBoxFlat.new()
		var selected := Game.player_class == id
		sb.bg_color = col if selected else col.darkened(0.28)
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(3 if selected else 2)
		sb.border_color = Color(0.96, 0.89, 0.65) if selected else Color(1, 1, 1, 0.28)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.modulate.a = 1.0 if selected or not Game.has_class() else 0.7


func _on_play() -> void:
	if not Game.has_class():
		return
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				_pick("feu")
			KEY_2:
				_pick("glace")
			KEY_3:
				_pick("foudre")
			KEY_ENTER, KEY_KP_ENTER:
				_on_play()
	if event.is_action_pressed("ui_accept"):
		_on_play()
