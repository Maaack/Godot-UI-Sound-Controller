@tool
class_name MaaacksUISoundControllerPlugin
extends EditorPlugin

const APIClient = preload("res://addons/maaacks_ui_sound_controller/utilities/api_client.gd")
const DownloadAndExtract = preload("res://addons/maaacks_ui_sound_controller/utilities/download_and_extract.gd")

const PLUGIN_NAME = "Maaack's UI Sound Controller"
const PROJECT_SETTINGS_PATH = "maaacks_ui_sound_controller/"
const OPEN_EDITOR_DELAY : float = 0.1
const MAX_PHYSICS_FRAMES_FROM_START : int = 60

var update_plugin_tool_string : String

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir() + "/"

func _open_check_plugin_version() -> void:
	if ProjectSettings.has_setting(PROJECT_SETTINGS_PATH + "disable_update_check"):
		if ProjectSettings.get_setting(PROJECT_SETTINGS_PATH + "disable_update_check"):
			return
	else:
		ProjectSettings.set_setting(PROJECT_SETTINGS_PATH + "disable_update_check", false)
		ProjectSettings.save()
	var check_version_scene : PackedScene = load(get_plugin_path() + "installer/check_plugin_version.tscn")
	var check_version_instance : Node = check_version_scene.instantiate()
	check_version_instance.auto_start = true
	check_version_instance.new_version_detected.connect(_add_update_plugin_tool_option)
	add_child(check_version_instance)

func _open_update_plugin() -> void:
	var update_plugin_scene : PackedScene = load(get_plugin_path() + "installer/update_plugin.tscn")
	var update_plugin_instance : Node = update_plugin_scene.instantiate()
	update_plugin_instance.auto_start = true
	update_plugin_instance.update_completed.connect(_remove_update_plugin_tool_option)
	add_child(update_plugin_instance)

func _add_update_plugin_tool_option(new_version : String) -> void:
	update_plugin_tool_string = "Update %s to v%s..." % [_get_plugin_name(), new_version]
	add_tool_menu_item(update_plugin_tool_string, _open_update_plugin)

func _remove_update_plugin_tool_option() -> void:
	if update_plugin_tool_string.is_empty(): return
	remove_tool_menu_item(update_plugin_tool_string)
	update_plugin_tool_string = ""

func _resave_if_recently_opened() -> void:
	if Engine.get_physics_frames() < MAX_PHYSICS_FRAMES_FROM_START:
		var timer: Timer = Timer.new()
		var callable := func():
			if Engine.get_frames_per_second() >= 10:
				timer.stop()
				EditorInterface.save_scene()
				timer.queue_free()
		timer.timeout.connect(callable)
		add_child(timer)
		timer.start(OPEN_EDITOR_DELAY)

func _add_audio_bus(bus_name : String) -> void:
	var has_bus_name := false
	for bus_idx in range(AudioServer.bus_count):
		var existing_bus_name := AudioServer.get_bus_name(bus_idx)
		if existing_bus_name == bus_name:
			has_bus_name = true
			break
	if not has_bus_name:
		AudioServer.add_bus()
		var new_bus_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(new_bus_idx, bus_name)
		AudioServer.set_bus_send(new_bus_idx, &"Master")
	ProjectSettings.save()

func _install_audio_busses() -> void:
	if ProjectSettings.has_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses"):
		if ProjectSettings.get_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses") :
			return
	_add_audio_bus("SFX")
	ProjectSettings.set_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses", true)
	ProjectSettings.save()

func _enter_tree() -> void:
	add_autoload_singleton("ProjectUISoundController", get_plugin_path() + "base/scenes/autoloads/project_ui_sound_controller.tscn")
	_install_audio_busses()
	_open_check_plugin_version()
	_resave_if_recently_opened()

func _exit_tree() -> void:
	remove_autoload_singleton("ProjectUISoundController")
	_remove_update_plugin_tool_option()
