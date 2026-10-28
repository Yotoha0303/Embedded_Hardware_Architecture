#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: setup_esp_idf.sh
# 适用平台: Omarchy (Arch Linux + Hyprland)
# 脚本作用: 自动化配置与校验 ESP-IDF v5.4 (ESP32-S3/C3/C6) 开发工具链及 Python 3.12 虚拟环境
# ==============================================================================

set -euo pipefail

IDF_TARGET_PATH="${IDF_PATH:-$HOME/esp/esp-idf}"
IDF_VERSION_BRANCH="release/v5.4"
IDF_TARGETS="esp32s3,esp32c3"
MIRROR_MODE="auto" # auto | cn | global

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mirror)
            MIRROR_MODE="$2"
            shift 2
            ;;
        --targets)
            IDF_TARGETS="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [--mirror auto|cn|global] [--targets esp32s3,esp32c3]"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

echo "================================================================="
echo " ⚙️ ESP-IDF 嵌入式开发工具链自动化部署与校验"
echo "================================================================="

# 1. 确保 Python 3.12 运行时就绪 (Arch Linux 系统自带 3.14，构建 wheels 需 3.12)
PYTHON_312_BIN=""

if command -v python3.12 >/dev/null 2>&1; then
    PYTHON_312_BIN="$(command -v python3.12)"
else
    # 查找 uv 安装的 python 3.12
    UV_PY312=$(find "$HOME/.local/share/uv/python" -name "python3.12" 2>/dev/null | head -n 1 || true)
    if [[ -n "$UV_PY312" && -x "$UV_PY312" ]]; then
        PYTHON_312_BIN="$UV_PY312"
    else
        echo "📦 系统未发现 Python 3.12，正在通过 uv 极速安装隔离运行时..."
        if ! command -v uv >/dev/null 2>&1; then
            echo "📥 安装 uv 包管理器..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
            export PATH="$HOME/.local/bin:$PATH"
        fi
        uv python install 3.12
        PYTHON_312_BIN="$(find "$HOME/.local/share/uv/python" -name "python3.12" 2>/dev/null | head -n 1)"
    fi
fi

echo "✅ Python 3.12 运行时就绪: $PYTHON_312_BIN"

# 2. 判断镜像网络源
CLONE_URL="https://github.com/espressif/esp-idf.git"
if [[ "$MIRROR_MODE" == "cn" ]]; then
    CLONE_URL="https://gitee.com/EspressifSystems/esp-idf.git"
    export IDF_GITHUB_ASSETS="dl.espressif.cn/github_assets"
elif [[ "$MIRROR_MODE" == "auto" ]]; then
    # 自动探测 GitHub 连通性
    if ! curl -Is --connect-timeout 2 https://github.com >/dev/null 2>&1; then
        echo "🌐 GitHub 探测较慢或不可达，自动切换为国内镜像源..."
        CLONE_URL="https://gitee.com/EspressifSystems/esp-idf.git"
        export IDF_GITHUB_ASSETS="dl.espressif.cn/github_assets"
    fi
fi

# 3. 检查或克隆 ESP-IDF
mkdir -p "$(dirname "$IDF_TARGET_PATH")"
if [[ ! -d "$IDF_TARGET_PATH/.git" ]]; then
    echo "📥 正在克隆 ESP-IDF ($IDF_VERSION_BRANCH) 至 $IDF_TARGET_PATH ..."
    git clone --depth 1 -b "$IDF_VERSION_BRANCH" "$CLONE_URL" "$IDF_TARGET_PATH"
    cd "$IDF_TARGET_PATH"
    echo "📥 更新子模块..."
    git submodule update --init --recursive --depth 1
else
    echo "✅ ESP-IDF 源码目录已存在: $IDF_TARGET_PATH"
fi

# 4. 执行 IDF 安装脚本 (指定 Python 3.12)
cd "$IDF_TARGET_PATH"
echo "🔧 执行 IDF 工具链安装 (目标芯片: $IDF_TARGETS) ..."
export ESP_IDF_PYTHON_ENV_PATH="$HOME/.espressif/python_env"
export PYTHON="$PYTHON_312_BIN"
bash ./install.sh "$IDF_TARGETS"

# 5. 生成快捷引导加载器 get_idf
mkdir -p "$HOME/.local/bin"
GET_IDF_PATH="$HOME/.local/bin/get_idf"
cat << 'EOF' > "$GET_IDF_PATH"
#!/usr/bin/env bash
# 加载 ESP-IDF 环境变量
IDF_PATH_DEFAULT="$HOME/esp/esp-idf"
TARGET_IDF="${IDF_PATH:-$IDF_PATH_DEFAULT}"

if [[ -f "$TARGET_IDF/export.sh" ]]; then
    # 查找 python3.12
    if [[ -z "${PYTHON:-}" ]]; then
        UV_PY312=$(find "$HOME/.local/share/uv/python" -name "python3.12" 2>/dev/null | head -n 1 || true)
        if [[ -n "$UV_PY312" ]]; then
            export PYTHON="$UV_PY312"
        fi
    fi
    . "$TARGET_IDF/export.sh"
else
    echo "❌ 错误: 未在 $TARGET_IDF 找到 export.sh"
    return 1 2>/dev/null || exit 1
fi
EOF
chmod +x "$GET_IDF_PATH"

echo "✅ ESP-IDF 环境部署完成！"
echo "💡 提示: 您可以在终端执行 'source get_idf' 立即激活 ESP-IDF 编译环境。"
