@tool
extends Control

const SCRIPT_BLANK_TEXT         = "Room will not have a script configured."
const SCRIPT_SELECT_TEXT        = "Please select script."
const PLAYER_BLANK_TEXT         = "Scene will be left blank."
const PLAYER_SELECT_TEXT        = "Please select scene."
const BACKGROUND_BLANK_TEXT     = "Image will be left blank."
const BACKGROUND_SELECT_TEXT    = "Please select image."

const ROOM_PATH_SETTING         = "escoria/wizard/path_to_rooms"

var settings_modified: bool

@onready var dialog_player_scene_file: FileDialog = $InformationWindows/PlayerSceneFileDialog
@onready var dialog_background_image_file: FileDialog = $InformationWindows/BackgroundImageFileDialog
@onready var dialog_room_folder: FileDialog = $InformationWindows/RoomFolderDialog
@onready var error_dialog_generic: AcceptDialog = $InformationWindows/GenericErrorDialog


func _ready() -> void:
	dialog_player_scene_file.get_cancel_button().connect("pressed", Callable(self, "PlayerSceneCancelled"))
	dialog_background_image_file.get_cancel_button().connect("pressed", Callable(self, "BackgroundFileCancelled"))
	
	for c in $InformationWindows.get_children():
		c.hide()

func PlayerSceneCancelled() -> void:
	if %PlayerScene.text == PLAYER_SELECT_TEXT:
		%UseEmptyPlayerButton.button_pressed = true


func BackgroundFileCancelled() -> void:
	if %BackgroundImage.text == BACKGROUND_SELECT_TEXT:
		%UseEmptyBackground.button_pressed = true


func room_creator_reset() -> void:
	var roompath = ProjectSettings.get_setting(ROOM_PATH_SETTING)
	
	%RoomName.text = ""
	%GlobalID.text = ""
	%PlayerScene.text = PLAYER_BLANK_TEXT
	%SelectPlayerScene.visible = false
	%SelectPlayerSceneSpacer.visible = true
	%UseEmptyPlayerButton.button_pressed = true
	%ESCScript.editable = false
	%ESCScript.text = SCRIPT_BLANK_TEXT
	%NoRoomScript.button_pressed = true
	%BackgroundImage.text = BACKGROUND_BLANK_TEXT
	%UseEmptyRoomSpacer.visible = true
	%UseEmptyBackground.button_pressed = true
	%SelectBackground.visible = false
	%SelectBackgroundSpacer.visible = true
	%BackgroundPreview.visible = true
	%RoomBackground.visible = true
	%BackgroundPreview.texture = null
	%RoomFolder.text = roompath if roompath else ""
	dialog_room_folder.current_dir = roompath if roompath else ""
	settings_modified = false


func _on_RoomName_text_changed(new_text: String) -> void:
	%GlobalID.text = new_text
	settings_modified = true


func _on_GlobalID_text_changed(new_text: String) -> void:
	settings_modified = true


func _on_UseEmptyPlayerButton_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		%SelectPlayerScene.visible = false
		%SelectPlayerSceneSpacer.visible = true
		%PlayerScene.text = PLAYER_BLANK_TEXT
	else:
		%SelectPlayerScene.visible = true
		%SelectPlayerSceneSpacer.visible = false
		%PlayerScene.text = PLAYER_SELECT_TEXT
		dialog_player_scene_file.popup_centered()


func _on_SelectPlayerScene_pressed() -> void:
	dialog_player_scene_file.visible = true
	dialog_player_scene_file.invalidate()


func _on_PlayerSceneFileDialog_file_selected(path: String) -> void:
	settings_modified = true
	%PlayerScene.text = path


func _on_UseEmptyRoomScript_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		%ESCScript.editable = false
		%ESCScript.text = SCRIPT_BLANK_TEXT
	else:
		%ESCScript.editable = true
		%ESCScript.text = "%s.esc" % %GlobalID.text


func _on_ESCScriptFileDialog_file_selected(path: String) -> void:
	settings_modified = true
	%ESCScript.text = path


