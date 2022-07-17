local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    RequestModel(Config.Locations['Ped'].pedModel)
    while not HasModelLoaded(Config.Locations['Ped'].pedModel) do
    Wait(1)
  end
    PilotPlanesPed = CreatePed(2, Config.Locations['Ped'].pedModel, Config.Locations['Ped'].pedLoc, false, false)
    SetPedFleeAttributes(PilotPlanesPed, 0, 0)
    SetPedDiesWhenInjured(PilotPlanesPed, false)
    TaskStartScenarioInPlace(PilotPlanesPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
    SetPedKeepTask(PilotPlanesPed, true)
    SetBlockingOfNonTemporaryEvents(PilotPlanesPed, true)
    SetEntityInvincible(PilotPlanesPed, true)
    FreezeEntityPosition(PilotPlanesPed, true)

    exports['qb-target']:AddBoxZone("PilotPlanesPed", Config.Locations['Ped'].targetLoc, 1, 1, {
        name="PilotPlanesPed",
        heading=0,
        debugpoly = false,
    }, {
        options = {
            {
                event = "mt-pilotjob:client:MenuVeiculos",
                icon = "fas fa-plane",
                label = Lang.PlanesShopLabel,
                job = Config.Job,
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("pilot-armario", Config.Locations['Cabinet'].loc, Config.Locations['Cabinet'].lenght, Config.Locations['Cabinet'].width, {
        name = "pilot-armario",
        heading = Config.Locations['Cabinet'].heading,
        debugpoly = false,
    }, {
        options = {
            {  
                event = "mt-pilotjob:client:AbrirArmario",
                icon = Config.Locations['Cabinet'].icon,
                label = Lang.CabinetLabel,
                job = Config.Job,
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("pilot-loja", Config.Locations['Shop'].loc, Config.Locations['Shop'].lenght, Config.Locations['Shop'].width, {
        name = "pilot-loja",
        heading = Config.Locations['Shop'].heading,
        debugpoly = false,
    }, {
        options = {
            {  
                event = "mt-pilotjob:client:AbrirLoja",
                icon = Config.Locations['Shop'].icon,
                label = Lang.ShopLabel,
                job = Config.Job,
            },
        },
        distance = 1.5
    })
    
    exports['qb-target']:AddBoxZone("pilot-roupeiro", Config.Locations['Clothes'].loc, Config.Locations['Clothes'].lenght, Config.Locations['Clothes'].width, {
        name = "pilot-roupeiro",
        heading = Config.Locations['Clothes'].heading,
        debugpoly = false,
    }, {
        options = {
            {  
                event = "qb-clothing:client:openOutfitMenu",
                icon = Config.Locations['Clothes'].icon,
                label = Lang.ClothesLabel,
                job = Config.Job,
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("pilot-servico", Config.Locations['Duty'].loc, Config.Locations['Duty'].lenght, Config.Locations['Duty'].width, {
        name = "pilot-servico",
        heading = Config.Locations['Duty'].heading,
        debugpoly = false,
    }, {
        options = {
            {  
                event = "mt-pilotjob:client:Servico",
                icon = Config.Locations['Duty'].icon,
                label = Lang.DutyLabel,
                job = Config.Job,
            },
        },
        distance = 1.5
    })

    local blip = AddBlipForCoord(Config.Locations['Ped'].targetLoc)
    
    SetBlipSprite (blip, 16)
    SetBlipDisplay(blip, 2)
    SetBlipScale  (blip, 0.9)
    SetBlipColour (blip, 37)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('LS Airlines')
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    while true do
        Wait(1)
        local pos = GetEntityCoords(PlayerPedId())
        local spawn = Config.Locations['PlanesSpawn']
        local coords = vector3(spawn.x, spawn.y, spawn.z)
        local Veiculo = GetVehiclePedIsIn(PlayerPedId(), true)
        if IsPedInAnyVehicle(PlayerPedId(), true) then
            local takeDist = #(pos - coords)
            if takeDist <= 10 then
                exports['qb-core']:DrawText(Lang.EButtom, 'left')
                if IsControlJustPressed(0, 46) then
                    DeleteEntity(Veiculo)
                end
            else
                exports['qb-core']:HideText()
            end
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
		if PlayerData.job.onduty then
			if PlayerData.job.name == Config.Job then
				TriggerServerEvent("QBCore:ToggleDuty")
			end
		end
	end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = PlayerJob.onduty
end)

RegisterNetEvent("mt-pilotjob:client:Servico", function()
    TriggerServerEvent("QBCore:ToggleDuty")
end)

RegisterNetEvent('mt-pilotjob:client:AbrirArmario', function()
    TriggerEvent("inventory:client:SetCurrentStash", "ArmarioPiloto")
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "ArmarioPiloto", {
        maxweight = 250000,
        slots = 40,
    })
end)

RegisterNetEvent('mt-pilotjob:client:AbrirLoja', function()
    local columns = {
        {
            header = Lang.ShopMenuHeader,
            isMenuHeader = true,
        },
    }
    for k, v in pairs(Config.ShopItems) do
        local item = {}
        item.header = "<img src=nui://aj-inventory/html/images/" .. QBCore.Shared.Items[v.itemName].image .. " width=35px style='margin-right: 10px'> " .. QBCore.Shared.Items[v.itemName].label
        item.text = Lang.Price .. v.itemPrice .. '$'
        item.params = {
            event = 'mt-pilotjob:client:ComprarItemLoja',
            args = {
                type = k
            }
        }
        table.insert(columns, item)
    end
    exports['qb-menu']:openMenu(columns)
end)

RegisterNetEvent('mt-pilotjob:client:ComprarItemLoja', function(args)
    local current = args.type
    local dinheiro = Config.ShopItems[current].itemPrice
    local item = Config.ShopItems[current].itemName

    local dialog = exports['qb-input']:ShowInput({
        header = Lang.AmountHeader,
        submitText = Lang.SubmitLabel,
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = 'Amount'
            }
        }
    })

    if dialog then
        if not dialog.amount then 
            return 
        end
        if dialog.amount >= '1' then
            local quantidade = dialog.amount
            TriggerServerEvent('mt-pilotjob:server:ComprarItems', item, dinheiro, quantidade)
        else
            QBCore.Functions.Notify(Lang.AmountInvalid, 'error', 7500)
        end
    end
end)

RegisterNetEvent('mt-pilotjob:client:MenuVeiculos', function()
    exports['qb-menu']:openMenu({
        {
            header = Lang.PlanesListHeader,
            isMenuHeader = true,
        },
        {
            header = Lang.CloseMenu,
            icon = "fas fa-times-circle",
            event = "qb-menu:closeMenu",
        },
        {
            header = Lang.FreePlanes,
            txt = Lang.FreePlanesTxt,
            icon = "fas fa-plane",
            params = {
                event = 'mt-pilotjob:client:MenuVeiculosFree',
            },
        },
        {
            header = Lang.PaidPlanes,
            txt = Lang.PaidPlanesTxt,
            icon = "fas fa-dollar-sign",
            params = {
                event = 'mt-pilotjob:client:MenuVeiculosPagos',
            },
        },
    })
end)

RegisterNetEvent('mt-pilotjob:client:MenuVeiculosPagos', function()
    local columns = {
        {
            header = Lang.PaidVehicleHeader,
            isMenuHeader = true,
        },
        {
            header = Lang.GetBack,
            icon = "fas fa-backward",
            params = {
                event = "mt-pilotjob:client:MenuVeiculos",
            },
        },
    }
    for k, v in pairs(Config.PaidPlanesList) do
        local item = {}
        item.header = v.vehicleLabel
        item.icon = "fas fa-plane"
        item.text = Lang.Price .. v.vehiclePrice .. "$"
        item.params = {
            event = "mt-pilotjob:client:SelecionarVeiculosPagos",
            args = {
                type = k
            }
        }
        table.insert(columns, item)
    end
    exports['qb-menu']:openMenu(columns)
end)

RegisterNetEvent('mt-pilotjob:client:SelecionarVeiculosPagos', function(args)
    local currentPlane = args.type
    local columns = {
        {
            header = Lang.PaidPlanesOptions,
            isMenuHeader = true,
        },
        {
            header = Lang.GetBack,
            icon = "fas fa-backward",
            params = {
                event = "mt-pilotjob:client:MenuVeiculosPagos",
            },
        },
        {
            header = Lang.CurrentPlane .. Config.PaidPlanesList[currentPlane].vehicleLabel,
            icon = "fas fa-plane",
        },
        {
            header = Lang.SellToPlayer,
            text = Lang.SellToPlayerText,
            icon = "fas fa-user",
            params = {
                event = "mt-pilotjob:client:VenderVeiculoPlayer",
                args = {
                    type = currentPlane
                },
            }
        },
        {
            header = Lang.BuyVehicle,
            text = Lang.BuyVehicleText,
            icon = "fas fa-plane",
            params = {
                event = "mt-pilotjob:client:ComprarVeiculo",
                args = {
                    type = currentPlane
                },
            }
        },
    }
    exports['qb-menu']:openMenu(columns)
end)

RegisterNetEvent('mt-pilotjob:client:ComprarVeiculo', function(args)
    local Plane = args.type 
    local aviao = Config.PaidPlanesList[Plane].vehicleName
    local preco = Config.PaidPlanesList[Plane].vehiclePrice
    local coords = Config.Locations['PlanesSpawn']

    QBCore.Functions.SpawnVehicle(aviao, function(veh)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
        SetVehicleEngineOn(veh, false, false)
        TriggerServerEvent('mt-pilotjob:server:ComprarVeiculo', preco, aviao)
    end, coords, true)
end)

RegisterNetEvent('mt-pilotjob:client:VenderVeiculoPlayer', function(args)
    local Plane = args.type
    local dialog = exports['qb-input']:ShowInput({
        header = Lang.GivePlaneHeader,
        submitText = Lang.SubmitLabel,
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'id',
                text = 'Player ID'
            }
        }
    })

    if dialog then
        if not dialog.id then
            return
        end
        local aviao = Config.PaidPlanesList[Plane].vehicleName
        local preco = Config.PaidPlanesList[Plane].vehiclePrice
        local coords = Config.Locations['PlanesSpawn']
        local playerId = dialog.id

        QBCore.Functions.SpawnVehicle(aviao, function(veh)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
            SetVehicleEngineOn(veh, false, false)
            TriggerServerEvent('mt-pilotjob:server:venderVeiculoPlayer', playerId, preco, aviao)
        end, coords, true)
    end
end)

RegisterNetEvent('mt-pilotjob:client:MenuVeiculosFree', function()
    local columns = {
        {
            header = Lang.FreePlanesListHeader,
            isMenuHeader = true,
        },
        {
            header = Lang.GetBack,
            icon = "fas fa-backward",
            params = {
                event = "mt-pilotjob:client:MenuVeiculos",
            },
        },
    }
    for k, v in pairs(Config.FreePlanesList) do
        local item = {}
        item.header = v.vehicleLabel
        item.icon = "fas fa-plane"
        item.params = {
            event = "mt-pilotjob:client:SpawnVeiculosFree",
            args = {
                type = k
            }
        }
    table.insert(columns, item)
    end
    exports['qb-menu']:openMenu(columns)
end)

RegisterNetEvent('mt-pilotjob:client:SpawnVeiculosFree', function(args)
    local currentPlane = args.type
    local Plane = Config.FreePlanesList[currentPlane].vehicleName
    local coords = Config.Locations['PlanesSpawn']

    QBCore.Functions.SpawnVehicle(Plane, function(veh)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
        SetVehicleEngineOn(veh, false, false)
    end, coords, true)
end)
