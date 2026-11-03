local mat4 = require "mat4"

local Object = {}
Object.__index = Object

-- copied so objects never share a table with each other or the caller
local function vec3(v, default)
    v = v or default
    return {v[1], v[2], v[3]}
end

-- props (optional): name, pos, rot, scale, pivot
function Object:new(mesh, props)
    props = props or {}
    local self = setmetatable({
        name = props.name or "object",
        mesh = mesh,
        pos = vec3(props.pos, {0,0,0}),
        rot = vec3(props.rot, {0,0,0}), -- euler angles (radians) around x, y, z
        scale = vec3(props.scale, {1,1,1}),
        pivot = vec3(props.pivot, {0,0,0})
    }, self) -- self is the class being constructed, so subclasses get their own methods
    return self
end

-- model = T * R * S * T(-pivot)
function Object:get_model_matrix()
    local T = mat4.translate(self.pos[1], self.pos[2], self.pos[3])
    local R = mat4.rotateXYZ(self.rot[1], self.rot[2], self.rot[3])
    local S = mat4.scale(self.scale[1], self.scale[2], self.scale[3])
    local P = mat4.translate(-self.pivot[1], -self.pivot[2], -self.pivot[3])
    return mat4.mul(T, mat4.mul(R, mat4.mul(S, P)))
end

--TEMP:
-- CPU mirror of cube_shader's projection, so the wireframe lines up with the shaded mesh
local NEAR, FAR, FOV = 0.1, 100.0, math.rad(70)
local F = 1 / math.tan(FOV / 2)

-- world -> camera space (same as inverse_camera_rotate in the shader)
local function to_view(p, cam)
    local x, y, z = p[1] - cam.x, p[2] - cam.y, p[3] - cam.z

    local cy, sy = math.cos(-cam.yaw), math.sin(-cam.yaw)
    x, z = x * cy + z * sy, -x * sy + z * cy

    local cx, sx = math.cos(-cam.pitch), math.sin(-cam.pitch)
    y, z = y * cx - z * sx, y * sx + z * cx

    return {x, y, z}
end

-- camera space -> pixel coords on the current render target
local function to_screen(p, w, h)
    local ndc_x = p[1] * F / (w / h) / -p[3]
    local ndc_y = p[2] * F / -p[3]
    return (ndc_x + 1) * 0.5 * w, (1 - ndc_y) * 0.5 * h
end

-- clips a camera-space segment to the near plane (camera looks down -z); nil if fully behind
local function clip_near(a, b)
    local a_in, b_in = a[3] <= -NEAR, b[3] <= -NEAR
    if a_in and b_in then return a, b end
    if not a_in and not b_in then return nil end
    local t = (-NEAR - a[3]) / (b[3] - a[3])
    local c = { a[1] + (b[1]-a[1])*t, a[2] + (b[2]-a[2])*t, -NEAR }
    if a_in then return a, c else return c, b end
end

