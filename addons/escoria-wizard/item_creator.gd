@tool
extends MarginContainer

@onready var lineedit_item_name:LineEdit = %ItemName
@onready var lineedit_gloabl_id:LineEdit = %ItemGlobalID
@onready var lineedit_image_path:LineEdit = %ImagePath

@onready var checkbox_is_interactive:CheckBox = %StartsInteractiveCheckBox
@onready var checkbox_is_background_object:CheckBox = %BackgroundObjectCheckBox

@onready var option_default_action:OptionButton = %DefaultActionOption

@onready var textrect_preview:TextureRect = %Preview
@onready var textrect_preview_inventory:TextureRect = %InventoryPreview
@onready var textrect_preview_object:TextureRect = %ObjectPreview

@onready var label_image_size:Label = %ImageSize
@onready var label_object_item:Label = %ObjectHeading
@onready var label_inventory_item:Label = %InventoryHeading
@onready var label_object_desc:Label = %ObjectDescription
@onready var label_inventory_desc:Label = %InventoryDescription
@onready var label_inventory_path:Label = %InventoryPath
@onready var label_inventory_path_label:Label = %InventoryPathLabel

@onready var dialog_set_image:FileDialog = %SetImageDialog
@onready var dialog_confirmation:ConfirmationDialog = %ConfirmationDialog
@onready var dialog_error:AcceptDialog = %ErrorDialog

@onready var spacer_inventory_path:Control = %InventoryPathSpacer

@onready var button_change_inventory_path:Button = %ChangeInvPathButton
@onready var button_create_item:Button = %CreateButton

var source_image:Image
var image_stream_texture:CompressedTexture2D
var image_has_been_loaded:bool
var image_size:Vector2
var main_menu_requested:bool
var inventory_mode:bool
var settings_modified:bool
var preview_size:Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Capture the size of the window before we update its contents so we have
	# the absolute size before it gets scaled contents applied to it
	preview_size = textrect_preview.size
	inventory_mode = not checkbox_is_background_object.pressed
	item_creator_reset()


func item_creator_reset() -> void:
	lineedit_item_name.text = "replace_me"
	lineedit_gloabl_id.text = ""
	lineedit_image_path.text = ""
	checkbox_is_interactive.button_pressed = true

	if option_default_action.get_item_count() > 0:
		option_default_action.clear()

		for option_list in ["look", "pick up", "open", "close", "use", "push", "pull", "talk"]:
			option_default_action.add_item(option_list)

	option_default_action.selected = 0
	image_size = Vector2.ZERO
	image_has_been_loaded = false
	main_menu_requested = false
	settings_modified = false
	textrect_preview.texture = null

	if inventory_mode:
		label_inventory_path.text = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
		button_create_item.text = "Create Inventory"
		textrect_preview_inventory.visible = true
		textrect_preview_object.visible = false

		for loop in [label_inventory_path, label_inventory_path_label, spacer_inventory_path, \
			button_change_inventory_path]:
			loop.visible = true
	else:
		button_create_item.text = "Create Object"
		textrect_preview_inventory.visible = false
		textrect_preview_object.visible = true
		for loop in [label_inventory_path, label_inventory_path_label, spacer_inventory_path, \
			button_change_inventory_path]:
			loop.visible = false

	for loop in [label_object_item, label_object_desc]:
		loop.visible = not inventory_mode

	for loop in [label_inventory_item, label_inventory_desc, label_inventory_path]:
		loop.visible = inventory_mode
	$Windows/FileDialog.current_dir = ProjectSettings.get_setting("escoria/ui/inventory_items_path")

func resize_image() -> void:
	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	image_size = image_stream_texture.get_size()
	var preview_scale = Vector2.ONE
	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

	if preview_scale.y > preview_scale.x:
		textrect_preview.scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		textrect_preview.scale = Vector2(preview_scale.y, preview_scale.y)

func background_on_ItemName_text_changed(new_text: String) -> void:
	lineedit_gloabl_id.text = new_text
	settings_modified = true


func change_image_button_pressed():
	dialog_set_image.popup_centered()


func LoadObjectFileDialog_file_selected(path: String) -> void:
	image_stream_texture = load(path)

	textrect_preview.texture = image_stream_texture

	resize_image()

	label_image_size.text = "(%s, %s)" % [image_size.x, image_size.y]

	lineedit_image_path.text = path
	image_has_been_loaded = true
	settings_modified = true
	textrect_preview_inventory.visible = false
	textrect_preview_object.visible = false


