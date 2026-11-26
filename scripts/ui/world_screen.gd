extends Node2D
## The open world, drawn in 2.5D (isometric). Tap the ground to walk, tap a mineral vein to
## gather it, walk into monsters to fight them with dice. All rules live in scripts/core/world.gd.

const World = preload("res://scripts/core/world.gd")
const Profile = preload("res://scripts/core/profile.gd")
const Combat = preload("res://scripts/core/combat.gd")
const CombatView = preload("res://scripts/ui/combat_view.gd")
const UnitSprite = preload("res://scripts/ui/unit_sprite.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")
const Sfx = preload("res://scripts/ui/sfx.gd")

const TOWN_SCENE := "res://scenes/town.tscn"
const BIOMES := ["deadwood", "swamp", "deepforest", "coast", "snow", "volcanic", "wasteland"]
const BIOME_MAP_COLORS := {
	"deadwood": Color("#5a524a"), "swamp": Color("#3e5a3c"), "deepforest": Color("#2f6e36"), "coast": Color("#b8a478"),
	"snow": Color("#dfe6ee"), "volcanic": Color("#5a2e2a"), "wasteland": Color("#8a7a6a"),
}
const TIER_COLORS := [Color("#7fd07f"), Color("#7fd07f"), Color("#e8d66a"), Color("#f09a4a"), Color("#e0504a"), Color("#b070f0")]
const DECOR_DENSITY := 0.13
const SPEED := 95.0
const GATHER_TIME := 1.2
const BATTLE_SCENES := {
	"deadwood": ["battle_early", Color(1, 1, 1)], "swamp": ["battle_mid", Color(0.8, 1.0, 0.8)],
	"deepforest": ["battle_early", Color(0.75, 1.15, 0.8)], "coast": ["battle_mid", Color(0.85, 0.95, 1.2)],
	"snow": ["battle_early", Color(1.3, 1.35, 1.5)], "volcanic": ["battle_late", Color(1, 1, 1)],
	"wasteland": ["battle_boss", Color(1.1, 0.95, 0.85)],
}

var world: World
var profile: Profile
var rng := RandomNumberGenerator.new()

var _ground: TileMapLayer
var _objects: Node2D
var _player: AnimatedSprite2D
var _camera: Camera2D
var _target := Vector2.ZERO
var _moving := false
var _pending_node := ""
var _gathering := 0.0
var _node_sprites := {}     # node id -> Sprite2D
var _enemy_nodes := {}      # enemy id -> Node2D
var _regen := 0.0
var _save_timer := 0.0
var _in_combat := false
var _fight_enemy: Dictionary = {}
var _challenge_boss := ""      # bosses only fight when you tap them on purpose
var _boss_warned := ""

# HUD
var _hud: CanvasLayer
var _country_label: Label
var _tier_label: Label
var _desc_label: Label
var _party_box: HBoxContainer
var _bag_label: Label
var _minimap: TextureRect
var _mini_dot: ColorRect
var _big_map: Control
var _sharpen_panel: PanelContainer  # 3.4: pick 1 of 3 sharpenings after an Isle win
var _sharpen_box: VBoxContainer
var _toast: Label
var _gather_bar: ProgressBar
var _combat_view: CombatView
var _last_country := -1


func _ready() -> void:
	rng.randomize()
	profile = Profile.new()
	profile.load_profile()
	world = World.new()
	if not profile.world_state.is_empty():
		world.load_dict(profile.world_state)
	# The party always sets out with its current gear and stars from town.
	var pet_id: String = profile.owned_pets[0] if not profile.owned_pets.is_empty() else ""
	# 3.5: an Isle trip interrupted by closing the app resumes (HP, sharpened faces, a pending sharpening).
	var resumed := world.begin_trip(profile.party, profile.stars, pet_id, profile.gear_bonuses(), profile.level("chapel"))
	world.time_of_day = profile.time_name()
	_build_world()
	_build_hud()
	_player.position = _ground.map_to_local(world.player_cell)
	_target = _player.position
	_camera.position = _player.position
	_camera.reset_smoothing()
	_refresh_hud()
	if resumed:
		_show_toast(tr("You pick up the trail where you left it."), Color("#b07cf0"))
	if not world.sharpen_offers.is_empty():
		_show_sharpen()


