-------------------- CONFIGURATION --------------------
-- Main configuration file (edit in config)
local CfgParkSensor          = Config.ParkSensor or true
local CfgDebugDistance       = Config.DebugDistance or false
local CfgDetectPed           = Config.DetectPed or true
local CfgDetectObj           = Config.DetectObj or true
local CfgDetectVeh           = Config.DetectVeh or true

-- 360 Camera config
local CfgCam360              = Config.Cam360 or true
local CfgCam360CMD           = Config.Cam360CMD or "360"
local CfgCam360Key           = Config.Cam360Key or "F9"
local CfgCam360AnimDur       = Config.Cam360AnimDur or 500
local CfgCam360FOV           = Config.Cam360FOV or 90.0
local CfgCam360Offset        = Config.Cam360Offset or vector3(0, 0, 7)

-- Thresholds for distance classes (edit in config)
local CfgThresholdFar        = Config.Thresholds.far or 12.0
local CfgThresholdMedium     = Config.Thresholds.medium or 10.0
local CfgThresholdClose      = Config.Thresholds.close or 8.0
local CfgThresholdVeryClose  = Config.Thresholds.veryClose or 6.0

-- Beep sound settings (edit in config)
local CfgBeepSound           = Config.BeepSound or {Name = "Beep_Red", Ref = "DLC_HEIST_HACKING_SNAKE_SOUNDS"}
local CfgBeepIntervals       = Config.BeepInvervals or {far = 1200, medium = 700, close = 500, veryClose = 200}


-------------------- STATE VARIABLES --------------------
local lastBeepTime    = 0
local uiVisible       = false
local dist            = 9999
local doBeepSound     = false
local Cam360          = nil
local is360CamActive  = false
local lastLineClass   = 'hidden'
local lastDetected    = nil


---------------- Functions ----------------
-- Calculates beep pitch based on distance
local function gpfd(dist)
    if not CfgParkSensor then return end
    local maxDist = CfgThresholdFar
    local minDist = CfgThresholdVeryClose
    if dist > maxDist then
        return 0.5
    elseif dist < minDist then
        return 1.5
    else
        local ratio = (maxDist - dist) / (maxDist - minDist)
        return 0.5 + ratio
    end
end

-- Check if entity is behind and within right/left bounds
local function isBehindAndWithin(entityPos, backCenter, pos, forwardVector, rightVector, rightLimit, forwardLimit)
    local toEntity = entityPos - backCenter
    local rightDot = toEntity.x * rightVector.x + toEntity.y * rightVector.y + toEntity.z * rightVector.z
    local forwardDot = (entityPos - pos).x * forwardVector.x + (entityPos - pos).y * forwardVector.y + (entityPos - pos).z * forwardVector.z
    return math.abs(rightDot) < rightLimit and forwardDot < forwardLimit
end

-- Find closest entity from a list
local function findClosestEntityAll(pos, backCenter, forwardVector, rightVector, minDist, vehicle, occupants)
    local closestEntity, closestDist = nil, minDist

    -- Helper for checking entities
    local function checkEntities(entities, getEntity, getCoords, exclude, rightLimit)
        for i = 1, #entities do
            local data = entities[i]
            local entity = getEntity(data)
            if entity and DoesEntityExist(entity) and (not exclude or not exclude[entity]) then
                local entityPos = getCoords(data)
                local toEntity = entityPos - backCenter
                local rightDot = toEntity.x * rightVector.x + toEntity.y * rightVector.y + toEntity.z * rightVector.z
                local forwardDot = (entityPos - pos).x * forwardVector.x + (entityPos - pos).y * forwardVector.y + (entityPos - pos).z * forwardVector.z
                if math.abs(rightDot) < rightLimit and forwardDot < 0 then
                    local thisDist = #(pos - entityPos)
                    if thisDist < closestDist then
                        closestDist = thisDist
                        closestEntity = entity
                    end
                end
            end
        end
    end

    if CfgDetectPed then
        local peds = lib.getNearbyPeds(pos, CfgThresholdFar + 0.2)
        checkEntities(peds, function(d) return d.ped end, function(d) return d.coords end, occupants, 2.0)
    end
    if CfgDetectObj then
        local objects = lib.getNearbyObjects(pos, CfgThresholdFar + 0.2)
        checkEntities(objects, function(d) return d.object end, function(d) return d.coords end, nil, 2.0)
    end
    if CfgDetectVeh then
        local vehicles = lib.getNearbyVehicles(pos, CfgThresholdFar + 0.2, false)
        checkEntities(vehicles, function(d) return d.vehicle end, function(d) return d.coords end, {[vehicle]=true}, 1.5)
    end

    return closestEntity, closestDist
end

-- Activates the 360 camera view for the vehicle
local function c360(vehicle)
    if not CfgCam360 then return end
    if Cam360 then
        DestroyCam(Cam360, false)
        Cam360 = nil
    end
    DoScreenFadeOut(CfgCam360AnimDur)
    Wait(CfgCam360AnimDur)
    local offset = CfgCam360Offset
    Cam360 = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    SetCamFov(Cam360, CfgCam360FOV)
    SetCamActive(Cam360, true)
    RenderScriptCams(true, false, 0, true, true)
    is360CamActive = true
    AttachCamToEntity(Cam360, vehicle, offset.x, offset.y, offset.z, true)
    -- Keep camera attached and rotated with vehicle
    CreateThread(function()
        while is360CamActive do
            if not DoesEntityExist(vehicle) then
                is360CamActive = false
                break
            end
            local vehicleRot = GetEntityRotation(vehicle, 2)
            SetCamRot(Cam360, -90.0, 0.0, vehicleRot.z, 2)
            Wait(10)
        end
        if Cam360 then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(Cam360, false)
            Cam360 = nil
        end
    end)
    DoScreenFadeIn(CfgCam360AnimDur)
    Wait(CfgCam360AnimDur)
