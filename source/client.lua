local ped
local veh
local activated = false
local purging = false
local screen = false
local purge = {}

local display = false
local noslvl, purgelvl = 0.0, 0.0
local player = PlayerId()
local isInVehicle = false
local isEnteringVehicle = false

DecorRegister("ND_NITRO_STATUS", 2)
DecorRegister("ND_NITRO_NOS", 1)
DecorRegister("ND_NITRO_PURGE", 1)

function hasNOS(veh)
    if not DecorExistOn(veh, "ND_NITRO_STATUS") then
        return false
    end
    return DecorGetBool(veh, "ND_NITRO_STATUS")
end

function setNOS(veh, status)
    DecorSetBool(veh, "ND_NITRO_STATUS", status)
end

function getValuesNOS(veh)
    return DecorGetFloat(veh, "ND_NITRO_NOS"), DecorGetFloat(veh, "ND_NITRO_PURGE")
end

exports("nos", function(data, slot)
    ped = PlayerPedId()
    veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    
    exports.ox_inventory:useItem(data)
    setNOS(veh, true)
    DecorSetFloat(veh, "ND_NITRO_NOS", 100.0)
    DecorSetFloat(veh, "ND_NITRO_PURGE", 0.0)

    SendNUIMessage({
        type = "nosLevel",
        nos = 100
    })
    SendNUIMessage({
        type = "purgeLevel",
        purge = 0
    })

    if not display then
        display = true
        SendNUIMessage({
            type = "status",
            display = display
        })
    end
end)

RegisterCommand("+purge", function()
    if activated then return end
    purging = true

    ped = PlayerPedId()
    veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local seatPed = GetPedInVehicleSeat(veh, -1)
    if seatPed ~= ped then return end
    if not hasNOS(veh) then return end

    if not display then
        display = true
        SendNUIMessage({
            type = "status",
            display = display
        })
    end

    TriggerServerEvent("ND_Nitro:purge", true)
end, false)

RegisterCommand("-purge", function()
    if activated then return end
    purging = false

    ped = PlayerPedId()
    veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local seatPed = GetPedInVehicleSeat(veh, -1)
    if seatPed ~= ped then return end
    if not hasNOS(veh) then return end

    TriggerServerEvent("ND_Nitro:purge", false)
end, false)

RegisterKeyMapping("+purge", "Nitro: purge", "keyboard", "LMENU")

RegisterCommand("+nitro", function()
    if not IsControlPressed(0, 71) then Wait(10) end
    if purging then return end

    ped = PlayerPedId()
    veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local seatPed = GetPedInVehicleSeat(veh, -1)
    if seatPed ~= ped then return end
    if not hasNOS(veh) then return end

    if not display then
        display = true
        SendNUIMessage({
            type = "status",
            display = display
        })
    end

    while not HasNamedPtfxAssetLoaded("veh_xs_vehicle_mods") do
        RequestNamedPtfxAsset("veh_xs_vehicle_mods")
        Wait(10)
    end

    activated = true
    EnableVehicleExhaustPops(veh, false)
    SetVehicleBoostActive(veh, activated)
    TriggerServerEvent("ND_Nitro:flames", true)
end, false)

RegisterCommand("-nitro", function()
    if purging then return end

    ped = PlayerPedId()
    veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local seatPed = GetPedInVehicleSeat(veh, -1)
    if seatPed ~= ped then return end
    if not hasNOS(veh) then return end

    activated = false
    TriggerServerEvent("ND_Nitro:flames", false)
    SetVehicleBoostActive(veh, activated)
    SetVehicleCheatPowerIncrease(veh, 1.0)

    screen = false
    StopGameplayCamShaking(true)
    SetTransitionTimecycleModifier("default", 0.35)
    Wait(1000)
    EnableVehicleExhaustPops(veh, true)
end, false)

RegisterKeyMapping("+nitro", "Nitro: boost", "keyboard", "LSHIFT")

CreateThread(function()
    local wait = 1500
    while true do
        Wait(wait)
        if veh ~= 0 and hasNOS(veh) then
            wait = 500

            noslvl, purgelvl = getValuesNOS(veh)

            if noslvl < 1 then
                setNOS(veh, false)
                display = false
                SendNUIMessage({
                    type = "status",
                    display = display
                })

                activated = false
                TriggerServerEvent("ND_Nitro:flames", false)
                SetVehicleBoostActive(veh, activated)
                SetVehicleCheatPowerIncrease(veh, 1.0)
                screen = false
                StopGameplayCamShaking(true)
                SetTransitionTimecycleModifier("default", 0.35)
                EnableVehicleExhaustPops(veh, true)
            end

            if activated and noslvl > 0 then
                local lvl = noslvl - 1.0
                DecorSetFloat(veh, "ND_NITRO_NOS", lvl)
                SendNUIMessage({
                    type = "nosLevel",
                    nos = lvl
                })

                if purgelvl < 100 then
                    local lvl = purgelvl + 4.0
                    DecorSetFloat(veh, "ND_NITRO_PURGE", lvl)
                    SendNUIMessage({
                        type = "purgeLevel",
                        purge = lvl
                    })
                end
            end

            if purging and purgelvl > 0 then
                local lvl = purgelvl - 15.0
                DecorSetFloat(veh, "ND_NITRO_PURGE", lvl)
                SendNUIMessage({
                    type = "purgeLevel",
                    purge = lvl
                })
            elseif purging and purgelvl < 0 then
                local lvl = noslvl - 5.0
                DecorSetFloat(veh, "ND_NITRO_NOS", lvl)
                SendNUIMessage({
                    type = "nosLevel",
                    nos = lvl
                })
            end
        else
            wait = 1500
        end
    end
end)

