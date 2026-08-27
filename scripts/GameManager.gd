extends Node
##
## GameManager (Autoload / Singleton)
## Guarda el progreso del jugador: monedas, dia actual, apodo,
## personajes/herramientas desbloqueadas, ninos reformados, etc.
## Tambien contiene la "base de datos" del juego: personajes, habilidades
## y tipos de ninos problematicos.
##

signal coins_changed(new_amount)
signal day_changed(new_day)
signal achievement_unlocked(id)

# ---------------------------------------------------------------------------
# ESTADO DEL JUGADOR
# ---------------------------------------------------------------------------
var nickname: String = "Jugador"
var coins: int = 0
var current_day: int = 1
var recess_index: int = 1 # 1 o 2
var selected_character: String = "conserje"

var unlocked_characters: Dictionary = {
	"conserje": true,
	"profesor": false,
	"director": false,
}

var owned_tools: Dictionary = {
	"iman_basura": false,   # aumenta el radio de recoleccion
	"bolsa_grande": false,  # aumenta la capacidad de basura cargada
	"botas_veloces": false, # aumenta la velocidad de movimiento
}

# Lista de "tipos" de ninos que ya fueron reformados y pueden regresar
# como aliados en dias futuros.
var reformed_kid_memory: Array = []

var total_kids_defeated: int = 0
var total_trash_collected: int = 0

# ---------------------------------------------------------------------------
# BASE DE DATOS: PERSONAJES JUGABLES
# ---------------------------------------------------------------------------
# El conserje es el mas debil pero es el personaje principal (siempre
# disponible). El profesor y la directora son mas fuertes pero hay que
# desbloquearlos en la tienda con monedas.
const CHARACTERS := {
	"conserje": {
		"display_name": "El Conserje",
		"texture": "res://assets/characters/conserje.png",
		"max_hp": 45,
		"power": 5,
		"unlock_cost": 0,
		"money_multiplier": 1.0,
		"passive_desc": "Sin habilidad especial. El de siempre, curtido y confiable.",
		"color": Color(0.55, 0.65, 0.55),
		"abilities": [
			{"name": "Escobazo", "power": 7, "desc": "Un golpe rapido de escoba.", "stun_chance": 0.0},
			{"name": "Grito de Autoridad", "power": 4, "desc": "Intimida al nino, puede aturdirlo.", "stun_chance": 0.35},
			{"name": "Trapeada Giratoria", "power": 11, "desc": "Ataque fuerte pero impreciso.", "stun_chance": 0.0, "accuracy": 0.75},
			{"name": "Manguerazo", "power": 9, "desc": "Un chorro de agua a presion.", "stun_chance": 0.0, "accuracy": 0.85},
		],
	},
	"profesor": {
		"display_name": "El Profesor",
		"texture": "res://assets/characters/profesor.png",
		"max_hp": 55,
		"power": 7,
		"unlock_cost": 180,
		"money_multiplier": 2.0,
		"passive_desc": "Doble Sueldo: gana el doble de monedas en todo.",
		"color": Color(0.55, 0.7, 0.95),
		"abilities": [
			{"name": "Regla Voladora", "power": 8, "desc": "Le lanza una regla de madera.", "stun_chance": 0.0},
			{"name": "Sermon Educativo", "power": 5, "desc": "Un discurso agotador.", "stun_chance": 0.4},
			{"name": "Examen Sorpresa", "power": 13, "desc": "Ataque devastador pero lento.", "stun_chance": 0.0, "accuracy": 0.7},
			{"name": "Tarea Extra", "power": 6, "desc": "Castiga con deberes interminables.", "stun_chance": 0.25},
		],
	},
	"director": {
		"display_name": "La Directora",
		"texture": "res://assets/characters/director.png",
		"max_hp": 65,
		"power": 9,
		"unlock_cost": 350,
		"money_multiplier": 1.5,
		"passive_desc": "Autoridad Maxima: gana 50% mas monedas en todo.",
		"color": Color(0.25, 0.28, 0.4),
		"abilities": [
			{"name": "Mirada que Congela", "power": 5, "desc": "Una mirada gelida que paraliza casi siempre.", "stun_chance": 0.6},
			{"name": "Portazo", "power": 14, "desc": "Cierra la puerta de golpe. Certero.", "stun_chance": 0.0, "accuracy": 0.9},
			{"name": "Carta a los Padres", "power": 20, "desc": "La amenaza definitiva, pero arriesgada.", "stun_chance": 0.0, "accuracy": 0.55},
			{"name": "Doble Suspension", "power": 7, "desc": "Golpea DOS veces seguidas.", "stun_chance": 0.0, "accuracy": 0.85, "hits": 2},
		],
	},
}

