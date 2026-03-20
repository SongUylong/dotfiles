#!/usr/bin/env bash

# ASUS ROG G17 fan control via asus_wmi hwmon
# Fan channels: pwm1 = CPU fan, pwm2 = GPU fan
# The asus_wmi driver exposes fans under a hwmon device named "asus"

# Find the correct hwmon device dynamically
find_hwmon() {
    local chip_name="$1"
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$hwmon/name" 2> /dev/null)" = "$chip_name" ]; then
            echo "$hwmon"
            return
        fi
    done
}

# Try asus_wmi first (ROG laptops), fall back to nct6795 (desktop)
HWMON_PATH=$(find_hwmon "asus")
CHIP="asus"

if [ -z "$HWMON_PATH" ]; then
    HWMON_PATH=$(find_hwmon "nct6795")
    CHIP="nct6795"
fi

if [ -z "$HWMON_PATH" ]; then
    echo "Error: Could not find asus or nct6795 hwmon device"
    echo "Available hwmon devices:"
    for hwmon in /sys/class/hwmon/hwmon*; do
        echo "  $hwmon: $(cat "$hwmon/name" 2> /dev/null || echo unknown)"
    done
    exit 1
fi

echo "Chip: $CHIP ($HWMON_PATH)"
echo ""

# Detect available fan channels
FAN_CHANNELS=()
if [ "$CHIP" = "asus" ]; then
    # ASUS ROG: pwm1 = CPU fan, pwm2 = GPU fan
    for ch in 1 2; do
        if [ -f "$HWMON_PATH/pwm${ch}" ]; then
            FAN_CHANNELS+=("$ch")
        fi
    done
else
    # Desktop nct6795: pwm6
    FAN_CHANNELS=(6)
fi

if [ ${#FAN_CHANNELS[@]} -eq 0 ]; then
    echo "Error: No PWM fan channels found under $HWMON_PATH"
    exit 1
fi

echo "Current Fan Status:"
for ch in "${FAN_CHANNELS[@]}"; do
    label="Fan $ch"
    [ "$CHIP" = "asus" ] && [ "$ch" = "1" ] && label="CPU Fan"
    [ "$CHIP" = "asus" ] && [ "$ch" = "2" ] && label="GPU Fan"

    current_pwm=$(cat "$HWMON_PATH/pwm${ch}" 2> /dev/null || echo "N/A")
    current_rpm=$(cat "$HWMON_PATH/fan${ch}_input" 2> /dev/null || echo "N/A")
    enable_val=$(cat "$HWMON_PATH/pwm${ch}_enable" 2> /dev/null || echo "N/A")

    if [ "$current_pwm" != "N/A" ]; then
        pct=$((current_pwm * 100 / 255))
        echo "  $label: PWM=$current_pwm/255 (${pct}%)  RPM=$current_rpm  mode=$enable_val"
    else
        echo "  $label: PWM=N/A  RPM=$current_rpm"
    fi
done

echo ""
echo "PWM Guide:"
echo "  0   = Fan off (dangerous, avoid)"
echo "  60  = Quiet  (~20% speed)"
echo "  130 = Balanced (~50% speed)"
echo "  200 = Performance (~78% speed)"
echo "  255 = Maximum (100% speed)"
echo ""
echo "Control modes (pwmN_enable):"
echo "  0 = Full auto (BIOS/EC controlled) — recommended for normal use"
echo "  1 = Manual PWM (override)"
echo ""

echo "Fan channel to control:"
select_ch=""
if [ ${#FAN_CHANNELS[@]} -gt 1 ]; then
    echo "  a) All fans"
    for ch in "${FAN_CHANNELS[@]}"; do
        label="Fan $ch"
        [ "$CHIP" = "asus" ] && [ "$ch" = "1" ] && label="CPU Fan (pwm1)"
        [ "$CHIP" = "asus" ] && [ "$ch" = "2" ] && label="GPU Fan (pwm2)"
        echo "  $ch) $label"
    done
    read -p "Choice [a/${FAN_CHANNELS[*]}]: " select_ch
else
    select_ch="${FAN_CHANNELS[0]}"
fi

if [ "$select_ch" = "a" ] || [ -z "$select_ch" ]; then
    TARGET_CHANNELS=("${FAN_CHANNELS[@]}")
else
    TARGET_CHANNELS=("$select_ch")
fi

read -p "Enter new PWM value (0=auto/BIOS, 60-255=manual): " new_pwm

# Validate
if ! [[ "$new_pwm" =~ ^[0-9]+$ ]] || [ "$new_pwm" -gt 255 ]; then
    echo "Error: Please enter a number between 0 and 255"
    exit 1
fi

if [ "$new_pwm" -eq 0 ]; then
    echo "Restoring fan to automatic BIOS/EC control..."
    for ch in "${TARGET_CHANNELS[@]}"; do
        sudo bash -c "echo 0 > $HWMON_PATH/pwm${ch}_enable" 2> /dev/null
        echo "  pwm${ch}: restored to auto"
    done
    exit 0
fi

if [ "$new_pwm" -lt 60 ] && [ "$new_pwm" -gt 0 ]; then
    echo "Warning: Values below 60 may stall the fan. Proceeding anyway..."
fi

echo "Setting PWM to $new_pwm..."
for ch in "${TARGET_CHANNELS[@]}"; do
    sudo bash -c "echo 1 > $HWMON_PATH/pwm${ch}_enable && echo $new_pwm > $HWMON_PATH/pwm${ch}"
    if [ $? -eq 0 ]; then
        sleep 1
        new_rpm=$(cat "$HWMON_PATH/fan${ch}_input" 2> /dev/null || echo "N/A")
        echo "  pwm${ch}: set to $new_pwm PWM (~$new_rpm RPM)"
    else
        echo "  pwm${ch}: failed to set"
    fi
done
