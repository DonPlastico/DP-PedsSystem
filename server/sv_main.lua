local QBCore = exports['qb-core']:GetCoreObject()

-- Tabla para almacenar TODAS las peds de los jugadores (global)
PlayerPeds = {}

-- Cargar TODAS las peds al iniciar el script
MySQL.query('SELECT * FROM player_peds', {}, function(result)
    if result then
        for _, row in ipairs(result) do
            PlayerPeds[row.citizenid] = json.decode(row.peds) or {}
        end
    end
end)

-- Función para cargar las peds al conectar (redundante pero segura)
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
    local citizenid = player.PlayerData.citizenid
    if not PlayerPeds[citizenid] then
        LoadPlayerPeds(citizenid)
    end
end)

-- Función para guardar las peds al desconectar
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(player)
    local citizenid = player.PlayerData.citizenid
    SavePlayerPeds(citizenid)
end)

-- Cargar peds del jugador (usando oxmysql)
function LoadPlayerPeds(citizenid)
    local result = MySQL.query.await('SELECT peds FROM player_peds WHERE citizenid = ?', {citizenid})

    if result and result[1] then
        PlayerPeds[citizenid] = json.decode(result[1].peds) or {}
    else
        PlayerPeds[citizenid] = {}
        MySQL.insert.await('INSERT INTO player_peds (citizenid, peds) VALUES (?, ?)', {citizenid, '[]'})
    end
end

-- Guardar peds del jugador (usando oxmysql)
function SavePlayerPeds(citizenid)
    if PlayerPeds[citizenid] then
        MySQL.update.await('UPDATE player_peds SET peds = ? WHERE citizenid = ?',
            {json.encode(PlayerPeds[citizenid]), citizenid})
    end
end

-- Verificar y crear tabla al iniciar
MySQL.ready(function()
    -- Crear tabla si no existe
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS player_peds (
            citizenid VARCHAR(255) NOT NULL,
            peds LONGTEXT,
            PRIMARY KEY (citizenid)
        )
    ]], {}, function()
        -- Cargar TODAS las peds después de asegurar que la tabla existe
        MySQL.query('SELECT * FROM player_peds', {}, function(result)
            if result then
                for _, row in ipairs(result) do
                    PlayerPeds[row.citizenid] = json.decode(row.peds) or {}
                end
            else
                print('[DP-PedSystem] Error al cargar peds desde la base de datos')
            end
        end)
    end)
end)

-- Obtener peds de un jugador
QBCore.Functions.CreateCallback('dp-pedsystem:server:GetPlayerPeds', function(source, cb, targetId)
    local target = QBCore.Functions.GetPlayer(targetId)
    if not target then
        cb(nil)
        return
    end

    local citizenid = target.PlayerData.citizenid
    cb(PlayerPeds[citizenid] or {})
end)

-- Evento para renombrar una ped
RegisterNetEvent('dp-pedsystem:server:RenamePed', function(pedModel, newName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    if PlayerPeds[citizenid] then
        for _, ped in ipairs(PlayerPeds[citizenid]) do
            if ped.model == pedModel then
                ped.name = newName
                break
            end
        end

        SavePlayerPeds(citizenid)
        TriggerClientEvent('QBCore:Notify', src, "Ped renombrada a: " .. newName, "success")
    end
end)

-- Evento para eliminar una ped
RegisterNetEvent('dp-pedsystem:server:DeletePed', function(pedModel, targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local target = nil
    local citizenid = nil

    if targetId then
        target = QBCore.Functions.GetPlayer(tonumber(targetId))
        if target then
            citizenid = target.PlayerData.citizenid
        end
    else
        citizenid = Player.PlayerData.citizenid
    end

    if not citizenid then
        return
    end

    -- Eliminar la ped
    if PlayerPeds[citizenid] then
        for i, ped in ipairs(PlayerPeds[citizenid]) do
            if ped.model == pedModel then
                table.remove(PlayerPeds[citizenid], i)
                break
            end
        end
        SavePlayerPeds(citizenid)
    end

    -- Refrescar menú correctamente
    if targetId then
        TriggerClientEvent('dp-pedsystem:client:OpenPedsMenu', src, PlayerPeds[citizenid], true, targetId)
    else
        TriggerClientEvent('dp-pedsystem:client:OpenPedsMenu', src, PlayerPeds[citizenid], false)
    end
end)

-- Backup automático cada 5 minutos
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutos
        print('[DP-PedSystem] Realizando backup automático de peds...')
        for citizenid, peds in pairs(PlayerPeds) do
            SavePlayerPeds(citizenid)
        end
    end
end)

-- Evento para que los admins vean peds de otros jugadores
RegisterNetEvent('dp-pedsystem:server:AdminViewPeds', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(targetId)

    -- Verificar permisos de admin
    if not IsPlayerAdmin(Player) then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications.noPermission, 'error')
        return
    end

    if not target then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications.playerNotFound, 'error')
        return
    end

    local citizenid = target.PlayerData.citizenid
    local targetPeds = PlayerPeds[citizenid] or {}

    TriggerClientEvent('dp-pedsystem:client:OpenPedsMenu', src, targetPeds, true)
end)

-- Evento para que los admins añadan peds a otros jugadores
RegisterNetEvent('dp-pedsystem:server:AdminAddPed', function(targetId, pedModel, pedName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    -- Verificar permisos de admin
    if not IsPlayerAdmin(Player) then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications.noPermission, 'error')
        return
    end

    local target = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not target then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications.playerNotFound, 'error')
        return
    end

    local citizenid = target.PlayerData.citizenid

    -- Añadir la ped
    if not PlayerPeds[citizenid] then
        PlayerPeds[citizenid] = {}
    end

    table.insert(PlayerPeds[citizenid], {
        name = pedName,
        model = pedModel
    })

    SavePlayerPeds(citizenid)
    TriggerClientEvent('QBCore:Notify', src, Config.Notifications.pedGiven, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'Se te ha asignado una nueva ped: ' .. pedName, 'success')
    -- Refrescar menú al admin
    TriggerClientEvent('dp-pedsystem:client:OpenPedsMenu', src, PlayerPeds[citizenid], true, targetId)
end)