local function drawWireframe(mesh, model, cam)
    local m = model

    -- transform every vertex into camera space
    local view = {}
    for i = 1, mesh:getVertexCount() do
        local x, y, z = mesh:getVertex(i) -- VertexPosition is the first attribute
        local world = {
            m[1]*x + m[2]*y  + m[3]*z  + m[4],
            m[5]*x + m[6]*y  + m[7]*z  + m[8],
            m[9]*x + m[10]*y + m[11]*z + m[12],
        }
        view[i] = to_view(world, cam)
    end

    -- triangle index list (honours a vertex map if the mesh has one)
    local indices = mesh:getVertexMap()
    if not indices then
        indices = {}
        for i = 1, #view do indices[i] = i end
    end

    -- collect unique edges; vertices are duplicated per face, so dedupe by position
    local function key(i)
        local v = view[i]
        return string.format("%.5f,%.5f,%.5f", v[1], v[2], v[3])
    end
    local edges, seen = {}, {}
    local function add_edge(i, j)
        local ki, kj = key(i), key(j)
        local k = ki < kj and (ki .. "|" .. kj) or (kj .. "|" .. ki)
        if not seen[k] then
            seen[k] = true
            edges[#edges+1] = {i, j}
        end
    end
    for t = 1, #indices - 2, 3 do
        local a, b, c = indices[t], indices[t+1], indices[t+2]
        add_edge(a, b); add_edge(b, c); add_edge(c, a)
    end

    -- canvases set as a table ({canvas, depthstencil = ...}) come back as a table
    local target = love.graphics.getCanvas()
    while type(target) == "table" do target = target[1] end
    local w, h
    if target then w, h = target:getDimensions() else w, h = love.graphics.getDimensions() end

    love.graphics.push("all")
    love.graphics.setShader()
    love.graphics.setDepthMode()
    love.graphics.setLineWidth(2)

    love.graphics.setColor(1,1,0,1)
    for _, e in ipairs(edges) do
        local a, b = clip_near(view[e[1]], view[e[2]])
        if a then
            local x1, y1 = to_screen(a, w, h)
            local x2, y2 = to_screen(b, w, h)
            love.graphics.line(x1, y1, x2, y2)
        end
    end

    love.graphics.setColor(1, 0.8, 0.2, 1)
    for _, v in ipairs(view) do
        if v[3] <= -NEAR and v[3] >= -FAR then
            local sx, sy = to_screen(v, w, h)
            love.graphics.circle("fill", sx, sy, 4)
        end
    end

    love.graphics.pop()
end

local function transform(m, x, y, z)
    return {
        m[1]*x + m[2]*y  + m[3]*z  + m[4],
        m[5]*x + m[6]*y  + m[7]*z  + m[8],
        m[9]*x + m[10]*y + m[11]*z + m[12],
    }
end

-- red:   halfway between the projected left and right edges (screen-space midpoint)
-- green: the projection of the square's true 3D centre
-- these only coincide when the square faces the camera; perspective pulls them apart otherwise
local function drawCentreLines(mesh, model, cam)
    local n = mesh:getVertexCount()
    local local_pos = {}
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge
    local min_z, max_z = math.huge, -math.huge
    for i = 1, n do
        local x, y, z = mesh:getVertex(i)
        local_pos[i] = {x, y, z}
        min_x, max_x = math.min(min_x, x), math.max(max_x, x)
        min_y, max_y = math.min(min_y, y), math.max(max_y, y)
        min_z, max_z = math.min(min_z, z), math.max(max_z, z)
    end

    local target = love.graphics.getCanvas()
    while type(target) == "table" do target = target[1] end
    local w, h
    if target then w, h = target:getDimensions() else w, h = love.graphics.getDimensions() end

    -- screen x of the left/right edges = average of the projected vertices on each edge
    local eps = 1e-5
    local left_sum, left_n, right_sum, right_n = 0, 0, 0, 0
    for i = 1, n do
        local p = local_pos[i]
        local v = to_view(transform(model, p[1], p[2], p[3]), cam)
        if v[3] > -NEAR then return end -- part of the square is behind the camera
        local sx = to_screen(v, w, h)
        if math.abs(p[1] - min_x) < eps then left_sum, left_n = left_sum + sx, left_n + 1 end
        if math.abs(p[1] - max_x) < eps then right_sum, right_n = right_sum + sx, right_n + 1 end
    end
    local red_x = (left_sum / left_n + right_sum / right_n) / 2

    local centre = to_view(transform(model,
        (min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2), cam)
    local green_x = to_screen(centre, w, h)

    love.graphics.push("all")
    love.graphics.setShader()
    love.graphics.setDepthMode()
    love.graphics.setLineWidth(4)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.line(red_x, 0, red_x, h)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.line(green_x, 0, green_x, h)
    love.graphics.pop()
end

function Object:draw(shader, cam)
    shader:send("model", self:get_model_matrix())
    love.graphics.draw(self.mesh)

    drawWireframe(self.mesh, self:get_model_matrix(), cam)
    drawCentreLines(self.mesh, self:get_model_matrix(), cam) --TEMP
end

return Object