# ---------------------------------------------------------------------------
# BASE DE DATOS: TIPOS DE NINOS PROBLEMATICOS
# ---------------------------------------------------------------------------
const KID_TYPES := {
	"normal": {
		"label": "Normal",
		"icon": "😐",
		"color": Color(0.4, 0.55, 0.85),
		"hp_mult": 1.0, "speed_mult": 1.0, "power_mult": 1.0,
		"max_litter": 5,
	},
	"veloz": {
		"label": "Super Veloz",
		"icon": "⚡",
		"color": Color(0.95, 0.85, 0.2),
		"hp_mult": 0.85, "speed_mult": 3.2, "power_mult": 0.9,
		"max_litter": 5,
	},
	"basurero": {
		"label": "Botabasura",
		"icon": "🗑",
		"color": Color(0.5, 0.35, 0.2),
		"hp_mult": 1.15, "speed_mult": 1.0, "power_mult": 0.85,
		"max_litter": 10,
	},
	"fuerte": {
		"label": "Fortachon",
		"icon": "💪",
		"color": Color(0.85, 0.25, 0.25),
		"hp_mult": 1.7, "speed_mult": 0.85, "power_mult": 1.6,
		"max_litter": 5,
	},
}

# cada nino bota basura cada N segundos (fijo, sin importar el tipo)
const LITTER_INTERVAL := 17.0

const TOOLS := {
	"iman_basura": {"label": "Iman de Basura", "cost": 70, "desc": "Aumenta el radio de recoleccion de basura."},
	"bolsa_grande": {"label": "Bolsa Grande", "cost": 60, "desc": "Puedes cargar mas basura antes de ir al basurero."},
	"botas_veloces": {"label": "Botas Veloces", "cost": 80, "desc": "Aumenta tu velocidad de movimiento."},
}

# ---------------------------------------------------------------------------
# POCIONES (objetos consumibles, se usan desde la Mochila en batalla)
# ---------------------------------------------------------------------------
const POTIONS := {
	"pocion_curacion": {
		"label": "Pocion de Curacion",
		"cost": 35,
		"desc": "Restaura 25 de vida en batalla.",
		"heal": 25,
	},
	"pocion_fuerza": {
		"label": "Pocion de Fuerza",
		"cost": 45,
		"desc": "Aumenta tu poder de ataque en el siguiente turno.",
		"power_boost": 0.6,
	},
}

var inventory: Dictionary = {
	"pocion_curacion": 0,
	"pocion_fuerza": 0,
}

func buy_potion(id: String) -> bool:
	if not POTIONS.has(id):
		return false
	var cost: int = POTIONS[id]["cost"]
	if spend_coins(cost):
		inventory[id] = int(inventory.get(id, 0)) + 1
		return true
	return false

func use_potion(id: String) -> bool:
	if int(inventory.get(id, 0)) <= 0:
		return false
	inventory[id] = int(inventory[id]) - 1
	return true

const REFLECTION_LINES := [
	"Lo siento.",
	"Disculpa.",
	"No volvere a hacerlo.",
	"Lo limpiare.",
	"Bueno, ya lo recojo.",
	"Aja, si, ya voy a recoger.",
	"Esperame y lo recogere.",
]

