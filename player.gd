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

# 攻击力系统（Day 5 改造）
var base_attack = 100  # 基础攻击力（固定值）
# 【设计决策】初始基础攻击力20
# 敌人初始血量50（Step 2.3会设置）
# 3次攻击击杀（20*3=60>50）

var attack_power = 20  # 当前攻击力（基础+装备加成）
# 【Day 5 新增】attack_power 是最终攻击力
# 由 base_attack + equipment_bonus["attack"] 计算得出
# 拾取装备后会自动更新
# 【重要】初始值必须等于 base_attack（没有装备时）

var attack_cooldown = 0.0  # 攻击冷却计时器
# 【概念⭐】冷却机制：
# - 攻击后设置为0.5秒
# - 每帧减少delta
# - 小于0时才能再次攻击
# 【为什么需要冷却】防止按住空格连续攻击（手感不好）

# 生命值系统（Day 5 改造）
var hp = 100
var base_max_hp = 100  # 基础最大血量（固定值）
var max_hp = 100  # 当前最大血量（基础+装备加成）
# 【Day 5 新增】max_hp 是最终最大血量
# 由 base_max_hp + equipment_bonus["hp"] 计算得出
# 拾取装备后会自动更新

# 【设计决策】初始血量100
# 敌人攻击力10（Step 3.3会设置）
# 10次攻击死亡
# 后续装备可以提升到200-300

# ============ 装备系统（Day 5 新增）============

# 装备栏：存储当前装备的物品数据
var equipped_weapon: Dictionary = {}  # 当前装备的武器数据
# 【数据结构】Dictionary 类型，存储装备的完整信息
# 例如：{"type": "weapon", "name": "铁剑", "rarity": 1, "stats": {"attack": 15}}

var equipped_armor: Dictionary = {}  # 当前装备的防具数据
# 【数据结构】同上，例如：{"type": "armor", "name": "布衣", "rarity": 0, "stats": {"hp": 30}}

# 装备加成统计：累计所有装备提供的属性加成
var equipment_bonus: Dictionary = {
	"attack": 0,  # 装备提供的攻击力加成
	"hp": 0       # 装备提供的生命值加成
}
# 【计算公式】
# attack_power = base_attack + equipment_bonus["attack"]
# max_hp = base_max_hp + equipment_bonus["hp"]
#
# 【为什么分开存储】
# 1. equipped_*：存储完整物品数据（用于显示、保存等）
# 2. equipment_bonus：只存储数值加成（用于快速计算）


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

func _ready() -> void:
	# 【Day 5 新增】初始化角色属性
	# 确保 attack_power 和 max_hp 正确计算
	recalculate_stats()

	# 初始化血条显示
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


# ============ 拾取系统（Day 5 新增）============

func pickup_item(item_data: Dictionary) -> void:
	# 【接口方法】由掉落物（DroppedItem）调用
	# 当玩家靠近掉落物时，掉落物会调用此方法
	#
	# 参数：item_data - 包含装备信息的字典
	# 格式示例：{"type": "weapon", "name": "铁剑", "rarity": 1, "stats": {"attack": 15}}

	# 在控制台显示拾取信息
	print("拾取: ", ItemData.get_full_name(item_data))
	# 【输出示例】"拾取: 稀有 铁剑"

	# 根据装备类型进行分类处理
	if item_data["type"] == "weapon":
		# 如果是武器，调用装备武器方法
		equip_weapon(item_data)
	elif item_data["type"] == "armor":
		# 如果是防具，调用装备防具方法
		equip_armor(item_data)

	# 重新计算角色属性（攻击力、血量等）
	recalculate_stats()