CreateThread(function()
    Wait(500)
    local model = GetEntityModel(veh)
    local maxSpeed = GetVehicleModelMaxSpeed(model)
    local wait = 500
    while true do
        Wait(wait)
        if noslvl > 0 and purgelvl < 100 then
            if activated then
                wait = 0

                local speed = GetEntitySpeed(veh)
                local mph = speed * 2.236936

                local thisModel = GetEntityModel(veh)
                if model ~= thisModel or maxSpeed == 0 then
                    model = thisModel
                    maxSpeed = GetVehicleModelMaxSpeed(model)
                end

                if mph < 5.0 then
                    SetControlNormal(0, 71, 0.5)
                else
                    local multiplier =  2.0 * maxSpeed / GetEntitySpeed(veh)
                    SetVehicleCheatPowerIncrease(veh, multiplier)
                end

                if screen and mph < 60.0 then
                    screen = false
                    StopGameplayCamShaking(true)
                    SetTransitionTimecycleModifier("default", 0.35)
                elseif not screen and mph > 60.0 then
                    screen = true
                    SetTimecycleModifier("rply_motionblur")
                    ShakeGameplayCam("SKY_DIVING_SHAKE", 0.25)
                end

                EnableVehicleExhaustPops(veh, false)
            else
                wait = 500
            end
        elseif activated then
            wait = 500
            activated = false
            TriggerServerEvent("ND_Nitro:flames", false)
            SetVehicleBoostActive(veh, activated)
            SetVehicleCheatPowerIncrease(veh, 1.0)
            screen = false
            StopGameplayCamShaking(true)
            SetTransitionTimecycleModifier("default", 0.35)
            EnableVehicleExhaustPops(veh, true)
        else
            wait = 500
        end
    end
end)

CreateThread(function()
    ped = PlayerPedId()
    veh = GetVehiclePedIsIn(ped)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        InVehicle = true
        if not display and hasNOS(veh) then
            Wait(1000)
            display = true
            local noslvl, purgelvl = getValuesNOS(veh)
            SendNUIMessage({
                type = "nosLevel",
                nos = noslvl
            })
            SendNUIMessage({
                type = "purgeLevel",
                purge = purgelvl
            })
            SendNUIMessage({
                type = "status",
                display = display
            })
        end
    end

	while true do
		Wait(500)
		if not isInVehicle and not IsPlayerDead(player) then
            local vehicle = GetVehiclePedIsTryingToEnter(ped)
			if vehicle ~= 0 and hasNOS(vehicle) and not isEnteringVehicle and GetPedInVehicleSeat(veh, -1) then
                -- trying to enter a vehicle!
				isEnteringVehicle = true
                veh = vehicle
			elseif vehicle == 0 and hasNOS(vehicle) and not IsPedInAnyVehicle(ped, true) and isEnteringVehicle then
				-- vehicle entering aborted
				isEnteringVehicle = false
			elseif IsPedInAnyVehicle(ped, false) then
				-- suddenly appeared in a vehicle, possible teleport
				isEnteringVehicle = false
				isInVehicle = true
				veh = GetVehiclePedIsUsing(ped)
                if GetPedInVehicleSeat(veh, -1) == ped and hasNOS(veh) and not display then
                    display = true
                    local noslvl, purgelvl = getValuesNOS(veh)
                    SendNUIMessage({
                        type = "nosLevel",
                        nos = noslvl
                    })
                    SendNUIMessage({
                        type = "purgeLevel",
                        purge = purgelvl
                    })
                    SendNUIMessage({
                        type = "status",
                        display = display
                    })
                end
			end
		elseif isInVehicle then
			if not IsPedInAnyVehicle(ped, false) or IsPlayerDead(player) then
				-- left vehicle
				isInVehicle = false

                if activated then
                    activated = false
                    TriggerServerEvent("ND_Nitro:flames", false, VehToNet(veh))
                    SetVehicleBoostActive(veh, activated)
                    SetVehicleCheatPowerIncrease(veh, 1.0)
                end
                if screen then
                    screen = false
                    StopGameplayCamShaking(true)
                    SetTransitionTimecycleModifier("default", 0.35)
                    Wait(1000)
                    EnableVehicleExhaustPops(veh, true)
                end
                if purging then
                    purging = false
                    TriggerServerEvent("ND_Nitro:purge", false, VehToNet(veh))
                end
                if display then
                    display = false
                    SendNUIMessage({
                        type = "status",
                        display = display
                    })
                end
			end
		end
		Wait(50)
	end
end)

AddStateBagChangeHandler("flames", nil, function(bagName, key, value, reserved, replicated)
    if value == nil then return end
    Wait(50)

    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId)
    if not entity then return end

    while not HasNamedPtfxAssetLoaded("veh_xs_vehicle_mods") do
        RequestNamedPtfxAsset("veh_xs_vehicle_mods")
        Wait(10)
    end

    SetVehicleNitroEnabled(entity, value)
end)

AddStateBagChangeHandler("purge", nil, function(bagName, key, value, reserved, replicated)
    if value == nil then return end
    Wait(50)

    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId)
    if not entity then return end

    if value then
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
    else
        StopParticleFxLooped(purge[entity].left)
        StopParticleFxLooped(purge[entity].right)
        purge[entity] = nil
    end
end)