end

-- Deactivates the 360 camera view
local function d360()
    if Cam360 then
        DoScreenFadeOut(CfgCam360AnimDur)
        Wait(CfgCam360AnimDur)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(Cam360, false)
        Cam360 = nil
        is360CamActive = false
        DoScreenFadeIn(CfgCam360AnimDur)
        Wait(CfgCam360AnimDur)
    end
end


---------------- Threads ----------------
-- Main parking sensor logic thread
CreateThread(function()
    local waitActive = 750
    local waitInactive = 1000
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetVehicleClass(vehicle) ~= 13 and GetPedInVehicleSeat(vehicle, -1) == ped and CfgParkSensor then
            local gear = GetVehicleCurrentGear(vehicle)
            if gear == 0 then
                if not uiVisible then
                    SendNUIMessage({ action = 'show' })
                    uiVisible = true
                end
                local pos = GetEntityCoords(vehicle)
                local forwardVector = GetEntityForwardVector(vehicle)
                local rightVector = vector3(-forwardVector.y, forwardVector.x, 0.0)
                local backCenter = pos - forwardVector * 2.5
                local minDist = 9999
                local occupants = {}
                for seatIndex = -1, 6 do
                    local occupantPed = GetPedInVehicleSeat(vehicle, seatIndex)
                    if occupantPed and occupantPed ~= 0 then
                        occupants[occupantPed] = true
                    end
                end

                local detectedEntity, closestDist = findClosestEntityAll(
                    pos, backCenter, forwardVector, rightVector, minDist, vehicle, occupants
                )

                -- Only update UI and beep if entity or distance class changed
                if detectedEntity then
                    dist = closestDist
                    local lineClass
                    if dist > CfgThresholdFar then
                        lineClass = 'hidden'
                    elseif dist > CfgThresholdMedium then
                        lineClass = 'far'
                    elseif dist > CfgThresholdClose then
                        lineClass = 'medium'
                    elseif dist > CfgThresholdVeryClose then
                        lineClass = 'close'
                    else
                        lineClass = 'veryClose'
                    end
                    if lineClass ~= lastLineClass or detectedEntity ~= lastDetected then
                        SendNUIMessage({ action = 'update', line = lineClass })
                        lastLineClass = lineClass
                        lastDetected = detectedEntity
                    end
                    if CfgDebugDistance then print("Distance: " .. dist) end
                    doBeepSound = true
                else
                    if lastLineClass ~= 'hidden' then
                        SendNUIMessage({ action = 'update', line = 'hidden' })
                        lastLineClass = 'hidden'
                        lastDetected = nil
                    end
                    doBeepSound = false
                end
                Wait(waitActive)
            else
                if uiVisible then
                    SendNUIMessage({ action = 'hide' })
                    doBeepSound = false
                    uiVisible = false
                    lastLineClass = 'hidden'
                    lastDetected = nil
                end
                Wait(waitInactive)
            end
        else
            if uiVisible then
                SendNUIMessage({ action = 'hide' })
                doBeepSound = false
                uiVisible = false
                lastLineClass = 'hidden'
                lastDetected = nil
            end
            if isParkingCamActive then
                destroyParkingCamera()
            end
            Wait(waitInactive)
        end
    end
end)

-- Thread for handling the beep sound logic
CreateThread(function()
    while true do
        if CfgParkSensor and doBeepSound then
            local currentTime = GetGameTimer()
            local beepInterval
            if dist > CfgThresholdFar then
                beepInterval = nil
            elseif dist > CfgThresholdMedium then
                beepInterval = CfgBeepIntervals.far
            elseif dist > CfgThresholdClose then
                beepInterval = CfgBeepIntervals.medium
            elseif dist > CfgThresholdVeryClose then
                beepInterval = CfgBeepIntervals.close
            else
                beepInterval = CfgBeepIntervals.veryClose
            end

            if beepInterval and (currentTime - lastBeepTime) > beepInterval then
                local pitch = gpfd(dist)
                PlaySoundFrontend(-1, CfgBeepSound.Name, CfgBeepSound.Ref, pitch)
                lastBeepTime = currentTime
            end
            Wait(200)
        else
            Wait(750)
        end
    end
end)


---------------- Command ----------------
-- Command to toggle the 360 camera
RegisterCommand(CfgCam360CMD, function()
    if CfgCam360 then
        if is360CamActive then
            d360()
        else
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
            if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end
            c360(vehicle)
        end
    end
end)


---------------- KeyBinding ----------------
-- Register a key mapping for the 360 camera command
if CfgCam360 and CfgCam360Key ~= false then
    RegisterKeyMapping(CfgCam360CMD, 'Toggle vehicle 360 cam', 'keyboard', CfgCam360Key)
end