func equip_weapon(item_data: Dictionary) -> void:
	# 【方法职责】装备武器并更新攻击力加成
	#
	# 参数：item_data - 武器装备数据字典
	# 【数据示例】{"type": "weapon", "name": "铁剑", "rarity": 1, "stats": {"attack": 15}}

	# 保存武器数据到装备栏
	equipped_weapon = item_data
	# 【注意】这会覆盖之前的武器（Day 5 简化版本）
	# Day 6 会添加背包系统，旧装备会放入背包

	# 从装备数据中获取攻击力加成
	# get("attack", 0) 表示：如果有 "attack" 键就返回其值，否则返回 0
	equipment_bonus["attack"] = item_data["stats"].get("attack", 0)
	# 【示例】
	# 稀有铁剑：stats = {"attack": 15} → equipment_bonus["attack"] = 15
	# 普通铁剑：stats = {"attack": 10} → equipment_bonus["attack"] = 10

	# 在控制台显示装备信息
	print("装备武器: ", ItemData.get_full_name(item_data), " 攻击+", equipment_bonus["attack"])
	# 【输出示例】"装备武器: 稀有 铁剑 攻击+15"


func equip_armor(item_data: Dictionary) -> void:
	# 【方法职责】装备防具并更新生命值加成
	#
	# 参数：item_data - 防具装备数据字典
	# 【数据示例】{"type": "armor", "name": "布衣", "rarity": 0, "stats": {"hp": 30}}

	# 保存防具数据到装备栏
	equipped_armor = item_data
	# 【注意】这会覆盖之前的防具（Day 5 简化版本）

	# 从装备数据中获取生命值加成
	equipment_bonus["hp"] = item_data["stats"].get("hp", 0)
	# 【示例】
	# 优秀布衣：stats = {"hp": 39} → equipment_bonus["hp"] = 39
	# 普通布衣：stats = {"hp": 30} → equipment_bonus["hp"] = 30

	# 在控制台显示装备信息
	print("装备防具: ", ItemData.get_full_name(item_data), " 生命+", equipment_bonus["hp"])
	# 【输出示例】"装备防具: 优秀 布衣 生命+39"


func recalculate_stats() -> void:
	# 【核心方法】重新计算所有角色属性
	#
	# 调用时机：
	# 1. 拾取新装备时
	# 2. 装备/卸下装备时（Day 6）
	# 3. 其他可能影响属性的事件
	#
	# 【计算流程】
	# 1. 基础属性 + 装备加成 = 最终属性
	# 2. 更新 UI 显示
	# 3. 同步血量百分比

	# 计算攻击力：基础值 + 装备加成
	attack_power = base_attack + equipment_bonus["attack"]
	# 【计算示例】
	# base_attack = 20, equipment_bonus["attack"] = 15
	# attack_power = 20 + 15 = 35

	# 保存旧的最大血量（用于计算百分比）
	var old_max_hp: float = max_hp

	# 计算新的最大血量：基础值 + 装备加成
	max_hp = base_max_hp + equipment_bonus["hp"]
	# 【计算示例】
	# base_max_hp = 100, equipment_bonus["hp"] = 30
	# max_hp = 100 + 30 = 130

	# 如果最大血量增加了，按比例增加当前血量
	if max_hp > old_max_hp:
		# 计算当前血量百分比
		var hp_percent: float = float(hp) / old_max_hp
		# 【数学示例】
		# hp = 50, old_max_hp = 100 → 50/100 = 0.5 (50%)
		# 新的 max_hp = 130
		# 新的 hp = 130 * 0.5 = 65
		#
		# 【设计意图】
		# 玩家拾取装备后，血量百分比保持不变
		# 如果之前是半血，拾取后还是半血（但数值增加了）

		# 根据百分比计算新的当前血量
		hp = int(max_hp * hp_percent)

	# 更新血条 UI
	update_hp_bar()

	# 【Day 5 扩展】通知 Main 更新攻击力显示
	# 获取 Main 节点（场景树的根节点）
	var main_node = get_tree().root.get_node("Main")
	# 检查 Main 节点是否存在且有 update_player_stats 方法
	if main_node and main_node.has_method("update_player_stats"):
		main_node.update_player_stats()
		# 【调用效果】Main 会更新屏幕左上角的攻击力显示

	# 在控制台输出完整的属性信息
	print("属性更新 - 攻击:", attack_power, " 血量:", hp, "/", max_hp)
	# 【输出示例】"属性更新 - 攻击: 35 血量: 65/130"
