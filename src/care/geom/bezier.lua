bezier = {}

-- basic quadratic bezier point
function bezier.point(t, x0, y0, cx, cy, x1, y1)
    local u = 1 - t
    local x = u*u*x0 + 2*u*t*cx + t*t*x1
    local y = u*u*y0 + 2*u*t*cy + t*t*y1
    return x, y
end

-- automatically generate a suitable control point
function bezier.control_point(x0, y0, x1, y1, strength)
    strength = strength or 120

    local dx = x1 - x0
    local dy = y1 - y0
    local len = math.sqrt(dx*dx + dy*dy)

    if (len == 0) then return x0,y0 end

    -- perpendicular
    local nx = -dy / len
    local ny = dx / len

    -- midpoint
    local mx = (x0 + x1) / 2
    local my = (y0 + y1) / 2

    -- scale curve by distance (optional, feels nicer)
    local curve = math.min(strength, len * 0.5)

    return mx + nx*curve, my + ny*curve
end

-- generate polyline points
function bezier.get_curve(x0, y0, x1, y1, opts)
    opts = opts or {}
    local segments = opts.segments or 30

    local cx, cy
    if (opts.cx and opts.cy) then
        cx, cy = opts.cx, opts.cy
    else
        cx, cy = bezier.control_point(x0, y0, x1, y1, opts.strength)
    end

    local points = {}

    for i = 0,segments do
        local t = i / segments
        local x, y = bezier.point(t, x0, y0, cx, cy, x1, y1)
        table.insert(points, x)
        table.insert(points, y)
    end

    return points, cx, cy
end

return bezier