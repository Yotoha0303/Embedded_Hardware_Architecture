#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: setup_udev_rules.sh
# 适用平台: Omarchy (Arch Linux + Hyprland) / 通用 Linux
# 脚本作用: 配置嵌入式硬件串口与 USB-JTAG 设备的免提权 udev 规则，并确保当前用户拥有串口访问权限 (uucp/dialout 组)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RULE_SRC="$PROJECT_ROOT/config/99-esp32-hardware.rules"
RULE_DEST="/etc/udev/rules.d/99-esp32-hardware.rules"

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
fi

echo "================================================================="
echo " 🔌 嵌入式硬件 udev 规则与串口设备权限配置"
echo "================================================================="

# 1. 检查规则源文件是否存在
if [[ ! -f "$RULE_SRC" ]]; then
    echo "❌ 错误: 未找到规则源文件 $RULE_SRC"
    exit 1
fi

# 2. 检查用户组权限
CURRENT_USER="${SUDO_USER:-$USER}"
GROUPS_NEEDED=()

if grep -q "^uucp:" /etc/group; then
    GROUPS_NEEDED+=("uucp")
fi
if grep -q "^dialout:" /etc/group; then
    GROUPS_NEEDED+=("dialout")
fi

USER_IN_GROUP=true
for grp in "${GROUPS_NEEDED[@]}"; do
    if ! id -nG "$CURRENT_USER" | grep -qw "$grp"; then
        USER_IN_GROUP=false
    fi
done

if [[ "$CHECK_ONLY" == true ]]; then
    echo "🔍 [Check Mode] 正在检测配置状态..."
    if [[ -f "$RULE_DEST" ]] && cmp -s "$RULE_SRC" "$RULE_DEST"; then
        echo "✅ udev 规则文件已部署: $RULE_DEST"
    else
        echo "⚠️ udev 规则文件未部署或内容不一致"
    fi

    if [[ "$USER_IN_GROUP" == true ]]; then
        echo "✅ 用户 '$CURRENT_USER' 已加入硬件串口权限用户组 (${GROUPS_NEEDED[*]})"
    else
        echo "⚠️ 用户 '$CURRENT_USER' 尚未加入硬件串口组 (${GROUPS_NEEDED[*]})"
    fi
    exit 0
fi

# 3. 部署 udev 规则文件
echo "📦 正在部署 udev 规则到 $RULE_DEST ..."
if [[ $EUID -ne 0 ]]; then
    sudo cp "$RULE_SRC" "$RULE_DEST"
    sudo chmod 644 "$RULE_DEST"
    echo "🔄 重载 udev 规则并触发硬件事件..."
    sudo udevadm control --reload-rules
    sudo udevadm trigger
else
    cp "$RULE_SRC" "$RULE_DEST"
    chmod 644 "$RULE_DEST"
    echo "🔄 重载 udev 规则并触发硬件事件..."
    udevadm control --reload-rules
    udevadm trigger
fi
echo "✅ udev 规则部署成功！"

# 4. 配置用户组
for grp in "${GROUPS_NEEDED[@]}"; do
    if ! id -nG "$CURRENT_USER" | grep -qw "$grp"; then
        echo "👤 正在将用户 '$CURRENT_USER' 添加到用户组 '$grp'..."
        if [[ $EUID -ne 0 ]]; then
            sudo usermod -aG "$grp" "$CURRENT_USER"
        else
            usermod -aG "$grp" "$CURRENT_USER"
        fi
        echo "⚠️ 提示: 已添加用户组。若要在当前终端立即生效，请运行 'newgrp $grp' 或重新登录桌面会话。"
    fi
done

echo "🎉 硬件权限配置全部完成！开发板插入后无需 root 即可读写串口与执行 JTAG 调试。"
