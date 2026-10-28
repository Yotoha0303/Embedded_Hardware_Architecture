#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: clean.sh
# 适用平台: Omarchy (Arch Linux + Hyprland) / 通用 Linux
# 脚本作用: 清理嵌入式工程编译产物、中间对象、构建缓存与临时文件 (随开随用、用完即净)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates/esp32s3_starter"

ALL_CLEAN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            ALL_CLEAN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            cat << 'EOF'
用法: ./clean.sh [选项]

选项:
  -a, --all      深度清理 (包含 sdkconfig、ccache 缓存以及临时配置)
  -v, --verbose  显示详细删除过程
  -h, --help     显示本帮助信息
EOF
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1"
            exit 1
            ;;
    esac
done

echo "================================================================="
echo " 🧹 Omarchy 嵌入式硬件工程: 环境生命周期闭环清理"
echo "================================================================="

# 1. 清理 starter 固件编译产物
if [[ -d "$TEMPLATE_DIR/build" ]]; then
    echo "🗑️ 正在清理固件构建产物目录: $TEMPLATE_DIR/build ..."
    if [[ "$VERBOSE" == true ]]; then
        rm -rfv "$TEMPLATE_DIR/build"
    else
        rm -rf "$TEMPLATE_DIR/build"
    fi
    echo "✅ 固件 build 目录已清理。"
else
    echo "ℹ️ 固件构建目录不存在，无需清理。"
fi

# 2. 深度清理 (sdkconfig, ccache, 临时文件)
if [[ "$ALL_CLEAN" == true ]]; then
    echo "🧹 执行深度清理 (-a/--all)..."
    
    # 清理生成的 sdkconfig (保留 sdkconfig.defaults)
    if [[ -f "$TEMPLATE_DIR/sdkconfig" ]]; then
        rm -f "$TEMPLATE_DIR/sdkconfig"
        rm -f "$TEMPLATE_DIR/sdkconfig.old"
        echo "✅ 已移除临时生成的 sdkconfig。"
    fi

    # 清理 ccache (若系统安装)
    if command -v ccache >/dev/null 2>&1; then
        echo "🔄 清空 ccache 编译器缓存..."
        ccache -C >/dev/null 2>&1 || true
        echo "✅ ccache 缓存已重置。"
    fi

    # 清理 Python 字节码与缓存
    find "$SCRIPT_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$SCRIPT_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true
    echo "✅ Python 临时缓存已清理。"
fi

echo "🎉 清理完成！工程目录保持轻量整洁。"
