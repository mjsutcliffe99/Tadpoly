local util = {}

function util.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function util.contains(item,set)
    for _,e in ipairs(set) do
        if (item == e) then return true end
    end
    return false
end

return util