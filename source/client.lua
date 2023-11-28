local display = false
local preventNitro = false
local purge = {}
local nosActivated, purgeActivated = false, false
local keybindNos, keybindPurge
local vehicleModel, vehicleMaxSpeed
local screenEffect = false

---@param status boolean
local function setHUD(status)
    display = status
    SendNUIMessage({
        type = "status",
        display = display
    })
end

---@param checkDriver boolean
---@return boolean
local function isInVehicle(checkDriver)
    return checkDriver and cache.seat == -1 and cache.vehicle or cache.vehicle
end

---@param veh entity
---@return boolean
local function vehicleHasNitro(veh)
    if not veh or not DoesEntityExist(veh) then return end
    local state = Entity(veh).state
    local value = state.nd_nitro_nos
    return value and value > 0
end

---@param setType string
---@param value number
local function vehicleSetValue(setType, value)
    local veh = isInVehicle(true)
    if not veh or not DoesEntityExist(veh) then return end
    local state = Entity(veh).state
    state:set(("nd_nitro_%s"):format(setType), value, true)
    if setType == "nos" then
        SendNUIMessage({
            type = "nosLevel",
            nos = value
        })
    else
        SendNUIMessage({
            type = "purgeLevel",
            purge = value
        })
    end
end

---@param veh entity
---@param setType string
---@param value boolean
local function vehicleActivate(veh, setType, value)
    if not veh or not DoesEntityExist(veh) then return end
    local state = Entity(veh).state
    state:set(("nd_nitro_activated_%s"):format(setType), value, true)
end

---@param veh number
---@return number
---@return number
local function vehicleGetValues(veh)
    if not veh or not DoesEntityExist(veh) then return end
    local state = Entity(veh).state
    return state.nd_nitro_nos, state.nd_nitro_purge
end

local function vehicleAddNitro()
    vehicleSetValue("nos", 100.0)
    vehicleSetValue("purge", 0.0)
    setHUD(true)
end

---@param veh entity
local function startedNos(veh)
    local noslvl, purgelvl = vehicleGetValues(veh)

    if purgelvl < 100 then
        local lvl = purgelvl+4.0
        vehicleSetValue("purge", lvl)
        if preventNitro then
            preventNitro = false
        end
    else
        preventNitro = true
        return vehicleActivate(veh, "flames", false)
    end

    local lvl = noslvl-1.0
    vehicleSetValue("nos", lvl)

    if noslvl < 1 then
        vehicleActivate(veh, "flames", false)
        vehicleActivate(veh, "purge", false)
        setHUD(false)
    end
end

---@param veh entity
local function startedPurge(veh)
    local noslvl, purgelvl = vehicleGetValues(veh)
    if purgelvl < 100 then
        preventNitro = false
    end
    if purgelvl > 0 then
        local lvl = purgelvl-15.0
        vehicleSetValue("purge", lvl)
    elseif purgelvl < 0 then
        local lvl = noslvl-5.0
        vehicleSetValue("nos", lvl)
    end
end

---@param veh entity
---@return boolean
local function nitroCheck(veh)
    if not DoesEntityExist(veh) then return end
    
    local noslvl, purgelvl = vehicleGetValues(veh)
    if noslvl <= 0 or purgelvl >= 100 then return end

    local speed = GetEntitySpeed(veh)
    local mph = speed*2.236936

    local model = GetEntityModel(veh)
    if model ~= vehicleModel or maxSpeed == 0 then
        vehicleModel = model
        vehicleMaxSpeed = GetVehicleModelMaxSpeed(model)
    end

    if mph < 5.0 then
        SetControlNormal(0, 71, 0.5)
    else
        local multiplier =  2.0*vehicleMaxSpeed/GetEntitySpeed(veh)
        SetVehicleCheatPowerIncrease(veh, multiplier)
    end

    if screenEffect and mph < 60.0 then
        screenEffect = false
        StopGameplayCamShaking(true)
        SetTransitionTimecycleModifier("default", 0.35)
    elseif not screenEffect and mph > 60.0 then
        screenEffect = true
        SetTimecycleModifier("rply_motionblur")
        ShakeGameplayCam("SKY_DIVING_SHAKE", 0.25)
    end
    
    return true
end

---@param veh entity
local function displayNitro(veh)
    local noslvl, purgelvl = vehicleGetValues(veh)
    if not noslvl or noslvl <= 0 then return end
    SendNUIMessage({
        type = "nosLevel",
        nos = noslvl
    })
    SendNUIMessage({
        type = "purgeLevel",
        purge = purgelvl
    })
    setHUD(true)
end

-- this is used with inventory to add nitro bottle to vehicle.
exports("nos", function(data, slot)
    local veh = isInVehicle(checkDriver)
    if not veh or not DoesEntityExist(veh) then return end
    if data then exports.ox_inventory:useItem(data) end
    vehicleAddNitro()
end)

keybindNos = lib.addKeybind({
    name = "nd_nitro_boost",
    description = "Nitro: boost",
    defaultKey = "LSHIFT",
    onPressed = function(self)
        if not IsControlPressed(0, 71) then Wait(10) end
        
        local veh = isInVehicle(true)
        if preventNitro or not veh or not DoesEntityExist(veh) or not vehicleHasNitro(veh) or keybindNos.disabled then return end
        if not display then setHUD(true) end
    
        self.isPressed = true
        keybindPurge:disable(true)
        lib.requestNamedPtfxAsset("veh_xs_vehicle_mods")
        vehicleActivate(veh, "flames", true)
        
        CreateThread(function()
            while self.isPressed and isInVehicle(true) == veh and DoesEntityExist(veh) do
                Wait(1000)
                startedNos(veh)
            end
        end)
    end,
    onReleased = function(self)
        self.isPressed = false
        local veh = isInVehicle(true)
        if not veh or not DoesEntityExist(veh) or not vehicleHasNitro(veh) then return end

        keybindPurge:disable(false)
        vehicleActivate(veh, "flames", false)
    end
})