# ---------------------------------------------------------------- building the world

func _build_world() -> void:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(64, 32)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/world/tiles.png")
	src.texture_region_size = Vector2i(64, 32)
	var count: int = src.texture.get_width() / 64
	for i in count:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	_ground = TileMapLayer.new()
	_ground.tile_set = ts
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_ground)
	var water_base := BIOMES.size() * 3
	var deco_rng := RandomNumberGenerator.new()
	deco_rng.seed = 77
	_objects = Node2D.new()
	_objects.y_sort_enabled = true
	_objects.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_objects)
	var decor_tex := {}
	for b in BIOMES:
		decor_tex[b] = [load("res://assets/world/decor_%s_0.png" % b), load("res://assets/world/decor_%s_1.png" % b)]
	var margin := 12
	for y in range(-margin, world.size + margin):
		for x in range(-margin, world.size + margin):
			var cell := Vector2i(x, y)
			var ci := world.country_index_at(cell)
			if ci == 255:
				_ground.set_cell(cell, 0, Vector2i(water_base + ((x + y) & 1), 0))
				continue
			var biome: String = world.countries[ci]["biome"]
			_ground.set_cell(cell, 0, Vector2i(BIOMES.find(biome) * 3 + deco_rng.randi_range(0, 2), 0))
			if deco_rng.randf() < DECOR_DENSITY and Vector2(cell).distance_to(Vector2(world.player_cell)) > 2.5:
				var spr := Sprite2D.new()
				spr.texture = decor_tex[biome][deco_rng.randi_range(0, 1)]
				spr.offset = Vector2(0, -20)
				spr.position = _ground.map_to_local(cell) + Vector2(deco_rng.randf_range(-10, 10), deco_rng.randf_range(-4, 4))
				_objects.add_child(spr)
	# Mineral veins
	for n in world.nodes:
		var c: Dictionary = world.countries[n["country"]]
		var spr := Sprite2D.new()
		if n["kind"] == "tree":
			spr.set_meta("tex", "tree_" + c["wood"]["id"])
			spr.set_meta("spent", "tree_stump")
			spr.offset = Vector2(0, -24)
		else:
			spr.set_meta("tex", "ore_" + c["mineral"]["id"])
			spr.set_meta("spent", "ore_depleted")
			spr.offset = Vector2(0, -10)
		spr.position = _ground.map_to_local(n["cell"])
		_objects.add_child(spr)
		_node_sprites[n["id"]] = spr
	# Roaming monsters
	for e in world.enemies:
		var holder := Node2D.new()
		holder.position = _ground.map_to_local(e["cell"])
		var a := AnimatedSprite2D.new()
		a.sprite_frames = UnitSprite.frames_for(e["group"][0])
		a.flip_h = true
		var big: bool = e.get("boss", false)
		a.offset = Vector2(0, -24) if big else Vector2(0, -16)
		if big:
			a.scale = Vector2(1.3, 1.3)
			var crown := Label.new()
			crown.text = tr("BOSS: ") + w_name(e["group"][0])
			crown.add_theme_font_size_override("font_size", 8)
			crown.add_theme_color_override("font_color", Color("#f2c443"))
			crown.add_theme_color_override("font_shadow_color", Color.BLACK)
			crown.position = Vector2(-40, -70)
			crown.size = Vector2(80, 10)
			crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			holder.add_child(crown)
		a.speed_scale = rng.randf_range(0.8, 1.2)
		a.play("idle")
		holder.add_child(a)
		if e["group"].size() > 1:
			var l := Label.new()
			l.text = "x%d" % e["group"].size()
			l.add_theme_font_size_override("font_size", 8)
			l.add_theme_color_override("font_color", Color("#e05050"))
			l.position = Vector2(6, -34)
			holder.add_child(l)
		_objects.add_child(holder)
		_enemy_nodes[e["id"]] = holder
		# Lazy wandering around their spot (bosses guard their lair).
		if e.get("boss", false):
			continue
		var tw := holder.create_tween().set_loops()
		var home := holder.position
		tw.tween_property(holder, "position", home + Vector2(rng.randf_range(-24, 24), rng.randf_range(-12, 12)), rng.randf_range(2.0, 4.0))
		tw.tween_property(holder, "position", home, rng.randf_range(2.0, 4.0))
	# The party leader
	_player = AnimatedSprite2D.new()
	_player.sprite_frames = UnitSprite.frames_for(world.party[0]["id"] if not world.party.is_empty() else "varek")
	_player.offset = Vector2(0, -16)
	_player.play("idle")
	_objects.add_child(_player)
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2.5, 2.5)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	add_child(_camera)
	_refresh_world_objects()