# ---------------------------------------------------------------------------
# FUNCIONES DE ECONOMIA
# ---------------------------------------------------------------------------
func add_coins(amount: int) -> void:
	var mult: float = 1.0
	if CHARACTERS.has(selected_character):
		mult = CHARACTERS[selected_character].get("money_multiplier", 1.0)
	var final_amount: int = int(round(amount * mult))
	coins += final_amount
	emit_signal("coins_changed", coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		return true
	return false

func unlock_character(id: String) -> bool:
	if not CHARACTERS.has(id):
		return false
	var cost: int = CHARACTERS[id]["unlock_cost"]
	if unlocked_characters.get(id, false):
		return false
	if spend_coins(cost):
		unlocked_characters[id] = true
		_check_taumata_achievement()
		return true
	return false

func buy_tool(id: String) -> bool:
	if not TOOLS.has(id):
		return false
	if owned_tools.get(id, false):
		return false
	var cost: int = TOOLS[id]["cost"]
	if spend_coins(cost):
		owned_tools[id] = true
		_check_taumata_achievement()
		return true
	return false

# ---------------------------------------------------------------------------
# CICLO DE DIAS Y DIFICULTAD
# ---------------------------------------------------------------------------
func next_recess_or_day() -> String:
	# Devuelve "recess2" o "newday" segun corresponda
	if recess_index == 1:
		recess_index = 2
		return "recess2"
	else:
		current_day += 1
		recess_index = 1
		emit_signal("day_changed", current_day)
		return "newday"

## Devuelve los parametros de dificultad para el dia actual.
## La cantidad de ninos y la probabilidad de tipos problematicos
## sube con el paso de los dias, pero con algo de variacion aleatoria
## para que algunos dias sean mas dificiles y otros mas tranquilos.
func get_difficulty_params() -> Dictionary:
	var base_min: int = 2
	var base_max: int = 4
	var growth: int = int(current_day / 2.0)
	var noise: int = randi_range(-1, 2)

	var min_kids: int = clampi(base_min + growth + noise, 2, 12)
	var max_kids: int = clampi(base_max + growth + noise + 2, min_kids, 14)

	var problematic_chance: float = clampf(0.12 + current_day * 0.025 + randf_range(-0.05, 0.05), 0.08, 0.85)

	return {
		"min_kids": min_kids,
		"max_kids": max_kids,
		"problematic_chance": problematic_chance,
	}

func reset_new_game() -> void:
	coins = 0
	current_day = 1
	recess_index = 1
	selected_character = "conserje"
	unlocked_characters = {"conserje": true, "profesor": false, "director": false}
	owned_tools = {"iman_basura": false, "bolsa_grande": false, "botas_veloces": false}
	inventory = {"pocion_curacion": 0, "pocion_fuerza": 0}
	reformed_kid_memory.clear()
	total_kids_defeated = 0
	total_trash_collected = 0

func get_carry_capacity() -> int:
	return 9 if owned_tools.get("bolsa_grande", false) else 5

func get_move_speed() -> float:
	return 300.0 if owned_tools.get("botas_veloces", false) else 220.0

func get_pickup_radius() -> float:
	return 90.0 if owned_tools.get("iman_basura", false) else 40.0

# ---------------------------------------------------------------------------
# GUARDADO / CARGA
# ---------------------------------------------------------------------------
const SAVE_PATH := "user://savegame.save"

func save_game() -> void:
	var data := {
		"nickname": nickname,
		"coins": coins,
		"current_day": current_day,
		"recess_index": recess_index,
		"selected_character": selected_character,
		"unlocked_characters": unlocked_characters,
		"owned_tools": owned_tools,
		"inventory": inventory,
		"reformed_kid_memory": reformed_kid_memory,
		"total_kids_defeated": total_kids_defeated,
		"total_trash_collected": total_trash_collected,
		"unlocked_achievements": unlocked_achievements,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var text: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	nickname = d.get("nickname", nickname)
	coins = int(d.get("coins", coins))
	current_day = int(d.get("current_day", current_day))
	recess_index = int(d.get("recess_index", recess_index))
	selected_character = d.get("selected_character", selected_character)
	unlocked_characters = d.get("unlocked_characters", unlocked_characters)
	owned_tools = d.get("owned_tools", owned_tools)
	inventory = d.get("inventory", inventory)
	reformed_kid_memory = d.get("reformed_kid_memory", reformed_kid_memory)
	total_kids_defeated = int(d.get("total_kids_defeated", total_kids_defeated))
	total_trash_collected = int(d.get("total_trash_collected", total_trash_collected))
	unlocked_achievements = d.get("unlocked_achievements", unlocked_achievements)
	return true

# ---------------------------------------------------------------------------
# LOGROS
# ---------------------------------------------------------------------------
# Los logros NO se borran al empezar una partida nueva (reset_new_game):
# son un registro permanente del jugador, como en cualquier juego con logros.
const ACHIEVEMENTS := {
	"bienvenido": {
		"title": "Bienvenido Eric",
		"desc": "Crea una nueva partida.",
	},
	"que_rapido": {
		"title": "Que Rapido",
		"desc": "Compra la habilidad de Super Velocidad y corre por el mapa durante 5 segundos.",
	},
	"taumata": {
		"title": "Taumata",
		"desc": "Consigue todas las habilidades y personajes del juego.",
	},
}

var unlocked_achievements: Dictionary = {}

func unlock_achievement(id: String) -> void:
	if not ACHIEVEMENTS.has(id):
		return
	if unlocked_achievements.get(id, false):
		return
	unlocked_achievements[id] = true
	emit_signal("achievement_unlocked", id)

func is_achievement_unlocked(id: String) -> bool:
	return unlocked_achievements.get(id, false)

func _check_taumata_achievement() -> void:
	var all_characters := true
	for id in CHARACTERS.keys():
		if not unlocked_characters.get(id, false):
			all_characters = false
			break
	var all_tools := true
	for id in TOOLS.keys():
		if not owned_tools.get(id, false):
			all_tools = false
			break
	if all_characters and all_tools:
		unlock_achievement("taumata")

# ---------------------------------------------------------------------------
# PANTALLA COMPLETA
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
