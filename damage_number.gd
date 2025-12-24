extends Label

# ============ 动画参数 ============

var float_speed = 50  # 向上飘动速度（像素/秒）
var fade_duration = 1.0  # 淡出时长（秒）
var lifetime = 1.0  # 总生命周期（秒）

# ============ 初始化 ============

func _ready():
	# 【动画方案对比】
	# 
	# 方案A：用Tween（我们的选择）
	# - 优点：代码简单，自动插值
	# - 缺点：需要理解Tween概念
	# 
	# 方案B：用AnimationPlayer
	# - 优点：可视化编辑动画
	# - 缺点：需要提前创建动画资源
	# 
	# 方案C：手动在_process中更新
	# - 优点：完全控制
	# - 缺点：代码复杂，容易出bug
	
	# 创建Tween动画
	var tween = create_tween()
	# 【概念⭐】Tween（补间动画）
	# - 自动在两个值之间插值
	# - 例如：从透明度1.0到0.0
	# - Godot自动计算中间每一帧的值
	
	# 设置为并行模式
	tween.set_parallel(true)
	# 【概念】并行 vs 串行
	# - 并行（parallel）：多个动画同时执行
	# - 串行（默认）：一个动画完成后再执行下一个
	# 
	# 【为什么用并行】
	# 我们需要"飘动"和"淡出"同时进行
	
	# 动画1：向上飘动
	tween.tween_property(self, "position:y", position.y - float_speed, lifetime)
	# 【参数说明】
	# - self：要动画的对象（这个Label）
	# - "position:y"：要改变的属性（Y坐标）
	# - position.y - float_speed：目标值（当前位置往上50像素）
	# - lifetime：动画时长（1秒）
	# 
	# 【效果】
	# 在1秒内，Y坐标从当前位置移动到-50像素
	# Godot自动计算每帧移动多少
	
	# 动画2：淡出（透明度）
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	# 【参数说明】
	# - "modulate:a"：透明度（alpha通道）
	# - 0.0：目标透明度（完全透明）
	# - fade_duration：1秒
	# 
	# 【效果】
	# 在1秒内，从不透明(1.0)变为完全透明(0.0)
	
	# 【概念⭐】为什么用modulate而不是alpha_modulate？
	# modulate是Color类型(R,G,B,A)
	# modulate:a只改变A（透明度）通道
	# 这样颜色保持不变，只改变透明度
	
	# 动画完成后删除自己
	await get_tree().create_timer(lifetime).timeout
	# 【概念】create_timer()
	# - 创建一个计时器
	# - lifetime秒后触发timeout信号
	# - await等待这个信号
	
	queue_free()  # 删除自己
	# 【生命周期管理】
	# 1秒后数字消失，不再需要这个节点
	# 及时删除避免内存泄漏

	# 【删除节点】queue_free()
	# - 标记节点为"待删除"
	# - 在当前帧结束时真正删除
	# - 相比直接free()更安全

# ============ 公共接口 ============

func set_damage(damage_value):
	# 【接口方法】
	# 生成伤害数字时调用这个方法设置显示的数字
	
	text = str(damage_value)
	# str()：转换为字符串
	# 例如：20 → "20"
	
	# 【可选】根据伤害类型改变颜色
	# if damage_value > 50:
	#     modulate = Color(1, 0, 0)  # 高伤害红色
	# elif damage_value > 20:
	#     modulate = Color(1, 1, 0)  # 中伤害黄色
	# else:
	#     modulate = Color(1, 1, 1)  # 低伤害白色
