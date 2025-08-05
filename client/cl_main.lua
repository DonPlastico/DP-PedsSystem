local QBCore = nil
local lastViewedPlayerId = nil
local adminPedName = ""
local adminPedModel = ""

CreateThread(function()
    while not QBCore do
        QBCore = exports['qb-core']:GetCoreObject()
        Wait(100)
    end

    -- Evento para abrir el menú de peds (modificado)
    RegisterNetEvent('dp-pedsystem:client:OpenPedsMenu', function(peds, isAdminView, targetId)
        local PlayerData = QBCore.Functions.GetPlayerData()
        if not PlayerData or not PlayerData.charinfo then
            QBCore.Functions.Notify("Error al cargar datos del jugador", "error")
            return
        end

        if isAdminView then
            lastViewedPlayerId = targetId
        else
            lastViewedPlayerId = nil
        end

        adminPedName = ""
        adminPedModel = ""

        local menu = {{
            header = "MENÚ PEDS",
            isMenuHeader = true
        }}

        if isAdminView then
            table.insert(menu, {
                header = "Dar ped",
                icon = "fa-solid fa-plus",
                params = {
                    event = "dp-pedsystem:client:AdminGivePed"
                }
            })
        else
            table.insert(menu, {
                header = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname,
                txt = "Volver a mi skin original",
                icon = "fa-solid fa-user",
                params = {
                    event = "dp-pedsystem:client:RevertToOriginalSkin"
                }
            })
        end

        if not peds or #peds == 0 then
            table.insert(menu, {
                header = isAdminView and "No tiene peds asignadas" or "No tienes peds asignadas",
                txt = isAdminView and "Este jugador no tiene peds" or "Contacta con un administrador",
                icon = "fa-solid fa-exclamation",
                disabled = true
            })
        else
            for _, ped in ipairs(peds) do
                table.insert(menu, {
                    header = ped.name,
                    txt = ped.model,
                    icon = "fa-solid fa-person",
                    params = {
                        event = "dp-pedsystem:client:OpenPedOptions",
                        args = {
                            pedName = ped.name,
                            pedModel = ped.model,
                            isAdminView = isAdminView
                        }
                    }
                })
            end
        end

        table.insert(menu, {
            header = "Cerrar",
            icon = "fa-solid fa-xmark",
            params = {
                event = "qb-menu:closeMenu"
            }
        })

        exports['qb-menu']:openMenu(menu)
    end)

    -- Menú para dar ped con edición de campos
    RegisterNetEvent('dp-pedsystem:client:AdminGivePed', function()
        local menu = {{
            header = "Asignar nueva Ped",
            isMenuHeader = true
        }, {
            header = "Nombre de la ped",
            txt = adminPedName ~= "" and adminPedName or "Pulsa para escribir",
            icon = "fa-solid fa-pen",
            params = {
                event = "dp-pedsystem:client:EditPedName"
            }
        }, {
            header = "Modelo de la ped",
            txt = adminPedModel ~= "" and adminPedModel or "Pulsa para escribir",
            icon = "fa-solid fa-pen",
            params = {
                event = "dp-pedsystem:client:EditPedModel"
            }
        }}
        if adminPedName ~= "" and adminPedModel ~= "" then
            table.insert(menu, {
                header = "Confirmar",
                icon = "fa-solid fa-check",
                params = {
                    event = "dp-pedsystem:client:ConfirmGivePed"
                }
            })
        end
        table.insert(menu, {
            header = "Cancelar",
            icon = "fa-solid fa-xmark",
            params = {
                event = "qb-menu:closeMenu"
            }
        })
        exports['qb-menu']:openMenu(menu)
    end)

    RegisterNetEvent('dp-pedsystem:client:EditPedName', function()
        local input = exports['qb-input']:ShowInput({
            header = "Nombre de la ped",
            submitText = "Guardar",
            inputs = {{
                text = "Nombre",
                name = "pedName",
                type = "text",
                isRequired = true,
                default = adminPedName
            }}
        })
        if input and input.pedName then
            adminPedName = input.pedName
        end
        TriggerEvent('dp-pedsystem:client:AdminGivePed')
    end)

    RegisterNetEvent('dp-pedsystem:client:EditPedModel', function()
        local input = exports['qb-input']:ShowInput({
            header = "Modelo de la ped",
            submitText = "Guardar",
            inputs = {{
                text = "Modelo",
                name = "pedModel",
                type = "text",
                isRequired = true,
                default = adminPedModel
            }}
        })
        if input and input.pedModel then
            adminPedModel = input.pedModel
        end
        TriggerEvent('dp-pedsystem:client:AdminGivePed')
    end)

    RegisterNetEvent('dp-pedsystem:client:ConfirmGivePed', function()
        TriggerServerEvent('dp-pedsystem:server:AdminAddPed', lastViewedPlayerId, adminPedModel, adminPedName)
    end)

    -- Evento para el submenú de opciones de ped
    RegisterNetEvent('dp-pedsystem:client:OpenPedOptions', function(data)
        local menu = {{
            header = data.pedName,
            txt = data.pedModel,
            isMenuHeader = true
        }}

        if data.isAdminView then
            -- Solo opción de eliminar para admins
            table.insert(menu, {
                header = "Eliminar",
                icon = "fa-solid fa-trash",
                params = {
                    event = "dp-pedsystem:client:DeletePed",
                    args = {
                        pedName = data.pedName,
                        pedModel = data.pedModel
                    }
                }
            })
        else
            -- Opciones completas para el jugador
            table.insert(menu, {
                header = "Seleccionar",
                icon = "fa-solid fa-check",
                params = {
                    event = "dp-pedsystem:client:SelectPed",
                    args = {
                        pedModel = data.pedModel
                    }
                }
            })
            table.insert(menu, {
                header = "Renombrar",
                icon = "fa-solid fa-signature",
                params = {
                    event = "dp-pedsystem:client:RenamePed",
                    args = {
                        currentName = data.pedName,
                        pedModel = data.pedModel
                    }
                }
            })
            table.insert(menu, {
                header = "Eliminar",
                icon = "fa-solid fa-trash",
                params = {
                    event = "dp-pedsystem:client:DeletePed",
                    args = {
                        pedName = data.pedName,
                        pedModel = data.pedModel
                    }
                }
            })
        end

        table.insert(menu, {
            header = "Cerrar",
            icon = "fa-solid fa-xmark",
            params = {
                event = "qb-menu:closeMenu"
            }
        })

        exports['qb-menu']:openMenu(menu)
    end)

    -- Evento para seleccionar la ped
    RegisterNetEvent('dp-pedsystem:client:SelectPed', function(data)
        local playerPed = PlayerPedId()
        local model = data.pedModel

        -- Cargar el modelo
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(500)
        end

        -- Cambiar la ped del jugador
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)

        QBCore.Functions.Notify("Has seleccionado la ped: " .. model, "success")
    end)

    -- Evento para renombrar la ped
    RegisterNetEvent('dp-pedsystem:client:RenamePed', function(data)
        local input = exports['qb-input']:ShowInput({
            header = "Renombrar Ped",
            submitText = "Confirmar",
            inputs = {{
                text = "Nuevo nombre",
                name = "newName",
                type = "text",
                isRequired = true,
                default = data.currentName,
                min = 3,
                max = 50
            }}
        })

        if input then
            TriggerServerEvent('dp-pedsystem:server:RenamePed', data.pedModel, input.newName)
        end
    end)

    -- Evento para eliminar la ped
    RegisterNetEvent('dp-pedsystem:client:DeletePed', function(data)
        local menu = {{
            header = "¿Eliminar " .. data.pedName .. "?",
            isMenuHeader = true
        }, {
            header = "CONFIRMAR ELIMINACIÓN",
            icon = "fa-solid fa-check",
            txt = "Esta acción no se puede deshacer",
            params = {
                event = "dp-pedsystem:client:ConfirmDelete",
                args = {
                    pedModel = data.pedModel
                }
            }
        }, {
            header = "Cancelar",
            icon = "fa-solid fa-xmark",
            params = {
                event = "qb-menu:closeMenu"
            }
        }}

        exports['qb-menu']:openMenu(menu)
    end)

    RegisterNetEvent('dp-pedsystem:client:ConfirmDelete', function(data)
        TriggerServerEvent('dp-pedsystem:server:DeletePed', data.pedModel, lastViewedPlayerId)
    end)

    -- Nuevo evento para volver a la skin original
    RegisterNetEvent('dp-pedsystem:client:RevertToOriginalSkin', function()
        QBCore.Functions.Progressbar("revert_skin", "Volviendo a tu apariencia original...", 2500, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
        }, {
            animDict = "clothingshirt",
            anim = "try_shirt_positive_d",
            flags = 49
        }, {}, {}, function() -- Done
            ExecuteCommand("refreshskin")
            QBCore.Functions.Notify("Has vuelto a tu apariencia original", "success")
        end, function() -- Cancel
            QBCore.Functions.Notify("Acción cancelada", "error")
        end)
    end)
end)