func w_name(monster_id: String) -> String:
	return tr(world.monster_defs[monster_id]["name"])


func _refresh_world_objects() -> void:
	for n in world.nodes:
		var spr: Sprite2D = _node_sprites[n["id"]]
		spr.texture = load("res://assets/world/%s.png" % (spr.get_meta("tex") if world.node_ready(n) else spr.get_meta("spent")))
	for e in world.enemies:
		_enemy_nodes[e["id"]].visible = world.enemy_active(e)


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var top := UI.panel()
	top.position = Vector2(16, 12)
	top.size = Vector2(430, 0)
	_hud.add_child(top)
	var tb := VBoxContainer.new()
	top.add_child(tb)
	_country_label = UI.label("", 24, UI.TEXT)
	tb.add_child(_country_label)
	_tier_label = UI.label("", 15, UI.GOLD)
	tb.add_child(_tier_label)
	_desc_label = UI.wrap_label("", 13, UI.DIM, 400)
	tb.add_child(_desc_label)

	# Minimap (tap it for the big world map)
	var img := Image.create(world.size, world.size, false, Image.FORMAT_RGBA8)
	for y in world.size:
		for x in world.size:
			var ci := world.country_index_at(Vector2i(x, y))
			img.set_pixel(x, y, Color("#1e324a") if ci == 255 else BIOME_MAP_COLORS[world.countries[ci]["biome"]])
	var map_tex := ImageTexture.create_from_image(img)
	_minimap = TextureRect.new()
	_minimap.texture = map_tex
	_minimap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_minimap.stretch_mode = TextureRect.STRETCH_SCALE
	_minimap.size = Vector2(192, 192)
	_minimap.position = Vector2(1072, 16)
	_minimap.tooltip_text = tr("Tap for the world map")
	_minimap.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: _big_map.visible = not _big_map.visible)
	_hud.add_child(_minimap)
	_mini_dot = ColorRect.new()
	_mini_dot.color = Color.WHITE
	_mini_dot.size = Vector2(6, 6)
	_minimap.add_child(_mini_dot)
	_big_map = _build_big_map(map_tex)

	# Bottom bar: party, bag, actions
	var bottom := UI.panel()
	bottom.position = Vector2(16, 600)
	bottom.size = Vector2(1248, 104)
	_hud.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bottom.add_child(row)
	_party_box = HBoxContainer.new()
	_party_box.add_theme_constant_override("separation", 10)
	row.add_child(_party_box)
	_bag_label = UI.wrap_label("", 13, UI.TEXT, 330)
	_bag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_bag_label)
	var col := VBoxContainer.new()
	row.add_child(col)
	var map_btn := UI.button(tr("World Map"), func(): _big_map.visible = not _big_map.visible, 14)
	map_btn.custom_minimum_size = Vector2(200, 36)
	col.add_child(map_btn)
	var home := UI.choice_button(tr("Return to Ashfall"), _return_to_town, UI.GOLD)
	home.autowrap_mode = TextServer.AUTOWRAP_OFF
	home.custom_minimum_size = Vector2(200, 44)
	col.add_child(home)

	_toast = UI.label("", 20, UI.GOLD)
	_toast.add_theme_color_override("font_shadow_color", Color.BLACK)
	_toast.add_theme_constant_override("shadow_offset_x", 2)
	_toast.add_theme_constant_override("shadow_offset_y", 2)
	_toast.position = Vector2(240, 520)
	_toast.size = Vector2(800, 30)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_hud.add_child(_toast)
	_gather_bar = ProgressBar.new()
	_gather_bar.show_percentage = false
	_gather_bar.size = Vector2(120, 12)
	_gather_bar.position = Vector2(580, 300)
	_gather_bar.max_value = GATHER_TIME
	_gather_bar.hide()
	_hud.add_child(_gather_bar)
	_sharpen_panel = UI.panel(Color("#b07cf0"), 2)
	_sharpen_panel.position = Vector2(390, 200)
	_sharpen_panel.custom_minimum_size = Vector2(500, 0)
	_sharpen_box = VBoxContainer.new()
	_sharpen_box.add_theme_constant_override("separation", 8)
	_sharpen_panel.add_child(_sharpen_box)
	_hud.add_child(_sharpen_panel)
	_sharpen_panel.hide()
	_hud.add_child(_big_map)  # last, so it covers the rest of the HUD
	_big_map.hide()

	var combat_layer := CanvasLayer.new()
	combat_layer.layer = 10
	add_child(combat_layer)
	_combat_view = CombatView.new()
	combat_layer.add_child(UI.full_rect(_combat_view))
	_combat_view.hide()
	_combat_view.finished.connect(_on_combat_finished)


