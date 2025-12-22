extends CharacterBody2D
# 这表示我们的脚本继承自CharacterBody2D，可以使用它的所有功能

# ============ 角色属性 ============
var speed = 200
# 每秒移动200像素的速度

var attack_power = 20  # 新增：攻击力
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
