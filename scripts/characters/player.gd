extends BaseCharacter  # 改为继承 BaseCharacter
# 删除：extends CharacterBody2D

# ============ 场景预加载（Day 3 新增）============

# 删除：var damage_number_scene（已在基类中）

# ============ 角色属性 ============
var speed = 200
# 每秒移动200像素的速度

var facing_right: bool = true
# Day 9 新增：角色朝向
# true: 面向右
# false: 面向左

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

# ============ Day 10 新增：攻击动画系统变量 ============
var is_attacking: bool = false
# 是否正在执行攻击动作
# true时: 禁止移动、禁止再次攻击
# false时: 允许正常活动

var attack_hit_registered: bool = false
# 防止同一次攻击重复判定伤害
# 每次 attack 开始时重置为 false
# 帧2判定后设为 true

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
@onready var animated_sprite = $AnimatedSprite2D  # Day 9 新增
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

	# Day 9 新增：播放待机动画（添加安全检查）
	# 只有在动画资源已创建时才播放，避免报错
	if animated_sprite and animated_sprite.sprite_frames:
		# Day 10: 连接动画信号
		animated_sprite.frame_changed.connect(_on_animation_frame_changed)
		animated_sprite.animation_finished.connect(_on_animation_finished)

		# Day 9: 播放待机动画
		animated_sprite.set_frame_and_progress(0, 0.0)
		animated_sprite.scale = Vector2(0.2, 0.2)
		animated_sprite.play("idle")

		print("玩家初始化完成，动画信号已连接")

# ============ 游戏主循环 ============

func _physics_process(_delta):
	# _physics_process在固定的物理帧率下调用（默认60次/秒）
	# 适合处理物理相关的逻辑，如移动、碰撞等

	# ============ Day 10 新增：攻击输入检测 ============
	if Input.is_action_just_pressed("ui_accept"):
		if not is_attacking:
			# 只有非攻击状态才能发起新攻击
			# 注意：这里不检查 attack_cooldown，冷却在动画结束时设置
			start_attack()

	# ============ 移动逻辑（Day 9 已有，Day 10 修改）============
	if not is_attacking:
		# 只在非攻击状态允许移动
		var direction = Input.get_axis("ui_left", "ui_right")
		# get_axis返回值：
		# → -1.0（按A键，向左）
		# → 0.0（不按键）
		# → 1.0（按D键，向右）

		# 更新朝向和翻转（Day 9 已有）
		if direction != 0:
			facing_right = direction > 0
			animated_sprite.flip_h = not facing_right

		# 计算速度（Day 9 已有）
		if direction:
			velocity.x = direction * speed
			# 检查当前动画不是 attack 才切换
			if animated_sprite.animation != "attack":
				animated_sprite.play("walk")
		else:
			velocity.x = 0
			if animated_sprite.animation != "attack":
				animated_sprite.play("idle")
	else:
		# 攻击中停止移动（Day 10 新增）
		velocity.x = 0

	# ============ 应用物理移动（Day 9 已有）============
	move_and_slide()
	# CharacterBody2D的内置方法：
	# 1. 根据velocity移动角色
	# 2. 自动处理碰撞
	# 3. 内部已经乘了delta，所以我们不需要乘

# ============ Day 10 新增：攻击动画系统方法 ============

func start_attack() -> void:
	"""
	开始执行攻击动画（替换原有的 do_attack 瞬时判定）

	职责:
	1. 设置攻击状态
	2. 重置判定标记
	3. 播放攻击动画
	4. 伤害判定在帧2通过信号触发
	"""
	# 设置攻击状态
	is_attacking = true

	# 重置判定标记
	attack_hit_registered = false

	# 播放攻击动画
	animated_sprite.play("attack")

	print("=== 攻击动画开始 ===")

	# 播放攻击音效（保留 Day 1 代码）
	get_node("/root/AudioManager").play_sound("attack")

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

# ============ Day 10 新增：信号回调函数 ============

func _on_animation_frame_changed() -> void:
	"""
	动画帧变化时调用 - 用于在帧2执行判定

	触发时机:
	- 帧0切换到帧1: 调用
	- 帧1切换到帧2: 调用
	- 帧2切换到帧3: 调用
	"""
	# ============ 只处理攻击动画 ============
	if animated_sprite.animation != "attack":
		# walk 和 idle 动画也会触发这个信号
		# 但我们只想在攻击动画时执行判定
		return

	# ============ 只在第2帧 (frame = 1) 执行判定 ============
	if animated_sprite.frame == 1:
		# frame = 1 对应第2张图片（打击帧）

		# ============ 防止重复判定 ============
		if not attack_hit_registered:
			# 本次攻击还没判定过，执行判定
			perform_attack_hit_detection()

			# 标记已判定，防止同一次攻击重复触发
			attack_hit_registered = true

			print("→ 执行帧2判定")

