extends CharacterBody2D

# ============ 场景预加载（Day 3 新增）============

var damage_number_scene = preload("res://damage_number.tscn")
# 【概念⭐】preload vs load
#
# preload("path")：
# - 编译时加载
# - 游戏启动时就加载到内存
# - 更快，但占用内存
# - 适合：经常使用的资源
#
# load("path")：
# - 运行时加载
# - 需要时才加载
# - 较慢，但节省内存
# - 适合：偶尔使用的资源
#
# 【为什么伤害数字用preload】
# - 伤害数字频繁生成（每次攻击都要）
# - 预加载避免每次都读取文件
# - instantiate() 会更快

# ============ 敌人属性 ============

@export var hp = 50
# 【设计决策】初始血量50
# 玩家攻击力20，3次击杀
# 后续会增加更强的敌人（hp=100, 150）
# 【@export说明】可以在 Inspector 的 Script Variables 中修改此值

@export var max_hp = 50
# 保存最大血量，用于计算血条百分比（Day 5会用到）

@export var speed = 80
# 【设计决策】为什么比玩家慢？
# 玩家speed=200，敌人speed=80
# 玩家能"风筝"敌人（边退边打）
# 如果敌人更快，玩家只能硬拼，缺少策略性

@export var attack_power = 10
# 敌人的攻击力（Day 3会实现敌人攻击玩家）

# ============ AI状态 ============

var player = null
# 引用玩家节点
# 【为什么初始是null】
# _ready()时才能找到玩家
# 避免在场景加载前访问导致错误

var attack_cooldown = 0.0  # 新增：攻击冷却
var attack_range = 70.0    # 新增：攻击距离


# ============ 节点引用 ============
@onready var hp_bar = $ProgressBar  # 新增


# ============ 初始化 ============

func _ready():
	# 【设计决策点4】⭐ 如何找到玩家？
	# 
	# 方案A：通过组（Group）查找（我们的选择）
	# 方案B：通过路径get_node("../Player")
	# 方案C：通过父节点传递引用
	# 
	# 【为什么选A】
	# - 灵活：Player可以在场景任何位置
	# - 解耦：Enemy不需要知道Player的具体路径
	# - 可扩展：后续可以找"最近的玩家"（多人游戏）
	# 
	# 【如何使用组】
	# 1. Player场景添加到"player"组（Step 2.4会做）
	# 2. Enemy通过get_tree().get_first_node_in_group("player")查找
	
	# 等待一帧，确保场景树完全加载
	await get_tree().process_frame
	# 【概念⭐】await的作用：
	# - 暂停函数执行，等待某个信号
	# - process_frame：下一帧开始的信号
	# - 确保所有节点都已经_ready()
	# 
	# 【为什么需要等待】
	# - Enemy的_ready()可能比Player先执行
	# - 那时Player还没加入"player"组
	# - 等待一帧确保所有节点都准备好了
	# 
	# 【深入理解】支线任务会探讨节点加载顺序
	
	player = get_tree().get_first_node_in_group("player")
	# 【方法说明】
	# - get_tree()：获取场景树
	# - get_first_node_in_group("player")：获取"player"组的第一个节点
	# - 如果没找到，返回null
	
	if player == null:
		print("警告：没有找到玩家！")
		# 调试信息，如果忘记给Player添加组，会提示

	update_hp_bar()  # 初始化血条

# ============ AI逻辑 ============

