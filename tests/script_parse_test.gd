extends SceneTree
## Load every project GDScript without recursively reloading this running test.

var _script_paths: PackedStringArray = []
var _failures: PackedStringArray = []
var _visited_directories: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_collect_scripts("res://", 0)
	_script_paths.sort()
	for script_path in _script_paths:
		# This test is already parsed and running; reloading itself with CACHE_MODE_IGNORE
		# can cause a self-reload cycle in headless CI.
		if script_path == "res://tests/script_parse_test.gd":
			continue
		var resource := ResourceLoader.load(script_path, "GDScript")
		if resource == null:
			_failures.append("%s: ResourceLoader returned null" % script_path)
		elif not resource is GDScript:
			_failures.append("%s: resource is not a GDScript" % script_path)

	if _script_paths.is_empty():
		_failures.append("No GDScript files were discovered.")

	if not _failures.is_empty():
		push_error("GDScript validation failed (%d/%d):" % [_failures.size(), _script_paths.size()])
		for failure in _failures:
			push_error(failure)
		quit(1)
		return

	print("GDScript validation passed: %d scripts loaded without parse errors." % _script_paths.size())
	quit(0)


func _collect_scripts(directory_path: String, depth: int) -> void:
	if depth > 8 or _visited_directories.has(directory_path):
		return
	_visited_directories[directory_path] = true

	for file_name in DirAccess.get_files_at(directory_path):
		if file_name.get_extension().to_lower() == "gd":
			_script_paths.append(directory_path.path_join(file_name))

	for directory_name in DirAccess.get_directories_at(directory_path):
		if not directory_name.begins_with("."):
			_collect_scripts(directory_path.path_join(directory_name), depth + 1)
