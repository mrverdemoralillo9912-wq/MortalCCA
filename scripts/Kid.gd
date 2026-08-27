extends Node2D
class_name Kid
##
## Kid.gd
## Representa a un nino en el patio. Puede ser "normal" (estudiante comun)
## o tener una habilidad especial (veloz, botabasura, fuerte). Deambula,
## bota basura cada cierto tiempo (con un limite maximo), y puede ser
## retado a batalla por el jugador.
##
## Nota: cada tipo de nino usa UNA sola imagen fija (sin animaciones de
## direccion/accion) para mantenerlo simple y evitar glitches visuales.
##

enum State { WANDER, IN_BATTLE, AWAITING_REFLECTION, REFLECTED, ALLY }

signal wants_battle(kid)

var kid_type: String = "normal"
var is_reformed_ally: bool = false

var max_hp: int = 20
var hp: int = 20
var power: int = 4
var speed: float = 60.0

var max_litter: int = 5
var litter_count: int = 0

var state: int = State.WANDER

var _litter_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _bob_time: float = 0.0
var _bounds: Rect2 = Rect2(60, 140, 1160, 480)
var _gave_ally_bonus_today: bool = false

var _sprite: Sprite2D = null
var _facing_sign: float = 1.0

var texture_path: String = ""

# una sola imagen fija por tipo especial
const SPECIAL_TEXTURES := {
	"veloz": "res://assets/kids/veloz_base.png",
	"basurero": "res://assets/kids/basurero_base.png",
	"fuerte": "res://assets/kids/fuerte_base.png",
}

const NORMAL_DESIGN_COUNT := 8

func setup(type_id: String, day: int, bounds: Rect2, reformed: bool = false) -> void:
	kid_type = type_id
	_bounds = bounds
	is_reformed_ally = reformed

	var t: Dictionary = GameManager.KID_TYPES[type_id]
	max_hp = int((14 + day * 1.5) * t["hp_mult"])
	hp = max_hp
	power = int((3 + day * 0.5) * t["power_mult"])
	speed = 55.0 * t["speed_mult"]
	max_litter = int(t.get("max_litter", 5))
	litter_count = 0

	if type_id == "normal":
		var n: int = randi_range(1, NORMAL_DESIGN_COUNT)
		texture_path = "res://assets/kids/npc%d_front.png" % n
	else:
		texture_path = SPECIAL_TEXTURES.get(type_id, "")

	if reformed:
		state = State.ALLY
	else:
		state = State.WANDER

	_pick_new_wander_target()
	_setup_sprite()
	_apply_tint()
	queue_redraw()

func _setup_sprite() -> void:
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite)
	var tex := load(texture_path)
	_sprite.texture = tex
	var target_h := 72.0
	var s: float = target_h / tex.get_size().y
	_sprite.scale = Vector2(s * _facing_sign, s)
	_sprite.offset = Vector2(0, -tex.get_size().y / 2.0)

func _set_facing_sign(sign_val: float) -> void:
	if sign_val == 0.0 or sign_val == _facing_sign:
		return
	_facing_sign = sign_val
	if _sprite != null:
		_sprite.scale.x = abs(_sprite.scale.x) * _facing_sign

func _apply_tint() -> void:
	if _sprite == null:
		return
	if is_reformed_ally or state == State.ALLY:
		_sprite.modulate = Color(0.7, 1.0, 0.75)
	elif state == State.AWAITING_REFLECTION:
		_sprite.modulate = Color(0.6, 0.6, 0.6)
	else:
		_sprite.modulate = Color(1, 1, 1)

func _process(delta: float) -> void:
	_bob_time += delta
	match state:
		State.WANDER:
			_do_wander(delta)
			_do_litter(delta)
		State.ALLY:
			_do_wander(delta)
	queue_redraw()

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_new_wander_target()
	var dir: Vector2 = (_wander_target - position)
	if dir.length() > 4.0:
		position += dir.normalized() * speed * delta
		if dir.x != 0.0:
			_set_facing_sign(1.0 if dir.x > 0 else -1.0)
	position.x = clampf(position.x, _bounds.position.x, _bounds.position.x + _bounds.size.x)
	position.y = clampf(position.y, _bounds.position.y, _bounds.position.y + _bounds.size.y)

func _pick_new_wander_target() -> void:
	_wander_timer = randf_range(1.5, 4.0)
	_wander_target = Vector2(
		randf_range(_bounds.position.x, _bounds.position.x + _bounds.size.x),
		randf_range(_bounds.position.y, _bounds.position.y + _bounds.size.y)
	)

