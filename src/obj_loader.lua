local ObjLoader = {}

local function split_words(line)
    local t = {}
    for word in line:gmatch("%S+") do
        table.insert(t, word)
    end
    return t
end

local function parse_face_vertex(s)
    -- supports:
    -- v
    -- v/vt
    -- v//vn
    -- v/vt/vn
    local v, vt, vn = s:match("([^/]*)/?([^/]*)/?([^/]*)")

    return tonumber(v), tonumber(vt), tonumber(vn)
end

local function make_vertex(face_token, positions, uvs, normals)
    local vi, ti, ni = parse_face_vertex(face_token)

    local p = positions[vi]
    local uv = uvs[ti] or {0, 0}
    local n = normals[ni] or {0, 0, 1}

    return {
        p[1], p[2], p[3],  -- position
        uv[1], uv[2],      -- uv
        n[1], n[2], n[3],  -- normal
    }
end

function ObjLoader.load(path)
    local positions = {}
    local uvs = {}
    local normals = {}

    local vertices = {}

    for line in love.filesystem.lines(path) do
        line = line:match("^%s*(.-)%s*$")

        if line ~= "" and line:sub(1, 1) ~= "#" then
            local parts = split_words(line)
            local tag = parts[1]

            if tag == "v" then
                table.insert(positions, {
                    tonumber(parts[2]),
                    -tonumber(parts[3]),
                    tonumber(parts[4])
                })

            elseif tag == "vt" then
                table.insert(uvs, {
                    tonumber(parts[2]),
                    1 - tonumber(parts[3]) -- flip V for LÖVE-style textures
                })

            elseif tag == "vn" then
                table.insert(normals, {
                    tonumber(parts[2]),
                    tonumber(parts[3]),
                    tonumber(parts[4])
                })

            elseif tag == "f" then
                -- supports triangles and quads
                local face = {}
                for i = 2, #parts do
                    table.insert(face, parts[i])
                end

                -- fan triangulation:
                -- quad 1 2 3 4 becomes:
                -- 1 2 3
                -- 1 3 4
                for i = 2, #face - 1 do
                    table.insert(vertices, make_vertex(face[1], positions, uvs, normals))
                    table.insert(vertices, make_vertex(face[i], positions, uvs, normals))
                    table.insert(vertices, make_vertex(face[i + 1], positions, uvs, normals))
                end
            end
        end
    end

    return vertices
end

return ObjLoader