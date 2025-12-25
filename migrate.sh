#!/bin/bash
# 项目结构迁移脚本
# 用途：将项目文件按类型组织到不同文件夹

# 进入项目目录（根据实际情况修改路径）
cd "C:/Users/admin/Desktop/AI/game/cardlegend"

echo "=== Step 7.4: 项目结构迁移 ==="

# 步骤1：创建文件夹结构
echo "创建文件夹结构..."
mkdir -p scenes/characters scenes/items scenes/ui
mkdir -p scripts/characters scripts/systems scripts/ui
mkdir -p assets/sounds

# 步骤2：移动场景文件
echo "移动场景文件..."
mv player.tscn enemy.tscn enemy_strong.tscn scenes/characters/
mv dropped_item.tscn item_slot.tscn scenes/items/
mv inventory.tscn damage_number.tscn scenes/ui/
mv main.tscn scenes/

# 步骤3：移动脚本文件
echo "移动脚本文件..."
mv base_character.gd player.gd enemy.gd scripts/characters/
mv item_data.gd audio_manager.gd enemy_spawner.gd scripts/systems/
mv main.gd inventory.gd damage_number.gd dropped_item.gd item_slot.gd scripts/ui/

# 步骤4：移动音效文件
echo "移动音效文件..."
mv sounds/* assets/sounds/
rmdir sounds

echo ""
echo "=== 文件移动完成！==="
echo ""
echo "接下来需要："
echo "1. 更新 project.godot 中的路径"
echo "2. 更新脚本中的 preload() 路径"
echo "3. 更新 .tscn 文件中的脚本引用"
echo "4. 删除 .godot 文件夹"
echo "5. 重新打开 Godot 项目"
echo ""
