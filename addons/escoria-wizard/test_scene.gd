extends Node2D


# Called when the node enters the scene tree for the first time.
# To test do the following steps:
# - deactivate all Escoria plugins except the wizard
# - Change application/run/main_scene from res://addons/escoria-core/game/main_scene.tscn
#   to res://addons/escoria-wizard/test_scene.tscn
func _ready():
	print("It works")
	$CharacterCreator.setup_test_data()
	$CharacterCreator.export_player()
