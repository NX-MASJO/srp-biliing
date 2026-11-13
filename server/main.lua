local QBCore = exports['qb-core']:GetCoreObject()
local createCooldowns = {}
local sourceIdentifiers = {}
local receiptUseCooldowns = {}

local function logError(message)
    print(('[srp-billing] ERROR: %s'):format(message))
end

local function notify(source, description, kind)
    TriggerClientEvent('ox_lib:notify', source, {
        description = description,
        type = kind or 'error'
    })
end

local function decodeJson(value)
    if type(value) == 'table' then
        return value
    end
    if type(value) ~= 'string' or value == '' then
        return {}
    end
    local ok, decoded = pcall(json.decode, value)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end
    return decoded
end

local function playerFor(source)
    return QBCore.Functions.GetPlayer(source)
end

local function playerIdentifier(player)
    return player and player.PlayerData and player.PlayerData.citizenid
end

local function playerName(player)
    if not player or not player.PlayerData then
        return 'Unknown'
    end
    local info = player.PlayerData.charinfo or {}
    local name = ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('%s+$', '')
    return name ~= '' and name or player.PlayerData.name or 'Unknown'
end

local function jobFor(player)
    return player and player.PlayerData and player.PlayerData.job
end

local function societyConfig(jobName)
    return jobName and Config.Societies[jobName]
end

local function isAdmin(source)
    if IsPlayerAceAllowed(source, Config.AdminAce) then
        return true
    end
    return QBCore.Functions.HasPermission(source, 'admin') == true
end

local function isBoss(player, society)
    local job = jobFor(player)
    if not job or not society then
        return false
    end
    local grade = job.grade and tonumber(job.grade.level) or 0
    return job.isboss == true or grade >= (society.bossGrade or 0)
end

local function canManageTemplates(player, society)
    if not society or society.canManageTemplates ~= true then
        return false
    end
    local job = jobFor(player)
    if not job then
        return false
    end
    local minimumGrade = tonumber(society.templateGrade)
    if minimumGrade then
        local grade = job.grade and tonumber(job.grade.level) or 0
        return grade >= minimumGrade
    end
    return isBoss(player, society)
end

local function societyContext(source, requestedJob)
    if isAdmin(source) and type(requestedJob) == 'string' then
        local society = societyConfig(requestedJob)
        if society then
            return requestedJob, society
        end
        return nil, nil
    end
    local job = jobFor(playerFor(source))
    local society = job and societyConfig(job.name)
    return job and job.name, society
end

local function cleanText(value, maxLength)
    if type(value) ~= 'string' then
        return nil
    end
    value = value:gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' or #value > maxLength then
        return nil
    end
    return value
end

local function validInteger(value, minimum, maximum)
    local number = tonumber(value)
    if not number or number % 1 ~= 0 or number < minimum or number > maximum then
        return nil
    end
    return number
end

local function validDate(value)
    if value == nil or value == '' then
        return nil
    end
    if type(value) ~= 'string' then
        return false
    end
    local year, month, day = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if not year or month < 1 or month > 12 or day < 1 or day > 31 then
        return false
    end
    local timestamp = os.time({ year = year, month = month, day = day, hour = 12 })
    if not timestamp or os.date('%Y-%m-%d', timestamp) ~= value then
        return false
    end
    local maximum = os.time({ year = os.date('*t').year, month = os.date('*t').month, day = os.date('*t').day, hour = 12 })
        + (Config.Limits.MaxDueDays * 86400)
    return timestamp <= maximum
end

local function validateAttachments(entries)
    if entries == nil then
        return {}, 0
    end
    if type(entries) ~= 'table' then
        return nil
    end

    local count, total, lines = 0, 0, {}
    for _, entry in ipairs(entries) do
        count = count + 1
        if count > Config.Limits.MaxAttachments or type(entry) ~= 'table' then
            return nil
        end
        local label = cleanText(entry.label, Config.Limits.MaxItemLabelLength)
        local quantity = validInteger(entry.quantity, 1, 50)
        local unitPrice = validInteger(entry.unitPrice, 1, Config.Limits.MaxAmount)
        if not label or not quantity or not unitPrice then
            return nil
        end
        total = total + unitPrice * quantity
        if total > Config.Limits.MaxAmount then
            return nil
        end
        local id = type(entry.id) == 'string' and cleanText(entry.id, 64) or tostring(count)
        if not id then
            return nil
        end
        for _, line in ipairs(lines) do
            if line.id == id then
                return nil
            end
        end
        lines[#lines + 1] = {
            id = id,
            label = label,
            quantity = quantity,
            unitPrice = unitPrice
        }
    end
    for key in pairs(entries) do
        if type(key) ~= 'number' or key % 1 ~= 0 or key < 1 or key > count then
            return nil
        end
    end
    return lines, total
