<div align="right">
  <strong>Languages:</strong>
  <a href="README.md">简体中文</a> |
  <a href="README_EN.md">English</a>
</div>

# Omarchy Modern Embedded Hardware & IoT Architecture Guide

[![CI Pipeline](https://github.com/Yotoha0303/Embedded_Hardware_Architecture/actions/workflows/ci.yml/badge.svg)](https://github.com/Yotoha0303/Embedded_Hardware_Architecture/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/Yotoha0303/Embedded_Hardware_Architecture?label=Release&color=blue)](https://github.com/Yotoha0303/Embedded_Hardware_Architecture/releases)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Omarchy%20(Arch%20Linux)-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![ESP-IDF](https://img.shields.io/badge/ESP--IDF-v5.4+-E7352C?logo=espressif&logoColor=white)](https://github.com/espressif/esp-idf)
[![Target](https://img.shields.io/badge/Target-ESP32--S3%20%7C%20C3%20%7C%20C6-FF6F00)](config/hardware_matrix.json)
[![Python](https://img.shields.io/badge/Python-3.12%20(uv)-3776AB?logo=python&logoColor=white)](scripts/setup_esp_idf.sh)
[![VOFA+](https://img.shields.io/badge/Telemetry-VOFA%2B-5B5EA6)](https://www.vofa.plus/)

This project is tailored specifically for the **Omarchy (Arch Linux + Hyprland)** desktop environment, adopting a modern **Linux Embedded & IoT Engineering Architecture**. It delivers a seamless, closed-loop development pipeline: one-click toolchain initialization, unprivileged hardware bus authorization via udev, real-time multi-channel telemetry waveform plotting, and CI/CD firmware smoke testing.

> 📖 **Companion Manuals & Guides**:
> - 📘 [**User Guide (USER_GUIDE.md)**](USER_GUIDE.md): Full hands-on guide for firmware & hardware developers (quickstart, pinout wiring, VOFA+ protocol, SquareLine Studio LVGL UI porting, FAQ)
> - 🛠️ [**Script Reference Manual (脚本使用手册.md)**](脚本使用手册.md): Low-level parameters, execution flows, output artifacts, and rollback strategies
> - 📝 [**Changelog (CHANGELOG.md)**](CHANGELOG.md): Core release features and architecture evolution notes

---

## 1. Architecture Tiers & Component Mapping

| Tier | Tools & Components | Deployment Form | Config & Directory Mapping |
| :--- | :--- | :--- | :--- |
| **1. Host Environment & Desktop Tools** | VS Code (ESP-IDF Extension), VOFA+ Serial Plotter, SquareLine Studio, tio/minicom | Native on Omarchy (Arch + Hyprland) | `scripts/setup_host_tools_omarchy.sh`<br>`.vscode/tasks.json`, `.vscode/settings.json` |
| **2. Device Permissions & udev Bus** | Linux udev rules, `uucp`/`dialout` group mappings | Host Kernel uevent subsystem | `config/99-esp32-hardware.rules`<br>`scripts/setup_udev_rules.sh` |
| **3. Compiler & Isolated Runtime** | ESP-IDF v5.4.4 LTS, Xtensa GCC 14.2.0, OpenOCD-ESP32, esptool, Python 3.12 (via uv) | Isolated venv (`~/.espressif/python_env`) | `scripts/setup_esp_idf.sh`<br>`~/.local/bin/get_idf` |
| **4. Hardware Target & Peripherals** | ESP32-S3 (Xtensa Dual-Core LX7 @ 240MHz, 8MB Flash), Native USB-CDC/JTAG, CH340/CP2102 | Hardware dev board & bus interfaces | `config/hardware_matrix.json`<br>`templates/esp32s3_starter/sdkconfig.defaults` |
| **5. Firmware Template & Data Stream** | FreeRTOS Scheduler, Chip Feature Detection, VOFA+ FireWater Telemetry Task, LVGL Driver | C / CMake Standard Firmware Template | `templates/esp32s3_starter/main/main.c`<br>`templates/esp32s3_starter/CMakeLists.txt` |
| **6. Automated Smoke Test & CI** | Local 6-Metric Architecture Scorecard, GitHub Actions Remote Build | POSIX Shell + Containerized CI Runner | `scripts/smoke_test.sh`, `start.sh`, `clean.sh`<br>`.github/workflows/ci.yml` |

### Architecture & Data Flow Diagram

<p align="center">
  <img src="docs/images/architecture_diagram.svg" alt="Omarchy Embedded Hardware Architecture Diagram" width="100%" />
</p>

---

## 2. Host Environment Setup (Omarchy & Linux)

On Omarchy (Arch Linux + Hyprland), host embedded packages and Wayland window rules are handled automatically:

```bash
# Run host setup (installs cmake, ninja, libusb, tio, minicom, openocd, vofa-plus-bin)
./scripts/setup_host_tools_omarchy.sh

# Or check status without modifying system
./scripts/setup_host_tools_omarchy.sh --check
```

---

## 3. Quick Start Guide

### One-Click Launch Matrix

| Platform | Entrypoint | Behavior |
| :--- | :--- | :--- |
| **Omarchy (Arch Linux)** | `./start.sh` or<br>`bash start.sh` | [Tier 1: udev Bus Rules] (Deploy `99-esp32-hardware.rules`, verify `uucp` group)<br>[Tier 2: Host Tools] (Verify `esptool`, `tio`, `openocd`, `vofa+`)<br>[Tier 3: Runtime] (Verify Python 3.12 venv and ESP-IDF v5.4.4)<br>[Tier 4: Hardware Matrix] (Load `hardware_matrix.json`)<br>[Tier 5: Smoke Test] (Compile `esp32s3_starter` firmware and output 6-metric scorecard)<br>[Tier 6: IDE Hook] (Optionally launch VS Code via `--code`) |

```bash
# Full launch with 6-metric automated smoke test (Recommended)
./start.sh

# Force domestic mirror (Gitee / dl.espressif.cn)
./start.sh --mirror cn

# Setup environment only, skip compilation
./start.sh --up-only

# Launch and open project in VS Code
./start.sh --code

# Clean build artifacts (closed lifecycle)
./clean.sh
./clean.sh -a  # Deep clean (removes sdkconfig and compiler caches)
```

---

## 4. Operational Verification Checklist

Run the automated diagnostic scorecard directly:
```bash
./scripts/smoke_test.sh
```

Expected output:
```text
=================================================================
 📊 Architecture Health Scorecard
-----------------------------------------------------------------
 Total Metrics: 6 | Passed: 6
 Architecture Readiness: 100% (Grade A Hardware Pipeline)
=================================================================
🎉 All smoke tests passed! Ready for production hardware development.
```

---

## 5. License

This project is licensed under the [Apache License 2.0](LICENSE).