func _build_big_map(tex: Texture2D) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.size = Vector2(1280, 720)
	dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: dim.hide())
	var map := TextureRect.new()
	map.texture = tex
	map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.stretch_mode = TextureRect.STRETCH_SCALE
	map.size = Vector2(560, 560)
	map.position = Vector2(360, 100)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(map)
	var title := UI.label(tr("The Cursed Isle  -  tap anywhere to close"), 24, UI.GOLD)
	title.position = Vector2(360, 52)
	dim.add_child(title)
	var scale := 560.0 / world.size
	for c in world.countries:
		var l := UI.label(tr("%s\nTier %s") % [tr(c["name"]), ["I", "II", "III", "IV", "V"][int(c["tier"]) - 1]], 15, TIER_COLORS[int(c["tier"])])
		l.add_theme_color_override("font_shadow_color", Color.BLACK)
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(180, 40)
		l.position = map.position + Vector2(c["center"][0], c["center"][1]) * scale - Vector2(90, 20)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.add_child(l)
		var mineral := UI.label(tr("%s, %s\nBoss: %s") % [tr(c["mineral"]["name"]), tr(c["wood"]["name"]), world.monster_defs[c["boss"]]["name"]], 11, Color("#d8c8f0"))
		mineral.position = l.position + Vector2(20, 38)
		mineral.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.add_child(mineral)
	return dim


func _refresh_hud() -> void:
	var ci := world.country_index_at(world.player_cell)
	if ci != 255:
		var c: Dictionary = world.countries[ci]
		var tier := int(c["tier"])
		_country_label.text = tr(c["name"])
		_tier_label.text = tr("Tier %s   -   %s   -   Mineral: %s") % [["I", "II", "III", "IV", "V"][tier - 1],
			tr("Danger: fall here and you lose your bag") if world.is_dangerous(c) else tr("Safe: your bag is kept if you fall"), tr(c["mineral"]["name"])]
		_tier_label.add_theme_color_override("font_color", TIER_COLORS[tier])
		var rec: String = ["", tr("any party"), tr("SR gear recommended"), tr("SR gear and 2-star heroes recommended"), tr("SSR gear recommended"), tr("SSR gear and 3-star heroes recommended")][tier]
		_desc_label.text = tr("%s  Recommended: %s.") % [tr(c["desc"]), rec]
		if ci != _last_country and _last_country != -1:
			_show_toast(tr("Entering %s") % tr(c["name"]), TIER_COLORS[tier])
		if not _in_combat:
			Sfx.music(self, c["biome"])
		_last_country = ci
	var scale := 192.0 / world.size
	_mini_dot.position = Vector2(world.player_cell) * scale - Vector2(3, 3)
	for ch in _party_box.get_children():
		ch.queue_free()
	for h in world.party:
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(150, 0)
		v.add_child(UI.label(Combat.short_name(h), 13, UI.TEXT if Combat.is_alive(h) else UI.DIM))
		v.add_child(UI.hp_bar(h["hp"], h["max_hp"], 16))
		_party_box.add_child(v)
	var parts: Array[String] = []
	for id in world.bag:
		parts.append("%s x%d" % [world.material_name(id), int(world.bag[id])])
	_bag_label.text = tr("Bag: ") + (", ".join(parts) if not parts.is_empty() else tr("empty - tap a vein to mine, a marked tree to chop, hunt beasts for hides"))


