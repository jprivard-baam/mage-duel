extends CanvasLayer

@onready var hp_bar: ColorRect = $Hud/Hp/VBox/Track/Fill
@onready var hun_bar: ColorRect = $Hud/Hunger/VBox/Track/Fill
@onready var man_bar: ColorRect = $Hud/Mana/VBox/Track/Fill
@onready var bois_label: Label = $Hud/Bois/VBox/Count
@onready var class_label: Label = $Hud/ClassChip/VBox/Name
@onready var clock: Label = $Hud/Clock
@onready var toast: Label = $Toast
@onready var death: Control = $Death
@onready var joystick: Control = $Joystick
@onready var knob: Control = $Joystick/Knob
@onready var btn_sort: Button = $Actions/Sort
@onready var btn_frapper: Button = $Actions/Row/Frapper
@onready var btn_saut: Button = $Actions/Row/Saut
@onready var btn_retry: Button = $Death/VBox/Retry

var _joy_id := -1
var _toast_time := 0.0


func _ready() -> void:
	Game.stats_changed.connect(_refresh)
	Game.died.connect(_on_died)
	Game.toasted.connect(_on_toast)
	death.visible = false
	btn_sort.pressed.connect(func() -> void: Game.queue_cast())
	btn_frapper.pressed.connect(func() -> void: Game.queue_strike())
	btn_saut.pressed.connect(func() -> void: Game.queue_jump())
	btn_retry.pressed.connect(_on_retry)
	joystick.gui_input.connect(_joystick_event)
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	_style_spell(btn_sort, Game.class_couleur())
	_style_joystick()
	_apply_safe_area()
	_refresh()
	call_deferred("_set_knob", Vector2.ZERO)


func _style_spell(btn: Button, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(44)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.35)
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = col.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _style_joystick() -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(1, 1, 1, 0.10)
	base.set_corner_radius_all(80)
	base.set_border_width_all(2)
	base.border_color = Color(1, 1, 1, 0.22)
	joystick.add_theme_stylebox_override("panel", base)
	if joystick.has_node("Base"):
		joystick.get_node("Base").visible = false
	if knob is ColorRect:
		(knob as ColorRect).color = Color(0.96, 0.89, 0.65, 0.0)
	var knob_panel := Panel.new()
	knob_panel.name = "KnobVisual"
	knob_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	knob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0.96, 0.89, 0.65, 0.88)
	ks.set_corner_radius_all(40)
	knob_panel.add_theme_stylebox_override("panel", ks)
	knob.add_child(knob_panel)


func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var win := get_viewport().get_visible_rect()
	var left := maxf(10.0, float(safe.position.x - win.position.x) + 8.0)
	var bottom := maxf(10.0, float((win.position.y + win.size.y) - (safe.position.y + safe.size.y)) + 10.0)
	var top := maxf(8.0, float(safe.position.y - win.position.y) + 6.0)
	var right := maxf(10.0, float((win.position.x + win.size.x) - (safe.position.x + safe.size.x)) + 8.0)
	$Hud.offset_left = left
	$Hud.offset_top = top
	$Hud.offset_right = -right
	$Joystick.offset_left = left + 4.0
	$Joystick.offset_bottom = -bottom
	$Actions.offset_right = -right
	$Actions.offset_bottom = -bottom


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			toast.modulate.a = 0.0
	_refresh_clock()
	var spec: Dictionary = Game.SPELLS.get(Game.player_class, {})
	var cost := float(spec.get("cout", 999.0))
	btn_sort.disabled = Game.is_dead or Game.mana < cost or not Game.has_class()
	btn_sort.modulate.a = 0.38 if btn_sort.disabled else 1.0
	btn_saut.disabled = Game.is_dead
	btn_frapper.disabled = Game.is_dead
	var ready := (Game.can_strike or Game.can_chop) and not Game.is_dead
	btn_frapper.modulate.a = 1.0 if ready else 0.55
	clock.modulate = Color(0.75, 0.8, 1.0) if Game.is_night else Color.WHITE


func _refresh() -> void:
	_set_fill(hp_bar, Game.hp / Game.MAX_HP)
	_set_fill(hun_bar, Game.hunger / Game.MAX_HUNGER)
	_set_fill(man_bar, Game.mana / Game.MAX_MANA)
	bois_label.text = str(Game.bois)
	class_label.text = Game.class_nom().to_upper() if Game.has_class() else "—"
	class_label.add_theme_color_override("font_color", Game.class_couleur())


func _set_fill(fill: ColorRect, ratio: float) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	fill.anchor_right = r
	fill.offset_right = 0.0


func _refresh_clock() -> void:
	clock.text = "Nuit" if Game.is_night else "Jour"


func _on_died() -> void:
	death.visible = true
	Game.move_stick = Vector2.ZERO


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_toast(message: String) -> void:
	toast.text = message
	toast.modulate.a = 1.0
	_toast_time = 1.8


func _set_knob(dir: Vector2) -> void:
	var c := joystick.size * 0.5
	if c == Vector2.ZERO:
		c = Vector2(64, 64)
	var r := minf(c.x, c.y) - 28.0
	knob.position = c + dir * r - knob.size * 0.5


func _joystick_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_joy_id = st.index
			_update_joy(st.position)
		elif st.index == _joy_id:
			_joy_id = -1
			Game.move_stick = Vector2.ZERO
			_set_knob(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _joy_id or _joy_id < 0:
			_joy_id = sd.index
			_update_joy(sd.position)


func _update_joy(local_pos: Vector2) -> void:
	var c := joystick.size * 0.5
	if c == Vector2.ZERO:
		c = Vector2(64, 64)
	var delta := local_pos - c
	var r := minf(c.x, c.y) - 8.0
	if delta.length() > r:
		delta = delta.normalized() * r
	var dir := Vector2(delta.x / r, -delta.y / r)
	Game.move_stick = dir if dir.length() > 0.08 else Vector2.ZERO
	_set_knob(Vector2(dir.x, -dir.y))
