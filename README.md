# ArduPilot-XTail-Mixer
Hi! This is a Flight tested, 4 surface X-tail control mixer for ArduPilot, implemented in Lua. Enables independent and simultaneous roll, pitch, and yaw control through real time control allocation on unconventional fixed-wing UAVs.
It converts ArduPlane's roll, pitch, and yaw servo demands into four independent fin commands, allowing all three axes to be controlled individually or together.

Take note this is developed for a Matek H743-Wing V3 running ArduPlane (MATEKH743). Other boards require an ArduPilot firmware build with Lua scripting support.

# Features:
Three-axis mixing at 50 Hz
Adjustable roll, pitch, and yaw gains in the script
Per-fin servo direction settings
Ground-station trim parameters (XTRM_ROLL, XTRM_PITCH, XTRM_YAW)
DataFlash XTL logging of axis demands and fin commands

# Installation
1. Use an ArduPlane firmware build with Lua scripting support.
2. Set the parameters below. These channel assignments match the author's aircraft; adapt them to yours.
3. Copy xtail_mixer.lua to the flight controller's SD card at APM/scripts/.
4. Reboot and check ground-station messages for XTail mixer: running.
5. Verify the direction, range, and combined motion of all fins before flight. 



# Control mixing

After applying trim and axis gains, the script uses these signed demands (R also includes an intentional sign inversion):
F1 = P + R + Y
F2 = P - R - Y
F3 = P - R + Y
F4 = P + R - Y
Each command is then multiplied by its per-fin reversal, clipped to [-1, 1], and mapped to 1000–2000 µs PWM with a 1500 µs center. The default per-fin reversals are [-1, +1, +1, -1], specific to the original airframe. Output reversal is handled in the script rather than with SERVOn_REVERSED.



# Default gains: 
pitch 0.6, roll 0.5, yaw 0.3. Change them in the script for your aircraft as you'd like. XTRM_ROLL, XTRM_PITCH, and XTRM_YAW default to zero and are limited to ±0.5 controller-demand units.


# Flight testing
I demonstrated this in flight on my aircraft aircraft with independent roll, pitch, and yaw inputs, as well as combined-axis inputs, AUTOTUNE isn't required for this but I recommend it, as long as you have a decent stability margin, you don't need to get your Ixx, Iyy etc and put it into some stupid SITL software, you can fly it, AUTOTUNE and your PID will be more accurate than any SITL could give you. The published gains and configuration should be verified against the particular aircraft and firmware in use, ie if you are more nose heavy you'll want more gains on your pitch. 

The XTL DataFlash message logs RollD, PitchD, YawD (untrimmed controller demands) and F1–F4 (final normalized fin commands).




