-- xtail_mixer.lua - Four-fin X-tail mixer for ArduPlane
-- Tested on Matek H743-Wing V3. Requires ArduPilot Lua scripting support.
-- Rear view: F1=top right (S2), F2=top left (S3),
--            F3=bottom left (S4), F4=bottom right (S5).
-- Setup: SERVO1_FUNCTION=70, SERVO2..5_FUNCTION=94..97, SCR_ENABLE=1.
-- Verify servo directions and limits for your aircraft before flight.

local PITCH_GAIN, ROLL_GAIN, YAW_GAIN = 0.6, 0.5, 0.3
local PWM_MIN, PWM_MAX, PWM_TRIM = 1000, 2000, 1500
local REV_FIN1, REV_FIN2, REV_FIN3, REV_FIN4 = -1, 1, 1, -1
local CHAN_FIN1, CHAN_FIN2, CHAN_FIN3, CHAN_FIN4 = 2, 3, 4, 5
local TIMEOUT_MS, PARAM_KEY, TRIM_LIMIT = 100, 74, 0.5

-- Trim parameters XTRM_ROLL/PITCH/YAW are limited to +/-0.5 demand units.
assert(param:add_table(PARAM_KEY, "XTRM_", 3), "XTail: param table failed")
assert(param:add_param(PARAM_KEY, 1, "ROLL", 0), "XTail: XTRM_ROLL failed")
assert(param:add_param(PARAM_KEY, 2, "PITCH", 0), "XTail: XTRM_PITCH failed")
assert(param:add_param(PARAM_KEY, 3, "YAW", 0), "XTail: XTRM_YAW failed")

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function to_pwm(demand)
    return math.floor(clamp(PWM_TRIM + demand * (PWM_MAX - PWM_TRIM), PWM_MIN, PWM_MAX))
end

local function get_trim(name)
    return clamp(param:get(name) or 0, -TRIM_LIMIT, TRIM_LIMIT)
end

local last_announce = 0

local function update()
    local now = millis()
    if now - last_announce > 5000 then
        gcs:send_text(6, "XTail mixer: running")
        last_announce = now
    end

    -- ArduPlane virtual outputs: 4=aileron, 19=elevator, 21=rudder.
    local roll_d  = (SRV_Channels:get_output_scaled(4)  or 0) / 4500
    local pitch_d = (SRV_Channels:get_output_scaled(19) or 0) / 4500
    local yaw_d   = (SRV_Channels:get_output_scaled(21) or 0) / 4500

    local roll  = -(roll_d + get_trim("XTRM_ROLL")) * ROLL_GAIN
    local pitch =  (pitch_d + get_trim("XTRM_PITCH")) * PITCH_GAIN
    local yaw   =  (yaw_d + get_trim("XTRM_YAW")) * YAW_GAIN

    -- Servo reversal is handled here, not by SERVOn_REVERSED.
    local fin1 = clamp((pitch + roll + yaw) * REV_FIN1, -1, 1)
    local fin2 = clamp((pitch - roll - yaw) * REV_FIN2, -1, 1)
    local fin3 = clamp((pitch - roll + yaw) * REV_FIN3, -1, 1)
    local fin4 = clamp((pitch + roll - yaw) * REV_FIN4, -1, 1)

    SRV_Channels:set_output_pwm_chan_timeout(CHAN_FIN1 - 1, to_pwm(fin1), TIMEOUT_MS)
    SRV_Channels:set_output_pwm_chan_timeout(CHAN_FIN2 - 1, to_pwm(fin2), TIMEOUT_MS)
    SRV_Channels:set_output_pwm_chan_timeout(CHAN_FIN3 - 1, to_pwm(fin3), TIMEOUT_MS)
    SRV_Channels:set_output_pwm_chan_timeout(CHAN_FIN4 - 1, to_pwm(fin4), TIMEOUT_MS)

    logger:write('XTL', 'RollD,PitchD,YawD,F1,F2,F3,F4', 'fffffff',
                 roll_d, pitch_d, yaw_d, fin1, fin2, fin3, fin4)

    return update, 20
end

gcs:send_text(6, "XTail mixer: script loaded and running")
return update()
