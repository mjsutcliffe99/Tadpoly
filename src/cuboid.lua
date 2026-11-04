local Object = require "object"

local Cuboid = setmetatable({}, { __index = Object })
Cuboid.__index = Cuboid

local s = 0.5

-- 6 vertices per face: x, y, z, u, v (u/v span the whole face from 0 to 1)
local FACES = {
    front = { -- +Z
        {-s,-s, s, 0,1}, {-s, s, s, 0,0}, { s, s, s, 1,0},
        {-s,-s, s, 0,1}, { s, s, s, 1,0}, { s,-s, s, 1,1},
    },
    back = { -- -Z
        { s,-s,-s, 0,1}, { s, s,-s, 0,0}, {-s, s,-s, 1,0},
        { s,-s,-s, 0,1}, {-s, s,-s, 1,0}, {-s,-s,-s, 1,1},
    },
    left = { -- -X
        {-s,-s,-s, 0,1}, {-s, s,-s, 0,0}, {-s, s, s, 1,0},
        {-s,-s,-s, 0,1}, {-s, s, s, 1,0}, {-s,-s, s, 1,1},
    },
    right = { -- +X
        { s,-s, s, 0,1}, { s, s, s, 0,0}, { s, s,-s, 1,0},
        { s,-s, s, 0,1}, { s, s,-s, 1,0}, { s,-s,-s, 1,1},
    },
    top = { -- +Y
        {-s, s, s, 0,1}, {-s, s,-s, 0,0}, { s, s,-s, 1,0},
        {-s, s, s, 0,1}, { s, s,-s, 1,0}, { s, s, s, 1,1},
    },
    bottom = { -- -Y
        {-s,-s,-s, 0,1}, {-s,-s, s, 0,0}, { s,-s, s, 1,0},
        {-s,-s,-s, 0,1}, { s,-s, s, 1,0}, { s,-s,-s, 1,1},
    },
}

local FACE_ORDER = { "front" }--, "back", "left", "right", "top", "bottom" }

local FORMAT = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
}

-- maps a face's 0..1 uv into the quad's pixel region of the texture (no quad = whole texture)
local function face_vertex(v, quad, texture)
    if not quad then return { v[1], v[2], v[3], v[4], v[5] } end
    local tw, th = texture:getDimensions()
    return { v[1], v[2], v[3], (quad.x + v[4] * quad.w) / tw, (quad.y + v[5] * quad.h) / th }
end

-- props (optional): everything Object:new accepts, plus
--   faces = { front = quad, back = quad, left = quad, right = quad, top = quad, bottom = quad }
-- where each quad is a Quad (pixels) into texture; any face left out shows the whole texture
function Cuboid:new(texture, props)
    props = props or {}
    local faces = props.faces or {}

    local vertices = {}
    for _, face in ipairs(FACE_ORDER) do
        for _, v in ipairs(FACES[face]) do
            vertices[#vertices+1] = face_vertex(v, faces[face], texture)
        end
    end

    local mesh = love.graphics.newMesh(FORMAT, vertices, "triangles", "static")
    mesh:setTexture(texture)

    local self = Object.new(self, mesh, props)
    if not props.name then self.name = "cuboid" end
    self.texture = texture
    return self
end

-- change one face's quad after creation (nil = whole texture)
function Cuboid:set_face(face, quad)
    for i, face_name in ipairs(FACE_ORDER) do
        if face_name == face then
            for j, v in ipairs(FACES[face]) do
                self.mesh:setVertex((i-1)*6 + j, face_vertex(v, quad, self.texture))
            end
            return
        end
    end
    error("unknown cuboid face: " .. tostring(face))
end

return Cuboid
