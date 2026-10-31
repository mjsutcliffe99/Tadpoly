local json = require "care.third_party.json"

local i18n = {}

i18n.locales = {}   -- a list of loaded locales, e.g. locales["en"] = English locale table
i18n.locale  = nil  -- the active locale, e.g. "en"

local function lookup(locale,key)
    local node = i18n.locales[locale]
    for part in key:gmatch("[^%.]+") do
        if (type(node) ~= "table") then return nil end
        node = node[part]
        if (node == nil) then return nil end
    end
    return node
end

-- e.g. t("ui.dashboard.speedometer",{player.speed})
function i18n.t(key,params)
    local str = lookup(i18n.locale,key)

    if (not params) then return str end
    return (str:gsub("{(.-)}", function(k)
        return tostring(params[k] ~= nil and params[k] or "{"..k.."}")
    end))
end

function i18n.load_locale(name,path)
    i18n.locales[name] = json.decode(love.filesystem.read(path))
end

function i18n.load_locales(locales)
    for name,path in pairs(locales) do
        i18n.load_locale(name,path)
    end
end

function i18n.set_locale(locale)
    i18n.locale = locale
end

function i18n.get_locale()
    return i18n.locale
end

return i18n