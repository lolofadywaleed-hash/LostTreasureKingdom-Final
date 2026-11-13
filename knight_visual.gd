extends Node3D
## KnightVisual - اختبار مؤقت: يستبدل الشكل المرئي للاعب بموديل KayKit Knight.
## الاستخدام: أضفه كـ Node3D ابن مباشر لعقدة Player (CharacterBody3D) واربط هذا السكريبت به.
## لا يغيّر الحركة ولا التصادم ولا الكاميرا. يخفي الشكل القديم فقط (لا يحذفه).
## لا يضيف أي أنيميشن وهمي: لو الموديل بلا حركات يطبع تحذيراً ولا يشغّل شيئاً.

@export_file("*.glb") var model_path: String = "res://assets/models/louay_rigged_animated.glb"
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

	_hide_old_visual()
	_fit_to_collision()
	_setup_animations()


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
	_states["jump"] = _find_anim(names, ["jump"])
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


func _physics_process(_delta: float) -> void:
	if _anim == null or _body == null:
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
		"idle": ["idle"],
	}
	var clip := ""
	for s in order[state]:
		if _states.get(s, "") != "":
			clip = _states[s]
			break
	if clip == "" or clip == _current:
		return
	_current = clip
	_anim.play(clip, blend_time)
