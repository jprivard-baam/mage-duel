extends Node

## État global du proto survie (PV, faim, mana, bois, cycle jour/nuit).

signal stats_changed
signal died
signal night_changed(is_night: bool)
signal toasted(message: String)

const MAX_HP := 100.0
const MAX_HUNGER := 100.0
const MAX_MANA := 100.0
const HUNGER_DRAIN := 0.85
const MANA_REGEN := 14.0
const STARVE_DPS := 7.0
const DAY_LENGTH := 150.0

const SPELLS := {
	"feu": {"cout": 22.0, "degats": 34.0, "vitesse": 14.0, "couleur": Color(1.0, 0.38, 0.12), "rayon": 0.22},
	"glace": {"cout": 18.0, "degats": 24.0, "vitesse": 11.0, "couleur": Color(0.42, 0.85, 1.0), "rayon": 0.24},
	"foudre": {"cout": 20.0, "degats": 40.0, "vitesse": 22.0, "couleur": Color(0.78, 0.52, 1.0), "rayon": 0.18},
}

var hp: float = MAX_HP
var hunger: float = MAX_HUNGER
var mana: float = MAX_MANA
var bois: int = 0
var is_dead: bool = false
var is_night: bool = false
## 0 = aube. Commence en matinée pour laisser le temps de s'orienter.
var world_time: float = 4.0
var can_chop: bool = false

var move_stick: Vector2 = Vector2.ZERO
var jump_queued: bool = false
var cast_queued: String = ""
var chop_queued: bool = false


func reset() -> void:
	hp = MAX_HP
	hunger = MAX_HUNGER
	mana = MAX_MANA
	bois = 0
	is_dead = false
	is_night = false
	world_time = 4.0
	can_chop = false
	move_stick = Vector2.ZERO
	jump_queued = false
	cast_queued = ""
	chop_queued = false
	stats_changed.emit()


func tick_survival(delta: float) -> void:
	if is_dead:
		return
	hunger = maxf(0.0, hunger - HUNGER_DRAIN * delta)
	mana = minf(MAX_MANA, mana + MANA_REGEN * delta)
	if hunger <= 0.05:
		apply_damage(STARVE_DPS * delta)
	world_time = fmod(world_time + delta, DAY_LENGTH)
	var night := day_factor() < 0.30
	if night != is_night:
		is_night = night
		night_changed.emit(is_night)
		if is_night:
			toasted.emit("La nuit tombe")
		else:
			toasted.emit("Le jour se lève")
	stats_changed.emit()


func day_factor() -> float:
	var t := world_time / DAY_LENGTH
	return clampf(0.5 + 0.5 * cos((t - 0.22) * TAU), 0.0, 1.0)


func apply_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	stats_changed.emit()
	if hp <= 0.0:
		is_dead = true
		died.emit()


func try_spend_mana(cost: float) -> bool:
	if is_dead or mana < cost:
		return false
	mana -= cost
	stats_changed.emit()
	return true


func add_bois(amount: int) -> void:
	if amount <= 0:
		return
	bois += amount
	stats_changed.emit()


func heal_hunger(amount: float) -> void:
	hunger = minf(MAX_HUNGER, hunger + amount)
	stats_changed.emit()


func queue_jump() -> void:
	jump_queued = true


func queue_cast(kind: String) -> void:
	cast_queued = kind


func queue_chop() -> void:
	chop_queued = true
