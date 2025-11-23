#!/usr/bin/env python3
import tkinter as tk
from tkinter import messagebox
import os
import glob

def find_hwmon_path():
    """
    Returns the hwmon path for the NCT6795D chip.
    """
    for path in glob.glob("/sys/class/hwmon/hwmon*/name"):
        with open(path) as f:
            name = f.read().strip()
            if name.startswith("nct67") or name.startswith("nct6795"):
                return path.replace("/name", "")
    return None

hwmon = find_hwmon_path()
if hwmon is None:
    raise SystemExit("ERROR: Could not find nct6795 (Nuvoton) hwmon device.")

PWM_ENABLE = os.path.join(hwmon, "pwm6_enable")
PWM_VALUE  = os.path.join(hwmon, "pwm6")

# Ensure pwm6 is in manual mode
try:
    with open(PWM_ENABLE, "w") as f:
        f.write("1")
except PermissionError:
    print("ERROR: Run this program with sudo:")
    print("sudo python3 fancontrol.py")
    raise SystemExit

def read_pwm():
    """Read current PWM6 value from sysfs."""
    try:
        with open(PWM_VALUE, "r") as f:
            return int(f.read().strip())
    except Exception:
        return 150  # fallback if something goes wrong

def set_pwm(value):
    """Write PWM value to pwm6."""
    try:
        with open(PWM_VALUE, "w") as f:
            f.write(str(int(value)))
        value_label.config(text=f"Current PWM6: {value}")
    except PermissionError:
        messagebox.showerror("Permission Denied", "Run this script using sudo.")
    except Exception as e:
        messagebox.showerror("Error", str(e))

# --- GUI ---
root = tk.Tk()
root.title("Manual CPU Fan Controller (PWM6)")
root.geometry("350x200")
root.resizable(False, False)

title = tk.Label(root, text="PWM6 Fan Controller", font=("Arial", 14))
title.pack(pady=10)

current_pwm = read_pwm()

slider = tk.Scale(
    root, from_=0, to=255, orient=tk.HORIZONTAL,
    length=300, label="Fan Speed (0–255)",
    command=set_pwm
)
slider.set(current_pwm)  # initialize with current value
slider.pack(pady=10)

value_label = tk.Label(root, text=f"Current PWM6: {current_pwm}", font=("Arial", 12))
value_label.pack(pady=10)

root.mainloop()