end

local function validateInvoiceFields(data)
    if type(data) ~= 'table' then
        return nil
    end
    local title = cleanText(data.title, Config.Limits.MaxTitleLength)
    local discount = validInteger(data.discountPercent or 0, 0, 90)
    local dueDate = validDate(data.dueDate)
    if not title or not discount or dueDate == false then
        return nil
    end
    if not dueDate then
        dueDate = os.date('%Y-%m-%d', os.time() + (Config.DefaultDueDays * 86400))
    end

    local attachments, attachedTotal = validateAttachments(data.attachments)
    if not attachments then
        return nil
    end
    local subtotal
    if #attachments > 0 then
        subtotal = attachedTotal
    else
        subtotal = validInteger(data.amount, 1, Config.Limits.MaxAmount)
    end
    if not subtotal or subtotal < 1 then
        return nil
    end
    local total = math.floor((subtotal * (100 - discount) / 100) + 0.5)
    if total < 1 or total > Config.Limits.MaxAmount then
        return nil
    end

    return {
        title = title,
        subtotal = subtotal,
        discountPercent = discount,
        total = total,
        dueDate = dueDate,
        attachments = attachments
    }
end

local function applyTemplateQuantities(templateLines, requestedLines)
    if requestedLines == nil then
        return templateLines
    end
    if type(requestedLines) ~= 'table' or #requestedLines ~= #templateLines then
        return nil
    end

    local quantities = {}
    for key, entry in pairs(requestedLines) do
        if type(key) ~= 'number' or key % 1 ~= 0 or key < 1 or key > #requestedLines
            or type(entry) ~= 'table' then
            return nil
        end
        local id = type(entry.id) == 'string' and cleanText(entry.id, 64)
        local quantity = validInteger(entry.quantity, 1, 50)
        if not id or not quantity or quantities[id] then
            return nil
        end
        quantities[id] = quantity
    end

    local total = 0
    local lines = {}
    for _, line in ipairs(templateLines) do
        local quantity = quantities[line.id]
        if not quantity then
            return nil
        end
        total = total + line.unitPrice * quantity
        if total > Config.Limits.MaxAmount then
            return nil
        end
        lines[#lines + 1] = {
            id = line.id,
            label = line.label,
            unitPrice = line.unitPrice,
            quantity = quantity
        }
    end
    return lines, total
end

local function canManageSociety(player, jobName)
    local job = jobFor(player)
    local society = societyConfig(jobName)
    return job and job.name == jobName and society and isBoss(player, society), society
end

local function closeToPlayer(source, targetSource)
    local sourcePed, targetPed = GetPlayerPed(source), GetPlayerPed(targetSource)
    if sourcePed == 0 or targetPed == 0 then
        return false
    end
    return #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) <= 5.0
end

local function insertInvoice(values)
    local id = MySQL.insert.await([[
        INSERT INTO billing_invoices
            (invoice_type, sender_identifier, sender_name, sender_job, sender_society,
             recipient_identifier, recipient_name, recipient_society, title, subtotal,
             discount_percent, total, due_date, attachments)
        VALUES (?, ?, ?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''),
                NULLIF(?, ''), NULLIF(?, ''), ?, ?, ?, ?, NULLIF(?, ''), ?)
    ]], values)
    if not id then
        logError('invoice insert returned no id')
        return nil
    end
    return id
end

local function societyCall(exportName, account, amount)
    local ok, result = pcall(function()
        return exports['Renewed-Banking'][exportName](account, amount)
    end)
    if not ok then
        logError(('Renewed-Banking %s failed for %s: %s'):format(exportName, account, tostring(result)))
        return false
    end
    return result ~= false
end

local function resetInvoice(id)
    MySQL.update.await("UPDATE billing_invoices SET status = 'pending' WHERE id = ? AND status = 'processing'", { id })
end

local function refundPayment(sourcePlayer, account, amount, invoice)
    if invoice.invoice_type == 'b2b' then
        local society = societyConfig(invoice.recipient_society)
        return society and societyCall('addAccountMoney', society.account, amount)
    end
    return sourcePlayer.Functions.AddMoney(account, amount, 'billing-refund') ~= false
end

local function debitPayment(sourcePlayer, account, amount, invoice)
    if invoice.invoice_type == 'b2b' then
        local society = societyConfig(invoice.recipient_society)
        return society and societyCall('removeAccountMoney', society.account, amount)
    end
    return sourcePlayer.Functions.RemoveMoney(account, amount, 'billing-payment') == true
