# Main_scene is the entry point for Godot Engine.
# This scene sets up the main menu scene to load.
extends Node
class_name ESCMain

var escoria_node: Escoria

var wizard_test: bool = false

# Start the main menu
func _ready():
	escoria.logger.info(self, "Escoria starts...")
	if wizard_test:
		escoria.logger.info(self, "Starting wizard test...")
		var test_node = preload("res://addons/escoria-wizard/test_wizard.tscn").instantiate()
		add_child(test_node)
		return

	escoria_node = preload("res://addons/escoria-core/game/escoria.tscn").instantiate()
	add_child(escoria_node)

	if not escoria.is_direct_room_run:
		escoria_node.init()
