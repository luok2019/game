extends CharacterBody2D

# ============ 敌人属性 ============

var hp = 50
# 【设计决策】初始血量50
# 玩家攻击力20，3次击杀
# 后续会增加更强的敌人（hp=100, 150）

var max_hp = 50
# 保存最大血量，用于计算血条百分比（Day 5会用到）

var speed = 80
# 【设计决策】为什么比玩家慢？
# 玩家speed=200，敌人speed=80
# 玩家能"风筝"敌人（边退边打）
# 如果敌人更快，玩家只能硬拼，缺少策略性

var attack_power = 10
# 敌人的攻击力（Day 3会实现敌人攻击玩家）

# ============ AI状态 ============

var player = null
# 引用玩家节点
# 【为什么初始是null】
# _ready()时才能找到玩家
# 避免在场景加载前访问导致错误

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

# ============ AI逻辑 ============

func _physics_process(delta):
	# 如果玩家存在且敌人还活着
	if player and hp > 0:
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
