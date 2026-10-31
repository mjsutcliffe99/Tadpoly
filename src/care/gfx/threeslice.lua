local Threeslice = {}
Threeslice.__index = Threeslice

function Threeslice:new(atlas,quad_names,is_vertical,max_length)
    local self = setmetatable({
        atlas = atlas,
        quads = {
            t  = atlas:get_quad(quad_names.t),
            c  = atlas:get_quad(quad_names.c),
            b  = atlas:get_quad(quad_names.b)
        } and is_vertical or {
            l  = atlas:get_quad(quad_names.l),
            c  = atlas:get_quad(quad_names.c),
            r  = atlas:get_quad(quad_names.r)
        },
        is_vertical = is_vertical, -- horizontal vs vertical
        breadth     = nil         -- width for vertical threeslices and height for horizontal threeslices
    }, Threeslice)

    -- Determine breadth and (if max_length is known) initialise canvas:
    if (self.is_vertical) then
        local _, _, t_w, _ = self.quads.t:getViewport()
        local _, _, c_w, _ = self.quads.c:getViewport()
        local _, _, b_w, _ = self.quads.b:getViewport()
        self.breadth = math.max(t_w,c_w,b_w)
    else
        local _, _, _, l_h = self.quads.l:getViewport()
        local _, _, _, c_h = self.quads.c:getViewport()
        local _, _, _, r_h = self.quads.r:getViewport()
        self.breadth = math.max(l_h,c_h,r_h)
    end

    return self
end

function Threeslice:render_horizontal(canvas,w,max_length)
    local quads        = self.quads
    local _, _, l_w, _ = quads.l:getViewport()
    local _, _, c_w, _ = quads.c:getViewport()
    local _, _, r_w, _ = quads.r:getViewport()
    local in_w         = w-l_w-r_w -- internal width (border excluded)
    if (in_w<=0) then in_w = 0; w = l_w + r_w end -- enforce minimum width
    local c_w_scale    = in_w/c_w
    
    local prevCanvas = love.graphics.getCanvas()
    if (canvas==nil) then canvas = love.graphics.newCanvas(max_length or w,self.breadth)
    elseif (max_length and max_length~=canvas:getWidth()) then canvas = love.graphics.newCanvas(max_length,self.breadth) end
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.draw(self.atlas.image, quads.l, 0, 0)
    love.graphics.draw(self.atlas.image, quads.c, l_w, 0, 0, c_w_scale, 1)
    love.graphics.draw(self.atlas.image, quads.r, l_w+in_w, 0)
    love.graphics.setCanvas(prevCanvas)
    return canvas
end

function Threeslice:render_vertical(canvas,h,max_length)
    local quads        = self.quads
    local _, _, _, t_h = quads.t:getViewport()
    local _, _, _, c_h = quads.c:getViewport()
    local _, _, _, b_h = quads.b:getViewport()
    local in_h         = h-t_h-b_h -- internal height (border excluded)
    if (in_h<=0) then in_h = 0; h = t_h + b_h end -- enforce minimum height
    local c_h_scale    = in_h/c_h
    
    local prevCanvas = love.graphics.getCanvas()
    if (canvas==nil) then canvas = love.graphics.newCanvas(self.breadth,max_length or h)
    elseif (max_length and max_length~=canvas:getHeight()) then canvas = love.graphics.newCanvas(self.breadth,max_length) end
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.draw(self.atlas.image, quads.t, 0, 0)
    love.graphics.draw(self.atlas.image, quads.c, 0, t_h, 0, 1, c_h_scale)
    love.graphics.draw(self.atlas.image, quads.b, 0, t_h+in_h)
    love.graphics.setCanvas(prevCanvas)
    return canvas
end

function Threeslice:render(canvas,length,max_length)
    if (self.is_vertical) then return self:render_vertical(canvas,length,max_length)
    else                       return self:render_horizontal(canvas,length,max_length)
    end
end

return Threeslice