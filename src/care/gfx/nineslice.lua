local Nineslice = {}
Nineslice.__index = Nineslice

function Nineslice:new(atlas,quad_names)
    local self = setmetatable({
        atlas = atlas,
        quads = {
            tl = atlas:get_quad(quad_names.tl),
            t  = atlas:get_quad(quad_names.t),
            tr = atlas:get_quad(quad_names.tr),
            l  = atlas:get_quad(quad_names.l),
            c  = atlas:get_quad(quad_names.c),
            r  = atlas:get_quad(quad_names.r),
            bl = atlas:get_quad(quad_names.bl),
            b  = atlas:get_quad(quad_names.b),
            br = atlas:get_quad(quad_names.br)
        }
    }, Nineslice)
    return self
end

function Nineslice:render(w,h)
    local _, _, c_w,   c_h = self.quads.c:getViewport()
    local _, _, tl_w, tl_h = self.quads.tl:getViewport()
    local _, _, br_w, br_h = self.quads.br:getViewport()
    local in_w, in_h       = w-tl_w-br_w, h-tl_h-br_h -- internal dimensions (border excluded)
    local c_w_scale, c_h_scale = in_w/c_w, in_h/c_h
    
    local prevCanvas = love.graphics.getCanvas()
    local c = love.graphics.newCanvas(w,h)
    love.graphics.setCanvas(c)
    love.graphics.clear(0,0,0,0)
    love.graphics.draw(self.atlas.image, self.quads.tl, 0,                 0)
    love.graphics.draw(self.atlas.image, self.quads.t,  tl_w,              0, 0, c_w_scale,         1)
    love.graphics.draw(self.atlas.image, self.quads.tr, tl_w+in_w,         0)
    love.graphics.draw(self.atlas.image, self.quads.l,  0,              tl_h, 0,       1,   c_h_scale)
    love.graphics.draw(self.atlas.image, self.quads.c,  tl_w,           tl_h, 0, c_w_scale, c_h_scale)
    love.graphics.draw(self.atlas.image, self.quads.r,  tl_w+in_w,      tl_h, 0,       1,   c_h_scale)
    love.graphics.draw(self.atlas.image, self.quads.bl, 0,         tl_h+in_h)
    love.graphics.draw(self.atlas.image, self.quads.b,  tl_w,      tl_h+in_h, 0, c_w_scale,         1)
    love.graphics.draw(self.atlas.image, self.quads.br, tl_w+in_w, tl_h+in_h)
    love.graphics.setCanvas(prevCanvas)
    return c
end

return Nineslice