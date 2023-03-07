extends CharacterBody3D

# emit a signal from player to update health bar
signal health_changed(health_value)

# Get References
@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D


const STARTING_HEALTH = 100
const PISTOL_DAMAGE: int = 25
const WALK: float = 7.0
const RUN: float = 10.0
const JUMP_VELOCITY: float = 7.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = 20.0
var sensivity: float = .005
var speed: float = WALK

var health: int = STARTING_HEALTH

# multiplayer authority for controlling each unique player
# need to be check on _ready, _unhandled_input, and _physics_process
func _enter_tree():
	# has to be an interger
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# set camera for the correct current player
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensivity)
		camera.rotate_x(-event.relative.y * sensivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_pressed("run") and is_on_floor():
		speed = RUN
	
	if not Input.is_action_pressed("run") and is_on_floor():
		speed =  WALK
	
	if Input.is_action_just_pressed("shoot") \
		and anim_player.current_animation != "shoot":
		play_shoot_fx.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, slow_and_stop(velocity.x, delta * gravity), speed)
			velocity.z = move_toward(velocity.z, slow_and_stop(velocity.z, delta * gravity), speed)
	
	# Handle player animation 
	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

# will be call on the remote instance
# call_local args will make this call on both remote and local
@rpc("call_local")
func play_shoot_fx() -> void:
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

# any_peer args needed to call this func on player that dont have authority
# because they're receiving damage
@rpc("any_peer")
func receive_damage() -> void:
	health -= PISTOL_DAMAGE
	if health <= 0:
		health = STARTING_HEALTH
		position = Vector3.ZERO
	health_changed.emit(health)

func slow_and_stop(vel, decelerate) -> float:
	if vel < 0 and vel - decelerate < 0:
		return vel + decelerate
	elif vel > 0 and vel - decelerate > 0:
		return vel - decelerate
	else:
		return 0

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
