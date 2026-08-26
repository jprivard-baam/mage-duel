extends Control

func _ready() -> void:
	$Center/VBox/PlayButton.pressed.connect(_on_play)
	$Center/VBox/PlayButton.grab_focus()


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ENTER):
		_on_play()
