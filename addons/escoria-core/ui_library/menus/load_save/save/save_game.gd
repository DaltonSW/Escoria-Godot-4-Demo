# A container for saving to a save slot
extends Control

# Emitted when the back button is pressed
signal back_button_pressed


# The scene to display a slot
@export var slot_ui_scene: PackedScene


# The slot that was pressed
var _slot_pressed = null


# Load the savegames when loaded
func _ready():
	refresh_savegames()


# A slot was pressed, save the game
func _on_slot_pressed(p_slot_n: int):
	_slot_pressed = p_slot_n
	if escoria.save_manager.save_game_exists(p_slot_n):
		$overwrite_confirm_popup.popup_centered_ratio(.3)
	else:
		$save_name_popup.popup_centered_ratio(.3)


# Create the slots from the list of savegames
func refresh_savegames():
	var _slots = $VBoxContainer/ScrollContainer/slots
	for slot in _slots.get_children():
		_slots.remove_child(slot)

	var saves_list = escoria.save_manager.get_saves_list()
	if not saves_list.is_empty():
		for save_key in saves_list.keys():
			var new_slot = slot_ui_scene.instantiate()
			_slots.add_child(new_slot)
			new_slot.set_slot_name_date(saves_list[save_key]["name"], saves_list[save_key]["date"])
			new_slot.connect("pressed", Callable(self, "_on_slot_pressed").bind(save_key))

	var datetime = Time.get_datetime_dict_from_system()
	var datetime_string = "%02d/%02d/%02d %02d:%02d" % [
		datetime["day"],
		datetime["month"],
		datetime["year"],
		datetime["hour"],
		datetime["minute"],
	]
	var new_slot = slot_ui_scene.instantiate()
	_slots.add_child(new_slot)
	new_slot.set_slot_name_date(tr("New save"), datetime_string)
	new_slot.connect("pressed", Callable(self, "_on_slot_pressed").bind(saves_list.size()+1))


# The back button was pressed
func _on_back_pressed():
	back_button_pressed.emit()


# The name for the save game was given, save the game.
#
# #### Parameters
# - p_savename: The name of the savegame entered
func _on_save_name_popup_savegame_name_ok(p_savename: String):
	escoria.save_manager.save_game(_slot_pressed, p_savename)
	refresh_savegames()
	_slot_pressed = null


# Overwriting the savegame was confirmed, show the save name popup
func _on_overwrite_confirm_popup_confirm_yes():
	$save_name_popup.popup_centered_ratio(.3)