func _on_UseEmptyBackground_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		%SelectBackground.visible = false
		%SelectBackgroundSpacer.visible = true
		%BackgroundImage.text = BACKGROUND_BLANK_TEXT
		%BackgroundPreview.texture = null
		%RoomBackground.visible = true
	else:
		%SelectBackground.visible = true
		%SelectBackgroundSpacer.visible = false
		%BackgroundImage.text = BACKGROUND_SELECT_TEXT

		var viewport_centre: Vector2 = get_viewport_rect().size / 2
		var dialog_start: Vector2 = dialog_background_image_file.size / 2
		var dialog_pos: Vector2 = viewport_centre - dialog_start
		dialog_background_image_file.position = dialog_pos

		dialog_background_image_file.popup_centered()


func _on_SelectBackground_pressed() -> void:
	var viewport_centre: Vector2 = get_viewport_rect().size / 2
	var dialog_start: Vector2 = dialog_background_image_file.size / 2
	var dialog_pos: Vector2 = viewport_centre - dialog_start
	dialog_background_image_file.position = dialog_pos

	dialog_background_image_file.visible = true
	dialog_background_image_file.invalidate()


func _on_BackgroundImageFileDialog_file_selected(path: String) -> void:
	settings_modified = true

	%BackgroundImage.text = path

	var image_stream_texture:CompressedTexture2D

	image_stream_texture = load(path)

	%BackgroundPreview.texture = image_stream_texture
	%RoomBackground.visible = false
	set_preview_scale()


func set_preview_scale() -> void:
	var preview_scale = Vector2.ONE
	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	var preview_size = %RoomBackground.get_size()
#	%BackgroundPreview.rect_scale = Vector2.ONE
	var image_size = %BackgroundPreview.texture.get_size()

	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

#	print("scale = "+str(preview_scale)+", preview size = "+str(preview_size)+", image_size = "+str(image_size))
	if preview_scale.y > preview_scale.x:
		%BackgroundPreview.scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		# Image width will hit the preview boundary before the height will
		%BackgroundPreview.scale = Vector2(preview_scale.y, preview_scale.y)


func _on_ClearButton_pressed() -> void:
	if settings_modified:
		$InformationWindows/ClearConfirmationDialog.popup_centered()


func _on_MainMenuButton_pressed() -> void:
	if settings_modified:
		$InformationWindows/MainMenuConfirmationDialog.popup_centered()
	else:
		get_node("../Menu").visible = true
		get_node("../RoomCreator").visible = false


func _on_ClearConfirmationDialog_confirmed() -> void:
	room_creator_reset()


func _on_MainMenuConfirmationDialog_confirmed() -> void:
	get_node("../Menu").visible = true
	get_node("../RoomCreator").visible = false


func _on_ChangeRoomFolderButton_pressed() -> void:
	dialog_room_folder.popup_centered()


func _on_RoomFolderDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting(ROOM_PATH_SETTING, dir)
	var property_info = {
		"name": ROOM_PATH_SETTING,
		"type": TYPE_STRING
	}
	ProjectSettings.add_property_info(property_info)
	%RoomFolder.text = dir

