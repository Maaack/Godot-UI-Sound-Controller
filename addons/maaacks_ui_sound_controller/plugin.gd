@tool
class_name MaaacksUISoundControllerPlugin
extends EditorPlugin

const PLUGIN_NAME = "Maaack's UI Sound Controller"
const PROJECT_SETTINGS_PATH = "maaacks_ui_sound_controller/"
const PLUGIN_REPO_URL = "https://github.com/Maaack/Godot-UI-Sound-Controller"
const UI_SOUND_CONTROLLER_RELATIVE_PATH = "base/scenes/autoloads/project_ui_sound_controller.tscn"
const OPEN_EDITOR_DELAY : float = 0.1
const MAX_PHYSICS_FRAMES_FROM_START : int = 60

static func get_plugin_name() -> String:
	return PLUGIN_NAME

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir() + "/"

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
	if not ProjectSettings.get_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses", false):
		_add_audio_bus("SFX")
		ProjectSettings.set_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses", true)
		ProjectSettings.save()

func _enable_plugin():
	add_autoload_singleton("ProjectUISoundController", get_plugin_path() + UI_SOUND_CONTROLLER_RELATIVE_PATH)

func _disable_plugin():
	remove_autoload_singleton("ProjectUISoundController")

func _add_to_auto_update_list() -> void:
	var plugin_repos:Dictionary = ProjectSettings.get_setting("plugin_updater/plugins", {})
	plugin_repos[get_plugin_path()] = PLUGIN_REPO_URL
	ProjectSettings.set_setting("plugin_updater/plugins", plugin_repos)

func _remove_from_auto_update_list() -> void:
	var plugin_repos:Dictionary = ProjectSettings.get_setting("plugin_updater/plugins", {})
	plugin_repos.erase(get_plugin_path())
	ProjectSettings.set_setting("plugin_updater/plugins", plugin_repos)

func _enter_tree() -> void:
	_install_audio_busses()
	_add_to_auto_update_list()
	_resave_if_recently_opened()

func _exit_tree() -> void:
	_remove_from_auto_update_list()
