---------------- Main data ----------------
local thresholdFar = Config.Thresholds.far
local thresholdMedium = Config.Thresholds.medium
local thresholdClose = Config.Thresholds.close
local thresholdVeryClose = Config.Thresholds.veryClose
local beepIntervals = Config.BeepInvervals
local lastBeepTime = 0
local uiVisible = false
local dist = 9999
local doBeepSound = false
local occupants = {}
local Cam360 = nil
local is360CamActive = false


---------------- Functions ----------------
    -- Get pitch from distance function
local function gpfd(dist)
    if not Config.ParkSensor then return end
    local maxDist = Config.Thresholds.far
    local minDist = Config.Thresholds.veryClose
    if dist > maxDist then
        return 0.5
    elseif dist < minDist then
        return 1.5
    else
        local ratio = (maxDist - dist) / (maxDist - minDist)
        return 0.5 + ratio
    end
end

    -- 360 camera functions
local function c360(vehicle)
    if not Config.Cam360 then return end
    if Cam360 then
        DestroyCam(Cam360, false)
        Cam360 = nil
    end
    DoScreenFadeOut(Config.Cam360AnimDur)
    Wait(Config.Cam360AnimDur)
    local offset = Config.Cam360Offset
    Cam360 = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    SetCamFov(Cam360, Config.Cam360FOV)
    SetCamActive(Cam360, true)
    RenderScriptCams(true, false, 0, true, true)
    is360CamActive = true
    AttachCamToEntity(Cam360, vehicle, offset.x, offset.y, offset.z, true)
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
    DoScreenFadeIn(Config.Cam360AnimDur)
    Wait(Config.Cam360AnimDur)
end
local function d360()
    if Cam360 then
        DoScreenFadeOut(Config.Cam360AnimDur)
        Wait(Config.Cam360AnimDur)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(Cam360, false)
        Cam360 = nil
        is360CamActive = false
        DoScreenFadeIn(Config.Cam360AnimDur)
        Wait(Config.Cam360AnimDur)
    end
end


---------------- Threads ----------------
    -- Main thread
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetVehicleClass(vehicle) ~= 13 and GetPedInVehicleSeat(vehicle, -1) == ped and Config.ParkSensor then
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
                local detectedEntity = nil
                local minDist = 9999
                local occupants = {}
                for seatIndex = -1, 6 do
                    local occupantPed = GetPedInVehicleSeat(vehicle, seatIndex)
                    if occupantPed and occupantPed ~= 0 then
                        occupants[occupantPed] = true
                    end
                end
                local entityPositions = {}
                if Config.DetectPed then
                    local peds = GetGamePool('CPed')
                    for _, pedEntity in ipairs(peds) do
                        if pedEntity ~= ped and not occupants[pedEntity] and DoesEntityExist(pedEntity) then
                            local pedPos = entityPositions[pedEntity] or GetEntityCoords(pedEntity)
                            entityPositions[pedEntity] = pedPos
                            local toPed = pedPos - backCenter
                            local rightDot = toPed.x * rightVector.x + toPed.y * rightVector.y + toPed.z * rightVector.z
                            local forwardDot = (pedPos - pos).x * forwardVector.x + (pedPos - pos).y * forwardVector.y + (pedPos - pos).z * forwardVector.z
                            if math.abs(rightDot) < 2.0 and forwardDot < 0 then
                                dist = #(pos - pedPos)
                                if dist < minDist then
                                    minDist = dist
                                    detectedEntity = pedEntity
                                end
                            end
                        end
                    end
                end
                if Config.DetectObj then
                    local objects = GetGamePool('CObject')
                    for _, obj in ipairs(objects) do
                        if DoesEntityExist(obj) then
                            local objPos = entityPositions[obj] or GetEntityCoords(obj)
                            entityPositions[obj] = objPos
                            local toObj = objPos - backCenter
                            local rightDot = toObj.x * rightVector.x + toObj.y * rightVector.y + toObj.z * rightVector.z
                            local forwardDot = (objPos - pos).x * forwardVector.x + (objPos - pos).y * forwardVector.y + (objPos - pos).z * forwardVector.z
                            if math.abs(rightDot) < 2.0 and forwardDot < 0 then
                                dist = #(pos - objPos)
                                if dist < minDist then
                                    minDist = dist
                                    detectedEntity = obj
                                end
                            end
                        end
                    end
                end
                if Config.DetectVeh then
                    local vehicles = GetGamePool('CVehicle')
                    for _, veh in ipairs(vehicles) do
                        if veh ~= vehicle and DoesEntityExist(veh) then
                            local vehPos = entityPositions[veh] or GetEntityCoords(veh)
                            entityPositions[veh] = vehPos
                            local toVeh = vehPos - backCenter
                            local rightDot = toVeh.x * rightVector.x + toVeh.y * rightVector.y + toVeh.z * rightVector.z
                            local forwardDot = (vehPos - pos).x * forwardVector.x + (vehPos - pos).y * forwardVector.y + (vehPos - pos).z * forwardVector.z
                            if math.abs(rightDot) < 1.5 and forwardDot < 0 then
                                dist = #(pos - vehPos)
                                if dist < minDist then
                                    minDist = dist
                                    detectedEntity = veh
                                end
                            end
                        end
                    end
                end
                if detectedEntity then
                    dist = minDist
                    local lineClass = nil
                    if dist > Config.Thresholds.far then
                        lineClass = 'hidden'
                    elseif dist > Config.Thresholds.medium then
                        lineClass = 'far'
                    elseif dist > Config.Thresholds.close then
                        lineClass = 'medium'
                    elseif dist > Config.Thresholds.veryClose then
                        lineClass = 'close'
                    else
                        lineClass = 'veryClose'
                    end
                    SendNUIMessage({ action = 'update', line = lineClass })
                    if Config.DebugDistance then print("Distance: " .. dist) end
                    doBeepSound = true
                else
                    SendNUIMessage({ action = 'update', line = 'hidden' })
                    doBeepSound = false
                end
            else
                if uiVisible then
                    SendNUIMessage({ action = 'hide' })
                    doBeepSound = false
                    uiVisible = false
                end
                Wait(250)
            end
        else
            if uiVisible then
                SendNUIMessage({ action = 'hide' })
                doBeepSound = false
                uiVisible = false
            end
            if isParkingCamActive then
                destroyParkingCamera()
            end
            Wait(500)
        end
    end
