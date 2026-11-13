Locales = Locales or {}

function BillingLocale(key, replacements)
    local locale = Locales[Config.Locale] or Locales.en or {}
    local value = locale[key] or (Locales.en and Locales.en[key]) or key

    if replacements then
        for name, replacement in pairs(replacements) do
            value = value:gsub('{' .. name .. '}', tostring(replacement))
        end
    end

    return value
end
