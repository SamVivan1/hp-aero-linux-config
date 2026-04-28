#!/bin/bash

# --- KONFIGURASI SENSOR ---
TEMP_PATH="/sys/class/hwmon/hwmon6/temp1_input"
POWER_PATH="/sys/class/power_supply/BAT1/power_now"
STATUS_PATH="/sys/class/power_supply/ACAD/online"

# --- AMBANG BATAS ---
TEMP_THRESHOLD=75000 # 80°C
WATT_THRESHOLD=15    # 15W
INTERVAL=10          # Cek sensor setiap 10 detik

# --- KONFIGURASI NOTIFIKASI (COOLDOWN) ---
# Berapa lama script harus diam (dalam detik) setelah mengirim satu notif
TEMP_NOTIF_COOLDOWN=300  # 5 Menit (Suhu cukup kritis, 5 menit sekali oke)
POWER_NOTIF_COOLDOWN=900 # 15 Menit (Daya hanya info efisiensi, jangan sering-sering)

# Inisialisasi Timer (0 artinya boleh kirim notif sekarang)
LAST_TEMP_NOTIF=0
LAST_POWER_NOTIF=0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sentinel Service Started."
echo "Monitoring Temp Path: $TEMP_PATH"
echo "Monitoring Power Path: $POWER_PATH"

while true; do
  CURRENT_TIME=$(date +%s) # Ambil waktu sekarang dalam format detik (epoch)

  # 1. Baca Status Power (0 = Battery, 1 = AC)
  IS_AC=$(cat "$STATUS_PATH")

  # 2. Baca Suhu
  CURRENT_TEMP=$(cat "$TEMP_PATH")
  DISPLAY_TEMP=$((CURRENT_TEMP / 1000))

  # 3. Logika Alert & Cooldown
  if [ "$IS_AC" -eq 1 ]; then
    # --- MODE AC ---
    if [ "$CURRENT_TEMP" -gt "$TEMP_THRESHOLD" ]; then
      # Cek apakah sudah melewati masa tenang 5 menit
      if ((CURRENT_TIME - LAST_TEMP_NOTIF > TEMP_NOTIF_COOLDOWN)); then
        echo "[$(date '+%H:%M:%S')] ALERT: High Temp on AC! Current: ${DISPLAY_TEMP}°C"
        notify-send -u critical -i dialog-warning "AC Thermal Alert" "Suhu tembus ${DISPLAY_TEMP}°C! Lid tertutup bisa berbahaya."
        LAST_TEMP_NOTIF=$CURRENT_TIME # Reset timer
      fi
    fi
  else
    # --- MODE BATTERY ---
    RAW_WATT=$(cat "$POWER_PATH")
    if [ -z "$RAW_WATT" ]; then RAW_WATT=0; fi
    CURRENT_WATT=$(echo "scale=2; $RAW_WATT / 1000000" | bc)

    # Alert Suhu di Baterai
    if [ "$CURRENT_TEMP" -gt "$TEMP_THRESHOLD" ]; then
      if ((CURRENT_TIME - LAST_TEMP_NOTIF > TEMP_NOTIF_COOLDOWN)); then
        echo "[$(date '+%H:%M:%S')] ALERT: High Temp on BAT! Current: ${DISPLAY_TEMP}°C"
        notify-send -u critical -i dialog-warning "Battery Thermal Alert" "Suhu: ${DISPLAY_TEMP}°C. Segera cari sirkulasi udara!"
        LAST_TEMP_NOTIF=$CURRENT_TIME
      fi
    fi

    # Alert Power (Dengan Cooldown 15 Menit agar tidak mengganggu game)
    if (($(echo "$CURRENT_WATT > $WATT_THRESHOLD" | bc -l))); then
      if ((CURRENT_TIME - LAST_POWER_NOTIF > POWER_NOTIF_COOLDOWN)); then
        echo "[$(date '+%H:%M:%S')] ALERT: Power Drain High! Current: ${CURRENT_WATT}W"
        notify-send -u normal -i battery-caution "Power Warning" "Penggunaan daya: ${CURRENT_WATT}W (Target: ${WATT_THRESHOLD}W)."
        LAST_POWER_NOTIF=$CURRENT_TIME
      fi
    fi
  fi

  sleep $INTERVAL
done
