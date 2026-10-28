/*
 * ESP32-S3 Embedded Hardware Starter Template
 * Developed for Omarchy Linux Development Environment
 */

#include <stdio.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"
#include "esp_log.h"

static const char *TAG = "ESP32S3_STARTER";

// 心跳任务，兼作串口波形生成器 (可配合 VOFA+ FireWater / JustFloat 协议)
static void heartbeat_task(void *pvParameters)
{
    uint32_t counter = 0;
    while (1) {
        float dummy_voltage = 3.30f + 0.05f * (float)(counter % 10);
        float dummy_temperature = 25.0f + (float)(counter % 5);

        // 格式化输出 (VOFA+ RawData / FireWater 兼容格式)
        ESP_LOGI(TAG, "Heartbeat #%" PRIu32 " | VDD: %.2fV | Temp: %.1fC | FreeHeap: %" PRIu32 " bytes",
                 counter++, dummy_voltage, dummy_temperature, (uint32_t)esp_get_free_heap_size());

        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "=================================================");
    ESP_LOGI(TAG, " 🚀 Omarchy ESP32-S3 Hardware Starter Firmware");
    ESP_LOGI(TAG, "=================================================");

    /* 获取芯片与架构信息 */
    esp_chip_info_t chip_info;
    uint32_t flash_size;
    esp_chip_info(&chip_info);

    ESP_LOGI(TAG, "芯片核心: %s (核心数: %d)",
             CONFIG_IDF_TARGET,
             chip_info.cores);

    ESP_LOGI(TAG, "芯片特性支持: %s%s%s%s",
             chip_info.features & CHIP_FEATURE_WIFI_BGN ? "2.4GHz WiFi " : "",
             chip_info.features & CHIP_FEATURE_BT ? "BT " : "",
             chip_info.features & CHIP_FEATURE_BLE ? "BLE " : "",
             chip_info.features & CHIP_FEATURE_IEEE802154 ? "802.15.4 " : "");

    ESP_LOGI(TAG, "硅片版本: %d", chip_info.revision);

    if (esp_flash_get_size(NULL, &flash_size) == ESP_OK) {
        ESP_LOGI(TAG, "SPI Flash 容量: %" PRIu32 " MB (%s)",
                 flash_size / (1024 * 1024),
                 (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "片内嵌入" : "片外挂载");
    }

    ESP_LOGI(TAG, "系统当前可用堆内存: %" PRIu32 " KB", (uint32_t)(esp_get_free_heap_size() / 1024));
    ESP_LOGI(TAG, "系统最小历史堆内存: %" PRIu32 " KB", (uint32_t)(esp_get_minimum_free_heap_size() / 1024));

    /* 启动 FreeRTOS 心跳与遥测任务 */
    xTaskCreate(heartbeat_task, "heartbeat_task", 4096, NULL, 5, NULL);
}
