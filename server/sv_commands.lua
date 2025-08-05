local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand(Config.Commands.viewPeds, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not IsPlayerAdmin(Player) then
        return
    end

    if #args < 1 then
        return
    end

    local targetId = tonumber(args[1])
    local target = QBCore.Functions.GetPlayer(targetId)
    if not target then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications.playerNotFound, 'error')
        return
    end

    local citizenid = target.PlayerData.citizenid
    local peds = PlayerPeds[citizenid] or {}

    TriggerClientEvent('dp-pedsystem:client:OpenPedsMenu', src, peds, true, targetId)
end, false)

-- Función para verificar si un jugador es admin
function IsPlayerAdmin(Player)
    for _, group in ipairs(Config.AdminGroups) do
        if QBCore.Functions.HasPermission(Player.PlayerData.source, group) then
            return true
        end
    end
    return false
end
