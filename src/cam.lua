local Cam = {}
Cam.__index = Cam

function Cam:new(x, y, w, h, images, events)
    local self = setmetatable({
        x = 0, y = 0, z = 5,
        yaw = 0, -- TODO: should be mod 2pi, otherwise it can keep going if you keep spinning
        pitch = 0, -- TODO: objects use rotation matrix but cameras use {yaw,pitch} ??
        speed = 4,
        sensitivity = 0.002
    }, Cam)
    return self
end

function Cam:forward()
    local cp = math.cos(self.pitch)
    return {
        x = math.sin(self.yaw) * cp,
        y = math.sin(self.pitch),
        z = -math.cos(self.yaw) * cp,
    }
end

function Cam:right()
    return {
        x = math.cos(self.yaw),
        y = 0,
        z = math.sin(self.yaw),
    }
end

function Cam:up()
    local f = self:forward()
    local r = self:right()

    return {
        x = r.y * f.z - r.z * f.y,
        y = r.z * f.x - r.x * f.z,
        z = r.x * f.y - r.y * f.x,
    }
end

function Cam:screen_to_ray(mx, my)
    local sw, sh = viewport.w, viewport.h
    local aspect = sw / sh
    local fov = math.rad(70)
    local t = math.tan(fov / 2)

    local ndc_x = (mx / sw) * 2 - 1
    local ndc_y = (my / sh) * 2 - 1

    -- Camera space, matching your shader's projection
    local x = ndc_x * aspect * t
    local y = ndc_y * t
    local z = -1

    -- inverse of shader's pitch rotation
    local cp = math.cos(self.pitch)
    local sp = math.sin(self.pitch)

    local y2 = y * cp - z * sp
    local z2 = y * sp + z * cp
    y, z = y2, z2

    -- inverse of shader's yaw rotation
    local cy = math.cos(self.yaw)
    local sy = math.sin(self.yaw)

    local x2 = x * cy + z * sy
    local z3 = -x * sy + z * cy
    x, z = x2, z3

    local len = math.sqrt(x*x + y*y + z*z)

    return
        {self.x, self.y, self.z},
        {x / len, y / len, z / len}
end

function Cam:world_to_screen(p)
    local sw, sh = viewport.w, viewport.h
    local aspect = sw / sh
    local fov = math.rad(70)
    local t = math.tan(fov / 2)

    -- world relative to Camera
    local x = p[1] - self.x
    local y = p[2] - self.y
    local z = p[3] - self.z

    -- world -> Camera yaw
    local cy = math.cos(-self.yaw)
    local sy = math.sin(-self.yaw)

    local x2 = x * cy + z * sy
    local z2 = -x * sy + z * cy
    x, z = x2, z2

    -- world -> Camera pitch
    local cp = math.cos(-self.pitch)
    local sp = math.sin(-self.pitch)

    local y2 = y * cp - z * sp
    local z3 = y * sp + z * cp
    y, z = y2, z3

    -- Your Camera looks down -Z
    if z >= -0.001 then
        return nil
    end

    local ndc_x = (x / -z) / (aspect * t)
    local ndc_y = (y / -z) / t

    local sx = (ndc_x + 1) * 0.5 * sw
    local sy = (ndc_y + 1) * 0.5 * sh

    return sx, sy, -z
end

return Cam