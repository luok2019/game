extends BaseCharacter  # 改为继承 BaseCharacter

# ============ 场景预加载 ============

# 删除：var damage_number_scene（已在基类中）
var dropped_item_scene = preload("res://scenes/items/dropped_item.tscn")

# ============ 敌人属性 ============

# 删除：var hp, max_hp（已在基类中）
@export var speed = 80
@export var attack_power = 10

# ============ AI状态 ============

var player = null
var attack_cooldown = 0.0
var attack_range = 70.0

# ============ 节点引用 ============

# 删除：@onready var hp_bar（已在基类中）

# ============ 初始化 ============

func _ready() -> void:
	"""敌人初始化"""
	# 调用基类初始化
	super._ready()

	# 等待一帧，确保场景树完全加载
	await get_tree().process_frame

	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("警告：没有找到玩家！")

# ============ AI逻辑 ============

func _physics_process(delta):
	"""敌人AI：追击玩家并攻击"""
	if player and hp > 0:
		var distance_to_player = global_position.distance_to(player.global_position)

		# 攻击冷却倒计时
		if attack_cooldown > 0:
			attack_cooldown -= delta

		# 判断是否在攻击范围内
		if distance_to_player <= attack_range:
			# 在攻击范围内，停止移动
			velocity = Vector2.ZERO

			# 如果冷却完成，执行攻击
			if attack_cooldown <= 0:
				do_attack()
		else:
			# 不在攻击范围内，追击玩家
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed

		# 应用移动
		move_and_slide()

# ============ 攻击系统 ============

func do_attack():
	"""敌人攻击玩家"""
	attack_cooldown = 1.0  # 1秒冷却
	print("敌人攻击！")

	# 检查玩家是否还存在且在范围内
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			player.take_damage(attack_power)

# ============ 受伤系统 ============

# 删除：take_damage()（使用基类的）
# 删除：update_hp_bar()（使用基类的）
# 删除：spawn_damage_number()（使用基类的）

# 重写音效钩子
func on_take_damage() -> void:
	"""敌人受击时播放音效"""
	get_node("/root/AudioManager").play_sound("hit")

# 重写 die()，因为敌人死亡有掉落
func die() -> void:
	"""敌人死亡：增加击杀数并掉落装备"""
	print("敌人死亡！")

	# 播放死亡音效
	get_node("/root/AudioManager").play_sound("death")

	# 通知Main增加击杀数
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("add_kill"):
		main.add_kill()

	# 掉落装备
	drop_item()

	queue_free()

# ============ 掉落系统 ============

func drop_item() -> void:
	"""掉落装备"""
	var item = ItemData.generate_random_item()
	var dropped = dropped_item_scene.instantiate()
	dropped.set_item_data(item)
	dropped.position = position
	get_parent().add_child(dropped)

	print("掉落: ", ItemData.get_full_name(item))
