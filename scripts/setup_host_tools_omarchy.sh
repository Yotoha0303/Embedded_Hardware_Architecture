#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: setup_host_tools_omarchy.sh
# 适用平台: Omarchy (Arch Linux + Hyprland)
# 脚本作用: 安装与配置嵌入式硬件开发必备的宿主桌面工具 (串口工具、VOFA+ 波形分析、OpenOCD、esptool)
# ==============================================================================

set -euo pipefail

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
fi

echo "================================================================="
echo " 🖥️ Omarchy 嵌入式宿主桌面工具链安装与检测"
echo "================================================================="

REQUIRED_PKGS=(
    "esptool"
    "minicom"
    "tio"
    "openocd"
    "libusb"
    "cmake"
    "ninja"
)

AUR_PKGS=(
    "vofa-plus-bin"
)

MISSING_OFFICIAL=()
MISSING_AUR=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
        MISSING_OFFICIAL+=("$pkg")
    fi
done

for pkg in "${AUR_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
        MISSING_AUR+=("$pkg")
    fi
done

if [[ "$CHECK_ONLY" == true ]]; then
    echo "🔍 [Check Mode] 正在检测宿主工具安装状态..."
    if [[ ${#MISSING_OFFICIAL[@]} -eq 0 && ${#MISSING_AUR[@]} -eq 0 ]]; then
        echo "✅ 所有宿主工具均已安装就绪！"
    else
        [[ ${#MISSING_OFFICIAL[@]} -gt 0 ]] && echo "⚠️ 缺失官方源包: ${MISSING_OFFICIAL[*]}"
        [[ ${#MISSING_AUR[@]} -gt 0 ]] && echo "⚠️ 缺失 AUR 包: ${MISSING_AUR[*]}"
    fi
    exit 0
fi

if [[ ${#MISSING_OFFICIAL[@]} -gt 0 ]]; then
    echo "📦 正在安装官方源缺失依赖: ${MISSING_OFFICIAL[*]} ..."
    sudo pacman -S --needed --noconfirm "${MISSING_OFFICIAL[@]}"
else
    echo "✅ 官方源依赖均已满足。"
fi

if [[ ${#MISSING_AUR[@]} -gt 0 ]]; then
    echo "📦 正在通过 yay 安装 AUR 软件包: ${MISSING_AUR[*]} ..."
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm "${MISSING_AUR[@]}" || {
            echo "⚠️ AUR 安装 vofa-plus-bin 失败或网络超时，提供备用方案："
            echo "👉 可直接下载 VOFA+ 官方 AppImage: https://www.vofa.plus/"
        }
    else
        echo "⚠️ 系统未找到 yay，跳过 AUR 安装。"
    fi
else
    echo "✅ AUR 依赖均已满足。"
fi

# 检查并配置 Hyprland 窗口浮动规则 (针对 VOFA+ 串口示波器)
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HYPR_CONF" ]]; then
    if ! grep -q "windowrulev2 = float,class:^(vofa\+)" "$HYPR_CONF"; then
        echo "🪟 检测到 Hyprland 配置，正在添加 VOFA+ 窗口浮动规则..."
        echo "" >> "$HYPR_CONF"
        echo "# 嵌入式硬件开发: VOFA+ 窗口浮动与居中规则" >> "$HYPR_CONF"
        echo "windowrulev2 = float,class:^(vofa\+),title:^(VOFA\+.*)" >> "$HYPR_CONF"
        echo "windowrulev2 = center,class:^(vofa\+)" >> "$HYPR_CONF"
        echo "windowrulev2 = size 1200 800,class:^(vofa\+)" >> "$HYPR_CONF"
        echo "✅ 已向 hyprland.conf 添加 VOFA+ 规则！"
    fi
fi

echo "🎉 宿主工具环境配置完毕！"
