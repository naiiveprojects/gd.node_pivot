@tool
extends EditorPlugin

enum { TWO_DIMENSION, CONTROL }

const LIST_PIVOT := { # Title : [ 2D, Control ] preset
	"Top Left": [ Vector2i.ONE, Vector2i.ZERO ],
	"Center Top": [ Vector2i.DOWN, Vector2(0.5, 0) ],
	"Top Right": [ Vector2i(-1, 1), Vector2i.RIGHT ],
	"Center Left": [ Vector2i.RIGHT, Vector2(0, 0.5) ],
	"Center": [ Vector2i.ZERO, Vector2.ONE / 2 ],
	"Center Right": [ Vector2i.LEFT, Vector2(1, 0.5) ],
	"Bottom Left": [ Vector2i(1, -1), Vector2i.DOWN ],
	"Center Bottom": [ Vector2i.UP, Vector2(0.5, 1) ],
	"Bottom Right": [ -Vector2i.ONE, Vector2i.ONE ],
}

var objects: Array
var trigger: Button
var panel: PanelContainer
var container: VBoxContainer
var title: Label
var margin: MarginContainer
var grid: GridContainer


func _enter_tree() -> void:
	trigger = Button.new()
	panel = PanelContainer.new()
	container = VBoxContainer.new()
	title = Label.new()
	margin = MarginContainer.new()
	grid = GridContainer.new()
	
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	grid.columns = 3
	var margin_value := 6
	margin.add_theme_constant_override("margin_top", margin_value)
	margin.add_theme_constant_override("margin_left", margin_value)
	margin.add_theme_constant_override("margin_bottom", margin_value)
	margin.add_theme_constant_override("margin_right", margin_value)
	
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, trigger)
	trigger.get_parent().move_child(trigger, 0)
	trigger.flat = true
	trigger.icon = trigger.get_theme_icon("EditorPivot", "EditorIcons")
	trigger.tooltip_text = "Preset for Pivot Offset."
	title.text = "Pivot Offset"
	
	for key in LIST_PIVOT.keys():
		var button := Button.new()
		var icon := "ControlAlign" + str(key).replace(" ", "")
		button.flat = true
		button.icon = trigger.get_theme_icon(icon, "EditorIcons")
		button.tooltip_text = key
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.pressed.connect(_set_pivot_offset.bind(key))
		grid.add_child(button)
	
	panel.add_theme_stylebox_override(
			"panel",
			trigger.get_theme_stylebox("Content", "EditorStyles")
	)
	panel.visible = false
	margin.add_child(grid)
	container.add_child(title)
	container.add_child(margin)
	panel.add_child(container)
	add_child(panel)
	
	panel.mouse_exited.connect( func(): panel.hide() )
	trigger.pressed.connect(
			func():
				panel.position = trigger.global_position + trigger.size
				panel.position.x -= trigger.size.x
				panel.show()
	)


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, trigger)
	trigger.queue_free()
	panel.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		await get_tree().process_frame
		objects = get_editor_interface().get_selection().get_selected_nodes()
		trigger.visible = bool(objects != [])


func _set_pivot_offset(pivot_offset: String) -> void:
	for node in objects:
		if node.is_class("Sprite2D") or node.is_class("AnimatedSprite2D"):
			_set_pivot_2d(node, pivot_offset, node.get_class())
		elif node.is_class("Control"):
			_set_pivot_control(node, pivot_offset)
	panel.hide()


func _set_pivot_2d(node: Node2D, pivot_offset: String, type: String) -> void:
	var pivot: Vector2 = LIST_PIVOT[pivot_offset][TWO_DIMENSION]
	var tex = node.texture if type == "Sprite2D" else node.frames.get_frame(node.animation, 0)
	
	var offset := Vector2.ZERO
	offset.x = pivot.x * tex.get_width() / 2
	offset.y = pivot.y * tex.get_height() / 2
	
	node.centered = true
	node.offset = offset
	node.notify_property_list_changed()


func _set_pivot_control(node: Control, pivot_offset: String) -> void:
	var pivot: Vector2 = LIST_PIVOT[pivot_offset][CONTROL]
	
	var offset := Vector2.ZERO
	offset.x = pivot.x * node.size.x
	offset.y = pivot.y * node.size.y
	
	node.pivot_offset = offset
	node.notify_property_list_changed()
