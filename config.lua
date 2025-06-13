Config = {}

--------------- Parking sensor ---------------
Config.ParkSensor = true                    -- Should we enable parking sensor?
Config.DebugDistance = false                -- Show current distance to obstacle, check WIKI for more information

Config.BeepSound = {                        -- Beeping sound, check WIKI for more information
    Name = "Beep_Red",
    Ref = "DLC_HEIST_HACKING_SNAKE_SOUNDS"
}

Config.BeepInvervals = {                    -- Minimum time is 200 milliseconds!
    far = 1200,                                -- 1.2 second between beeps
    medium = 700,                              -- 0.7 seconds between beeps
    close = 500,                               -- 0.5 seconds between beeps
    veryClose = 200                            -- 0.2 seconds between beeps
}

Config.Thresholds = {                       -- It's recommended to keep these values as is.
    far = 12.0,                                -- 12 meters
    medium = 10.0,                             -- 10 meters
    close = 8.0,                               -- 8 meters
    veryClose = 6.0                            -- 6 meters
}

Config.DetectPed = true                     -- Should parking sensor detect nearby peds?    
Config.DetectObj = true                     -- Should parking sensor detect nearby objects?
Config.DetectVeh = true                     -- Should parking sensor detect nearby vehicles?


--------------- Parking camera ---------------
Config.Cam360 = true                        -- Should we enable 360 camera?

Config.Cam360CMD = "360"                    -- Command to toggle the camera
Config.Cam360Key = "F9"                     -- Keybinding to toggle the camera (SET TO false TO DISABLE THE KEYBINDING)

Config.Cam360AnimDur = 500                  -- Duration of the fadein-fadeout animation in milliseconds

Config.Cam360FOV = 90.0                     -- Camera FOV
Config.Cam360Offset = vector3(0, 0, 7)  -- Offset from vehicle center for camera position