func _show_toast(text: String, color: Color = UI.GOLD) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	var tw := _toast.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- input and movement

func _unhandled_input(event: InputEvent) -> void:
	if _in_combat or _big_map.visible or _sharpen_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		_pending_node = ""
		_challenge_boss = ""
		# Tapped a boss? Walk up and challenge it.
		for e in world.enemies:
			if e.get("boss", false) and world.enemy_active(e) and _enemy_nodes[e["id"]].position.distance_to(p + Vector2(0, 20)) < 30:
				_challenge_boss = e["id"]
				p = _enemy_nodes[e["id"]].position
				break
		# Tapped a vein? Walk there and gather.
		for n in world.nodes:
			var spr: Sprite2D = _node_sprites[n["id"]]
			var reach := 22.0 if n["kind"] == "tree" else 18.0
			if spr.position.distance_to(p + Vector2(0, 8 if n["kind"] == "ore" else 16)) < reach and world.node_ready(n):
				_pending_node = n["id"]
				p = spr.position + Vector2(0, 7)  # stand just in front of the vein
				break
		_target = p
		_moving = true
		_gathering = 0.0
		_gather_bar.hide()


func _process(delta: float) -> void:
	if _in_combat or _sharpen_panel.visible:
		return
	world.clock += delta
	_regen += delta
	if _regen >= 4.0:
		_regen = 0.0
		world.regenerate(1)
		_refresh_world_objects()
		_refresh_hud()
	_save_timer += delta
	if _save_timer >= 10.0:
		_save_timer = 0.0
		_save()
	if _moving:
		var to := _target - _player.position
		if to.length() < 3.0:
			_moving = false
		else:
			var step := to.normalized() * SPEED * delta
			var next := _player.position + (step if step.length() < to.length() else to)
			if world.is_walkable(_ground.local_to_map(next)):
				_player.position = next
				_player.flip_h = to.x < 0
				_player.offset.y = -16 - abs(sin(world.clock * 12.0)) * 2.0  # walking bob
			else:
				_moving = false
		var cell := _ground.local_to_map(_player.position)
		if cell != world.player_cell:
			world.player_cell = cell
			_refresh_hud()
	else:
		_player.offset.y = -16
	_camera.position = _player.position
	# Gathering
	if _pending_node != "" and not _moving:
		_gathering += delta
		_gather_bar.show()
		_gather_bar.value = _gathering
		if _gathering >= GATHER_TIME:
			var got := world.gather(_pending_node, rng)
			_pending_node = ""
			_gathering = 0.0
			_gather_bar.hide()
			if not got.is_empty():
				Sfx.play(self, "triple" if got["rare"] else "fate")
				_show_toast((tr("RARE! ") if got["rare"] else "") + "+%d %s" % [got["amount"], tr(got["name"])], Color("#b07cf0") if got["rare"] else UI.GOLD)
				_refresh_world_objects()
				_refresh_hud()
				_save()
	# Bumping into monsters starts a fight.
	for e in world.enemies:
		if not world.enemy_active(e):
			continue
		var node: Node2D = _enemy_nodes[e["id"]]
		var d := node.position.distance_to(_player.position)
		if e.get("boss", false):
			if d < 60.0 and _boss_warned != e["id"]:
				_boss_warned = e["id"]
				_show_toast(tr("%s guards this lair. Tap it to challenge (Tier %d).") % [w_name(e["group"][0]), int(world.countries[e["country"]]["tier"])], Color("#f2c443"))
			if d < 16.0 and _challenge_boss == e["id"]:
				_challenge_boss = ""
				_start_fight(e)
				break
			continue
		if d < 14.0:
			_start_fight(e)
			break


# ---------------------------------------------------------------- combat