end

local function creditPayment(invoice, amount)
    if invoice.invoice_type == 'personal' then
        local receiver = QBCore.Functions.GetPlayerByCitizenId(invoice.sender_identifier)
        if not receiver then
            return false, 'offline'
        end
        return receiver.Functions.AddMoney(Config.Payments.BankAccount, amount, 'billing-received') == true
    end
    local society = societyConfig(invoice.sender_job)
    if not society or not society.account then
        return false, 'society'
    end
    return societyCall('addAccountMoney', society.account, amount), 'society'
end

local function notifyIssuer(invoice, message)
    for _, playerId in ipairs(GetPlayers()) do
        local player = playerFor(tonumber(playerId))
        if playerIdentifier(player) == invoice.sender_identifier then
            notify(tonumber(playerId), message, 'success')
            return
        end
    end
end

local function giveInvoiceReceipt(source, invoice)
    local metadata = {
        description = ('Invoice #%s | %s | Paid: $%s'):format(
            invoice.id, invoice.title, invoice.total
        ),
        invoiceId = invoice.id,
        invoiceType = invoice.invoice_type,
        title = invoice.title,
        sender = invoice.sender_name,
        recipient = invoice.invoice_type == 'b2b' and invoice.recipient_society or invoice.recipient_name,
        subtotal = invoice.subtotal,
        discountPercent = invoice.discount_percent,
        total = invoice.total,
        items = decodeJson(invoice.attachments),
        issuedAt = invoice.created_at
    }
    local ok, added, response = pcall(function()
        return exports.ox_inventory:AddItem(source, Config.ReceiptItem, 1, metadata)
    end)
    if not ok or added ~= true then
        local reason = ok and tostring(response or 'inventory rejected item') or tostring(added)
        logError(('could not give receipt item for invoice %s to player %s: %s'):format(invoice.id, source, reason))
        return false
    end
    return true
end

