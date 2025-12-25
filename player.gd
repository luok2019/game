extends BaseCharacter  # 改为继承 BaseCharacter
# 删除：extends CharacterBody2D

# ============ 场景预加载（Day 3 新增）============

# 删除：var damage_number_scene（已在基类中）

# ============ 角色属性 ============
var speed = 200
# 每秒移动200像素的速度

# 攻击力系统（Day 5 改造）
var base_attack = 100  # 基础攻击力（固定值）
# 【设计决策】初始基础攻击力100
# 敌人初始血量50
# 1次攻击击杀（100 > 50）

var attack_power = 100  # 当前攻击力（基础+装备加成）
# 【Day 5 新增】attack_power 是最终攻击力
# 由 base_attack + equipment_bonus["attack"] 计算得出
# 拾取装备后会自动更新
# 【重要】初始值必须等于 base_attack（没有装备时）

var attack_cooldown = 0.0  # 攻击冷却计时器

# 生命值系统（Day 5 改造）
# 删除：var hp, max_hp（已在基类中）
var base_max_hp = 100  # 基础最大血量（固定值）

# ============ 装备系统（Day 5 新增）============

# 装备栏：存储当前装备的物品数据
var equipped_weapon: Dictionary = {}  # 当前装备的武器数据
var equipped_armor: Dictionary = {}  # 当前装备的防具数据

# 装备加成统计：累计所有装备提供的属性加成
var equipment_bonus: Dictionary = {
	"attack": 0,  # 装备提供的攻击力加成
	"hp": 0       # 装备提供的生命值加成
}

# ============ 节点引用 ============

@onready var attack_area = $AttackArea
# 删除：@onready var hp_bar（已在基类中）

# ============ 初始化 ============

func _ready() -> void:
	"""玩家初始化"""
	# 调用基类的 _ready()，初始化血条
	super._ready()

	# 玩家特有的初始化
	max_hp = base_max_hp
	hp = max_hp
	recalculate_stats()
	update_hp_bar()

# ============ 游戏主循环 ============

func _physics_process(delta):
	# _physics_process在固定的物理帧率下调用（默认60次/秒）
	# 适合处理物理相关的逻辑，如移动、碰撞等

	# 获取输入方向
	var direction = Input.get_axis("ui_left", "ui_right")
	# get_axis返回值：
	# - 按A键(或左箭头)：-1.0
	# - 按D键(或右箭头)：1.0
	# - 同时按或不按：0.0

	# 根据输入设置速度
	if direction:
		# 如果有输入
		velocity.x = direction * speed
		# 例如：按D键时，direction=1, velocity.x=200（向右）
		# 按A键时，direction=-1, velocity.x=-200（向左）
	else:
		# 如果没有输入
		velocity.x = 0
		# 立即停止（没有惯性）

	# 应用移动
	move_and_slide()
	# CharacterBody2D的内置方法：
	# 1. 根据velocity移动角色
	# 2. 自动处理碰撞
	# 3. 内部已经乘了delta，所以我们不需要乘

	# -------- 攻击冷却倒计时 --------
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# -------- 检测攻击输入 --------
	if Input.is_action_just_pressed("ui_accept") and attack_cooldown <= 0:
		do_attack()

# ============ 攻击方法 ============

func do_attack():
	# 设置冷却时间
	attack_cooldown = 0.5  # 0.5秒冷却

	# 新增：播放攻击音效
	get_node("/root/AudioManager").play_sound("attack")

	print("攻击！")  # 调试输出

	# 获取攻击范围内的所有物体
	var enemies = attack_area.get_overlapping_bodies()

	# 遍历所有检测到的物体
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			# 如果这个物体有take_damage方法，就调用它
			enemy.take_damage(attack_power)

# ============ 受伤系统（重写基类方法）============

# 删除：take_damage()（使用基类的）
# 删除：update_hp_bar()（使用基类的）
# 删除：spawn_damage_number()（使用基类的）
# 删除：flash_red()（使用基类的）

# 重写音效钩子
func on_take_damage() -> void:
	"""玩家受击时播放音效"""
	get_node("/root/AudioManager").play_sound("hit")

# 只重写 die()，因为玩家死亡有特殊处理
func die() -> void:
	"""玩家死亡：重新开始游戏"""
	print("玩家死亡！")

	# 播放死亡音效
	get_node("/root/AudioManager").play_sound("death")

	get_tree().reload_current_scene()

# ============ 拾取系统（Day 5 新增，Day 6 改造）============

func pickup_item(item_data: Dictionary) -> void:
	"""拾取装备并添加到背包"""
	print("拾取: ", ItemData.get_full_name(item_data))

	# 获取背包节点
	var inventory = get_tree().root.get_node("Main/UI/Inventory")
	if inventory:
		# 尝试添加到背包
		var success = inventory.add_item(item_data)
		if not success:
			# 背包满了，显示提示
			print("背包已满，无法拾取！")
			return


func equip_weapon(item_data: Dictionary) -> void:
	"""装备武器并更新攻击力加成"""
	equipped_weapon = item_data
	equipment_bonus["attack"] = item_data["stats"].get("attack", 0)
	print("装备武器: ", ItemData.get_full_name(item_data), " 攻击+", equipment_bonus["attack"])


func equip_armor(item_data: Dictionary) -> void:
	"""装备防具并更新生命值加成"""
	equipped_armor = item_data
	equipment_bonus["hp"] = item_data["stats"].get("hp", 0)
	print("装备防具: ", ItemData.get_full_name(item_data), " 生命+", equipment_bonus["hp"])


func recalculate_stats() -> void:
	"""重新计算所有角色属性"""
	# 计算攻击力：基础值 + 装备加成
	attack_power = base_attack + equipment_bonus["attack"]

	# 保存旧的最大血量（用于计算百分比）
	var old_max_hp: float = max_hp

	# 计算新的最大血量：基础值 + 装备加成
	max_hp = base_max_hp + equipment_bonus["hp"]

	# 如果最大血量增加了，按比例增加当前血量
	if max_hp > old_max_hp:
		var hp_percent: float = float(hp) / old_max_hp
		hp = int(max_hp * hp_percent)

	# 更新血条 UI
	update_hp_bar()

	# 通知 Main 更新攻击力显示
	var main_node = get_tree().root.get_node("Main")
	if main_node and main_node.has_method("update_player_stats"):
		main_node.update_player_stats()

	print("属性更新 - 攻击:", attack_power, " 血量:", hp, "/", max_hp)
