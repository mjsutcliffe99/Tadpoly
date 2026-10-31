local Button = {}
Button.__index = Button

function Button:new(x, y, w, h, label, events)
    local self = setmetatable({
        type = "button",        -- type of widget
        x = x,                  -- x-position (local to parent)
        y = y,                  -- y-position (local to parent)
        w = w,                  -- width
        h = h,                  -- height
        scale = 1,              -- shrink/stretch the whole widget
        rotation = 0,           -- roation in radians
        label = label,          -- text label
        quad_idle = nil,        -- idle graphic
        quad_hovered = nil,     -- hovered graphic  (or nil to use menu default or quad_idle)
        quad_pressed = nil,     -- pressed graphic  (or nil to use menu default or quad_idle)
        quad_disabled = nil,    -- disabled graphic (or nil to use menu default or quad_idle)
        on_hover_enter = nil,   -- callback or nil
        on_hover_exit = nil,    -- callback or nil
        on_press = nil,         -- callback or nil
        on_release = nil,       -- callback or nil
        on_click = nil,         -- callback or nil
        while_hover = nil,      -- callback or nil
        while_press = nil,      -- callback or nil
        parent = nil,           -- the menu to which this button belongs
        visible = true,         -- invisible widgets are ignored
        enabled = true          -- disabled buttons ignore mouse events
    }, Button)
    if (events) then self:set_events(events) end
    return self
end

function Button:set_events(events)
    if (events.on_hover_enter) then self.on_hover_enter = events.on_hover_enter end
    if (events.on_hover_exit)  then self.on_hover_exit  = events.on_hover_exit  end
    if (events.on_press)       then self.on_press       = events.on_press       end
    if (events.on_release)     then self.on_release     = events.on_release     end
    if (events.on_click)       then self.on_click       = events.on_click       end
    if (events.while_hover)    then self.while_hover    = events.while_hover    end
    if (events.while_press)    then self.while_press    = events.while_press    end
    if (events.on_mousemove)   then self.on_mousemove   = events.on_mousemove   end
    if (events.on_dragged)     then self.on_dragged     = events.on_dragged     end
    if (events.on_wheelmove)   then self.on_wheelmove   = events.on_wheelmove   end
end

function Button:set_graphics(quad_names)
    local atlas = self.parent.atlas
    if (quad_names.idle)     then self.quad_idle     = atlas:get_quad(quad_names.idle)     end
    if (quad_names.hovered)  then self.quad_hovered  = atlas:get_quad(quad_names.hovered)  end
    if (quad_names.pressed)  then self.quad_pressed  = atlas:get_quad(quad_names.pressed)  end
    if (quad_names.disabled) then self.quad_disabled = atlas:get_quad(quad_names.disabled) end
end

function Button:check_hover(x,y)
    return (self.enabled and x>=self.x and x<self.x+self.w and y>=self.y and y<self.y+self.h)
end

function Button:draw(is_hovered,is_pressed)
    local x,y = math.floor(self.x+self.parent.x), math.floor(self.y+self.parent.y) -- TODO (the floor part should be optional, as a flag in the viewport for pixel art)
    x,y = x-self.w*(self.scale-1)/2, y-self.h*(self.scale-1)/2 --TEMP!!

    local atlas = self.parent.atlas
    local defaults = self.parent.templates.button -- parent menu's default button values
    local quad
    if (not self.enabled) then quad = self.quad_disabled or defaults.quad_disabled or self.quad_idle or defaults.quad_idle
    elseif (is_pressed)   then quad = self.quad_pressed  or defaults.quad_pressed  or self.quad_idle or defaults.quad_idle
    elseif (is_hovered)   then quad = self.quad_hovered  or defaults.quad_hovered  or self.quad_idle or defaults.quad_idle
    else                       quad = self.quad_idle     or defaults.quad_idle
    end
    if (atlas and quad) then love.graphics.draw(atlas.image,quad,x,y,0,self.scale*atlas.scale,self.scale*atlas.scale) end

    --TEMP:
    local col = is_hovered and {0,0,1,0.5} or {1,0,0,0.5}
    love.graphics.setColor(col)
    love.graphics.rectangle("fill",x,y,self.w*self.scale,self.h*self.scale)
    love.graphics.printf(self.label,x,y,self.w,"center",0,self.scale,self.scale)
    love.graphics.setColor(1,1,1,1)
end

return Button