extends CharacterBody2D
# 这表示我们的脚本继承自CharacterBody2D，可以使用它的所有功能

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
# - 伤害数字频繁生成（每次受伤都要）
# - 预加载避免每次都读取文件
# - instantiate() 会更快

# ============ 角色属性 ============
var speed = 200
# 每秒移动200像素的速度

var attack_power = 100  # 新增：攻击力
# 【设计决策】初始攻击力20
# 敌人初始血量50（Step 2.3会设置）
# 3次攻击击杀（20*3=60>50）
# 后续装备可以提升到50-100

var attack_cooldown = 0.0  # 新增：攻击冷却计时器
# 【概念⭐】冷却机制：
# - 攻击后设置为0.5秒
# - 每帧减少delta
# - 小于0时才能再次攻击
# 【为什么需要冷却】防止按住空格连续攻击（手感不好）

# 新增：生命值
var hp = 100
var max_hp = 100
# 【设计决策】初始血量100
# 敌人攻击力10（Step 3.3会设置）
# 10次攻击死亡
# 后续装备可以提升到200-300


# ============ 节点引用 ============

@onready var attack_area = $AttackArea
# 【概念⭐】@onready的作用：
# - 等场景加载完成后才获取节点
# - $符号是get_node()的简写
# - $AttackArea 等同于 get_node("AttackArea")
# 
# 【为什么不在顶部写】
# var attack_area = $AttackArea  # 这样会报错！
# 因为脚本加载时场景树还没准备好
# 
# 【@onready的时机】
# 在_ready()之前执行，但场景树已经准备好了
# 
# 【深入理解】支线任务会探讨节点生命周期

@onready var hp_bar = $ProgressBar  # 新增：血条引用

# ============ 初始化 ============

func _ready():
	update_hp_bar()  # 初始化血条显示



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
		# 【数学】每帧减少delta
		# 60fps时，每帧减少0.0167
		# 0.5秒 / 0.0167 ≈ 30帧
		# 所以大约30帧后冷却完成
	
	# -------- 检测攻击输入 --------
	if Input.is_action_just_pressed("ui_accept") and attack_cooldown <= 0:
		# 【概念⭐】is_action_just_pressed vs is_action_pressed
		# 
		# is_action_just_pressed：
		# - 只在按下的那一帧返回true
		# - 适合"点击触发"的动作（攻击、跳跃）
		# 
		# is_action_pressed：
		# - 按住期间每帧都返回true
		# - 适合"持续触发"的动作（移动、瞄准）
		# 
		# 【判断标准】
		# - 需要"按一次执行一次" → just_pressed
		# - 需要"按住持续执行" → pressed
		# 
		# 【这里为什么用just_pressed】
		# 攻击是"点击触发"，按住也只攻击一次
		# 配合cooldown，实现"点一下攻击一次，冷却后才能再攻击"
		
		do_attack()
		
# ============ 攻击方法 ============

func do_attack():
	# 设置冷却时间
	attack_cooldown = 0.5  # 0.5秒冷却
	# 【设计决策】为什么是0.5秒？
	# - 太短（0.2秒）：像无CD，失去攻击节奏感
	# - 太长（1.5秒）：攻击频率太低，战斗拖沓
	# - 0.5秒：适中，大约每秒2次攻击
	
	print("攻击！")  # 调试输出
	
	# 获取攻击范围内的所有物体
	var enemies = attack_area.get_overlapping_bodies()
	# 【概念⭐】get_overlapping_bodies()
	# - Area2D的方法
	# - 返回当前与这个Area重叠的所有PhysicsBody（数组）
	# - 包括CharacterBody2D、RigidBody2D、StaticBody2D
	# 
	# 【为什么不是get_overlapping_areas()】
	# - 那个返回的是其他Area2D
	# - 敌人是CharacterBody2D（属于Body）
	# 
	# 【深入理解】支线任务会探讨Area2D的信号 vs 轮询
	
	# 遍历所有检测到的物体
	for enemy in enemies:
		# 【概念】鸭子类型检测
		# 不检查enemy是不是Enemy类
		# 而是检查它"有没有take_damage方法"
		# "如果它走起来像鸭子，叫起来像鸭子，那它就是鸭子"
		
		if enemy.has_method("take_damage"):
			# 如果这个物体有take_damage方法，就调用它
			enemy.take_damage(attack_power)
			# 【设计模式】接口模式
			# 任何有take_damage(damage)方法的物体都能被攻击
			# 不需要知道它是Enemy、Boss还是Barrel
			# 
			# 【好处】
			# - 解耦：Player不需要知道Enemy的具体实现
			# - 扩展：新增可破坏物体只需实现take_damage


