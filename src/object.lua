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
    }, Object)
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

function Object:draw(shader)
    shader:send("model", self:get_model_matrix())
    love.graphics.draw(self.mesh)
end

return Object
