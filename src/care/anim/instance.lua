-- Instance of an animation
local Instance = {}
Instance.__index = Instance

function Instance:new(anim,repeats,speed,on_complete)
    local self = setmetatable({
        anim         = anim,                              -- animation reference (of type Anim)
        repeats      = repeats~=nil and repeats or false, -- whether the animation repeats on complete (or is deleted)
        speed        = speed or anim.speed,               -- seconds per frame (overrides anim speed if non-nil)
        frame        = 1,                                 -- current frame number (1-indexed)
        t            = 0,                                 -- frame timer
        x            = 0,                                 -- centred x-position
        y            = 0,                                 -- centred y-position
        on_complete  = on_complete,                       -- function called upon completion of animation (after animation:on_complete)
        on_keyframes = {},                                -- For each frame i, on_keyframe[i] is either nil or a function that triggers on that frame
        dead         = false                              -- animation instance marked for deletion?
    }, Instance)
    return self
end

function Instance:play(x,y)
    self.x,self.y = x,y
    self.dead = false
    self.frame = 1
end

function Instance:set_position(x,y)
    self.x,self.y = x,y
end

function Instance:set_speed(speed)
    self.speed = speed or anim.speed
end

function Instance:finish()
    if (self.anim.on_complete) then self.anim.on_complete() end
    if (self.on_complete) then self.on_complete() end
    if (not self.repeats) then self.dead = true end
    -- TODO: log anim finish here (in verbose debug mode)
end

function Instance:delete()
    self.dead = true
end

function Instance:reset()
    self.dead  = false
    self.frame = 1
    --self.t     = 0
end

function Instance:set_on_keyframe(frame_num,func)
    self.on_keyframes[frame_num] = func
end

-- returns true if proceeding as normal, returns false if animation has ended
function Instance:update(dt)
    if (self.dead or self.frame<1) then return false end

    self.t = self.t + dt
    --self.frame = math.floor((self.t/self.speed))+1
    if (self.t > self.speed) then
        self.frame = self.frame+1
        self.t = self.t - self.speed
        -- keyframe animation:
        if (self.on_keyframes[self.frame]) then self.on_keyframes[self.frame]() end
    end

    -- end of animation cycle:
    if (self.frame>#self.anim.quads) then
        self:finish()
        if (self.repeats) then self.frame = 1 else self.frame = #self.anim.quads; return false end
    end
    return true
end

function Instance:draw()
    if (self.dead or self.frame<1 or self.frame>#self.anim.quads) then return end
    local quad = self.anim.quads[self.frame]
    local _, _, w, h = quad:getViewport()
    love.graphics.draw(self.anim.atlas.image,quad,self.x,self.y,0,self.anim.atlas.scale,self.anim.atlas.scale,math.floor(w/2),math.floor(h/2))
end

return Instance