func _do_litter(delta: float) -> void:
	if litter_count >= max_litter:
		return
	_litter_timer += delta
	if _litter_timer >= GameManager.LITTER_INTERVAL:
		_litter_timer = 0.0
		litter_count += 1
		var main := get_tree().get_first_node_in_group("main")
		if main and main.has_method("spawn_trash_at"):
			main.spawn_trash_at(position + Vector2(randf_range(-20, 20), randf_range(-10, 10)))

func try_start_battle() -> bool:
	if state == State.WANDER:
		state = State.IN_BATTLE
		emit_signal("wants_battle", self)
		return true
	return false

func on_battle_lost_by_kid() -> void:
	state = State.AWAITING_REFLECTION
	_apply_tint()
	queue_redraw()

func on_battle_lost_by_player() -> void:
	state = State.WANDER

func on_reflected(reward: int) -> void:
	GameManager.add_coins(reward)
	GameManager.total_kids_defeated += 1
	# posibilidad de que el nino se reforme y regrese como aliado en dias futuros
	if randf() < 0.25:
		GameManager.reformed_kid_memory.append(kid_type)
	state = State.REFLECTED
	_apply_tint()
	queue_redraw()
	_walk_to_exit_and_free()

## El nino/a se va caminando hacia la reja de salida y luego desaparece.
func leave_map() -> void:
	state = State.REFLECTED
	_apply_tint()
	queue_redraw()
	_walk_to_exit_and_free()

func _walk_to_exit_and_free() -> void:
	var exit_point := Vector2(640.0, 165.0)
	var dir_to_exit: Vector2 = exit_point - position
	if dir_to_exit.x != 0.0:
		_set_facing_sign(1.0 if dir_to_exit.x > 0 else -1.0)
	var dist: float = position.distance_to(exit_point)
	var duration: float = clampf(dist / 140.0, 0.6, 2.5)
	var tw := create_tween()
	tw.tween_property(self, "position", exit_point, duration)
	tw.tween_callback(queue_free)

func give_ally_bonus() -> int:
	if _gave_ally_bonus_today:
		return 0
	_gave_ally_bonus_today = true
	var bonus := randi_range(2, 5)
	GameManager.add_coins(bonus)
	return bonus

func get_random_ability() -> Dictionary:
	var abilities := [
		{"name": "Empujon", "power": power, "accuracy": 0.9},
		{"name": "Grito", "power": int(power * 0.7), "accuracy": 1.0},
	]
	return abilities[randi() % abilities.size()]

func _draw() -> void:
	var t: Dictionary = GameManager.KID_TYPES[kid_type]
	var bob := sin(_bob_time * 4.0) * 2.0

	if _sprite == null or _sprite.texture == null:
		var base_color: Color = t["color"]
		if state == State.AWAITING_REFLECTION:
			base_color = Color(0.6, 0.6, 0.6)
		elif state == State.ALLY:
			base_color = Color(0.35, 0.85, 0.45)
		draw_rect(Rect2(-10, -14 + bob, 20, 26), base_color, true)
		draw_circle(Vector2(0, -22 + bob), 11, Color(0.94, 0.8, 0.65))
		draw_rect(Rect2(-9, 12 + bob, 7, 12), Color(0.2, 0.2, 0.25), true)
		draw_rect(Rect2(2, 12 + bob, 7, 12), Color(0.2, 0.2, 0.25), true)
	else:
		_sprite.position.y = bob - 20

	# barra de vida (solo si no esta en estado normal de deambular sin pelear)
	if state == State.IN_BATTLE or (state == State.WANDER and hp < max_hp):
		var w := 34.0
		var bar_y := -80.0 if _sprite != null and _sprite.texture != null else -42.0
		draw_rect(Rect2(-w / 2, bar_y + bob, w, 5), Color(0.15, 0.15, 0.15), true)
		draw_rect(Rect2(-w / 2, bar_y + bob, w * (float(hp) / float(max_hp)), 5), Color(0.85, 0.2, 0.2), true)

	# icono de tipo especial
	var label_y := -72.0 if _sprite != null and _sprite.texture != null else -34.0
	if kid_type != "normal" and state != State.ALLY:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-6, label_y + bob), t["icon"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14)

	if state == State.ALLY:
		var font2 := ThemeDB.fallback_font
		draw_string(font2, Vector2(-8, label_y + bob), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 14)

	if state == State.AWAITING_REFLECTION:
		var font3 := ThemeDB.fallback_font
		draw_string(font3, Vector2(-24, label_y - 12 + bob), "[E] hablar", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 1, 0.6))
