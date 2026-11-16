extends Node3D
## KnightVisual - اختبار مؤقت: يستبدل الشكل المرئي للاعب بموديل KayKit Knight.
## الاستخدام: أضفه كـ Node3D ابن مباشر لعقدة Player (CharacterBody3D) واربط هذا السكريبت به.
## لا يغيّر الحركة ولا التصادم ولا الكاميرا. يخفي الشكل القديم فقط (لا يحذفه).
## لا يضيف أي أنيميشن وهمي: لو الموديل بلا حركات يطبع تحذيراً ولا يشغّل شيئاً.

const HERO_MODEL_PATHS := {
	"Lolo": "res://assets/models/louay_rigged_animated.glb",
	"Fady": "res://assets/models/fady_rigged_animated.glb",
	"AlSayed": "res://assets/models/alsayed_rigged_animated.glb"
}
const FALLBACK_MODEL_PATH := "res://assets/models/louay_rigged_animated.glb"
var model_path: String = FALLBACK_MODEL_PATH
var _hero_id: String = "Lolo"
var _action_animation_remaining: float = 0.0
var _weapon_anchor: BoneAttachment3D
var _attack_arm_attachment: BoneAttachment3D
var _attack_tween: Tween
## KayKit/glTF غالباً يواجه +Z بينما اتجاه الأمام في Godot هو -Z، لذلك 180 افتراضياً.
@export var face_rotation_deg: float = 180.0
## 0 = يأخذ الارتفاع تلقائياً من CollisionShape3D
@export var target_height: float = 0.0
## مسار الشكل القديم نسبةً لهذه العقدة (مثال: ../Visual). اتركه فارغاً للكشف التلقائي.
@export var old_visual_path: NodePath
@export var hide_old_visual: bool = true
## عتبات السرعة الأفقية لاختيار الحركة (اضبط run_threshold حسب سرعة اللاعب الفعلية)
@export var walk_threshold: float = 0.2
@export var run_threshold: float = 4.0
@export var blend_time: float = 0.15
@export var debug_log: bool = true

var _body: CharacterBody3D
var _model: Node3D
var _anim: AnimationPlayer
var _states: Dictionary = {}
var _current: String = ""


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	if _body == null:
		push_error("KnightVisual: the parent must be a CharacterBody3D (Player).")
		return

	_hero_id = str(get_tree().root.get_meta("selected_hero", "Lolo"))
	model_path = str(HERO_MODEL_PATHS.get(_hero_id, FALLBACK_MODEL_PATH))
	if not ResourceLoader.exists(model_path):
		push_warning("CharacterLoader: model for %s is missing; using the available Louay rigged model." % _hero_id)
		model_path = FALLBACK_MODEL_PATH
	var scene := load(model_path) as PackedScene
	if scene == null:
		push_error("KnightVisual: failed to load " + model_path)
		return

	position = Vector3.ZERO
	rotation = Vector3.ZERO

	_model = scene.instantiate() as Node3D
	if _model == null:
		push_error("KnightVisual: model root is not a Node3D.")
		return
	add_child(_model)
	_model.rotation_degrees.y = face_rotation_deg

	_apply_selected_hero_material()
	_hide_old_visual()
	_fit_to_collision()
	_setup_bone_attachments()
	_setup_animations()


func _apply_selected_hero_material() -> void:
	var hero_id := str(get_tree().root.get_meta("selected_hero", "Lolo"))
	var hero_colors := {
		"Lolo": Color(0.12, 0.82, 0.38),
		"Fady": Color(0.92, 0.16, 0.18),
		"AlSayed": Color(0.12, 0.42, 0.96)
	}
	var hero_color: Color = hero_colors.get(hero_id, hero_colors["Lolo"])
	var material := StandardMaterial3D.new()
	material.albedo_color = hero_color
	material.roughness = 0.68
	material.metallic = 0.08
	var count := 0
	material.albedo_color = Color(hero_color.r, hero_color.g, hero_color.b, 0.16)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	for item in _model.find_children("*", "MeshInstance3D", true, false):
		if item.is_in_group("weapon_visual"):
			continue
		(item as MeshInstance3D).material_overlay = material
		count += 1
	_log("hero material applied: %s (%d mesh instances)" % [hero_id, count])


