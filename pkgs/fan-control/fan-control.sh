#!/usr/bin/env bash

# Find the correct hwmon device (nct6795 chip) dynamically
HWMON_PATH=""
for hwmon in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$hwmon/name" 2>/dev/null)" = "nct6795" ]; then
        HWMON_PATH="$hwmon"
        break
    fi
done

if [ -z "$HWMON_PATH" ]; then
    echo "Error: Could not find nct6795 hwmon device"
    exit 1
fi

# Get current PWM value
current_pwm=$(cat "$HWMON_PATH/pwm6" 2>/dev/null || echo "Unknown")
current_rpm=$(cat "$HWMON_PATH/fan6_input" 2>/dev/null || echo "Unknown")

echo "Current Fan Status:"
echo "  PWM: $current_pwm / 255 ($(( current_pwm * 100 / 255 ))%)"
echo "  RPM: $current_rpm"
echo ""
echo "PWM Guide:"
echo "  60  = Quiet (~634 RPM)"
echo "  135 = Default (~2854 RPM)"
echo "  200 = Performance (~4000+ RPM)"
echo "  255 = Maximum (~4700 RPM)"
echo ""
read -p "Enter new PWM value (60-255): " new_pwm

# Validate input
if ! [[ "$new_pwm" =~ ^[0-9]+$ ]] || [ "$new_pwm" -lt 60 ] || [ "$new_pwm" -gt 255 ]; then
    echo "Error: Please enter a number between 60 and 255"
    exit 1
fi

# Set PWM value
echo "Setting PWM to $new_pwm..."
sudo bash -c "echo 1 > $HWMON_PATH/pwm6_enable && echo $new_pwm > $HWMON_PATH/pwm6"

if [ $? -eq 0 ]; then
    sleep 1
    new_rpm=$(cat "$HWMON_PATH/fan6_input" 2>/dev/null || echo "Unknown")
    echo "Success! Fan speed set to $new_pwm PWM (~$new_rpm RPM)"
else
    echo "Error: Failed to set fan speed"
    exit 1
fi
