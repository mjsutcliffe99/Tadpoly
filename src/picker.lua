-- picker.lua
local Picker = {}

local FOV = math.rad(70)

local function vec3(x,y,z) return {x=x,y=y,z=z} end
local function sub(a,b) return vec3(a.x-b.x, a.y-b.y, a.z-b.z) end
local function add(a,b) return vec3(a.x+b.x, a.y+b.y, a.z+b.z) end
local function mul(a,s) return vec3(a.x*s, a.y*s, a.z*s) end
local function dot(a,b) return a.x*b.x + a.y*b.y + a.z*b.z end
local function cross(a,b)
    return vec3(
        a.y*b.z - a.z*b.y,
        a.z*b.x - a.x*b.z,
        a.x*b.y - a.y*b.x
    )
end
local function normalize(v)
    local l = math.sqrt(dot(v,v))
    return vec3(v.x/l, v.y/l, v.z/l)
end

local function fract(x)
    return x - math.floor(x)
end

local function rotate_object(p, r)
    r = r or {0,0,0}

    local cx, sx = math.cos(r[1] or r.x or 0), math.sin(r[1] or r.x or 0)
    p.y, p.z = p.y * cx - p.z * sx, p.y * sx + p.z * cx

    local cy, sy = math.cos(r[2] or r.y or 0), math.sin(r[2] or r.y or 0)
    p.x, p.z = p.x * cy + p.z * sy, -p.x * sy + p.z * cy

    local cz, sz = math.cos(r[3] or r.z or 0), math.sin(r[3] or r.z or 0)
    p.x, p.y = p.x * cz - p.y * sz, p.x * sz + p.y * cz

    return p
end

local function mat4_transform_point(m, v)
    local x, y, z = v.x, v.y, v.z

    return vec3(
        m[1]  * x + m[2]  * y + m[3]  * z + m[4],
        m[5]  * x + m[6]  * y + m[7]  * z + m[8],
        m[9]  * x + m[10] * y + m[11] * z + m[12]
    )
end

local function local_to_world(v, obj)
    return mat4_transform_point(obj.world_matrix or obj.model, v)
end

local function ray_triangle(ro, rd, a, b, c)
    local eps = 1e-8
    local ab = sub(b, a)
    local ac = sub(c, a)
    local p = cross(rd, ac)
    local det = dot(ab, p)

    if math.abs(det) < eps then return nil end

    local inv_det = 1 / det
    local tvec = sub(ro, a)
    local u = dot(tvec, p) * inv_det
    if u < 0 or u > 1 then return nil end

    local q = cross(tvec, ab)
    local v = dot(rd, q) * inv_det
    if v < 0 or u + v > 1 then return nil end

    local t = dot(ac, q) * inv_det
    if t < 0 then return nil end

    return t, u, v
end

local function get_vertex(mesh, i)
    local v = { mesh:getVertex(i) }

    return {
        x = v[1],
        y = v[2],
        z = v[3],

        nx = v[4],
        ny = v[5],
        nz = v[6],

        u = v[7],
        v = v[8],

        face_id = v[9]
    }
end

local face_names = {
    [0] = "front",
    [1] = "back",
    [2] = "left",
    [3] = "right",
    [4] = "top",
    [5] = "bottom"
}

local function atlas_pixel(hit_uv, face_id, obj)
    local name = face_names[face_id] or "bottom"

    local uv_scale   = obj["uv_" .. name] or {1,1}
    local atlas_pos  = obj["atlas_" .. name .. "_pos"] or {0,0}
    local atlas_size = obj["atlas_" .. name .. "_size"] or {1,1}

    local local_u = fract(hit_uv.u * uv_scale[1])
    local local_v = fract(hit_uv.v * uv_scale[2])

    local atlas_u = atlas_pos[1] + local_u * atlas_size[1]
    local atlas_v = atlas_pos[2] + local_v * atlas_size[2]

    local tex_w, tex_h = obj.texture:getDimensions()

    local px = math.floor(atlas_u * tex_w)
    local py = math.floor(atlas_v * tex_h)

    px = math.max(0, math.min(tex_w - 1, px))
    py = math.max(0, math.min(tex_h - 1, py))

    return px, py, atlas_u, atlas_v
end

function Picker.pick(mx, my, camera, objects)
    local sw, sh = love.graphics.getDimensions()
    
    local ro_arr, rd_arr = camera:screen_to_ray(mx, my)
    local ro = vec3(ro_arr[1], ro_arr[2], ro_arr[3])
    local rd = vec3(rd_arr[1], rd_arr[2], rd_arr[3])

    local best = nil

    -- TODO: could find OBJECT in O(1) instead of O(N) by using a hidden colour picker canvas (with a unique colour per object)
    for mesh_index, obj in ipairs(objects) do
        local mesh = obj.mesh
        local vertex_count = mesh:getVertexCount()

        for i = 1, vertex_count, 3 do
            local v1 = get_vertex(mesh, i)
            local v2 = get_vertex(mesh, i + 1)
            local v3 = get_vertex(mesh, i + 2)

            local a = local_to_world(v1, obj)
            local b = local_to_world(v2, obj)
            local c = local_to_world(v3, obj)

            --local n = rotate_object(vec3(v1.nx, v1.ny, v1.nz), obj.rot or {0,0,0})
            --if dot(n, rd) < 0 then
            local t, bu, bv = ray_triangle(ro, rd, a, b, c)
            if t and (not best or t < best.distance) then
                local bw = 1 - bu - bv

                local uv = {
                    u = v1.u * bw + v2.u * bu + v3.u * bv,
                    v = v1.v * bw + v2.v * bu + v3.v * bv
                }

                local face_id = math.floor((v1.face_id or 0) + 0.5)
                local px, py, atlas_u, atlas_v = atlas_pixel(uv, face_id, obj)

                best = {
                    object = obj,
                    mesh = mesh,
                    mesh_index = mesh_index,

                    triangle_index = math.floor((i - 1) / 3) + 1,
                    vertex_start = i,

                    face_id = face_id,
                    face_name = face_names[face_id],

                    distance = t,
                    world_pos = add(ro, mul(rd, t)),

                    uv = uv,
                    atlas_uv = { u = atlas_u, v = atlas_v },
                    pixel = { x = px, y = py }
                }
            end
            --end
        end
    end

    return best
end

return Picker