RegisterNetEvent('srp-billing:server:useReceipt', function(slotId)
    local source = source
    local player = playerFor(source)
    local identifier = playerIdentifier(player)
    slotId = validInteger(slotId, 1, 1000)
    if not identifier or not slotId then
        return
    end

    local now = os.time()
    if receiptUseCooldowns[identifier] and now - receiptUseCooldowns[identifier] < Config.ReceiptUseCooldownSeconds then
        return
    end
    receiptUseCooldowns[identifier] = now

    local ok, slot = pcall(function()
        return exports.ox_inventory:GetSlot(source, slotId)
    end)
    if not ok or type(slot) ~= 'table' or slot.name ~= Config.ReceiptItem then
        return
    end
    local metadata = type(slot.metadata) == 'table' and slot.metadata or {}
    local invoiceId = validInteger(metadata.invoiceId, 1, 2147483647)
    if not invoiceId then
        notify(source, BillingLocale('error_receipt_invalid'), 'error')
        return
    end

    local invoice = MySQL.single.await(
        "SELECT id, invoice_type, sender_name, sender_society, recipient_name, recipient_society, title, subtotal, discount_percent, total, due_date, attachments, created_at, paid_at FROM billing_invoices WHERE id = ? AND status = 'paid'",
        { invoiceId }
    )
    if not invoice then
        notify(source, BillingLocale('error_receipt_invalid'), 'error')
        return
    end

    local receipt = {
        id = invoice.id,
        invoice_type = invoice.invoice_type,
        sender_name = invoice.sender_name,
        sender_society = invoice.sender_society,
        recipient_name = invoice.recipient_name or invoice.recipient_society,
        recipient_society = invoice.recipient_society,
        title = invoice.title,
        subtotal = invoice.subtotal,
        discount_percent = invoice.discount_percent,
        total = invoice.total,
        due_date = invoice.due_date,
        created_at = invoice.created_at,
        status = 'paid',
        attachments = decodeJson(invoice.attachments),
        canPay = false,
        canCancel = false,
        locale = Config.Locale
    }

    local sourcePed = GetPlayerPed(source)
    if sourcePed == 0 then
        notify(source, BillingLocale('error_generic'), 'error')
        return
    end
    local sourceCoords = GetEntityCoords(sourcePed)
    local maxDistance = tonumber(Config.ReceiptViewDistance) or 5.0
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        local targetPed = target and GetPlayerPed(target)
        if target == source or (targetPed and targetPed ~= 0 and #(GetEntityCoords(targetPed) - sourceCoords) <= maxDistance) then
            TriggerClientEvent('srp-billing:client:showReceipt', target, receipt)
        end
    end
end)

local function createInvoice(source, data)
    local sender = playerFor(source)
    local senderId = playerIdentifier(sender)
    if not senderId or type(data) ~= 'table' then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    local now = os.time()
    if createCooldowns[senderId] and now - createCooldowns[senderId] < Config.Limits.CreateCooldownSeconds then
        return { ok = false, error = BillingLocale('error_rate') }
    end

    local jobName, society = societyContext(source, data.societyJob)
    local admin = isAdmin(source)
    local senderJob = jobFor(sender)
    local invoiceType = data.invoiceType
    local recipientId, recipientName, senderSociety, recipientSociety
    if invoiceType == 'personal' then
        local targetSource = validInteger(data.targetId, 1, 65535)
        local target = targetSource and playerFor(targetSource)
        if not target or targetSource == source or not closeToPlayer(source, targetSource) then
            return { ok = false, error = BillingLocale('error_player') }
        end
        recipientId, recipientName = playerIdentifier(target), playerName(target)
    elseif invoiceType == 'job' then
        if not society or society.canBill ~= true or (not admin and (not senderJob or senderJob.name ~= jobName)) then
            return { ok = false, error = BillingLocale('error_permission') }
        end
        local targetSource = validInteger(data.targetId, 1, 65535)
        local target = targetSource and playerFor(targetSource)
        if not target or targetSource == source or not closeToPlayer(source, targetSource) then
            return { ok = false, error = BillingLocale('error_player') }
        end
        recipientId, recipientName = playerIdentifier(target), playerName(target)
        senderSociety = society.account
    elseif invoiceType == 'b2b' then
        if not society or society.canCreateB2B ~= true or (not admin and not isBoss(sender, society)) then
            return { ok = false, error = BillingLocale('error_permission') }
        end
        local targetJob = cleanText(data.recipientSociety, 50)
        local targetSociety = targetJob and societyConfig(targetJob)
        if not targetSociety or targetJob == jobName or not targetSociety.account then
            return { ok = false, error = BillingLocale('error_invalid') }
        end
        senderSociety, recipientSociety = society.account, targetSociety.account
    else
        return { ok = false, error = BillingLocale('error_invalid') }
    end

    local templateId
    if data.templateId ~= nil and data.templateId ~= '' then
        if invoiceType ~= 'job' then
            return { ok = false, error = BillingLocale('error_invalid') }
        end
        templateId = validInteger(data.templateId, 1, 2147483647)
        if not templateId then
            return { ok = false, error = BillingLocale('error_invalid') }
        end
    end

    local invoiceFields = data
    if templateId then
        if not society or society.canBill ~= true or (not admin and (not senderJob or senderJob.name ~= jobName)) then
            return { ok = false, error = BillingLocale('error_permission') }
        end
        local template = MySQL.single.await(
            'SELECT title, subtotal, discount_percent, attachments FROM billing_templates WHERE id = ? AND job_name = ?',
            { templateId, jobName }
        )
        if not template then
            return { ok = false, error = BillingLocale('error_invalid') }
        end
        local templateLines = validateAttachments(decodeJson(template.attachments))
        if not templateLines then
            logError(('template %s contains invalid item data'):format(templateId))
            return { ok = false, error = BillingLocale('error_generic') }
        end
        local selectedLines, selectedSubtotal = applyTemplateQuantities(templateLines, data.attachments)
        if not selectedLines then
            return { ok = false, error = BillingLocale('error_invalid') }
        end
        invoiceFields = {
            title = template.title,
            amount = #selectedLines > 0 and selectedSubtotal or template.subtotal,
            discountPercent = template.discount_percent,
            dueDate = data.dueDate,
            attachments = selectedLines
        }
    elseif invoiceType == 'job' then
        return { ok = false, error = BillingLocale('error_invalid') }
    else
        invoiceFields = data
    end

    local fields = validateInvoiceFields(invoiceFields)
    if not fields then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    local invoiceJobName = invoiceType == 'personal'
        and (senderJob and senderJob.name or '')
        or jobName
    local id = insertInvoice({
        invoiceType, senderId, playerName(sender), invoiceJobName or '', senderSociety or '',
        recipientId or '', recipientName or '', recipientSociety or '', fields.title, fields.subtotal,
        fields.discountPercent, fields.total, fields.dueDate or '',
        #fields.attachments > 0 and json.encode(fields.attachments) or '[]'
    })
    if not id then
        return { ok = false, error = BillingLocale('error_generic') }
    end
    createCooldowns[senderId] = now
    sourceIdentifiers[source] = senderId

    if recipientId then
        for _, playerId in ipairs(GetPlayers()) do
            local online = playerFor(tonumber(playerId))
            if playerIdentifier(online) == recipientId then
                notify(tonumber(playerId), BillingLocale('invoice_created'), 'inform')
                break
            end
        end
    end
    notify(source, BillingLocale('success_invoice'), 'success')
    return { ok = true, id = id }
end

local function settleInvoice(source, invoiceId, account)
    local payer = playerFor(source)
    local payerId = playerIdentifier(payer)
    invoiceId = validInteger(invoiceId, 1, 2147483647)
    if not payerId or not invoiceId then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    if account ~= Config.Payments.CashAccount and account ~= Config.Payments.BankAccount then
        return { ok = false, error = BillingLocale('error_invalid') }
    end

    local invoice = MySQL.single.await('SELECT * FROM billing_invoices WHERE id = ?', { invoiceId })
    if not invoice or invoice.status ~= 'pending' then
        return { ok = false, error = BillingLocale('error_invoice') }
    end
    if invoice.invoice_type == 'b2b' then
        local payerJob = jobFor(payer)
        local society = payerJob and societyConfig(payerJob.name)
        if not isAdmin(source) and (not society or society.account ~= invoice.recipient_society or not isBoss(payer, society)) then
            return { ok = false, error = BillingLocale('error_permission') }
        end
    elseif invoice.recipient_identifier ~= payerId then
        return { ok = false, error = BillingLocale('error_permission') }
    end

    local claimed = MySQL.update.await(
        "UPDATE billing_invoices SET status = 'processing' WHERE id = ? AND status = 'pending'",
        { invoiceId }
    )
    if claimed ~= 1 then
        return { ok = false, error = BillingLocale('error_invoice') }
    end

    if invoice.invoice_type ~= 'b2b' then
        local balance = tonumber(payer.Functions.GetMoney(account))
        if not balance or balance < invoice.total then
            resetInvoice(invoiceId)
            return { ok = false, error = BillingLocale('error_money') }
        end
    end
    if not debitPayment(payer, account, invoice.total, invoice) then
        resetInvoice(invoiceId)
        return { ok = false, error = BillingLocale('error_money') }
    end

    local commission = 0
    if invoice.invoice_type ~= 'personal' then
        local sellerSociety = societyConfig(invoice.sender_job)
        local percent = sellerSociety and validInteger(sellerSociety.commissionPercent or Config.CommissionPercent, 0, 50) or 0
        commission = math.floor(invoice.total * percent / 100)
    end
    local credited, creditKind = creditPayment(invoice, invoice.total - commission)
    if not credited then
        local refunded = refundPayment(payer, account, invoice.total, invoice)
        resetInvoice(invoiceId)
        if not refunded then
            logError(('payment refund failed for invoice %s; manual reconciliation required'):format(invoiceId))
        end
        local errorMessage = creditKind == 'offline'
            and BillingLocale('error_offline_sender')
            or BillingLocale('error_society')
        return { ok = false, error = errorMessage }
    end

    local queries = {
        {
            query = "UPDATE billing_invoices SET status = 'paid', paid_at = NOW() WHERE id = ? AND status = 'processing'",
            values = { invoiceId }
        }
    }
    if commission > 0 then
        queries[#queries + 1] = {
            query = [[
                INSERT INTO billing_commissions
                    (invoice_id, society, employee_identifier, employee_name, amount)
                VALUES (?, ?, ?, ?, ?)
            ]],
            values = { invoiceId, invoice.sender_society, invoice.sender_identifier, invoice.sender_name, commission }
        }
    end
    if invoice.invoice_type == 'b2b' then
        queries[#queries + 1] = {
            query = [[
                INSERT INTO billing_society_transfers
                    (invoice_id, debtor_society, creditor_society, amount)
                VALUES (?, ?, ?, ?)
            ]],
            values = { invoiceId, invoice.recipient_society, invoice.sender_society, invoice.total }
        }
    end
    local finalized = MySQL.transaction.await(queries)
    if not finalized then
        logError(('invoice %s was financially settled but final DB write failed; it remains processing'):format(invoiceId))
        return { ok = false, error = BillingLocale('error_generic') }
    end

    local receiptAdded = giveInvoiceReceipt(source, invoice)
    notify(source, BillingLocale('success_paid'), 'success')
    notifyIssuer(invoice, BillingLocale('success_paid'))
    if not receiptAdded then
        notify(source, BillingLocale('error_receipt_inventory'), 'warning')
    end
    return { ok = true }
end

local function getArchive(source, filters)
    local player = playerFor(source)
    local identifier = playerIdentifier(player)
    if not identifier then
        return {}
    end
    filters = type(filters) == 'table' and filters or {}
    local status = filters.status
    if status ~= 'pending' and status ~= 'paid' and status ~= 'cancelled' then
        status = nil
    end
    local search = cleanText(filters.search, 80)
    local job = jobFor(player)
    local society = job and societyConfig(job.name)
    local query, params
    if isAdmin(source) then
        query = 'SELECT * FROM billing_invoices WHERE 1 = 1'
        params = {}
    elseif society and society.canBill then
        query = [[
            SELECT * FROM billing_invoices
            WHERE (sender_identifier = ? OR recipient_identifier = ? OR sender_society = ? OR recipient_society = ?)
        ]]
        params = { identifier, identifier, society.account, society.account }
    else
        query = 'SELECT * FROM billing_invoices WHERE (sender_identifier = ? OR recipient_identifier = ?)'
        params = { identifier, identifier }
    end
    if status then
        query = query .. ' AND status = ?'
        params[#params + 1] = status
    end
    if search then
        query = query .. [[
            AND (title LIKE ? OR sender_name LIKE ? OR recipient_name LIKE ? OR CAST(id AS CHAR) = ?)
        ]]
        local term = ('%%%s%%'):format(search)
        params[#params + 1] = term
        params[#params + 1] = term
        params[#params + 1] = term
        params[#params + 1] = search
    end
    query = query .. ' ORDER BY created_at DESC LIMIT ?'
    params[#params + 1] = Config.Limits.MaxArchiveRows
    local rows = MySQL.query.await(query, params) or {}
    for _, row in ipairs(rows) do
        row.attachments = decodeJson(row.attachments)
        local managesSender = false
        if row.sender_society and society and society.account == row.sender_society then
            managesSender = isBoss(player, society)
        end
        local managesRecipient = false
        if row.recipient_society and society and society.account == row.recipient_society then
            managesRecipient = isBoss(player, society)
        end
        row.canPay = row.status == 'pending' and (
            row.recipient_identifier == identifier
            or (row.invoice_type == 'b2b' and (managesRecipient or isAdmin(source)))
        ) or false
        row.canCancel = row.status == 'pending' and (
            row.sender_identifier == identifier or managesSender or isAdmin(source)
        ) or false
    end
    return rows
end

local function cancelInvoice(source, invoiceId)
    local player = playerFor(source)
    local identifier = playerIdentifier(player)
    invoiceId = validInteger(invoiceId, 1, 2147483647)
    if not identifier or not invoiceId then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    local invoice = MySQL.single.await('SELECT * FROM billing_invoices WHERE id = ?', { invoiceId })
    if not invoice or invoice.status ~= 'pending' then
        return { ok = false, error = BillingLocale('error_invoice') }
    end
    local authorized = invoice.sender_identifier == identifier
    if not authorized and invoice.sender_society then
        local job = jobFor(player)
        local society = job and societyConfig(job.name)
        authorized = society and society.account == invoice.sender_society and isBoss(player, society)
    end
    authorized = authorized or isAdmin(source)
    if not authorized then
        return { ok = false, error = BillingLocale('error_permission') }
    end
    local changed = MySQL.update.await(
        "UPDATE billing_invoices SET status = 'cancelled', cancelled_at = NOW() WHERE id = ? AND status = 'pending'",
        { invoiceId }
    )
    if changed ~= 1 then
        return { ok = false, error = BillingLocale('error_invoice') }
    end
    notify(source, BillingLocale('success_cancelled'), 'success')
    return { ok = true }
end

local function getTemplates(player, jobName, admin)
    if not jobName then
        local job = jobFor(player)
        jobName = job and job.name
    end
    local society = societyConfig(jobName)
    local currentJob = jobFor(player)
    if not society or society.canBill ~= true or (not admin and (not currentJob or currentJob.name ~= jobName)) then
        return {}
    end
    local rows = MySQL.query.await(
        'SELECT id, name, title, subtotal, discount_percent, attachments FROM billing_templates WHERE job_name = ? ORDER BY name LIMIT 50',
        { jobName }
    ) or {}
    for _, row in ipairs(rows) do
        row.attachments = decodeJson(row.attachments)
    end
    return rows
end

local function saveTemplate(source, data)
    local player = playerFor(source)
    local identifier = playerIdentifier(player)
    local jobName, society = societyContext(source, type(data) == 'table' and data.societyJob)
    local admin = isAdmin(source)
    if not identifier or not society or not society.canBill or (not admin and not canManageTemplates(player, society)) then
        return { ok = false, error = BillingLocale('error_permission') }
    end
    local name = type(data) == 'table' and cleanText(data.name, Config.Limits.MaxTemplateNameLength)
    local fields = validateInvoiceFields(data)
    if not name or not fields then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    MySQL.insert.await([[
        INSERT INTO billing_templates (job_name, created_by, name, title, subtotal, discount_percent, attachments)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE created_by = VALUES(created_by), title = VALUES(title),
            subtotal = VALUES(subtotal), discount_percent = VALUES(discount_percent),
            attachments = VALUES(attachments)
    ]], {
        jobName, identifier, name, fields.title, fields.subtotal, fields.discountPercent,
        #fields.attachments > 0 and json.encode(fields.attachments) or '[]'
    })
    notify(source, BillingLocale('success_template'), 'success')
    return { ok = true }
end

local function deleteTemplate(source, data)
    local player = playerFor(source)
    local jobName, society = societyContext(source, type(data) == 'table' and data.societyJob)
    local admin = isAdmin(source)
    local templateId = validInteger(type(data) == 'table' and data.id, 1, 2147483647)
    if not society or not society.canBill or (not admin and not canManageTemplates(player, society)) or not templateId then
        return { ok = false, error = BillingLocale('error_permission') }
    end
    MySQL.update.await('DELETE FROM billing_templates WHERE id = ? AND job_name = ?', { templateId, jobName })
    return { ok = true }
end

local function getCommissions(player, jobName, admin)
    if not jobName then
        local job = jobFor(player)
        jobName = job and job.name
    end
    local society = societyConfig(jobName)
    if not society or (not admin and (not jobFor(player) or jobFor(player).name ~= jobName or not isBoss(player, society))) then
        return {}
    end
    return MySQL.query.await([[
        SELECT id, invoice_id, employee_identifier, employee_name, amount, status, created_at, paid_at
        FROM billing_commissions WHERE society = ? ORDER BY created_at DESC LIMIT 50
    ]], { society.account }) or {}
end

local function payCommission(source, data)
    local manager = playerFor(source)
    local jobName, society = societyContext(source, type(data) == 'table' and data.societyJob)
    local admin = isAdmin(source)
    local commissionId = validInteger(type(data) == 'table' and data.id, 1, 2147483647)
    if not society or (not admin and (not jobFor(manager) or jobFor(manager).name ~= jobName or not isBoss(manager, society))) or not commissionId then
        return { ok = false, error = BillingLocale('error_permission') }
    end
    local commission = MySQL.single.await(
        "SELECT * FROM billing_commissions WHERE id = ? AND society = ? AND status = 'available'",
        { commissionId, society.account }
    )
    if not commission then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    local employee = QBCore.Functions.GetPlayerByCitizenId(commission.employee_identifier)
    if not employee then
        return { ok = false, error = BillingLocale('error_player') }
    end
    local claimed = MySQL.update.await(
        "UPDATE billing_commissions SET status = 'processing' WHERE id = ? AND status = 'available'",
        { commissionId }
    )
    if claimed ~= 1 then
        return { ok = false, error = BillingLocale('error_invalid') }
    end
    if not societyCall('removeAccountMoney', society.account, commission.amount) then
        MySQL.update.await(
            "UPDATE billing_commissions SET status = 'available' WHERE id = ? AND status = 'processing'",
            { commissionId }
        )
        return { ok = false, error = BillingLocale('error_society') }
    end
    if employee.Functions.AddMoney(Config.Payments.BankAccount, commission.amount, 'billing-commission') ~= true then
        local refunded = societyCall('addAccountMoney', society.account, commission.amount)
        MySQL.update.await(
            "UPDATE billing_commissions SET status = 'available' WHERE id = ? AND status = 'processing'",
            { commissionId }
        )
        if not refunded then
            logError(('commission refund failed for record %s'):format(commissionId))
        end
        return { ok = false, error = BillingLocale('error_generic') }
    end
    local updated = MySQL.update.await(
        "UPDATE billing_commissions SET status = 'paid', paid_at = NOW() WHERE id = ? AND status = 'processing'",
        { commissionId }
    )
    if updated ~= 1 then
        logError(('commission %s was paid but its DB status could not be finalized'):format(commissionId))
        return { ok = false, error = BillingLocale('error_generic') }
    end
    notify(source, BillingLocale('success_commission'), 'success')
    notifyIssuer({ sender_identifier = commission.employee_identifier }, BillingLocale('commission_paid'))
    return { ok = true }
end

local function getTheme()
    local row = MySQL.single.await("SELECT setting_value FROM billing_settings WHERE setting_key = 'theme'")
    if row then
        local stored = decodeJson(row.setting_value)
        local theme = {}
        for _, key in ipairs(Config.ThemeKeys) do
            if type(stored[key]) == 'string' and stored[key]:match('^#%x%x%x%x%x%x$') then
                theme[key] = stored[key]
            end
        end
        if next(theme) then
            return theme
        end
    end
    return Config.Theme
end

local function saveTheme(source, data)
    local player = playerFor(source)
    if not playerIdentifier(player) or not isAdmin(source) or type(data) ~= 'table' then
        return { ok = false, error = BillingLocale('error_permission') }
    end
    local theme = {}
    for _, key in ipairs(Config.ThemeKeys) do
        local value = data[key]
        if type(value) ~= 'string' or not value:match('^#%x%x%x%x%x%x$') then
            return { ok = false, error = BillingLocale('error_invalid') }
        end
        theme[key] = value
    end
    MySQL.insert.await([[
        INSERT INTO billing_settings (setting_key, setting_value, updated_by)
        VALUES ('theme', ?, ?)
        ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_by = VALUES(updated_by)
    ]], { json.encode(theme), playerIdentifier(player) })
    return { ok = true, theme = theme }
end

lib.callback.register('srp-billing:createInvoice', createInvoice)
lib.callback.register('srp-billing:payInvoice', settleInvoice)
lib.callback.register('srp-billing:getArchive', getArchive)
lib.callback.register('srp-billing:cancelInvoice', cancelInvoice)
lib.callback.register('srp-billing:getTemplates', function(source, requestedJob)
    local jobName = societyContext(source, requestedJob)
    return getTemplates(playerFor(source), jobName, isAdmin(source))
end)
lib.callback.register('srp-billing:saveTemplate', saveTemplate)
lib.callback.register('srp-billing:deleteTemplate', deleteTemplate)
lib.callback.register('srp-billing:getCommissions', function(source, requestedJob)
    local jobName = societyContext(source, requestedJob)
    return getCommissions(playerFor(source), jobName, isAdmin(source))
end)
lib.callback.register('srp-billing:payCommission', payCommission)
lib.callback.register('srp-billing:getTheme', getTheme)
lib.callback.register('srp-billing:saveTheme', saveTheme)
lib.callback.register('srp-billing:getDashboard', function(source, filters)
    filters = type(filters) == 'table' and filters or {}
    local player = playerFor(source)
    local job = jobFor(player)
    local selectedJob, society = societyContext(source, filters.societyJob)
    local admin = isAdmin(source)
    if not selectedJob then
        selectedJob = job and job.name
    end
    if admin and not selectedJob then
        local names = {}
        for name in pairs(Config.Societies) do names[#names + 1] = name end
        table.sort(names)
        selectedJob = names[1]
    end
    society = societyConfig(selectedJob)
    local canUseSociety = society ~= nil and (admin or (job and job.name == selectedJob))
    return {
        archive = getArchive(source, filters),
        templates = getTemplates(player, selectedJob, admin),
        commissions = getCommissions(player, selectedJob, admin),
        theme = getTheme(),
        canCreateJobInvoice = canUseSociety and society.canBill == true or false,
        canCreateB2B = canUseSociety and society.canCreateB2B == true and (admin or isBoss(player, society)) or false,
        canManageCommissions = canUseSociety and (admin or isBoss(player, society)) or false,
        canManageTemplates = canUseSociety and society.canBill == true and (admin or canManageTemplates(player, society)) or false,
        isAdmin = admin,
        locale = Config.Locale,
        societyLabel = society and society.label or nil,
        selectedSocietyJob = selectedJob,
        profileName = playerName(player),
        jobLabel = job and job.label or '',
        maxAttachments = Config.Limits.MaxAttachments,
        allSocieties = (function()
            local choices = {}
            for name, config in pairs(Config.Societies) do
                choices[#choices + 1] = { job = name, label = config.label }
            end
            table.sort(choices, function(a, b) return a.label < b.label end)
            return choices
        end)(),
        societies = (function()
            local choices = {}
            for name, config in pairs(Config.Societies) do
                if name ~= selectedJob then
                    choices[#choices + 1] = { job = name, label = config.label }
                end
            end
            table.sort(choices, function(a, b) return a.label < b.label end)
            return choices
        end)()
    }
end)

AddEventHandler('playerDropped', function()
    local identifier = sourceIdentifiers[source]
    sourceIdentifiers[source] = nil
    if identifier then
        createCooldowns[identifier] = nil
    end
end)
