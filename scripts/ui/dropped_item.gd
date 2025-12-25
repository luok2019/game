extends Area2D

# ============ 装备数据 ============

var item_data: Dictionary = {}
# 存储这个掉落物的装备信息
# 例如：{"type": "weapon", "rarity": Rarity.RARE, ...}

# ============ 节点引用 ============

@onready var visual = $ColorRect

# ============ 初始化 ============

func _ready():
	# 连接信号：玩家进入拾取范围
	body_entered.connect(_on_body_entered)
	
	# 设置颜色
	if item_data.has("rarity"):
		visual.color = ItemData.rarity_colors[item_data["rarity"]]
	
	# 可选：添加上下浮动动画
	add_float_animation()

# ============ 拾取逻辑 ============

func _on_body_entered(body):
	# 【信号回调】当有Body进入Area时触发

	# 检查是不是玩家
	if body.is_in_group("player"):
		# 新增：播放拾取音效
		get_node("/root/AudioManager").play_sound("pickup")

		# 调用玩家的拾取方法
		if body.has_method("pickup_item"):
			body.pickup_item(item_data)

			# 删除掉落物
			queue_free()

# ============ 公共接口 ============

func set_item_data(data: Dictionary):
	# 【接口方法】生成掉落物时调用
	item_data = data
	
	# 如果已经_ready()了，更新颜色
	if visual:
		visual.color = ItemData.rarity_colors[data["rarity"]]

# ============ 可选动画 ============

func add_float_animation():
	# 上下浮动动画
	var tween = create_tween()
	tween.set_loops()  # 无限循环
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 向上10像素
	tween.tween_property(self, "position:y", position.y - 10, 1.0)
	# 向下10像素
	tween.tween_property(self, "position:y", position.y + 10, 1.0)
	
	# 【效果】掉落物会缓慢上下浮动
