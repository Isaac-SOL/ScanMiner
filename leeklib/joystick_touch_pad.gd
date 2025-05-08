@icon("res://leeklib/icons/JoystickTouchpad.svg")
class_name JoystickTouchPad extends Control

## Based on screen height
@export_range(0,1) var joystick_scale:float = 0.33
## If on, left and right sides will be swapped
@export var right_side: bool = false
## If on, will have two joysticks instead of a joystick and a button
@export var dual_stick: bool = false

# Joystick ui size variables, these are set in the _ready function
var joystick_starting_size: float
var joystick_handle_starting_size: float

# Joystick finger index
# In order to support multitouch we need to keep track the index or ID of the fingers on screen
var joystick_left_finger_index = null
var joystick_right_finger_index = null

# Final joystick output after normalization ( Use get_joystick() to read out this value ) 
var joystick_left: Vector2 = Vector2.ZERO
var joystick_right: Vector2 = Vector2.ZERO

# Button
var button_last_was_pressed: bool = false

# Window size variables
var window_width = 0
var window_height = 0

func _ready():
	if not Util.on_mobile():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	# Gettings screen size
	window_width = get_viewport().content_scale_size.x
	window_height = get_viewport().content_scale_size.y
	
	# Setting joystick base and handle sizes based on screen height and joystick scale
	joystick_starting_size = window_height*joystick_scale
	joystick_handle_starting_size = joystick_starting_size/2
	
	# Setting the sizes of the ui elements of the joystick
	%base_left.size = Vector2(joystick_starting_size,joystick_starting_size)
	%handle_left.size = Vector2(joystick_handle_starting_size,joystick_handle_starting_size)
	%base_right.size = Vector2(joystick_starting_size,joystick_starting_size)
	%handle_right.size = Vector2(joystick_handle_starting_size,joystick_handle_starting_size)

func _process(delta: float) -> void:
	button_last_was_pressed = false

func _input(event):
	# Checking if input is a touch
	if event is InputEventScreenTouch:
		# Handeling the start of a touch
		if event.pressed:
			# Checking if touch is on the correct side of the screen and the joystick if not yet active
			var x_pos = event.position.x * get_viewport().get_screen_transform().x.x
			var correct_side: bool = (x_pos > window_width / 2) if right_side else (x_pos < window_width / 2)
			var base: Control
			var handle: Control
			var do_start: bool = false
			if correct_side && !joystick_left_finger_index:
				# Starting the left touch
				base = %base_left
				handle = %handle_left
				joystick_left_finger_index = event.index
				do_start = true
			else:
				if dual_stick:
					if not joystick_right_finger_index:
						# Starting the right touch (joystick)
						base = %base_right
						handle = %handle_right
						joystick_right_finger_index = event.index
						do_start = true
				else:
					button_last_was_pressed = true
			if do_start:
				base.show()
				handle.show()
				base.position =  event.position - (base.size/2)
				handle.position = event.position - (base.size/2)  + (handle.size/2)
		else:
			# Handeling the end of a touch
			# Ending joystick touch hiding the ui and reseting the joystick
			if event.index == joystick_left_finger_index:
				%base_left.hide()
				%handle_left.hide()
				joystick_left = Vector2.ZERO
				joystick_left_finger_index = null
			if event.index == joystick_right_finger_index and dual_stick:
				%base_right.hide()
				%handle_right.hide()
				joystick_right = Vector2.ZERO
				joystick_right_finger_index = null
	# Checking if input is a touch drag 
	if event is InputEventScreenDrag:
		var base: Control
		var handle: Control
		var do_drag: bool = false
		if event.index == joystick_left_finger_index:
			base = %base_left
			handle = %handle_left
			do_drag = true
		elif event.index == joystick_right_finger_index and dual_stick:
			base = %base_right
			handle = %handle_right
			do_drag = true
		if do_drag:
			# Handeling touch drag of joystick 
			var handle_pos = event.position
			var handle_normalized = event.position
			
			handle_pos -= handle.size/2
			
			handle_normalized -= (base.position + base.size/2)
			handle_normalized = handle_normalized/base.size/2
			
			if base == %base_left:
				joystick_left = handle_normalized/base.size/2
			else:
				joystick_right = handle_normalized/base.size/2
			
			handle_normalized = handle_normalized.normalized()
			
			handle_normalized = handle_normalized*base.size/2
			handle_normalized += (base.position + base.size/2)
			handle_normalized -= handle.size/2
			
			# If touch moves outside of the joystick base use the normalized position of the handle 
			# This way the joystick handle never moves outside of the base
			if event.position.distance_to(base.position+base.size/2) < base.size.x/2:
				handle.position = handle_pos
			else:
				handle.position = handle_normalized

# Getter for joystick value
func get_joystick_left() -> Vector2:
	return joystick_left

# Getter for joystick value
func get_joystick_right() -> Vector2:
	return joystick_right

# Getter for button value (only raising edge)
func is_button_just_pressed() -> bool:
	return button_last_was_pressed
