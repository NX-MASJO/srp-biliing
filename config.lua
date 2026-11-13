Config = {}

Config.Locale = 'en'
Config.Debug = false
Config.Command = 'billing'
Config.AdminAce = 'billing.admin'
Config.ReceiptItem = 'billing_receipt'
Config.ReceiptViewDistance = 5.0
Config.ReceiptUseCooldownSeconds = 2

Config.Limits = {
    MaxAmount = 1000000,
    MaxTitleLength = 80,
    MaxItemLabelLength = 64,
    MaxTemplateNameLength = 48,
    MaxAttachments = 8,
    MaxArchiveRows = 50,
    MaxDueDays = 90,
    CreateCooldownSeconds = 3
}

Config.DefaultDueDays = 7
Config.CommissionPercent = 10
Config.Payments = {
    CashAccount = 'cash',
    BankAccount = 'bank'
}

Config.Theme = {
    accent = '#72f33d',
    background = '#080d09',
    surface = '#111a12',
    text = '#f0f7ed'
}

Config.Kiosks = {
    {
        coords = vec4(243.42, 224.12, 106.29, 160.0),
        model = 's_m_m_highsec_01',
        label = 'Pay outstanding invoices'
    }
}

Config.Societies = {
    government = {
        label = 'GOVERNMENT',
        account = 'government',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 9,
        bossGrade = 9,
        commissionPercent = 10
    },
    police = {
        label = 'SPD',
        account = 'police',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 9,
        bossGrade = 9,
        commissionPercent = 10
    },
    ambulance = {
        label = 'EMS',
        account = 'ambulance',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 9,
        bossGrade = 9,
        commissionPercent = 5
    },
    doj = {
        label = 'DOJ',
        account = 'doj',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 6,
        bossGrade = 6,
        commissionPercent = 8
    },
    resto = {
        label = 'RESTO',
        account = 'resto',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 6,
        bossGrade = 6,
        commissionPercent = 10
    },
    mechanic = {
        label = 'MECHANIC',
        account = 'mechanic',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 6,
        bossGrade = 6,
        commissionPercent = 10
    },
    edu = {
        label = 'EDUCATION',
        account = 'edu',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 2,
        bossGrade = 2,
        commissionPercent = 10
    },
    media = {
        label = 'MEDIA',
        account = 'media',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 6,
        bossGrade = 6,
        commissionPercent = 10
    },
    cardealer = {
        label = 'VEHICLE DEALER',
        account = 'cardealer',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 4,
        bossGrade = 4,
        commissionPercent = 10
    },
    realestate = {
        label = 'REAL ESTATE',
        account = 'realestate',
        canBill = true,
        canCreateB2B = true,
        canManageTemplates = true,
        templateGrade = 4,
        bossGrade = 4,
        commissionPercent = 10
    }
}

-- Each configured society account must exist in Renewed-Banking.
Config.ThemeKeys = { 'accent', 'background', 'surface', 'text' }
