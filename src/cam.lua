local Cam = {}
Cam.__index = Cam

function Cam:new()
    local self = setmetatable({
        x = 0, y = 0, z = 5,
        yaw = 0,
        pitch = 0,
        speed = 4,
        rot_speed = 2.5,
        sensitivity = 0.002
    }, Cam)
    return self
end

function Cam:clamp_pitch()
    local limit = math.rad(89)
    self.pitch = math.max(-limit, math.min(limit, self.pitch))
end

function Cam:update(dt)
    local speed = self.speed
    if love.keyboard.isDown("lshift") then
        speed = speed * 2
    end

    local forward_x = -math.sin(self.yaw)
    local forward_z = -math.cos(self.yaw)

    local right_x = math.cos(self.yaw)
    local right_z = -math.sin(self.yaw)

    if love.keyboard.isDown("w") then
        self.x = self.x + forward_x * speed * dt
        self.z = self.z + forward_z * speed * dt
    end
    if love.keyboard.isDown("s") then
        self.x = self.x - forward_x * speed * dt
        self.z = self.z - forward_z * speed * dt
    end
    if love.keyboard.isDown("d") then
        self.x = self.x + right_x * speed * dt
        self.z = self.z + right_z * speed * dt
    end
    if love.keyboard.isDown("a") then
        self.x = self.x - right_x * speed * dt
        self.z = self.z - right_z * speed * dt
    end

    if love.keyboard.isDown("space") then self.y = self.y + speed * dt end
    if love.keyboard.isDown("lctrl") then self.y = self.y - speed * dt end

    if love.keyboard.isDown("up")    then self.pitch = self.pitch + self.rot_speed * dt end
    if love.keyboard.isDown("down")  then self.pitch = self.pitch - self.rot_speed * dt end
    if love.keyboard.isDown("left")  then self.yaw   = self.yaw   + self.rot_speed * dt end
    if love.keyboard.isDown("right") then self.yaw   = self.yaw   - self.rot_speed * dt end
    self:clamp_pitch()
end

function Cam:mousemoved(dx, dy)
    self.yaw = self.yaw - dx * self.sensitivity
    self.pitch = self.pitch - dy * self.sensitivity
    self:clamp_pitch()
end

return Cam