func _physics_process(delta):
	# 如果玩家存在且敌人还活着
	if player and hp > 0:
		# 【Day 3 新增】计算到玩家的距离
		var distance_to_player = global_position.distance_to(player.global_position)
		# 【数学⭐】distance_to() 方法
		# - 计算两点之间的直线距离
		# - 返回浮点数（像素单位）
		# - 使用勾股定理：sqrt((x2-x1)^2 + (y2-y1)^2)
		#
		# 【示例】
		# 玩家在(200, 100)，敌人在(100, 100)
		# distance = sqrt((200-100)^2 + (100-100)^2)
		# distance = sqrt(10000) = 100像素

		# 【Day 3 新增】攻击冷却倒计时
		if attack_cooldown > 0:
			attack_cooldown -= delta
			# delta：上一帧到现在的经过时间（秒）
			# 例如：60fps时，delta ≈ 0.016秒

		# 【Day 3 新增】判断是否在攻击范围内
		if distance_to_player <= attack_range:
			# 在攻击范围内
			# 【设计决策】停止移动，准备攻击
			velocity = Vector2.ZERO
			# Vector2.ZERO = (0, 0)，即停止不动

			# 如果冷却完成，执行攻击
			if attack_cooldown <= 0:
				do_attack()
		else:
			# 不在攻击范围内，追击玩家
			# 计算方向：从敌人指向玩家
			var direction = (player.global_position - global_position).normalized()
			# 【数学】向量运算：
			# player.global_position：玩家的世界坐标
			# global_position：敌人的世界坐标（self可省略）
			# 相减：得到"从敌人指向玩家"的向量
			# normalized()：归一化（长度变为1，但保持方向）
			#
			# 【为什么要normalized】
			# 不归一化：距离远时向量长，移动更快（不合理）
			# 归一化后：无论距离，速度都是speed
			#
			# 【示例】
			# 玩家在(200, 100)，敌人在(100, 100)
			# 相减：(100, 0)
			# 归一化：(1, 0)（单位向量）
			# 乘以速度：(1, 0) * 80 = (80, 0)
			# 结果：每秒向右移动80像素

			# 设置速度
			velocity = direction * speed
			# 【为什么不用velocity.x】
			# direction是2D向量(x, y)
			# 敌人需要在x和y方向都追击玩家
			# 如果玩家在上方，敌人也要向上移动

		# 应用移动
		move_and_slide()
		# 和玩家一样，自动处理碰撞

# ============ 受伤系统 ============

func take_damage(damage):
	# 【接口方法】
	# 玩家的do_attack()会调用这个方法
	# 参数damage：受到的伤害值

	hp -= damage
	print("敌人受到 ", damage, " 点伤害！剩余血量：", hp)
	# 调试输出，后续会用伤害数字飘字替代

	# 【Day 3 新增】更新血条显示
	update_hp_bar()

	# 【Day 3 新增】显示伤害数字
	spawn_damage_number(damage)
	# 在敌人位置生成一个飘动的伤害数字
	# 数字会向上飘动并逐渐消失

	# 【可选】受击反馈
	# modulate = Color(1, 0.5, 0.5)  # 闪红色
	# await get_tree().create_timer(0.1).timeout
	# modulate = Color(1, 1, 1)  # 恢复
	# Day 3会实现完整的受击效果

	# 检查是否死亡
	if hp <= 0:
		die()

func die():
	print("敌人死亡！")
	# 后续会添加：
	# - 死亡动画
	# - 掉落装备
	# - 音效

	# 通知Main增加击杀数
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("add_kill"):
		main.add_kill()
	
	# 【说明】
	# get_tree().root：获取根节点
	# get_node("Main")：找到Main节点
	# add_kill()：调用Main的方法


	queue_free()  # 删除自己
	# 【概念⭐】queue_free() vs free()
	#
	# queue_free()：
	# - 安全删除，等当前帧结束后删除
	# - 推荐用法
	#
	# free()：
	# - 立即删除
	# - 如果其他代码还在访问这个节点会崩溃
	#
	# 【为什么用queue_free】
	# 当前在_physics_process中可能有其他逻辑还要执行
	# 立即删除会导致访问已删除节点的错误

# ============ 攻击系统（Day 3 新增）============

func do_attack():
	# 【方法职责】敌人攻击玩家
	# 攻击冷却完成后，_physics_process 会调用此方法

	attack_cooldown = 1.0  # 设置1秒冷却
	# 【设计决策】为什么敌人攻击慢？
	# 玩家攻击冷却：0.5秒
	# 敌人攻击冷却：1.0秒
	#
	# 【理由】
	# - 给玩家反应时间
	# - 玩家可以"两刀换一刀"
	# - 增加战斗的策略性
	# - 如果敌人攻击太快，玩家只能硬拼

	print("敌人攻击！")
	# 调试输出，后续会添加攻击动画和音效

	# 检查玩家是否还存在且在范围内
	# 【安全检查⭐】is_instance_valid()
	# - 确保玩家节点没有被删除
	# - 避免访问已删除节点导致崩溃
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		# 再次检查距离（防止玩家跑出范围）

		if distance <= attack_range:
			player.take_damage(attack_power)
			# 【接口调用】调用玩家的受伤方法
			# 玩家必须有 take_damage() 函数
			# 参数：attack_power（敌人的攻击力）

