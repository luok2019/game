extends Node2D

# ============ 敌人场景（多种）============

var enemy_scenes = [
	preload("res://scenes/characters/enemy.tscn"),        # 普通敌人
	preload("res://scenes/characters/enemy_strong.tscn")  # 强力敌人
	# preload("res://scenes/characters/enemy_fast.tscn")  # 快速敌人（如果创建了）
]
# 【Day 4.3 新增】多种敌人类型
# - 数组存储多个敌人场景
# - 通过索引访问：enemy_scenes[0] 是普通敌人
# - 预加载所有场景，生成时直接实例化

# 敌人生成权重（概率）
var enemy_weights = [
	70,  # 普通敌人70%
	30   # 强力敌人30%
	# 20 # 快速敌人20%（如果有3种）
]
# 【概念⭐】加权随机
# - 数组中的数字代表权重（不是百分比）
# - 权重越大，被选中的概率越高
# - 总权重 = 70 + 30 = 100
# - 普通敌人概率 = 70/100 = 70%
# - 强力敌人概率 = 30/100 = 30%
#
# 【设计决策】为什么是 70:30？
# - 普通敌人是"主力"，保持战斗节奏
# - 强力敌人是"挑战"，偶尔出现增加变化
# - 太多强力敌人会让人感到疲劳
# - 太少则缺乏新鲜感

# ============ 生成设置 ============

var spawn_interval = 3.0  # 生成间隔（秒），每3秒生成一个敌人
# 【设计决策】为什么是3秒？
# - 太快（1秒）：敌人太多，玩家应付不过来
# - 太慢（5秒）：战斗节奏拖沓，缺乏挑战
# - 3秒：适中，给玩家喘息时间

var spawn_offset_x = 400  # 敌人在玩家右侧的偏移距离（像素）
# 【横板游戏设计】
# - 敌人只在玩家右侧生成
# - 玩家向右推进，敌人从右边迎面而来
# - 这是经典横板ARPG的设计（如《死亡细胞》、《恶魔城》）

# ============ 难度系统（Day 7 新增）============

var time_elapsed = 0.0  # 游戏运行时间
var difficulty_level = 1  # 当前难度等级
# 【难度递增】每30秒提升一次难度

# ============ 引用 ============

@onready var timer = $Timer
# Timer节点的引用，用于控制生成间隔

@onready var player = get_tree().get_first_node_in_group("player")
# 【概念⭐】通过组查找玩家
# - get_tree()：获取场景树
# - get_first_node_in_group("player")：查找"player"组的第一个节点
# - Player场景需要添加到"player"组中
#
# 【为什么在@onready中获取】
# - _ready()时才能确保玩家已加入组
# - @onready在_ready()前执行，但场景树已准备好

# ============ 初始化 ============

func _ready():
	# 连接Timer信号
	timer.timeout.connect(_on_timer_timeout)
	# 【概念⭐】信号连接
	# - timer.timeout：Timer的timeout信号
	# - 每次Timer计时结束会触发这个信号
	# - connect()：将信号连接到回调函数
	#
	# 【工作流程】
	# 1. Timer开始计时（3秒）
	# 2. 3秒后触发timeout信号
	# 3. 调用_on_timer_timeout()函数
	# 4. 生成敌人
	# 5. Timer自动重新开始计时（如果One Shot = Off）

# ============ 难度系统（Day 7 新增）============

func _process(delta: float) -> void:
	"""每帧更新：检测难度提升"""
	time_elapsed += delta

	# 每30秒提升一次难度
	var new_difficulty = int(time_elapsed / 30.0) + 1
	if new_difficulty > difficulty_level:
		difficulty_level = new_difficulty
		increase_difficulty()

# ============ 生成逻辑 ============

func _on_timer_timeout():
	# 【回调函数】Timer每3秒触发一次
	# 【概念】回调函数
	# - 由信号自动调用的函数
	# - 不需要手动调用
	spawn_enemy()

