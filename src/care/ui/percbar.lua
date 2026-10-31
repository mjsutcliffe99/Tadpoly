-- Percentage bar

local Percbar = {}
Percbar.__index = Percbar

function Percbar:new(length,is_inverted,threeslice_back,threeslice_fore,value)
    local self = setmetatable({
        length          = length,
        breadth         = math.max(threeslice_back.breadth,threeslice_fore.breadth),
        --is_vertical     = is_vertical,     -- horizontal vs vertical bar (should match that of the threeslices)
        --is_inverted     = is_inverted,     -- TODO: progress right->left / bottom->top (rather than left->right / top->bottom)
        threeslice_back = threeslice_back,
        threeslice_fore = threeslice_fore,
        canvas_back     = nil,
        canvas_fore     = nil,
        value           = value or 0.5
    }, Percbar)
    self:render_back()
    self:render_fore()
    return self
end

function Percbar:render_back() -- Render background layer; Generally only needs to be rendered once (unless you want to resize the whole frame)
    self.canvas_back = self.threeslice_back:render(self.canvas_back,self.length,self.length)
    return self.canvas_back
end

function Percbar:render_fore() -- Render foreground layer; Only needs to be re-rendered when percbar value is changed
    self.canvas_fore = self.threeslice_fore:render(self.canvas_fore,self.length*self.value,self.length)
    return self.canvas_fore
end

function Percbar:set_value(value)
    if (value == self.value) then return                                    -- only re-render if value has changed
    elseif (value < 0) then value = 0 elseif (value > 1) then value = 1 end -- enforce 0<=value<=1
    self.value = value
    self:render_fore()
end

function Percbar:get_value()
    return self.value
end

function Percbar:draw(x,y,r,sx,sy,ox,oy,kx,ky)
    x = x or 0
    y = y or 0
    sx = sx or 1
    sy = sy or 1
    ox = ox or 0
    oy = oy or 0
    kx = kx or 0
    ky = ky or 0
    love.graphics.draw(self.canvas_back,x,y,r,sx,sy,ox,oy,kx,ky)
    if (self.value > 0) then love.graphics.draw(self.canvas_fore,x,y,r,sx,sy,ox,oy,kx,ky) end
end

return Percbar