func _on_animation_finished() -> void:
	"""
	动画播放完成时调用

	职责:
	1. 重置攻击状态
	2. 回到待机动画
	"""
	# ============ 只处理攻击动画 ============
	if animated_sprite.animation != "attack":
		return

	# ============ 重置攻击状态 ============
	is_attacking = false
	# → 解除攻击状态
	# → 允许玩家移动
	# → 允许发起新攻击

	# ============ 重置攻击冷却 ============
	attack_cooldown = 0.5  # 0.5秒冷却
	# → Day 10新设计：冷却在攻击结束后开始计时
	# → Day 1-8旧设计：冷却在攻击开始时立即计时
	# → 影响：连续攻击间隔 = 攻击动画时长(0.38秒) + 冷却(0.5秒) = 0.88秒

	attack_hit_registered = false
	# → 为下次攻击做准备

	# ============ 回到待机动画 ============
	animated_sprite.play("idle")
	# → 避免停留在攻击最后一帧

	print("=== 攻击结束 ===")

func perform_attack_hit_detection() -> void:
	"""
	执行攻击伤害判定

	流程:
	1. 临时启用攻击区域
	2. 等待物理帧更新
	3. 获取重叠的敌人列表
	4. 遍历并造成伤害
	5. 立即关闭攻击区域
	"""
	# ============ 第1步: 临时启用攻击区域 ============
	attack_area.monitoring = true
	# → 让 AttackArea 开始检测碰撞

	# ============ 第2步: 等待物理帧更新 ============
	await get_tree().physics_frame
	# → 让 Godot 的物理引擎完成一次计算
	# → 确保碰撞检测数据是最新的

	# ============ 第3步: 获取重叠的敌人列表 ============
	var bodies = attack_area.get_overlapping_bodies()
	# → 返回当前与 AttackArea 重叠的所有 Body 节点
	# → 可能包含: 敌人、墙壁、道具等

	print("检测到物体数量:", bodies.size())

	# ============ 第4步: 遍历并判断 ============
	for body in bodies:
		# ============ 检查是否是敌人 ============
		# 方法1: 检查是否有 take_damage 方法（推荐）
		if body.has_method("take_damage"):
			# 有这个方法，八成是敌人
			body.take_damage(attack_power)
			print("  → 命中:", body.name)

		# 方法2: 检查是否在 "enemies" 组中（备选）
		# elif body.is_in_group("enemies"):
		# 	body.take_damage(attack_power)

	# ============ 第5步: 立即关闭攻击区域 ============
	attack_area.monitoring = false
	# → 判定完成，停止检测
	# → 避免帧2持续时间内重复触发

# ============ 受伤系统（重写基类方法）============

# 删除：take_damage()（使用基类的）
# 删除：update_hp_bar()（使用基类的）
# 删除：spawn_damage_number()（使用基类的）
# 删除：flash_red()（使用基类的）

# 重写音效钩子
func on_take_damage() -> void:
	"""玩家受击时播放音效"""
	get_node("/root/AudioManager").play_sound("hit")

	# 触发相机震动（Day 7 新增）
	# 获取当前场景（兼容 safe_zone 和 battle_zone）
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("shake_camera"):
		current_scene.shake_camera(3.0, 0.15)

# 只重写 die()，因为玩家死亡有特殊处理
func die() -> void:
	"""玩家死亡：重置数据并返回安全区"""
	print("玩家死亡！")

	# 禁用处理，防止在场景切换期间继续执行
	set_physics_process(false)
	set_process(false)

	# 播放死亡音效
	get_node("/root/AudioManager").play_sound("death")

	# 重置全局数据（包括背包装备）
	GameData.reset_game()

	# 返回安全区
	get_tree().change_scene_to_file("res://scenes/safe_zone.tscn")

# ============ 拾取系统（Day 5 新增，Day 6 改造）============

func pickup_item(item_data: Dictionary) -> void:
	"""拾取装备并添加到背包"""
	print("拾取: ", ItemData.get_full_name(item_data))

	# 获取背包节点（兼容 safe_zone 和 battle_zone）
	var current_scene = get_tree().current_scene
	var inventory = null
	if current_scene:
		inventory = current_scene.get_node_or_null("UI/Inventory")

	if inventory:
		# 尝试添加到背包
		var success = inventory.add_item(item_data)
		if not success:
			# 背包满了，显示提示
			print("背包已满，无法拾取！")
			return
	else:
		print("警告：当前场景没有背包 UI")


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

	# 通知当前场景更新攻击力显示（兼容 safe_zone 和 battle_zone）
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("update_player_stats"):
		current_scene.update_player_stats()

	print("属性更新 - 攻击:", attack_power, " 血量:", hp, "/", max_hp)
