local ImageButton = {}
ImageButton.__index = ImageButton

function ImageButton:new(x, y, w, h, images, events)
    local self = setmetatable({
        type = "imagebutton",  -- type of widget
        x = x,                  -- x-position (local to parent)
        y = y,                  -- y-position (local to parent)
        w = w,                  -- width
        h = h,                  -- height
        scale = 1,              -- shrink/stretch the whole widget
        image_scale = 1,        -- scale of the images
        rotation = 0,           -- roation in radians
        img_idle = nil,         -- idle graphic (can be image or canvas or any other drawable)
        img_hovered = nil,      -- hovered graphic  (or nil to use menu default or img_idle)
        img_pressed = nil,      -- pressed graphic  (or nil to use menu default or img_idle)
        img_disabled = nil,     -- disabled graphic (or nil to use menu default or img_idle)
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
    }, ImageButton)
    if (images) then self:set_graphics(images) end
    if (events) then self:set_events(events) end
    return self
end

function ImageButton:set_events(events)
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

function ImageButton:set_graphics(images)
    if (images.idle)     then self.img_idle     = images.idle     end
    if (images.hovered)  then self.img_hovered  = images.hovered  end
    if (images.pressed)  then self.img_pressed  = images.pressed  end
    if (images.disabled) then self.img_disabled = images.disabled end
end

function ImageButton:check_hover(x,y)
    return (self.enabled and x>=self.x and x<self.x+self.w*self.scale and y>=self.y and y<self.y+self.h*self.scale)
end

function ImageButton:draw(is_hovered,is_pressed)
    local x,y = math.floor(self.x+self.parent.x), math.floor(self.y+self.parent.y) -- TODO (the floor part should be optional, as a flag in the viewport for pixel art)
    --x,y = x-self.w*(self.scale-1)/2, y-self.h*(self.scale-1)/2 --TEMP!! (used to scale from centre)

    local defaults = self.parent.templates.button -- parent menu's default imagebutton values
    local img
    if (not self.enabled) then img = self.img_disabled or defaults.img_disabled or self.img_idle or defaults.img_idle
    elseif (is_pressed)   then img = self.img_pressed  or defaults.img_pressed  or self.img_idle or defaults.img_idle
    elseif (is_hovered)   then img = self.img_hovered  or defaults.img_hovered  or self.img_idle or defaults.img_idle
    else                       img = self.img_idle     or defaults.img_idle
    end
    if (img) then love.graphics.draw(img,x,y,0,self.scale*self.image_scale,self.scale*self.image_scale) end

    --TEMP:
    --[[local col = is_hovered and {0,0,1,0.5} or {1,0,0,0.5}
    love.graphics.setColor(col)
    love.graphics.rectangle("fill",x,y,self.w*self.scale,self.h*self.scale)
    love.graphics.setColor(1,1,1,1)]]
end

return ImageButton