func _start_fight(e: Dictionary) -> void:
	_in_combat = true
	_moving = false
	_fight_enemy = e
	var c: Dictionary = world.countries[e["country"]]
	var look: Array = BATTLE_SCENES[c["biome"]]
	var combat := world.start_fight(e, rng.randi())
	_combat_view.show()
	_combat_view.bind(combat, tr("%s - Tier %d") % [tr(c["name"]), int(c["tier"])], look[0], look[1])


func _on_combat_finished(victory: bool) -> void:
	_combat_view.hide()
	_in_combat = false
	var fled: bool = _combat_view.combat.fled
	var r := world.flee_fight(_fight_enemy) if fled else world.finish_fight(_fight_enemy, victory, rng)
	profile.record_world_fight(_fight_enemy["group"], victory, _combat_view.combat.twists, _fight_enemy.get("boss", false))
	if victory:
		profile.embers += int(r["embers"])
		profile.star_dust += int(r["dust"])
		var loot: Array[String] = []
		for id in r.get("drops", {}):
			loot.append("%s x%d" % [world.material_name(id), int(r["drops"][id])])
		_show_toast((tr("BOSS DEFEATED! ") if r.get("boss", false) else tr("Victory! ")) + tr("+%d Embers%s%s") % [r["embers"],
			(tr(", +%d Dust") % r["dust"]) if r["dust"] > 0 else "", ("  |  " + ", ".join(loot)) if not loot.is_empty() else ""])
	elif fled:
		_player.position = _ground.map_to_local(world.player_cell)
		_target = _player.position
		_show_toast(tr("You got away. The enemy is still there."), Color("#e8d66a"))
	else:
		_player.position = _ground.map_to_local(world.player_cell)
		_target = _player.position
		_show_toast(tr("Your party was carried back to Ashfall%s") % (tr(" - your bag is lost!") if r["lost_bag"] else "."), UI.BLOOD)
	if r.get("sharpen", false):
		_show_sharpen()
	_refresh_world_objects()
	_refresh_hud()
	_save()


# ---------------------------------------------------------------- sharpening chooser (3.4)

func _show_sharpen() -> void:
	for ch in _sharpen_box.get_children():
		ch.queue_free()
	_sharpen_box.add_child(UI.label(tr("Battle-hardened"), 20, Color("#b07cf0")))
	_sharpen_box.add_child(UI.wrap_label(tr("The fight left its mark. Sharpen one face by +1 until you go home (%d of %d this trip).") % [
		world.trip_carvings + 1, World.MAX_TRIP_CARVINGS], 13, UI.DIM, 460))
	for i in world.sharpen_offers.size():
		var idx := i
		_sharpen_box.add_child(UI.choice_button(world.sharpen_offers[i]["text"], func(): _pick_sharpen(idx), Color("#b07cf0")))
	_sharpen_box.add_child(UI.button(tr("Skip"), func(): _pick_sharpen(-1), 14))
	_sharpen_panel.show()


func _pick_sharpen(index: int) -> void:
	var text := world.choose_sharpening(index) if index >= 0 else ""
	world.skip_sharpening()
	_sharpen_panel.hide()
	if text != "":
		_show_toast(text, Color("#b07cf0"))
		Sfx.play(self, "fate")
	_refresh_hud()
	_save()


# ---------------------------------------------------------------- town

func _save() -> void:
	profile.world_state = world.to_dict()
	profile.save()


func _return_to_town() -> void:
	var moved := profile.bank(world)
	profile.advance_time()  # a trip to the Isle takes time
	world.end_trip()
	_save()
	if not moved.is_empty() or not profile.last_bank_quests.is_empty():
		var TownScreen = load("res://scripts/ui/town_screen.gd")
		var parts: Array[String] = []
		for id in moved:
			parts.append("%s x%d" % [world.material_name(id), int(moved[id])])
		TownScreen.last_result = {"embers": 0, "dice": 0, "quests": profile.last_bank_quests, "banked": ", ".join(parts) if not parts.is_empty() else "nothing"}
	get_tree().change_scene_to_file(TOWN_SCENE)


# ---------------------------------------------------------------- phone Back button / app pause (see app_events.gd)

func on_back() -> bool:
	if _big_map.visible:
		_big_map.hide()
		return true
	return false


func save_state() -> void:
	_save()
