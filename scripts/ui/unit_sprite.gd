extends Control
## An animated character sprite for the UI.
## Sprite sheets live in res://assets/sprites/<id>.png as 3 square frames: idle A, idle B, attack.
## (Drawn by tools/make_sprites.py; replace the PNG with real art of the same layout any time.)
##
## Animations: idle breathing, attack lunge, hurt flash + shake, death, revive, enrage.

const FRAME_IDLE_A := 0
const FRAME_IDLE_B := 1
const FRAME_ATTACK := 2

var sprite_id := ""
var facing := 1          # 1 = faces right (heroes), -1 = faces left (monsters)
var dead := false
var _sprite: AnimatedSprite2D
var _base_pos := Vector2.ZERO
var _fx: Tween


## size_px: on-screen box size. Frames are scaled by whole numbers to stay crisp.
static func create(id: String, size_px: int, face_left: bool) -> Control:
	var s = load("res://scripts/ui/unit_sprite.gd").new()
	s.custom_minimum_size = Vector2(size_px, size_px)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.facing = -1 if face_left else 1
	s._setup(id, size_px)
	return s


static func frames_for(id: String) -> SpriteFrames:
	var path := "res://assets/sprites/%s.png" % id
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var h := tex.get_height()
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 2.0)
	sf.add_animation("attack")
	sf.set_animation_loop("attack", false)
	for i in 3:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * h, 0, h, h)
		if i < 2:
			sf.add_frame("idle", at)
		else:
			sf.add_frame("attack", at)
	sf.remove_animation("default")
	return sf


## First idle frame as a plain texture (for buttons and icons).
static func portrait(id: String) -> Texture2D:
	var path := "res://assets/sprites/%s.png" % id
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(0, 0, tex.get_height(), tex.get_height())
	return at


func _setup(id: String, size_px: int) -> void:
	sprite_id = id
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	set_texture_id(id, size_px)


func set_texture_id(id: String, size_px: int = -1) -> void:
	var sf := frames_for(id)
	if sf == null:
		return
	sprite_id = id
	if size_px < 0:
		size_px = int(custom_minimum_size.x)
	var h: int = sf.get_frame_texture("idle", 0).get_height()
	var scale_i: int = max(1, size_px / h)
	_sprite.sprite_frames = sf
	_sprite.scale = Vector2(scale_i * facing, scale_i)
	_base_pos = Vector2(size_px / 2.0, size_px / 2.0)
	_sprite.position = _base_pos
	_sprite.speed_scale = randf_range(0.85, 1.15)  # so a row of enemies does not breathe in sync
	_sprite.play("idle")
	_sprite.frame = randi() % 2


## Turn to face left (-1) or right (1), e.g. for villagers walking back and forth.
func set_facing(dir: int) -> void:
	facing = dir
	_sprite.scale.x = abs(_sprite.scale.x) * dir


func _kill_fx() -> void:
	if _fx != null and _fx.is_valid():
		_fx.kill()
	_sprite.position = _base_pos
	_sprite.rotation = 0.0


## Lunge toward the enemy side, showing the attack frame.
func attack(delay: float = 0.0) -> void:
	if dead:
		return
	_kill_fx()
	_fx = create_tween()
	_fx.tween_interval(delay)
	_fx.tween_callback(func(): _sprite.play("attack"))
	_fx.tween_property(_sprite, "position", _base_pos + Vector2(14 * facing, -4), 0.09).set_trans(Tween.TRANS_QUAD)
	_fx.tween_property(_sprite, "position", _base_pos, 0.16)
	_fx.tween_callback(func(): if not dead: _sprite.play("idle"))


## White flash and a short shake.
func hurt(delay: float = 0.0) -> void:
	if dead:
		return
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(_sprite, "modulate", Color(3.0, 3.0, 3.0), 0.03)
	tw.tween_property(_sprite, "modulate", Color(1.4, 0.5, 0.5), 0.08)
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	var sh := create_tween()
	sh.tween_interval(delay)
	for i in 4:
		sh.tween_property(_sprite, "position", _base_pos + Vector2(3 if i % 2 == 0 else -3, 0), 0.03)
	sh.tween_property(_sprite, "position", _base_pos, 0.03)


## Sinks and fades. Call with the unit's alive state after every refresh.
func set_dead(is_dead: bool, delay: float = 0.0) -> void:
	if is_dead == dead:
		return
	dead = is_dead
	_kill_fx()
	_fx = create_tween()
	_fx.tween_interval(delay)
	if dead:
		_fx.tween_callback(func(): _sprite.stop())
		_fx.tween_property(_sprite, "modulate", Color(0.6, 0.2, 0.2, 1.0), 0.1)
		_fx.parallel().tween_property(_sprite, "rotation", deg_to_rad(-80.0 * facing), 0.35)
		_fx.parallel().tween_property(_sprite, "position", _base_pos + Vector2(0, 16), 0.35)
		_fx.tween_property(_sprite, "modulate", Color(0.3, 0.3, 0.35, 0.35), 0.4)
	else:
		_fx.tween_property(_sprite, "modulate", Color(2.0, 2.0, 1.5), 0.2)
		_fx.parallel().tween_property(_sprite, "rotation", 0.0, 0.2)
		_fx.parallel().tween_property(_sprite, "position", _base_pos, 0.2)
		_fx.tween_property(_sprite, "modulate", Color.WHITE, 0.3)
		_fx.tween_callback(func(): _sprite.play("idle"))


## Boss phase 2: swap to the enraged sheet with a violent shake.
func enrage(new_id: String) -> void:
	_kill_fx()
	_fx = create_tween()
	for i in 10:
		_fx.tween_property(_sprite, "position", _base_pos + Vector2(randf_range(-5, 5), randf_range(-3, 3)), 0.04)
	_fx.tween_callback(func(): set_texture_id(new_id))
	_fx.tween_property(_sprite, "modulate", Color(2.5, 0.6, 0.6), 0.1)
	_fx.tween_property(_sprite, "modulate", Color.WHITE, 0.5)
