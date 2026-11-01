local mat4 = {}

function mat4.identity()
    return {
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1
    }
end

function mat4.copy(m)
    return {
        m[1],  m[2],  m[3],  m[4],
        m[5],  m[6],  m[7],  m[8],
        m[9],  m[10], m[11], m[12],
        m[13], m[14], m[15], m[16],
    }
end

function mat4.mul(a, b)
    local r = {}

    for row = 0,3 do
        for col = 0,3 do
            local sum = 0

            for k = 0,3 do
                sum = sum +
                    a[row*4 + k + 1] *
                    b[k*4 + col + 1]
            end

            r[row*4 + col + 1] = sum
        end
    end

    return r
end

function mat4.mulVec3(m, v)
    return {
        m[1] * v[1] + m[2] * v[2] + m[3] * v[3],
        m[5] * v[1] + m[6] * v[2] + m[7] * v[3],
        m[9] * v[1] + m[10] * v[2] + m[11] * v[3],
    }
end

function mat4.translate(x,y,z)
    return {
        1,0,0,x,
        0,1,0,y,
        0,0,1,z,
        0,0,0,1
    }
end

function mat4.scale(x,y,z)
    return {
        x,0,0,0,
        0,y,0,0,
        0,0,z,0,
        0,0,0,1
    }
end

function mat4.rotateX(a)
    local c = math.cos(a)
    local s = math.sin(a)

    return {
        1,0,0,0,
        0,c,-s,0,
        0,s,c,0,
        0,0,0,1
    }
end

function mat4.rotateY(a)
    local c = math.cos(a)
    local s = math.sin(a)

    return {
         c,0,s,0,
         0,1,0,0,
        -s,0,c,0,
         0,0,0,1
    }
end

function mat4.rotateZ(a)
    local c = math.cos(a)
    local s = math.sin(a)

    return {
        c,-s,0,0,
        s, c,0,0,
        0, 0,1,0,
        0, 0,0,1
    }
end

function mat4.rotateXYZ(rx, ry, rz)
    return mat4.mul(
        mat4.rotateZ(rz),
        mat4.mul(
            mat4.rotateY(ry),
            mat4.rotateX(rx)
        )
    )
end

function mat4.transpose3(m)
    return {
        m[1], m[5], m[9],  0,
        m[2], m[6], m[10], 0,
        m[3], m[7], m[11], 0,
        0,    0,    0,     1,
    }
end

return mat4