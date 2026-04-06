# HP Aero Linux Configuration

This repository contains my personal Linux configuration for the **HP Pavilion Aero 13**, optimized for maximum battery efficiency on the go and "beast mode" performance when plugged in. It also includes settings for a Macbook-like sleep/hibernate experience.

## ✨ Features

- 🔋 **Battery Efficiency:** TLP configured to limit CPU frequencies, disable turbo boost, and use power-saving scaling governors when on battery.
- ⚡ **Beast Mode (AC):** Full CPU performance, enabled turbo boost, and high-performance platform profiles when connected to power.
- 🌙 **Macbook-like Sleep:** Configured for `s2idle` (modern standby) and hibernation support to avoid unnecessary shutdowns.
- 🛠️ **Custom GRUB Theme:** Includes settings for the Elegant Mojave theme for a polished boot experience.

## 📂 Configuration Files

| File | Description |
|------|-------------|
| `grub` | GRUB configuration with kernel parameters for resume, modern standby, and themes. |
| `initramfs-resume` | Configuration for the initramfs to identify the hibernation resume point. |
| `tlp.conf` | Extensive TLP configuration for power management. |

### Key Settings in `tlp.conf`

- **CPU Scaling:** `powersave` on both AC/BAT, but with frequency limits.
- **Max Performance:** Limited to 30% on battery, 100% on AC.
- **Turbo Boost:** Disabled on battery, Enabled on AC.
- **Platform Profile:** `power-saver` on battery, `performance` on AC.
- **Modern Standby:** `s2idle` enabled for both modes.

## 🚀 Installation

> [!CAUTION]
> These configuration files contain UUIDs and offsets specific to my disk partition layout. **Do not copy blindly.**

### 1. Identify your Resume UUID and Offset
If you use a swap file for hibernation, you must find your UUID and offset:
```bash
# Find UUID of the partition containing the swap file
findmnt -no UUID -T /swapfile

# Find the resume_offset
sudo filefrag -v /swapfile | awk '{if($1=="0:"){print $4}}' | sed 's/\..//'
```

### 2. Apply GRUB Configuration
1. Copy the `grub` file to `/etc/default/grub` (backup your original first!).
2. Update the `resume=UUID=...` and `resume_offset=...` with your own values.
3. Update `update-grub`:
   ```bash
   sudo update-grub
   ```

### 3. Apply TLP Configuration
1. Install TLP if you haven't: `sudo apt install tlp`
2. Copy `tlp.conf` to `/etc/tlp.conf`.
3. Restart TLP:
   ```bash
   sudo tlp start
   ```

### 4. Apply Initramfs Resume
1. Copy `initramfs-resume` to `/etc/initramfs-tools/conf.d/resume`.
2. Update the UUID and Offset inside.
3. Update initramfs:
   ```bash
   sudo update-initramfs -u
   ```

## 📝 Notes
- The `package-lock.json` file is a placeholder/artifact and is not used for system configuration.
- The `GRUB_THEME` path points to `/boot/grub/themes/Elegant-mojave-window-left-dark/theme.txt`. Ensure this theme is installed in that directory.