keybindPurge = lib.addKeybind({
    name = "nd_nitro_purge",
    description = "Nitro: purge",
    defaultKey = "LMENU",
    onPressed = function(self)
        local veh = isInVehicle(true)
        if not veh or not DoesEntityExist(veh) or not vehicleHasNitro(veh) or keybindPurge.disabled then return end
        if not display then setHUD(true) end

        self.isPressed = true
        keybindNos:disable(true)
        vehicleActivate(veh, "purge", true)

        CreateThread(function()
            while self.isPressed and isInVehicle(true) == veh and DoesEntityExist(veh) do
                Wait(1000)
                startedPurge(veh)
            end
        end)
    end,
    onReleased = function(self)
        self.isPressed = false
        local veh = isInVehicle(true)
        if not veh or not DoesEntityExist(veh) or not vehicleHasNitro(veh) then return end

        keybindNos:disable(false)
        vehicleActivate(veh, "purge", false)
    end
})

AddEventHandler("onResourceStart", function(resourceName)
    if cache.resource ~= resourceName then return end
    Wait(500)
    displayNitro(cache.vehicle)
end)

lib.onCache("vehicle", function(value)
    local isDriver = GetPedInVehicleSeat(value, -1) == cache.ped
    if not isDriver or not value then
        return setHUD(false)
    end
    displayNitro(value)
end)

lib.onCache("seat", function(seat)
    if seat ~= -1 then
        return setHUD(false)
    end
    displayNitro(cache.vehicle)
end)

AddStateBagChangeHandler("nd_nitro_activated_flames", nil, function(bagName, key, value, reserved, replicated)
    if replicated or value == nil then return end
    
    local entity = GetEntityFromStateBagName(bagName)
    if not entity or not DoesEntityExist(entity) then return end
    
    lib.requestNamedPtfxAsset("veh_xs_vehicle_mods")
    SetVehicleNitroEnabled(entity, value)
    EnableVehicleExhaustPops(entity, not value)
    SetVehicleBoostActive(entity, value)
    
    local driver, passenger = isInVehicle(true) == entity, isInVehicle() == entity
    if not value then
        if driver then
            SetVehicleCheatPowerIncrease(entity, 1.0)
        end
        if driver or passenger then            
            StopGameplayCamShaking(true)
            SetTransitionTimecycleModifier("default", 0.35)
        end
        return
    end

    if not driver and not passenger then return end
    CreateThread(function()
        local state = Entity(entity).state
        while state.nd_nitro_activated_flames and nitroCheck(entity) do
            Wait(0)
        end
    end)
end)

AddStateBagChangeHandler("nd_nitro_activated_purge", nil, function(bagName, key, value, reserved, replicated)
    if replicated or value == nil then return end

    local entity = GetEntityFromStateBagName(bagName)
    if not entity or not DoesEntityExist(entity) then return end

    if not value then
        local currentPurge = purge[entity]
        if currentPurge?.left then
            StopParticleFxLooped(currentPurge.left)
        end
        if currentPurge?.right then
            StopParticleFxLooped(currentPurge.right)
        end
        purge[entity] = nil
        return
    end

    local bone = GetEntityBoneIndexByName(entity, "bonnet")
    local pos = GetWorldPositionOfEntityBone(entity, bone)
    local off = GetOffsetFromEntityGivenWorldCoords(entity, pos.x, pos.y, pos.z)
    if bone ~= -1 then
        UseParticleFxAssetNextCall("core")
        local leftPurge = StartParticleFxLoopedOnEntity("ent_sht_steam", entity, off.x - 0.5, off.y + 0.05, off.z, 40.0, -20.0, 0.0, 0.3, false, false, false)
        UseParticleFxAssetNextCall("core")
        local rightPurge = StartParticleFxLoopedOnEntity("ent_sht_steam", entity, off.x + 0.5, off.y + 0.05, off.z, 40.0, 20.0, 0.0, 0.3, false, false, false)
        purge[entity] = {left = leftPurge, right = rightPurge}
        return
    end

    local bone = GetEntityBoneIndexByName(entity, "engine")
    local pos = GetWorldPositionOfEntityBone(entity, bone)
    local off = GetOffsetFromEntityGivenWorldCoords(entity, pos.x, pos.y, pos.z)
    UseParticleFxAssetNextCall("core")
    local leftPurge = StartParticleFxLoopedOnEntity("ent_sht_steam", entity, off.x - 0.5, off.y - 0.2, off.z + 0.2, 40.0, -20.0, 0.0, 0.3, false, false, false)
    UseParticleFxAssetNextCall("core")
    local rightPurge = StartParticleFxLoopedOnEntity("ent_sht_steam", entity, off.x + 0.5, off.y - 0.2, off.z + 0.2, 40.0, 20.0, 0.0, 0.3, false, false, false)
    purge[entity] = {left = leftPurge, right = rightPurge}
end)
