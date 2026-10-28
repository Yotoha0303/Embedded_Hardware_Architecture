# 版本变更日志 (Changelog)

本项目遵循 [Semantic Versioning (语义化版本 2.0.0)](https://semver.org/lang/zh-CN/) 规范。

---

## [v1.0.0] - 2026-10-28

### 初始发布 (Initial Release)

- **Omarchy (Arch Linux + Hyprland) 现代化嵌入式硬件 6 大架构层级完整实现**：
  - **【层级 1: 宿主环境与桌面工具】**：
    - 新增 `scripts/setup_host_tools_omarchy.sh`，统一接管 `pacman` 与 `yay` 嵌入式依赖（`esptool`, `minicom`, `tio`, `openocd`, `vofa-plus-bin`）。
    - 针对 Hyprland 平铺式窗口管理器自动注入 VOFA+ 专用浮动与居中规则 (`windowrulev2 = float,class:^(vofa\+)`)。
    - 预置 `.vscode/settings.json`、`.vscode/extensions.json` 与 `.vscode/tasks.json`，一键通过 `Ctrl+Shift+B` 执行固件编译、烧录与监视。
  - **【层级 2: 设备权限与总线免提权】**：
    - 新增 `config/99-esp32-hardware.rules`，全面覆盖乐鑫原生 USB-JTAG/CDC (`303a:1001/1002/0002`)、南京沁恒 CH340/CH341、Silicon Labs CP210x、FTDI FT232 以及 CMSIS-DAP 调试器。
    - 编写 `scripts/setup_udev_rules.sh`，自动将用户加入 `uucp` 用户组，实现普通用户免 `sudo` 读写串口与在线调试。
  - **【层级 3: 编译器运行时与隔离环境】**：
    - 编写 `scripts/setup_esp_idf.sh`，采用 `uv` 部署独立的 Python 3.12 虚拟环境，彻底消除 Arch Linux 滚动更新到 Python 3.14 导致的 C 扩展 wheels 编译失败问题。
    - 部署 ESP-IDF v5.4.4 LTS 长期支持版及 Xtensa GCC 14.2.0 交叉编译器。
    - 生成快捷启动器 `~/.local/bin/get_idf`，支持终端任意位置 `source get_idf` 极速载入编译环境。
  - **【层级 4: 硬件配置矩阵与外设规范】**：
    - 新增 `config/hardware_matrix.json`，结构化定义 ESP32-S3、ESP32-C3 架构规格、原生 USB 与 UART 双通信总线引脚（GPIO19/20、GPIO43/44）及 1.3 英寸 OLED/LCD 屏幕选型。
  - **【层级 5: 固件工程标准模板】**：
    - 提供开箱即用的 `templates/esp32s3_starter/` 工程脚手架。
    - 配置 `sdkconfig.defaults` 固化 8MB Quad SPI Flash、1000Hz FreeRTOS 调度与原生 USB-Serial/JTAG 控制台。
    - 在 `main/main.c` 中实现芯片特性检测（硅片版本、Flash、堆内存）及 FreeRTOS 心跳遥测任务，支持与 VOFA+ FireWater 协议无缝对接。
  - **【层级 6: 持续集成与自动化冒烟测试】**：
    - 编写 `scripts/smoke_test.sh`，实现 6 项指标端到端全自动检测，输出 100% 满分架构评分卡 (Architecture Health Scorecard)。
    - 根目录提供顶级主入口 `start.sh`（支持 `--mirror cn|global|auto`, `--up-only`, `--code`, `--target`）与闭环清理脚本 `clean.sh`（支持 `-a` 深度清理与 `-v` 详情）。
    - 编写 `.github/workflows/ci.yml`，在 GitHub Actions 中自动执行 Shell Lint、JSON 语法校验与 ESP32-S3 官方容器固件构建验证。
- **高规格双语文档体系**：
  - 提供 `README.md`、`README_EN.md`、`USER_GUIDE.md`（完整开发指南与 FAQ）、`脚本使用手册.md`（参数与产物边界说明）。
  - 设计高清晰度 SVG 架构全景工程图 `docs/images/architecture_diagram.svg` 与 Mermaid 交互式数据流图。