func _setup_bone_attachments() -> void:
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("CharacterLoader: no Skeleton3D found; weapons will use the player fallback anchor.")
		return
	var skeleton := skeletons[0] as Skeleton3D
	var hand_bone := "RightHand"
	if skeleton.find_bone(hand_bone) < 0:
		hand_bone = "RightLowerArm"
	if skeleton.find_bone(hand_bone) >= 0:
		_weapon_anchor = BoneAttachment3D.new()
		_weapon_anchor.name = "WeaponHandAttachment"
		_weapon_anchor.bone_name = hand_bone
		skeleton.add_child(_weapon_anchor)
	_attack_arm_attachment = BoneAttachment3D.new()
	_attack_arm_attachment.name = "AttackArmAttachment"
	var arm_bone := "RightUpperArm"
	if skeleton.find_bone(arm_bone) < 0:
		arm_bone = hand_bone
	if skeleton.find_bone(arm_bone) >= 0:
		_attack_arm_attachment.bone_name = arm_bone
		skeleton.add_child(_attack_arm_attachment)


func get_weapon_anchor() -> Node3D:
	return _weapon_anchor


func _play_procedural_attack() -> void:
	if not is_instance_valid(_attack_arm_attachment):
		return
	if _attack_tween != null and _attack_tween.is_valid():
		_attack_tween.kill()
	_attack_arm_attachment.rotation = Vector3.ZERO
	_attack_tween = create_tween()
	_attack_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(_attack_arm_attachment, "rotation", Vector3(-0.75, 0.0, -1.05), 0.11)
	_attack_tween.set_ease(Tween.EASE_IN_OUT)
	_attack_tween.tween_property(_attack_arm_attachment, "rotation", Vector3.ZERO, 0.22)


func _log(msg: String) -> void:
	if debug_log:
		print("[KnightVisual] ", msg)


# ---------- الشكل القديم ----------

func _hide_old_visual() -> void:
	if not hide_old_visual:
		return
	if not old_visual_path.is_empty():
		var n := get_node_or_null(old_visual_path)
		if n is Node3D:
			(n as Node3D).visible = false
			_log("hid old visual: " + str(n.get_path()))
		else:
			push_warning("KnightVisual: old_visual_path is invalid: " + str(old_visual_path))
		return

	var hidden_count := 0
	for child in _body.get_children():
		if child == self:
			continue
		if child is CollisionShape3D or child is CollisionPolygon3D:
			continue
		if child is Camera3D or child is SpringArm3D:
			continue
		if child is Node3D and _has_geometry(child) and not _has_camera(child):
			(child as Node3D).visible = false
			hidden_count += 1
			_log("hid old visual: " + str(child.get_path()))
	if hidden_count == 0:
		push_warning("KnightVisual: no old visual found automatically. Set old_visual_path manually.")


func _has_geometry(node: Node) -> bool:
	if node is GeometryInstance3D:
		return true
	for c in node.get_children():
		if _has_geometry(c):
			return true
	return false


func _has_camera(node: Node) -> bool:
	if node is Camera3D or node is SpringArm3D:
		return true
	for c in node.get_children():
		if _has_camera(c):
			return true
	return false


# ---------- الحجم والموضع ----------

func _collision_extents() -> Dictionary:
	for c in _body.get_children():
		if c is CollisionShape3D and c.shape != null:
			var h := 0.0
			var s: Shape3D = c.shape
			if s is CapsuleShape3D:
				h = s.height
			elif s is CylinderShape3D:
				h = s.height
			elif s is BoxShape3D:
				h = s.size.y
			elif s is SphereShape3D:
				h = s.radius * 2.0
			if h > 0.0:
				return {"bottom": c.position.y - h * 0.5, "height": h}
	push_warning("KnightVisual: no usable CollisionShape3D found, using height 1.8 and bottom 0.")
	return {"bottom": 0.0, "height": 1.8}


