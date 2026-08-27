extends Node2D
class_name PlayerChar
##
## Player.gd
## Controla al personaje del jugador (Conserje / Profesor / Directora).
## Movimiento con WASD o flechas, con animacion simple de caminata/idle.
##

var carried_trash: int = 0
var battle_hp: int = 45
var battle_max_hp: int = 45

var _sprite: Sprite2D
var _label: Label
var _bounds: Rect2 = Rect2(60, 140, 1160, 480)
var _walk_time: float = 0.0
var _fast_run_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	add_child(_sprite)

	_label = Label.new()
	_label.position = Vector2(-40, -110)
	_label.size = Vector2(80, 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_font_size_override("font_size", 14)
	add_child(_label)

	set_character(GameManager.selected_character)

func set_character(id: String) -> void:
	var data: Dictionary = GameManager.CHARACTERS[id]
	var tex := load(data["texture"])
	_sprite.texture = tex
	var target_h := 90.0
	var tex_size: Vector2 = tex.get_size()
	if tex_size.y > 0:
		var s: float = target_h / tex_size.y
		_sprite.scale = Vector2(s, s)
	_sprite.centered = true
	_sprite.offset = Vector2(0, -tex_size.y / 2.0)
	battle_max_hp = data["max_hp"]
	battle_hp = battle_max_hp
	_label.text = GameManager.nickname

func set_bounds(b: Rect2) -> void:
	_bounds = b

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1

	var moving := dir.length() > 0.0
	if moving:
		dir = dir.normalized()
		position += dir * GameManager.get_move_speed() * delta
		position.x = clampf(position.x, _bounds.position.x, _bounds.position.x + _bounds.size.x)
		position.y = clampf(position.y, _bounds.position.y, _bounds.position.y + _bounds.size.y)
		_walk_time += delta * 8.0
	else:
		_walk_time = lerp(_walk_time, 0.0, delta * 5.0)

	_update_fast_run_achievement(moving, delta)

	# nota: no volteamos el sprite horizontalmente porque los retratos de
	# los personajes no son simetricos (ej. el profesor) y al voltearlos
	# se ven caminando "para atras". Solo se anima el rebote vertical.
	_sprite.position.y = sin(_walk_time) * 4.0 if moving else sin(Time.get_ticks_msec() / 400.0) * 1.5
	_label.position.x = -40

## Logro "Que Rapido": tener las Botas Veloces compradas y correr
## 5 segundos seguidos por el mapa.
func _update_fast_run_achievement(moving: bool, delta: float) -> void:
	if GameManager.is_achievement_unlocked("que_rapido"):
		return
	if moving and GameManager.owned_tools.get("botas_veloces", false):
		_fast_run_timer += delta
		if _fast_run_timer >= 5.0:
			GameManager.unlock_achievement("que_rapido")
	else:
		_fast_run_timer = 0.0
