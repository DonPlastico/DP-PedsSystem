local QBCore = exports['qb-core']:GetCoreObject()

-- SOLO DEJA EL COMANDO /peds PARA JUGADORES
CreateThread(function()
    while not QBCore do
        Wait(100)
    end

    RegisterCommand(Config.Commands.playerPeds, function()
        local Player = QBCore.Functions.GetPlayerData()
        local citizenid = Player.citizenid

        QBCore.Functions.TriggerCallback('dp-pedsystem:server:GetPlayerPeds', function(peds)
            if not peds or #peds == 0 then
                QBCore.Functions.Notify(Config.Notifications.noPeds, 'error')
                return
            end

            TriggerEvent('dp-pedsystem:client:OpenPedsMenu', peds)
        end, GetPlayerServerId(PlayerId()))
    end, false)
end)
