local shaders = require "shaders"

local water = {}

function water.make_water_grid(width, depth, nx, nz, texture)
    -- nx, nz = number of vertices along X/Z
    -- Example: make_water_grid(20, 20, 32, 32)

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

    local mesh = love.graphics.newMesh(format, vertices, "triangles", "static")
    mesh:setTexture(texture)
    mesh:setVertexMap(indices)

    return mesh
end

function water.draw(water_obj,camera,water_time)
    local water_mesh = water_obj.mesh

    local water_shader = shaders.water_shader
    love.graphics.setShader(water_shader)

    water_shader:send("time", water_time)

    water_shader:send("wave_amp", 0.62) --.62
    water_shader:send("wave_freq", 1.4)
    water_shader:send("wave_speed", 3.6) --3.6

    water_shader:send("cam_pos", {camera.x, camera.y, camera.z})
    water_shader:send("cam_yaw", camera.yaw)
    water_shader:send("cam_pitch", camera.pitch)
    water_shader:send("aspect", love.graphics.getWidth() / love.graphics.getHeight())

    water_shader:send("water_color", {1, 1, 1, 0.6})
    water_shader:send("uv_scale", {100, 100})        -- number of repeats across the mesh
    water_shader:send("uv_scroll", {0.5, 0.3}) -- scrolling speed

    water_shader:send("frame_count", 32) -- n frames in a horizontal strip
    water_shader:send("frame_rate", 12)  -- fps

    water_shader:send("model", water_obj.world_matrix)

    love.graphics.draw(water_mesh)

    love.graphics.setShader()
end

return water