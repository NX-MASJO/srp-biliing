local spawnedKiosks = {}
local billingAnimationActive = false

local function startBillingAnimation()
    if billingAnimationActive then
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then
        return
    end

    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    billingAnimationActive = true
end

local function closeUi()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if billingAnimationActive then
        ClearPedTasks(PlayerPedId())
        billingAnimationActive = false
    end
end

local function openUi(options)
    options = options or {}
    local dashboard = lib.callback.await('srp-billing:getDashboard', false, {
        status = options.status
    })
    if not dashboard then
        lib.notify({ description = BillingLocale('error_generic'), type = 'error' })
        return
    end
    startBillingAnimation()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        dashboard = dashboard,
        targetId = options.targetId,
        initialStatus = options.status,
        initialSection = options.initialSection or 'invoices'
    })
end

RegisterCommand(Config.Command, function()
    openUi()
end, false)

RegisterNetEvent('srp-billing:client:open', function(options)
    openUi(options)
end)

RegisterNetEvent('srp-billing:client:showReceipt', function(receipt)
    if type(receipt) ~= 'table' then
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showReceipt',
        receipt = receipt
    })
end)

exports('useReceipt', function(_, slot)
    local slotId = type(slot) == 'table' and slot.slot or slot
    TriggerServerEvent('srp-billing:server:useReceipt', slotId)
end)

RegisterNUICallback('close', function(_, callback)
    closeUi()
    callback({ ok = true })
end)

RegisterNUICallback('refresh', function(data, callback)
    local dashboard = lib.callback.await('srp-billing:getDashboard', false, data or {})
    callback(dashboard and { ok = true, dashboard = dashboard } or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('createInvoice', function(data, callback)
    local result = lib.callback.await('srp-billing:createInvoice', false, data)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('payInvoice', function(data, callback)
    local result = lib.callback.await('srp-billing:payInvoice', false, data.id, data.account)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('cancelInvoice', function(data, callback)
    local result = lib.callback.await('srp-billing:cancelInvoice', false, data.id)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('saveTemplate', function(data, callback)
    local result = lib.callback.await('srp-billing:saveTemplate', false, data)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('deleteTemplate', function(data, callback)
    local result = lib.callback.await('srp-billing:deleteTemplate', false, data)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('payCommission', function(data, callback)
    local result = lib.callback.await('srp-billing:payCommission', false, data)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('saveTheme', function(data, callback)
    local result = lib.callback.await('srp-billing:saveTheme', false, data)
    callback(result or { ok = false, error = BillingLocale('error_generic') })
end)

RegisterNUICallback('getArchive', function(data, callback)
    local rows = lib.callback.await('srp-billing:getArchive', false, data or {})
    callback({ ok = true, archive = rows or {} })
end)

RegisterNUICallback('getTemplates', function(data, callback)
    local templates = lib.callback.await('srp-billing:getTemplates', false, data and data.societyJob)
    callback({ ok = true, templates = templates or {} })
end)

RegisterNUICallback('getCommissions', function(data, callback)
    local commissions = lib.callback.await('srp-billing:getCommissions', false, data and data.societyJob)
    callback({ ok = true, commissions = commissions or {} })
end)

local function targetPlayer(entity)
    if not entity or entity == 0 then
        return
    end
    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
    if playerIndex == -1 or playerIndex == PlayerId() then
        return
    end
    local serverId = GetPlayerServerId(playerIndex)
    if serverId and serverId > 0 then
        openUi({ targetId = serverId, initialSection = 'create' })
    end
end

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        {
            name = 'srp_billing_target_player',
            icon = 'fa-solid fa-file-invoice-dollar',
            label = BillingLocale('target_bill'),
            distance = 2.0,
            onSelect = function(data)
                targetPlayer(data.entity)
            end
        }
    })

    for index, kiosk in ipairs(Config.Kiosks) do
        local model = joaat(kiosk.model)
        if not IsModelInCdimage(model) or not IsModelValid(model) then
            print(('[srp-billing] Invalid kiosk model: %s'):format(kiosk.model))
        else
            RequestModel(model)
            local deadline = GetGameTimer() + 10000
            while not HasModelLoaded(model) and GetGameTimer() < deadline do
                Wait(100)
            end
            if not HasModelLoaded(model) then
                print(('[srp-billing] Timed out loading kiosk model: %s'):format(kiosk.model))
            else
                local ped = CreatePed(0, model, kiosk.coords.x, kiosk.coords.y, kiosk.coords.z - 1.0, kiosk.coords.w, false, false)
                if ped and ped ~= 0 then
                    SetEntityAsMissionEntity(ped, true, true)
                    FreezeEntityPosition(ped, true)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    spawnedKiosks[#spawnedKiosks + 1] = ped
                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = ('srp_billing_kiosk_%s'):format(index),
                            icon = 'fa-solid fa-receipt',
                            label = kiosk.label or BillingLocale('kiosk'),
                            onSelect = function()
                                openUi({ status = 'pending', initialSection = 'invoices' })
                            end
                        }
                    })
                    SetModelAsNoLongerNeeded(model)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    closeUi()
    for _, ped in ipairs(spawnedKiosks) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)