func _on_CreateButton_pressed() -> void:
	var inventory_path = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	if not DirAccess.dir_exists_absolute(inventory_path):
		dialog_error.dialog_text = \
			"Folder %s does not exist. Please create or change the destination" % inventory_path
		dialog_error.popup_centered()
		return

	if not image_has_been_loaded:
		dialog_error.dialog_text = \
			"No image has been loaded."
		dialog_error.popup_centered()
		return

	if lineedit_item_name.text == "replace_me":
		dialog_error.dialog_text = \
			"Please change the object name."
		dialog_error.popup_centered()
		return

	#if inventory_mode == false:
	#	if not EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes():
	#		dialog_error.dialog_text = \
	#			"Please select a node in the scene tree\nto attach the object to."
	#		dialog_error.popup_centered()
	#		return

	var item = ESCItem.new()
	item.name = lineedit_item_name.text
	item.global_id = lineedit_gloabl_id.text
	item.is_interactive = checkbox_is_interactive.pressed
	item.tooltip_name = lineedit_item_name.text

	var selected_index = option_default_action.selected
	item.default_action = option_default_action.get_item_text(selected_index)

	# Make the item by default it's usable straight out of the inventory
	if inventory_mode == true:
		var new_pool_array: PackedStringArray = item.combine_when_selected_action_is_in
		new_pool_array.append("use")
		item.combine_when_selected_action_is_in = new_pool_array

	# Add Dialog Position to the background item
	var interact_position = ESCLocation.new()
	interact_position.name = "interact_position"
	interact_position.position.y = image_size.y * 2
	item.add_child(interact_position)

	# Add Collision shape to the background item
	var rectangle_shape = RectangleShape2D.new()
	var collision_shape = CollisionShape2D.new()

	collision_shape.shape = rectangle_shape
	collision_shape.shape.extents = image_size / 2
	item.add_child(collision_shape)

	# Add sprite to the background item
	var item_sprite = Sprite2D.new()
	item_sprite.texture = textrect_preview.texture
	item.add_child(item_sprite)

	if not inventory_mode:
		# Create in scene tree
		# Attach to currently selected node in scene tree
		#var current_node = EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes()[0]
		#current_node.add_child(item)
		var owning_node = get_tree().edited_scene_root
		item.set_owner(owning_node)
		# Make it so all the nodes can be seen in the scene tree
		collision_shape.set_owner(owning_node)
		interact_position.set_owner(owning_node)
		item_sprite.set_owner(owning_node)

		get_node("Windows/CreateCompleteDialog").dialog_text = \
			"Background object %s created.\n\n" % item + \
			"Note that you can right-click the node in the\n" + \
			"scene tree and select \"Save branch as scene\"\n" + \
			"if you'd like to reuse this item."
		print("Background object %s created." % item)
		get_node("Windows/CreateCompleteDialog").popup_centered()
	else:
		get_tree().edited_scene_root.add_child(item)
		# Make it so all the nodes can be seen in the scene tree
		collision_shape.set_owner(item)
		interact_position.set_owner(item)
		item_sprite.set_owner(item)

		item.set_owner(get_tree().edited_scene_root)
		# Export scene - create in inventory folder
		var packed_scene = PackedScene.new()

		packed_scene.pack(get_tree().edited_scene_root.get_node(item.name))

		# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
		var err = ResourceSaver.save(packed_scene, "%s/%s.tscn" % [inventory_path, lineedit_item_name.text], \
			ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		if err:
			dialog_error.dialog_text = \
				"Failed to save the item. Please make sure you can\n" + \
				"write to the destination folder" % inventory_path
			dialog_error.popup_centered()
			return
		else:
			item.queue_free()
			get_tree().edited_scene_root.get_node(item.name).queue_free()
			get_node("Windows/CreateCompleteDialog").dialog_text = \
				"Inventory item %s/%s.tscn created." % [inventory_path, lineedit_item_name.text]
			print("Inventory item %s/%s.tscn created." % [inventory_path, lineedit_item_name.text])
			get_node("Windows/CreateCompleteDialog").popup_centered()


func Item_on_ClearButton_pressed() -> void:
	if settings_modified == true:
		main_menu_requested = false
		dialog_confirmation.dialog_text = "WARNING!\n\n" + \
			"If you continue you will lose the current object."
		dialog_confirmation.popup_centered()


func _on_ObjectConfirmationDialog_confirmed() -> void:
	if main_menu_requested == true:
		switch_to_main_menu()
	else:
		item_creator_reset()


func Item_on_ExitButton_pressed() -> void:
	if settings_modified == true:
		main_menu_requested = true
		dialog_confirmation.dialog_text = "WARNING!\n\n" + \
			"If you continue you will lose the current object."
		dialog_confirmation.popup_centered()
	else:
		switch_to_main_menu()


func switch_to_main_menu() -> void:
	get_node("../Menu").visible = true
	get_node("../ItemCreator").visible = false


func _on_StartsInteractiveCheckBox_pressed() -> void:
	settings_modified = true


func _on_ItemGlobalID_text_changed(_new_text: String) -> void:
	settings_modified = true


func _on_DefaultActionOption_item_selected(_index: int) -> void:
	settings_modified = true


func _on_CreateCompleteDialog_confirmed() -> void:
	item_creator_reset()


func _on_BackgroundObjectCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed == false:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/InventoryItemCheckBox.set_pressed_no_signal(true)
		inventory_mode = true
	else:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/InventoryItemCheckBox.set_pressed_no_signal(false)
		inventory_mode = false

	item_creator_reset()


func _on_InventoryItemCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed == false:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox.set_pressed_no_signal(true)
		inventory_mode = false
	else:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox.set_pressed_no_signal(false)
		inventory_mode = true

	item_creator_reset()


func _on_ChangePathButton_pressed():
	$"Windows/FileDialog".popup_centered()


func _on_FileDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting("escoria/ui/inventory_items_path", dir)
	var property_info = {
		"name": "escoria/ui/inventory_items_path",
		"type": TYPE_STRING
	}
	ProjectSettings.add_property_info(property_info)
	label_inventory_path.text = dir