# ============ 受伤系统（新增）============

func take_damage(damage):
	# 【接口方法】
	# 和Enemy一样，实现take_damage接口
	# 这样敌人也能用同样的方式攻击玩家

	hp -= damage
	print("玩家受到 ", damage, " 点伤害！剩余血量：", hp)

	# 更新血条
	update_hp_bar()

	# 【Day 3 新增】显示伤害数字
	spawn_damage_number(damage)
	# 在玩家位置生成一个飘动的伤害数字
	# 数字会向上飘动并逐渐消失

	# 受击闪烁效果（可选，Step 3.2实现）
	# flash_red()

	# 检查死亡
	if hp <= 0:
		die()

func update_hp_bar():
	# 【核心方法】更新血条显示
	# 
	# 计算血量百分比：hp / max_hp
	# 转换为0-100的值：* 100
	# 
	# 【为什么用float】
	# hp和max_hp是整数，直接除法会取整
	# 例如：50 / 100 = 0（整数除法）
	# float(50) / 100 = 0.5（浮点除法）
	
	var hp_percent = (float(hp) / max_hp) * 100
	hp_bar.value = hp_percent
	# 【示例】
	# hp=50, max_hp=100 → 50%
	# hp=25, max_hp=100 → 25%
	
	# 【可选】根据血量改变颜色
	if hp_percent > 60:
		# 满血：绿色（已在场景设置）
		pass
	elif hp_percent > 30:
		# 半血：黄色
		# hp_bar.modulate = Color(1, 1, 0)
		pass
	else:
		# 残血：红色
		# hp_bar.modulate = Color(1, 0, 0)
		pass

func die():
	print("玩家死亡！")
	# Day 3先简单处理：
	# 重新加载场景
	get_tree().reload_current_scene()
	# 【概念⭐】get_tree().reload_current_scene()
	# - 重新加载当前场景
	# - 所有节点重置
	# - 相当于重新开始游戏
	#
	# 【未来改进】
	# - 显示"Game Over"界面
	# - 保存分数
	# - 返回主菜单

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

	# 设置位置（在玩家上方）
	dmg_num.position = position + Vector2(0, -50)
	# 【为什么是 position + Vector2(0, -50)】
	# - position：玩家的当前位置（本地坐标）
	# - Vector2(0, -50)：向上偏移50像素
	# - 结果：数字在玩家头顶上方显示
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
	# 如果 add_child(dmg_num) 【添加到 self/玩家】：
	# - 数字成为玩家的子节点
	# - 玩家移动，数字跟着移动（不想要这个效果）
	# - 玩家死亡，数字也被删除（数字没飘完就消失了）
	#
	# 如果 get_parent().add_child(dmg_num) 【添加到父节点/Main】：
	# - 数字成为 Main 的子节点
	# - 数字独立于玩家，有自己的位置
	# - 玩家死亡，数字继续飘动完成动画
	#
	# 【Scene Tree（场景树）结构对比】
	#
	# 方案A（错误）：添加到玩家
	# Main
	# └─ Player
	#     └─ DamageNumber ← 玩家死亡时一起删除
	#
	# 方案B（正确）：添加到Main
	# Main
	# ├─ Player
	# └─ DamageNumber ← 独立存在，动画完成后自动删除
	#
	# 【生命周期】
	# DamageNumber 会在动画结束后调用 queue_free()
	# 自动清理，不需要手动管理
