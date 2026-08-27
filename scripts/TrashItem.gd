extends Node2D
class_name TrashItem
##
## TrashItem.gd
## Un pedazo de basura tirado por un nino en el patio. El jugador
## lo recoge presionando E cuando esta cerca (radio segun herramientas).
##

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	var textures := _get_trash_textures()
	if textures.size() > 0:
		sprite.texture = load(textures[randi() % textures.size()])
		var target_h := 26.0
		var tex_size: Vector2 = sprite.texture.get_size()
		if tex_size.y > 0:
			var scale_factor: float = target_h / tex_size.y
			sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(sprite)

	# efecto de aparicion (sin mover la posicion, solo un pequeno "pop")
	scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(1, 1), 0.3)

static var _cached_textures: Array = []

func _get_trash_textures() -> Array:
	if _cached_textures.size() > 0:
		return _cached_textures
	var dir := DirAccess.open("res://assets/trash")
	var list: Array = []
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".png"):
				list.append("res://assets/trash/" + f)
			f = dir.get_next()
		dir.list_dir_end()
	_cached_textures = list
	return list

var _spawn_time: float = 0.0

func _process(delta: float) -> void:
	_spawn_time += delta
	# ligero balanceo, sin cambiar la posicion
	rotation = sin(_spawn_time * 2.0) * 0.05