func _model_aabb() -> AABB:
	var result := AABB()
	var is_first := true
	var inv := global_transform.affine_inverse()
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var m := node as MeshInstance3D
		if m.mesh == null:
			continue
		var box: AABB = (inv * m.global_transform) * m.get_aabb()
		if is_first:
			result = box
			is_first = false
		else:
			result = result.merge(box)
	return result


func _fit_to_collision() -> void:
	var ext := _collision_extents()
	var h: float = target_height if target_height > 0.0 else ext["height"]
	var box := _model_aabb()
	if box.size.y <= 0.001:
		push_warning("KnightVisual: model AABB is empty, cannot auto-fit.")
		return
	var s := h / box.size.y
	_model.scale = Vector3.ONE * s
	var center := box.get_center()
	_model.position = Vector3(
		-center.x * s,
		float(ext["bottom"]) - box.position.y * s,
		-center.z * s
	)
	_log("fit done: target height=%.3f, scale=%.4f, feet y=%.3f" % [h, s, float(ext["bottom"])])


# ---------- الأنيميشن (بدون أي حركات وهمية) ----------

func _setup_animations() -> void:
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		_log("NO AnimationPlayer in the model: no animation will be played (nothing is faked).")
		return
	_anim = players[0] as AnimationPlayer
	var names: PackedStringArray = _anim.get_animation_list()
	if names.is_empty():
		_log("AnimationPlayer exists but has no animations.")
		_anim = null
		return
	_log("animations found: " + ", ".join(names))

	_states["idle"] = _find_anim(names, ["idle"])
	_states["walk"] = _find_anim(names, ["walk"])
	_states["run"] = _find_anim(names, ["run", "sprint"])
	_states["jump"] = _find_anim(names, ["jump", "fall"])
	_states["attack"] = _find_anim(names, ["attack", "slash", "swing"])
	_log("state map: " + str(_states))

	for k in ["idle", "walk", "run"]:
		var clip: String = _states[k]
		if clip != "":
			var a := _anim.get_animation(clip)
			if a != null:
				a.loop_mode = Animation.LOOP_LINEAR


func _find_anim(names: PackedStringArray, keys: Array) -> String:
	for key in keys:
		for n in names:
			if n.to_lower() == key:
				return n
	for key in keys:
		for n in names:
			if n.to_lower().contains(key):
				return n
	return ""


func play_action_animation(animation_key: String, duration: float = 0.38) -> void:
	if animation_key.to_lower() != "attack":
		return
	if _anim != null and str(_states.get("attack", "")) != "":
		_action_animation_remaining = maxf(0.1, duration)
		_play("attack")
	else:
		_play_procedural_attack()


func _physics_process(delta: float) -> void:
	if _anim == null or _body == null:
		return
	if _action_animation_remaining > 0.0:
		_action_animation_remaining = maxf(0.0, _action_animation_remaining - delta)
		if _action_animation_remaining > 0.0 and str(_states.get("attack", "")) != "":
			_play("attack")
			return
	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	var want := "idle"
	if not _body.is_on_floor():
		want = "jump"
	elif speed > run_threshold:
		want = "run"
	elif speed > walk_threshold:
		want = "walk"
	_play(want)


func _play(state: String) -> void:
	var order := {
		"jump": ["jump"],
		"run": ["run", "walk"],
		"walk": ["walk", "run"],
		"attack": ["attack"],
		"idle": ["idle"],
	}
	var clip := ""
	for s in order[state]:
		if _states.get(s, "") != "":
			clip = _states[s]
			break
	if clip == "":
		return
	_anim.speed_scale = 1.45 if state == "run" and clip == str(_states.get("walk", "")) else 1.0
	if clip == _current:
		return
	_current = clip
	_anim.play(clip, blend_time)