func spawn_enemy():
	# 【方法职责】生成一个敌人
	# 每次Timer timeout时调用

	# 检查玩家是否存在
	if not player or not is_instance_valid(player):
		return  # 玩家死亡就不生成了
		# 【安全检查⭐】is_instance_valid()
		# - 确保玩家节点没有被删除
		# - 避免访问已删除节点导致崩溃

	# 【Day 4.3 新增】根据权重随机选择敌人类型
	var enemy_scene = get_weighted_random_enemy()
	var enemy = enemy_scene.instantiate()
	# 【概念⭐】instantiate()
	# - 从预加载的场景创建一个实例
	# - 类似"复制"场景模板
	# - 每次调用创建新的独立对象
	#
	# 【示例】
	# enemy_scene 是模具
	# instantiate() 是用模具生产产品
	# 每次生产的产品都是独立的

	# 【Day 7 新增】根据难度强化敌人
	if difficulty_level > 1:
		# 计算强化倍数：每级增加20%血量，15%攻击力
		var hp_multiplier = 1.0 + (difficulty_level - 1) * 0.2
		var atk_multiplier = 1.0 + (difficulty_level - 1) * 0.15

		# 应用强化（转换为整数避免浮点问题）
		enemy.hp = int(enemy.hp * hp_multiplier)
		enemy.max_hp = enemy.hp
		enemy.attack_power = int(enemy.attack_power * atk_multiplier)

	# 计算生成位置（玩家右侧屏幕外）
	var spawn_pos = player.global_position
	# 【概念】global_position vs position
	# - global_position：世界坐标（相对于场景原点）
	# - position：本地坐标（相对于父节点）
	# - 这里用世界坐标，因为敌人要添加到Main
	#
	# 【为什么用玩家的global_position】
	# - 敌人位置要跟随玩家
	# - 玩家移动到哪，敌人就在哪生成

	spawn_pos.x += spawn_offset_x
	# 【横板游戏】X轴偏移
	# - spawn_offset_x = 400像素
	# - 在玩家右侧400像素处生成
	# - 超出屏幕范围（假设屏幕宽度约1280）
	# - 敌人会从屏幕外走进来

	# Y轴保持与玩家一致，不添加随机偏移
	# 【设计决策】敌人在同一水平线生成
	# - 玩家不需要上下移动来瞄准
	# - 战斗更专注于左右移动和时机把握
	# - 适合初学者教程

	# 设置敌人位置
	enemy.global_position = spawn_pos
	# 【注意】用global_position而不是position
	# - 因为敌人要添加到Main（使用世界坐标）

	# 添加到场景树（作为Main的子节点）
	get_parent().add_child(enemy)
	# 【为什么添加到get_parent()】
	# - EnemySpawner的父节点是Main
	# - get_parent() = Main
	# - 敌人成为Main的子节点，和EnemySpawner平级
	#
	# 【Scene Tree（场景树）结构】
	# Main
	# ├─ Player
	# ├─ EnemySpawner
	# └─ Enemy (新生成的) ← 平级，独立存在

	# 调试输出
	print("生成敌人于: ", spawn_pos, " 难度等级: ", difficulty_level)
	# 【开发提示】后续可以删除
	# - 用于验证生成位置是否正确
	# - 确认敌人在玩家右侧

# ============ 加权随机选择（Day 4.3 新增）============

func get_weighted_random_enemy():
	# 【方法职责】根据权重随机选择一个敌人场景
	# 使用加权随机算法，确保权重高的敌人出现概率更高
	#
	# 【算法步骤】
	# 1. 计算总权重
	# 2. 生成一个随机数（0 到 总权重）
	# 3. 遍历权重数组，累加每个权重
	# 4. 当累加值 >= 随机数时，返回对应的敌人
	#
	# 【举例】weights = [70, 30]
	# 总权重 = 100
	# 随机数 = 45
	# 累加：70 >= 45 → 返回 enemy_scenes[0]（普通敌人）
	#
	# 随机数 = 85
	# 累加：70 < 85，70+30=100 >= 85 → 返回 enemy_scenes[1]（强力敌人）

	# 计算总权重
	var total_weight = 0
	for weight in enemy_weights:
		total_weight += weight

	# 生成随机数（0到总权重）
	var random_value = randf_range(0, total_weight)
	# 【概念】randf_range(min, max)
	# - 生成一个浮点随机数
	# - 范围：min <= 结果 < max
	# - randf_range(0, 100)：生成 0 到 99.99... 之间的随机数

	# 根据随机数选择敌人
	var current_weight = 0
	for i in range(enemy_scenes.size()):
		current_weight += enemy_weights[i]
		if random_value <= current_weight:
			return enemy_scenes[i]

	# 默认返回第一个（不应该到这里）
	return enemy_scenes[0]


# ============ 难度提升系统（Day 7 新增）============

func increase_difficulty() -> void:
	"""
	【内部方法】提升游戏难度
	每30秒自动调用一次
	"""
	# 缩短生成间隔（最低1.5秒）
	spawn_interval = max(1.5, spawn_interval - 0.2)
	timer.wait_time = spawn_interval

	# 增加强力敌人比例（难度等级3以上）
	if difficulty_level >= 3:
		enemy_weights = [50, 50]  # 50%普通，50%强力

	print("难度提升到 ", difficulty_level, " 级！生成间隔: ", spawn_interval, "秒")