# ============ 血条系统（Day 3 新增）============

func update_hp_bar():
	# 【方法职责】更新血条显示
	# 在受伤时和初始化时调用

	var hp_percent = (float(hp) / max_hp) * 100
	# 【数学⭐】血量百分比计算
	#
	# 公式：(当前血量 / 最大血量) × 100
	#
	# 【为什么用float()】
	# GDScript 的整数除法会取整
	# 例如：50 / 100 = 0（整数除法，结果0）
	# float(50) / 100 = 0.5（浮点除法，结果0.5）
	#
	# 【示例】
	# hp=50, max_hp=100 → 50%
	# hp=25, max_hp=100 → 25%
	# hp=75, max_hp=100 → 75%

	hp_bar.value = hp_percent
	# 【ProgressBar 属性】
	# value：当前值
	# min_value：最小值（设为0）
	# max_value：最大值（设为100）
	#
	# ProgressBar 会自动计算填充比例
	# fill_ratio = (value - min) / (max - min)
	# 例如：value=50 → 填充50%

# ============ 伤害数字系统（Day 3 新增）============

func spawn_damage_number(damage_value):
	# 【方法职责】生成并显示伤害数字
	# 在受伤时调用，创建一个飘动的数字效果
	#
	# 参数：damage_value - 要显示的伤害数值

	# 实例化伤害数字场景
	var dmg_num = damage_number_scene.instantiate()
	# 【概念⭐】instantiate()
	# - 从预加载的场景创建一个实例
	# - 类似"复制"场景模板
	# - 每次调用创建新的独立对象
	#
	# 【示例】
	# damage_number_scene 是模板（就像模具）
	# instantiate() 是用模具生产产品
	# 每次生产的产品都是独立的

	# 设置位置（在敌人上方）
	dmg_num.position = position + Vector2(0, -50)
	# 【为什么是 position + Vector2(0, -50)】
	# - position：敌人的当前位置（本地坐标）
	# - Vector2(0, -50)：向上偏移50像素
	# - 结果：数字在敌人头顶上方显示
	#
	# 【坐标系说明】
	# Godot 坐标系：Y轴向上是负方向
	# (0, -50) 表示向上移动50像素
	#
	# 【为什么不用 global_position】
	# 因为 dmg_num 要添加到父节点（Main）
	# 父节点使用世界坐标系统
	# 所以这里用 position（本地坐标）+ 偏移

	# 设置显示的数字
	dmg_num.set_damage(damage_value)
	# 【接口调用】调用伤害数字的设置方法
	# damage_number.gd 中定义了 set_damage() 函数
	# 该函数会更新 Label 的 text 属性

	# 添加到场景树（Scene Tree）
	get_parent().add_child(dmg_num)
	# 【重要⭐】为什么添加到 get_parent() 而不是 self？
	#
	# 如果 add_child(dmg_num) 【添加到 self/敌人】：
	# - 数字成为敌人的子节点
	# - 敌人移动，数字跟着移动（不想要这个效果）
	# - 敌人死亡，数字也被删除（数字没飘完就消失了）
	#
	# 如果 get_parent().add_child(dmg_num) 【添加到父节点/Main】：
	# - 数字成为 Main 的子节点
	# - 数字独立于敌人，有自己的位置
	# - 敌人死亡，数字继续飘动完成动画
	#
	# 【Scene Tree（场景树）结构对比】
	#
	# 方案A（错误）：添加到敌人
	# Main
	# └─ Enemy
	#     └─ DamageNumber ← 敌人死亡时一起删除
	#
	# 方案B（正确）：添加到Main
	# Main
	# ├─ Enemy
	# └─ DamageNumber ← 独立存在，动画完成后自动删除
	#
	# 【生命周期】
	# DamageNumber 会在动画结束后调用 queue_free()
	# 自动清理，不需要手动管理
