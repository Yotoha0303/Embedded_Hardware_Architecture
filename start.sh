#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: start.sh
# 适用平台: Omarchy (Arch Linux + Hyprland) / 通用 Linux
# 脚本作用: 一键拉起嵌入式硬件与 IoT 开发环境，执行权限配置、工具链初始化与冒烟测试
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认运行参数
RUN_TESTS=true
SETUP_HOST_TOOLS=true
OPEN_CODE=false
MIRROR_MODE="auto"
TARGET_CHIP="esp32s3"

# 参数解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mirror)
            MIRROR_MODE="$2"
            shift 2
            ;;
        --skip-tests|--up-only)
            RUN_TESTS=false
            shift
            ;;
        --skip-host-tools)
            SETUP_HOST_TOOLS=false
            shift
            ;;
        --tools-only)
            RUN_TESTS=false
            SETUP_HOST_TOOLS=true
            shift
            ;;
        --code)
            OPEN_CODE=true
            shift
            ;;
        --target)
            TARGET_CHIP="$2"
            shift 2
            ;;
        --help|-h)
            cat << 'EOF'
用法: ./start.sh [选项]

选项:
  --mirror <auto|cn|global>   指定下载镜像策略 (默认: auto 自动探测)
  --up-only, --skip-tests     仅拉起并配置环境，跳过固件编译冒烟测试
  --skip-host-tools           跳过宿主桌面工具检测与安装 (跳过 pacman/yay)
  --tools-only                仅配置宿主工具与 udev 权限，不执行测试
  --code                      配置完毕后自动唤起 VS Code 打开工程
  --target <esp32s3|esp32c3>  指定目标硬件架构 (默认: esp32s3)
  --help, -h                  显示本帮助信息
EOF
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1 (使用 --help 查看支持选项)"
            exit 1
            ;;
    esac
done

echo "=========================================================================="
echo " 🚀 Omarchy 嵌入式硬件与 IoT 架构开发环境 (一键启动器)"
echo " 目标平台: Omarchy Linux (Arch + Hyprland) | 目标架构: $TARGET_CHIP"
echo "=========================================================================="

# 步骤 1: 硬件总线免提权 udev 规则与权限检查
echo -e "\n📌 [层级 1: 硬件底座与总线权限]"
bash "$SCRIPT_DIR/scripts/setup_udev_rules.sh"

# 步骤 2: 宿主桌面与终端工具链检测
if [[ "$SETUP_HOST_TOOLS" == true ]]; then
    echo -e "\n📌 [层级 2: 宿主桌面分析工具链]"
    bash "$SCRIPT_DIR/scripts/setup_host_tools_omarchy.sh"
fi

# 步骤 3: ESP-IDF 与 Python 3.12 虚拟环境自动化就绪
echo -e "\n📌 [层级 3: 嵌入式编译器与编译运行时]"
bash "$SCRIPT_DIR/scripts/setup_esp_idf.sh" --mirror "$MIRROR_MODE" --targets "$TARGET_CHIP"

# 步骤 4: 硬件配置矩阵校验
echo -e "\n📌 [层级 4: 硬件参数与引脚配置矩阵]"
MATRIX_FILE="$SCRIPT_DIR/config/hardware_matrix.json"
if [[ -f "$MATRIX_FILE" ]]; then
    echo "✅ 成功加载硬件矩阵配置文件: $MATRIX_FILE"
else
    echo "⚠️ 硬件矩阵文件未找到"
fi

# 步骤 5: 自动化冒烟测试与固件编译
if [[ "$RUN_TESTS" == true ]]; then
    echo -e "\n📌 [层级 5: 固件自动化构建与端到端冒烟测试]"
    bash "$SCRIPT_DIR/scripts/smoke_test.sh"
fi

# 步骤 6: 唤起开发工具 (VS Code)
if [[ "$OPEN_CODE" == true ]]; then
    echo -e "\n📌 [层级 6: 开发者集成开发环境 (IDE)]"
    if command -v code >/dev/null 2>&1; then
        echo "💻 正在启动 VS Code 并加载嵌入式工作区配置..."
        code "$SCRIPT_DIR"
    else
        echo "⚠️ 未找到 VS Code 命令行入口 'code'，请手动打开。"
    fi
fi

echo -e "\n=========================================================================="
echo " 🎉 Omarchy 嵌入式硬件开发环境已全部就绪！"
echo " 👉 快速上手指南:"
echo "    1. 在任意终端执行: source get_idf"
echo "    2. 进入固件目录:   cd templates/esp32s3_starter"
echo "    3. 编译并烧录:     idf.py flash monitor (支持 Native USB 与串口桥接)"
echo "    4. 打开波形大屏:   vofa+ (已自动配置 Hyprland 浮动窗口)"
echo "=========================================================================="
