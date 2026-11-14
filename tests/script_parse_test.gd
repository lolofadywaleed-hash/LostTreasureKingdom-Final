extends SceneTree
## Load every GDScript in the repository; a parse/compile failure fails CI.

var _script_paths: PackedStringArray = []
var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_collect_scripts("res://")
	_script_paths.sort()
	for script_path in _script_paths:
		var resource := ResourceLoader.load(script_path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
		if resource == null:
			_failures.append("%s: ResourceLoader returned null" % script_path)
		elif not resource is GDScript:
			_failures.append("%s: resource is not a GDScript" % script_path)

	if not _failures.is_empty():
		push_error("GDScript validation failed (%d/%d):" % [_failures.size(), _script_paths.size()])
		for failure in _failures:
			push_error(failure)
		quit(1)
		return

	print("GDScript validation passed: %d scripts loaded without parse errors." % _script_paths.size())
	quit(0)


func _collect_scripts(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_failures.append("%s: could not open directory" % directory_path)
		return

	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var entry_path := directory_path.path_join(entry)
			if directory.current_is_dir():
				if not entry.begins_with("."):
					_collect_scripts(entry_path)
			elif entry.get_extension().to_lower() == "gd":
				_script_paths.append(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()
