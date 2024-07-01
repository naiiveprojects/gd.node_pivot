tool
extends EditorPlugin

enum { XY, CONTROL }

const LIST_PIVOT := {
	"Top Left": [ Vector2.ONE, Vector2.ZERO ],
	"Top Right": [ Vector2(-1, 1), Vector2.RIGHT ],
	"Bottom Right": [ -Vector2.ONE, Vector2.ONE ],
	"Bottom Left": [ Vector2(1, -1), Vector2.DOWN ], 0: null,
	"Center Left": [ Vector2.RIGHT, Vector2(0, 0.5) ],
	"Center Top": [ Vector2.DOWN, Vector2(0.5, 0) ],
	"Center Right": [ Vector2.LEFT, Vector2(1, 0.5) ],
	"Center Bottom": [ Vector2.UP, Vector2(0.5, 1) ],
	"Center": [ Vector2.ZERO, Vector2.ONE / 2 ]
}

var objects: Array
var trigger := ToolButton.new()
var options := PopupMenu.new()


func _enter_tree() -> void:
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, trigger)
	
	trigger.icon = trigger.get_icon("EditorPivot", "EditorIcons")
	trigger.hint_tooltip = "Preset for Pivot Offset."
	
	for key in LIST_PIVOT.keys():
		if not key is String:
			options.add_separator()
			continue
		
		var icon := "ControlAlign"
		if key.find("Center") == -1:
			icon += key.replace(" ", "")
		else:
			var text: Array = key.rsplit(" ", false)
			text.invert()
			icon += key if text.size() <= 1 else "{}{}".format(text, "{}")
		
		options.add_icon_item(trigger.get_icon(icon, "EditorIcons"), key)
	
	trigger.get_parent().move_child(trigger, 0)
	trigger.add_child(options)
	
	trigger.connect("pressed", self, "_show_options")
	options.connect("id_pressed", self, "_set_pivot_offset")


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, trigger)
	trigger.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		yield(get_tree(), "idle_frame")
		objects = get_editor_interface().get_selection().get_selected_nodes()
		trigger.visible = bool(objects != [])


func _set_pivot_offset(id: int) -> void:
	for node in objects:
		if node.is_class("Sprite") or node.is_class("AnimatedSprite"):
			_set_2d_pivot(node, options.get_item_text(id), node.get_class())
		elif node.is_class("Control"):
			_set_control_pivot(node, options.get_item_text(id))


func _set_2d_pivot(node: Node2D, list: String, type: String) -> void:
	var pivot: Vector2 = LIST_PIVOT[list][XY]
	var tex = node.texture if type == "Sprite" else node.frames.get_frame(node.animation, 0)
	
	var offset := Vector2.ZERO
	offset.x = pivot.x * tex.get_width() / 2
	offset.y = pivot.y * tex.get_height() / 2
	
	node.centered = true
	node.offset = offset
	node.property_list_changed_notify()


func _set_control_pivot(node: Control, list: String) -> void:
	var pivot: Vector2 = LIST_PIVOT[list][CONTROL]
	
	var offset := Vector2.ZERO
	offset.x = pivot.x * node.rect_size.x
	offset.y = pivot.y * node.rect_size.y
	
	node.rect_pivot_offset = offset
	node.property_list_changed_notify()


func _show_options() -> void:
	options.rect_position = trigger.rect_global_position + trigger.rect_size
	options.rect_position.x -= trigger.rect_size.x
	options.popup()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░ Title: NV Node Pivot
# ░░█▀█░█▀█░█░░░█░░░█░█░█▀▀░░ Act: preset for Pivot offset
# ░░█░█░█▀█░░▀▄░░▀▄░▀▄▀░█▀▀░░ Cast[ Editor, Node2D, Control ]
# ░░▀░▀░▀░▀░░░▀░░░▀░░▀░░▀▀▀░░ Writers[ @illlustr, ]
# ░ Projects ░░░░░░░░░░░░░░░░ https://github.com/naiiveprojects
