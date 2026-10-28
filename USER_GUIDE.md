# Omarchy 嵌入式硬件与 IoT 工程 - 用户使用说明书 (User Guide)

[![CI Pipeline](https://github.com/Yotoha0303/Embedded_Hardware_Architecture/actions/workflows/ci.yml/badge.svg)](https://github.com/Yotoha0303/Embedded_Hardware_Architecture/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/Yotoha0303/Embedded_Hardware_Architecture?label=Release&color=blue)](https://github.com/Yotoha0303/Embedded_Hardware_Architecture/releases)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Omarchy%20(Arch%20Linux)-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![ESP-IDF](https://img.shields.io/badge/ESP--IDF-v5.4+-E7352C?logo=espressif&logoColor=white)](https://github.com/espressif/esp-idf)
[![VOFA+](https://img.shields.io/badge/Telemetry-VOFA%2B-5B5EA6)](https://www.vofa.plus/)

本项目专为 **Omarchy (Arch Linux + Hyprland)** 操作系统设计，提供开箱即用、一键拉起的嵌入式硬件与物联网（IoT）工程开发体系，重点赋能 **ESP32-S3**（支持双核 LX7、矢量 AI 指令、原生硬件 USB-JTAG/CDC）以及 1.3 英寸 OLED/LCD 交互大屏开发。

> 📖 **更多参考文档**：
> - 📋 [**项目主页与快速开始 (README.md)**](README.md)
> - 🛠️ [**脚本使用手册 (脚本使用手册.md)**](脚本使用手册.md)
> - 📝 [**版本更新日志 (CHANGELOG.md)**](CHANGELOG.md)

---

## 目录

- [一、架构层级与硬件总线映射](#一架构层级与硬件总线映射)
- [二、系统前置要求与环境就绪检查](#二系统前置要求与环境就绪检查)
- [三、一键启动与全流程跑通 (推荐)](#三一键启动与全流程跑通-推荐)
  - [1. 快速启动与参数说明](#1-快速启动与参数说明)
  - [2. 生命周期闭环清理 (clean.sh)](#2-生命周期闭环清理-cleansh)
- [四、核心硬件模块与工具实战指南](#四核心硬件模块与工具实战指南)
  - [1. ESP32-S3 双模式通信与引脚定义](#1-esp32-s3-双模式通信与引脚定义)
  - [2. Linux udev 免提权总线规则与权限管理](#2-linux-udev-免提权总线规则与权限管理)
  - [3. VOFA+ 实时串口示波器与多通道遥测](#3-vofa-实时串口示波器与多通道遥测)
  - [4. SquareLine Studio + LVGL v8/v9 界面设计](#4-squareline-studio--lvgl-v8v9-界面设计)
  - [5. VS Code + OpenOCD 硬件断点与单步调试](#5-vs-code--openocd-硬件断点与单步调试)
- [五、固件工程模板与二次开发指南](#五固件工程模板与二次开发指南)
- [六、手动检查与验收 Checklist](#六手动检查与验收-checklist)
- [七、常见问题与高频排坑指南 (FAQ)](#七常见问题与高频排坑指南-faq)
  - [类别 A：串口设备识别与权限拒绝 (Permission Denied)](#类别-a串口设备识别与权限拒绝-permission-denied)
  - [类别 B：Arch Linux 系统 Python 3.14 与 IDF 兼容性](#类别-barch-linux-系统-python-314-与-idf-兼容性)
  - [类别 C：ESP32-S3 原生 USB 烧录与日志无输出](#类别-cesp32-s3-原生-usb-烧录与日志无输出)
  - [类别 D：VOFA+ 波形未绘制或数据显示乱码](#类别-dvofa-波形未绘制或数据显示乱码)
  - [类别 E：JTAG 硬件在线断点调试连接失败](#类别-ejtag-硬件在线断点调试连接失败)
- [八、开源协议](#八开源协议)

---

## 一、架构层级与硬件总线映射

| 架构层级 | 工具与组件 | 部署形态 | 对应配置文件 / 目录 | 职责与功能 |
| :--- | :--- | :--- | :--- | :--- |
| **层级 1: 宿主工具** | VS Code, VOFA+, SquareLine Studio, tio, esptool | 宿主原生 (Arch / Hyprland) | `scripts/setup_host_tools_omarchy.sh`<br>`.vscode/` | 提供代码编辑、波形大屏监视、UI 可视化设计及终端交互 |
| **层级 2: 设备权限** | udev 规则, `uucp` 用户组 | 系统内核事件层 | `config/99-esp32-hardware.rules`<br>`scripts/setup_udev_rules.sh` | 永久赋予普通用户对 USB/串口硬件节点的直接读写权限 |
| **层级 3: 编译器运行时** | ESP-IDF v5.4.4, Xtensa GCC 14.2.0, Python 3.12 | 隔离虚拟环境 | `scripts/setup_esp_idf.sh`<br>`~/.local/bin/get_idf` | 跨架构交叉编译支持，规避滚动发行版 Python 版本断层冲突 |
| **层级 4: 硬件通信总线** | 原生 USB-JTAG/CDC, 外置 UART 桥接 | 物理引脚与 USB 总线 | `config/hardware_matrix.json`<br>`templates/esp32s3_starter/sdkconfig.defaults` | 规范 GPIO19/20 与 GPIO43/44 双物理接口电气特性与传输协议 |
| **层级 5: 固件工程标准** | FreeRTOS 内核, 心跳遥测任务, 芯片检测 | C / CMake 标准工程 | `templates/esp32s3_starter/main/` | 提供生产级固件脚手架，兼容 VOFA+ FireWater 波形解析 |
| **层级 6: 持续集成验证** | 本地冒烟测试评分卡, GitHub Actions | 自动化运维与 CI | `scripts/smoke_test.sh`, `start.sh`<br>`.github/workflows/ci.yml` | 保证代码提交后 100% 可构建、配置参数无裂化 |

---

## 二、系统前置要求与环境就绪检查

本项目在 **ASUS VivoBook 15 (X513UA / M5100UA)** 搭载 **AMD Ryzen 7 5700U (8核16线程, 16GB RAM, OLED 1080P, scale 1.6)** 环境下经过全量实机调优验证。

* **基础依赖**：已安装 `git`, `bash`, `curl`, `pacman`, `yay`。
* **物理连接**：ESP32-S3 开发板通过 Type-C 数据线插入电脑 USB 接口。

---

## 三、一键启动与全流程跑通 (推荐)

### 1. 快速启动与参数说明

在项目根目录下，直接运行一键启动器：

```bash
./start.sh
```

脚本将全自动依次推进 6 大层级：
1. 校验并部署 `99-esp32-hardware.rules` 免提权规则。
2. 校验 `esptool`, `tio`, `openocd`, `vofa+` 是否完备。
3. 加载 ESP-IDF v5.4.4 与 Python 3.12 虚拟环境。
4. 校验 `config/hardware_matrix.json` 硬件定义。
5. 自动编译 `templates/esp32s3_starter` 固件工程并输出架构评分卡。

#### 常用参数组合：
```bash
# 强制使用国内镜像源（Gitee / 乐鑫国内资源库）
./start.sh --mirror cn

# 仅拉起并配置环境，不执行固件编译冒烟测试
./start.sh --up-only

# 配置完成后立即自动唤起 VS Code
./start.sh --code

# 指定针对 ESP32-C3 进行配置
./start.sh --target esp32c3
```

### 2. 生命周期闭环清理 (clean.sh)

嵌入式编译会生成百兆以上的 `.o` 与 `.elf` 中间体。开发调试完成后，运行以下命令随用随清：

```bash
# 快速清理构建输出 build/ 目录
./clean.sh

# 深度清理（包含 sdkconfig、ccache 缓存以及 Python 临时字节码）
./clean.sh -a
```

---

## 四、核心硬件模块与工具实战指南

### 1. ESP32-S3 双模式通信与引脚定义

ESP32-S3 拥有独特的硬件架构优势：它内置了 **原生 USB-OTG 与硬件 USB-Serial/JTAG 控制器**。

```text
               +----------------------------------+
               |         ESP32-S3 SoC             |
               |                                  |
   Type-C Port |  [GPIO 19] <-----> USB D-        |  识别为: /dev/ttyACM0
   (Native)    |  [GPIO 20] <-----> USB D+        |  特性: 硬件断点/免芯片/高速
               |                                  |
   Type-C Port |  [GPIO 43] <-----> TXD0 (CH340)  |  识别为: /dev/ttyUSB0
   (UART Bridge|  [GPIO 44] <-----> RXD0 (CH340)  |  特性: 传统串口/自复位电路
               +----------------------------------+
```

* **原生 USB 模式 (`/dev/ttyACM0`)**：
  - 推荐日常开发首选！直接连入芯片硬件控制器，无需板载 CH340 或 CP2102。
  - 支持免外置硬件仿真器直接进行 GDB JTAG 在线单步断点调试。
  - 在 `sdkconfig.defaults` 中已默认开启：
    `CONFIG_ESP_CONSOLE_USB_SERIAL_JTAG=y`

* **外置 UART 模式 (`/dev/ttyUSB0`)**：
  - 若使用普通双 Type-C 端口板的 `UART` 接口，芯片使用 GPIO43 与 GPIO44。

---

### 2. Linux udev 免提权总线规则与权限管理

在 Linux 下操作串口默认需要 `root` 权限。本项目通过 `config/99-esp32-hardware.rules` 彻底解决此痛点：
1. 包含针对乐鑫官方原生 VID/PID (`303a:1001`, `303a:1002`, `303a:0002`)、CH340/341、CP2102、FTDI 等全系列芯片的匹配规则。
2. 将设备模式设为 `MODE="0666"` 并归入 `uucp` 用户组。
3. 运行 `./scripts/setup_udev_rules.sh` 即可完成部署并自动触发 `udevadm control --reload-rules && udevadm trigger`。

---

### 3. VOFA+ 实时串口示波器与多通道遥测

[VOFA+](https://www.vofa.plus/) 是目前最强大的嵌入式实时串口示波器与数字仪表台。

#### 协议选择：FireWater（推荐）
在 `templates/esp32s3_starter/main/main.c` 中，预置的心跳任务以如下格式输出数据：
```c
printf("<%.2f,%.1f,%" PRIu32 ">\n", dummy_voltage, dummy_temperature, free_heap);
```

#### VOFA+ 快速配置 3 步走：
1. 在终端输入 `vofa+` 启动界面（Hyprland 已自动将其配置为 1200x800 浮动居中窗口）。
2. 在左上角端口设置中选择 `/dev/ttyACM0`（波特率 `115200` 或更高），数据协议选择 **FireWater**。
3. 从左侧控件库拖拽 **波形图 (Waveform)** 和 **数字表盘 (Value Table)** 放置到画布上，点击右上角 `Play`，即可看到实时动态渲染的电压曲线与可用内存波动图！

---

### 4. SquareLine Studio + LVGL v8/v9 界面设计

针对 1.3 英寸 OLED/LCD 显示屏（如 ST7789 SPI 240x240 或 SH1106 I2C 128x64）：
1. 在 SquareLine Studio 中创建项目，目标分辨率设为开发板屏幕尺寸。
2. 拖拽生成 UI 组件后，点击菜单：`Export` -> `Export UI Files`。
3. 将导出的 `ui.c`、`ui.h` 拷贝至本工程 `templates/esp32s3_starter/main/` 目录下。
4. 在 `CMakeLists.txt` 中将 `ui.c` 加入 `SRCS` 列表，在 `main.c` 初始化显示屏驱动并调用 `ui_init()` 即可！

---

### 5. VS Code + OpenOCD 硬件断点与单步调试

借助 ESP32-S3 内置的 USB-Serial/JTAG 硬件，无需购买任何外部 J-Link 或 ST-Link：
1. 打开 VS Code，按下 `Ctrl+Shift+P` 输入并选择：`OpenOCD: Start OpenOCD Server`。
2. 配置文件已固化：`board/esp32s3-builtin.cfg`。
3. 在代码行号左侧单击打下红点断点，按下 `F5` 启动调试。
4. 程序将准确定位并在断点处暂停，支持查看 CPU 寄存器、FreeRTOS 任务调用堆栈及局部变量！

---

## 五、固件工程模板与二次开发指南

`templates/esp32s3_starter/` 目录结构与作用：

```text
templates/esp32s3_starter/
├── CMakeLists.txt              # CMake 顶级配置 (申明最低版本与 ESP-IDF 包含)
├── sdkconfig.defaults          # 固化芯片选型 (ESP32-S3)、8MB Flash、1000Hz 调度配置
├── .vscode/                    # 针对 starter 工程的 IntelliSense 与断点配置
│   ├── c_cpp_properties.json   # C/C++ 宏与头文件解析
│   └── settings.json           # 默认 OpenOCD 与芯片目标定义
└── main/
    ├── CMakeLists.txt          # 组件注册: idf_component_register
    └── main.c                  # 芯片自检、多任务初始化与遥测数据流源文件
```

在日常业务开发中，您只需以 `templates/esp32s3_starter` 为蓝本复制创建新工程目录，直接在 `main.c` 中扩充 I2C / SPI / BLE 业务代码即可。

---

## 六、手动检查与验收 Checklist

| 检查项 | 验证步骤与命令 | 正常标志 | 检查结果 |
| :---: | :--- | :--- | :---: |
| 1 | 终端运行 `source get_idf && idf.py --version` | 输出 `ESP-IDF v5.4.4` | [ ] |
| 2 | 插入板卡后执行 `ls -l /dev/ttyACM0` | 权限为 `crw-rw-rw-` 且属组为 `uucp` | [ ] |
| 3 | 执行 `esptool chip_id` | 正常探测到 ESP32-S3 核心与 MAC 地址 | [ ] |
| 4 | 终端执行 `./scripts/smoke_test.sh` | 6/6 指标全部通过，评分 100% | [ ] |
| 5 | 启动 `vofa+` 串口波形监视器 | 窗口正常浮动居中，波形平滑刷新 | [ ] |

---

## 七、常见问题与高频排坑指南 (FAQ)

### 类别 A：串口设备识别与权限拒绝 (Permission Denied)
* **症状**：执行烧录时提示 `serial.serialutil.SerialException: [Errno 13] could not open port /dev/ttyACM0: [Errno 13] Permission denied`。
* **原因**：当前用户未被授权读写串口设备节点，或 udev 规则未生效。
* **修复方法**：
  1. 运行 `./scripts/setup_udev_rules.sh`。
  2. 执行 `sudo usermod -aG uucp $USER`。
  3. 重新拔插开发板或在终端中运行 `newgrp uucp` 即可立即生效。

### 类别 B：Arch Linux 系统 Python 3.14 与 IDF 兼容性
* **症状**：在 Arch 系统运行 `install.sh` 提示构建 wheels 失败或 `imp` 模块缺失。
* **原因**：Arch Linux 滚到了 Python 3.14，部分 C 扩展在最新 Python 上缺乏预编译二进制包。
* **修复方法**：本项目已通过 `scripts/setup_esp_idf.sh` 内置了 `uv python install 3.12`，自动将独立 Python 3.12 虚拟环境置于 `~/.espressif/python_env`，彻底与系统 Python 隔离。

### 类别 C：ESP32-S3 原生 USB 烧录与日志无输出
* **症状**：烧录完成断开后，串口终端没有任何字符打印。
* **原因**：ESP32-S3 默认控制台走 UART0 (GPIO43/44)，若未开启 USB-Serial/JTAG 控制台，原生 USB 口将收不到 `printf`。
* **修复方法**：检查工程中的 `sdkconfig.defaults`，确保包含以下配置项：
  ```ini
  CONFIG_ESP_CONSOLE_USB_SERIAL_JTAG=y
  ```
  执行 `./clean.sh -a && idf.py build` 重新编译即可。

### 类别 D：VOFA+ 波形未绘制或数据显示乱码
* **症状**：VOFA+ 收到串口字节流，但波形图不绘制或乱码。
* **原因**：
  1. 波特率配置不匹配（默认应为 `115200`）。
  2. 协议选错（需在 VOFA+ 界面将协议切换为与代码一致的 `FireWater`）。
  3. 数据帧尾缺少换行符 `\n`。

### 类别 E：JTAG 硬件在线断点调试连接失败
* **症状**：OpenOCD 提示 `Error: unable to open ftdi device with vid 303a, pid 1001`。
* **原因**：USB 设备被其它串口监视终端独占（如 `tio` 或 `minicom` 正在占用连接）。
* **修复方法**：先在终端中关闭 `tio` 串口监视进程，再启动 OpenOCD 调试。

---

## 八、开源协议

本项目采用 [Apache License 2.0](LICENSE) 开源协议。
