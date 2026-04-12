#!/bin/bash

# --- KONFIGURASI SENSOR ---
TEMP_PATH="/sys/class/hwmon/hwmon6/temp1_input"
POWER_PATH="/sys/class/power_supply/BAT1/power_now" 
STATUS_PATH="/sys/class/power_supply/ACAD/online"

# --- AMBANG BATAS ---
TEMP_THRESHOLD=80000  # 75°C
WATT_THRESHOLD=15     # 15W
INTERVAL=10           # Cek setiap 10 detik

# Log saat script mulai berjalan
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sentinel Service Started."
echo "Monitoring Temp Path: $TEMP_PATH"
echo "Monitoring Power Path: $POWER_PATH"

while true; do
    # 1. Baca Status Power (0 = Battery, 1 = AC)
    IS_AC=$(cat "$STATUS_PATH")

    # 2. Baca Suhu
    CURRENT_TEMP=$(cat "$TEMP_PATH")
    DISPLAY_TEMP=$((CURRENT_TEMP / 1000))

    # 3. Logika Alert & Logging
    if [ "$IS_AC" -eq 1 ]; then
        STATUS_STR="AC Mode"
        # --- MODE AC ---
        if [ "$CURRENT_TEMP" -gt "$TEMP_THRESHOLD" ]; then
            echo "[$(date '+%H:%M:%S')] ALERT: High Temp on AC! Current: ${DISPLAY_TEMP}°C"
            notify-send -u critical -i dialog-warning "AC Thermal Alert" "Suhu tembus ${DISPLAY_TEMP}°C! Lid tertutup bisa berbahaya."
        fi
    else
        STATUS_STR="Battery Mode"
        # --- MODE BATTERY ---
        RAW_WATT=$(cat "$POWER_PATH")
        # Pastikan RAW_WATT tidak kosong untuk menghindari error bc
        if [ -z "$RAW_WATT" ]; then RAW_WATT=0; fi
        CURRENT_WATT=$(echo "scale=2; $RAW_WATT / 1000000" | bc)

        # Alert Suhu
        if [ "$CURRENT_TEMP" -gt "$TEMP_THRESHOLD" ]; then
            echo "[$(date '+%H:%M:%S')] ALERT: High Temp on BAT! Current: ${DISPLAY_TEMP}°C"
            notify-send -u critical -i dialog-warning "Battery Thermal Alert" "Suhu: ${DISPLAY_TEMP}°C. Segera cari sirkulasi udara!"
        fi

        # Alert Power (Hanya di Baterai)
        if (( $(echo "$CURRENT_WATT > $WATT_THRESHOLD" | bc -l) )); then
            echo "[$(date '+%H:%M:%S')] ALERT: Power Drain High! Current: ${CURRENT_WATT}W"
            notify-send -u normal -i battery-caution "Power Warning" "Penggunaan daya: ${CURRENT_WATT}W (Melebihi target 15W)."
        fi
    fi

    # Log rutin setiap iterasi (Opsional: hapus jika log terlalu penuh)
    # echo "[$(date '+%H:%M:%S')] $STATUS_STR | Temp: ${DISPLAY_TEMP}°C | Power: ${CURRENT_WATT:-N/A}W"

    sleep $INTERVAL
done