# Creates the room.
# If parameter script_name is empty, no script will be attached
# If parameter player_scene_path is empty, no player will be attached
# If parameter background_image_path is empty, no background will be attached
func create_room(
	room_name: String,
	global_id: String,
	script_name: String,
	room_base_dir: String,
	player_scene_path: String,
	background_image_path: String,
	is_plugin_execution:bool = true
) -> void:
	print("Creating room:")
	print("Room Name: ", room_name)
	print("Global ID: ", global_id)
	print("Script Name: ", script_name)
	print("Room Base Directory: ", room_base_dir)
	print("Player Scene Path: ", player_scene_path)
	print("Background image path: ", background_image_path)
	# Check parameters first
	if room_name.length() < 1:
		error_dialog_generic.dialog_text = "Error!\n\nRoom name must be specified."
		error_dialog_generic.popup_centered()
		return
	
	# User wants a script. Check filename
	if not script_name.is_empty():
		if not script_name.ends_with(".esc") and script_name.length() > 4:
			error_dialog_generic.dialog_text = "Error!\n\n" \
			+ "Room ESC script must be a valid filename ending in '.esc'"
			error_dialog_generic.popup_centered()
			return
		if "/" in script_name:
			error_dialog_generic.dialog_text = "Error!\n\n" \
			+ "Please remove any '/' characters from the name of the Room ESC script."
			error_dialog_generic.popup_centered()
			return
	
	# Checks okay. Let's do this!	
	# Create Room
	var new_room: ESCRoom = ESCRoom.new()
	new_room.name = room_name
	new_room.global_id = global_id
	# Attach script
	if not script_name.is_empty():
		new_room.esc_script = "%s/%s/scripts/%s" % [room_base_dir, room_name, script_name]
	# Attach player
	if not player_scene_path.is_empty():
		var player_scene = load(player_scene_path)
		new_room.player_scene = player_scene
	
	# Attach background
	var background = ESCBackground.new()
	background.name = "Background"
	
	var background_size:Vector2 = Vector2.ONE
	
	if not background_image_path.is_empty():
		var image_stream_texture:CompressedTexture2D
		image_stream_texture = load(background_image_path)
		background.texture = image_stream_texture
		background_size = background.texture.get_size()
	else:
		# Set TextureRect to have the same size as the Viewport so that the room
		# works even if no texture is set in the TextureRect
		background_size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), \
							ProjectSettings.get_setting("display/window/size/viewport_height"))
		background.size = background_size
	new_room.add_child(background)
	
	# Attach walkable area
	var new_terrain = ESCTerrain.new()
	new_terrain.name = "WalkableArea"
	var walkable_area:NavigationRegion2D = NavigationRegion2D.new()
	walkable_area.name = "NavigationRegion2D"
	walkable_area.navigation_polygon = NavigationPolygon.new()
	new_terrain.add_child(walkable_area)
	new_room.add_child(new_terrain)
	
	# Attach Room object node
	var room_objects:Node2D = Node2D.new()
	room_objects.name = "RoomObjects"
	new_room.add_child(room_objects)

	# Attach Start position
	var start_pos = ESCLocation.new()
	start_pos.name = "StartPos"
	start_pos.is_start_location = true
	start_pos.global_id = "%s_start_pos" % room_name
	start_pos.position = Vector2(int(background_size.x / 2), int(background_size.y / 2))
	new_room.add_child(start_pos)

	# Add scene to tree and set owner
	# Only working as a plugin
	if is_plugin_execution:
		get_tree().edited_scene_root.add_child(new_room)
		new_room.set_owner(get_tree().edited_scene_root)

	walkable_area.set_owner(new_room)
	new_terrain.set_owner(new_room)
	background.set_owner(new_room)
	room_objects.set_owner(new_room)
	start_pos.set_owner(new_room)
	
	# Create directories and copy template script if wanted
	DirAccess.make_dir_recursive_absolute("%s/%s/scripts" % [room_base_dir, room_name])
	DirAccess.make_dir_recursive_absolute("%s/%s/objects" % [room_base_dir, room_name])
	# Copy script template
	if not script_name.is_empty():
		DirAccess.copy_absolute("res://addons/escoria-wizard/room_script_template.esc", "%s/%s/scripts/%s" % \
			[room_base_dir, room_name, script_name])

	# Export scene
	var packed_scene = PackedScene.new()
	if is_plugin_execution:
		packed_scene.pack(get_tree().edited_scene_root.get_node(str(new_room.name)))
	else:
		packed_scene.pack(new_room)

	var path_to_room_scene = "%s/%s/%s.tscn" % [room_base_dir, room_name, room_name]
	# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
	ResourceSaver.save(packed_scene, path_to_room_scene, \
		ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

	new_room.queue_free()
	
	if is_plugin_execution:
		get_tree().edited_scene_root.get_node(str(new_room.name)).queue_free()
		var plugin_reference = get_node("..").plugin_reference
		plugin_reference.open_scene(path_to_room_scene)
		plugin_reference._make_visible(false)
	# Scan the filesystem so that the new folders show up in the file browser.
	# Without this you might not see the objects/scripts folders in the filetree.
	# TODO: Check if necessary in Godot4
	# var ep = EditorPlugin.new()
	# ep.get_editor_interface().get_resource_filesystem().scan()
	# ep.free()
	$InformationWindows/CreateCompleteDialog.popup_centered()


func _on_CreateButton_pressed() -> void:
	# Set values to empty if it is placeholder text
	var player_scene_path = %PlayerScene.text
	var room_script_name = %ESCScript.text
	var background_image_path = %BackgroundImage.text
	if player_scene_path == PLAYER_BLANK_TEXT:
		player_scene_path = ""
	if room_script_name == SCRIPT_BLANK_TEXT:
		room_script_name = ""
	if background_image_path == BACKGROUND_BLANK_TEXT:
		background_image_path = ""
	
	create_room(
		%RoomName.text, 
		%GlobalID.text,
		room_script_name,
		%RoomFolder.text,
		player_scene_path,
		background_image_path
		)