end)
    -- Beep sound thread
CreateThread(function()
    while Config.ParkSensor do
        if doBeepSound then
            local currentTime = GetGameTimer()
            local beepInterval
            if dist > Config.Thresholds.far then
                beepInterval = nil
            elseif dist > Config.Thresholds.medium then
                beepInterval = Config.BeepInvervals.far
            elseif dist > Config.Thresholds.close then
                beepInterval = Config.BeepInvervals.medium
            elseif dist > Config.Thresholds.veryClose then
                beepInterval = Config.BeepInvervals.close
            else
                beepInterval = Config.BeepInvervals.veryClose
            end
            
            if beepInterval and (currentTime - lastBeepTime) > beepInterval then
                local pitch = gpfd(dist)
                PlaySoundFrontend(-1, Config.BeepSound.Name, Config.BeepSound.Ref, pitch)
                lastBeepTime = currentTime
            end
        end
        Wait(doBeepSound and 200 or 750) 
    end
end)
    -- 360 camera thread
CreateThread(function()
    while Config.HybridVehicle do
        Wait(400)
        local model = GetEntityModel(vehicle)
        if Config.HybridList[model] then
            local currSpeed = GetEntitySpeed(vehicle) * 3.6
            local hybridData = Config.HybridList[model]
            local vehSoundNew = currSpeed > Config.MaxElectricSpeed and hybridData.engine2 or hybridData.engine1
            
            if vehSound ~= vehSoundNew then
                local radioSt = GetPlayerRadioStationName() or "OFF"
                print(radioSt)
                ForceUseAudioGameObject(vehicle, vehSoundNew)
                Wait(100)
                SetRadioToStationName(radioSt)
                vehSound = vehSoundNew
            end
        end
    end
end)


---------------- Command ----------------
RegisterCommand(Config.Cam360CMD, function()
    if Config.Cam360 then
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
if Config.Cam360 and Config.Cam360Key ~= false then
    RegisterKeyMapping(Config.Cam360CMD, 'Toggle vehicle 360 cam', 'keyboard', Config.Cam360Key)
end