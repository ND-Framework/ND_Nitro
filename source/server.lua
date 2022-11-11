RegisterNetEvent("ND_Nitro:purge", function(status, vehid)
    local src = source
    if vehid then
        local veh = NetworkGetEntityFromNetworkId(vehid)
        local state = Entity(veh).state
        state.purge = status
        return
    end
    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local state = Entity(veh).state
    state.purge = status
end)

RegisterNetEvent("ND_Nitro:flames", function(status, vehid)
    local src = source
    if vehid then
        local veh = NetworkGetEntityFromNetworkId(vehid)
        local state = Entity(veh).state
        state.flames = status
        return
    end
    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local state = Entity(veh).state
    state.flames = status
end)