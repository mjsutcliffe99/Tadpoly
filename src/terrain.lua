local shaders = require "shaders"

local terrain = {}

function terrain.generate(width, depth, nx, nz, texture)
    -- nx, nz = number of vertices along X/Z

    local vertices = {}
    local indices = {}

    local half_w = width * 0.5
    local half_d = depth * 0.5

    for z = 0, nz - 1 do
        for x = 0, nx - 1 do
            local u = x / (nx - 1)
            local v = z / (nz - 1)

            local px = -half_w + u * width
            local py = 0
            local pz = -half_d + v * depth

            table.insert(vertices, {
                px, py, pz,   -- position
                u, v,        -- uv
                0, 1, 0      -- normal
            })
        end
    end

    local function id(x, z)
        return z * nx + x + 1
    end

    for z = 0, nz - 2 do
        for x = 0, nx - 2 do
            local a = id(x,     z)
            local b = id(x + 1, z)
            local c = id(x,     z + 1)
            local d = id(x + 1, z + 1)

            -- two triangles per grid cell
            table.insert(indices, a)
            table.insert(indices, c)
            table.insert(indices, b)

            table.insert(indices, b)
            table.insert(indices, c)
            table.insert(indices, d)
        end
    end

    local format = {
        { "VertexPosition", "float", 3 },
        { "VertexTexCoord",  "float", 2 },
        { "VertexNormal",    "float", 3 },
    }

    local mesh = love.graphics.newMesh(format, vertices, "triangles", "dynamic") -- TODO: should become "static" at compile time (or when the terrain tool is finished)
    mesh:setTexture(texture)
    mesh:setVertexMap(indices)

    return {
        mesh = mesh,
        vertices = vertices,
        nx = nx,
        nz = nz,
    }
end

function terrain.raise_vertex(terrain_obj, vx, vz, amount) --TEMP
    local i = vz * terrain_obj.nx + vx + 1
    terrain_obj.vertices[i][2] = terrain_obj.vertices[i][2] + amount
    terrain_obj.mesh:setVertex(i, terrain_obj.vertices[i])
end

return terrain