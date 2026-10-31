local cube = {}

cube.vertices = {
    {-1, -1, -1},
    { 1, -1, -1},
    { 1,  1, -1},
    {-1,  1, -1},

    {-1, -1,  1},
    { 1, -1,  1},
    { 1,  1,  1},
    {-1,  1,  1},
}

cube.edges = {
    {1,2}, {2,3}, {3,4}, {4,1},
    {5,6}, {6,7}, {7,8}, {8,5},
    {1,5}, {2,6}, {3,7}, {4,8},
}

local function rotate_point(x, y, z, rx, ry, rz)
    -- rotate around X
    local cosx, sinx = math.cos(rx), math.sin(rx)
    y, z = y * cosx - z * sinx, y * sinx + z * cosx

    -- rotate around Y
    local cosy, siny = math.cos(ry), math.sin(ry)
    x, z = x * cosy + z * siny, -x * siny + z * cosy

    -- rotate around Z
    local cosz, sinz = math.cos(rz), math.sin(rz)
    x, y = x * cosz - y * sinz, x * sinz + y * cosz

    return x, y, z
end

local function project_point(x, y, z, cx, cy, scale, distance)
    local perspective = distance / (distance + z)

    local sx = cx + x * scale * perspective
    local sy = cy + y * scale * perspective

    return sx, sy
end

function cube.draw_cube(cx, cy, size, rx, ry, rz, distance)
    distance = distance or 4

    local projected = {}

    for i, v in ipairs(cube.vertices) do
        local x, y, z = v[1], v[2], v[3]

        x, y, z = rotate_point(x, y, z, rx, ry, rz)

        projected[i] = {
            project_point(x, y, z, cx, cy, size, distance)
        }
    end

    for _, edge in ipairs(cube.edges) do
        local a = projected[edge[1]]
        local b = projected[edge[2]]

        love.graphics.line(a[1], a[2], b[1], b[2])
    end
end

return cube