local percbar = require "care.ui.percbar"

local Slider = {}
Slider.__index = Slider

function Slider:new(x,y,length,is_inverted,threeslice_back,threeslice_fore,value,events)
    local self = setmetatable({
        type            = "slider",          -- type of widget
        x               = x,                 -- x-position (local to parent)
        y               = y,                 -- y-position (local to parent)
        scale           = 1,                 -- shrink/stretch the whole widget
        rotation        = 0,                 -- roation in radians
        length          = length,
        --is_vertical     = is_vertical,     -- horizontal vs vertical bar (should match that of the threeslices)
        --is_inverted     = is_inverted,     -- TODO: progress right->left / bottom->top (rather than left->right / top->bottom)
        threeslice_back = threeslice_back,
        threeslice_fore = threeslice_fore,
        percbar = percbar:new(length,is_inverted,threeslice_back,threeslice_fore,value),
        on_changed = nil,       -- function which runs when the slider value is changed
        parent  = nil,          -- the menu to which this button belongs
        visible = true,         -- invisible widgets are ignored
        enabled = true          -- disabled buttons ignore mouse events
    }, Slider)
    self.percbar:render_back()
    self.percbar:render_fore()
    if (events) then self:set_events(events) end
    return self
end

function Slider:set_events(events)
    if (events.on_changed) then self.on_changed = events.on_changed end
end

function Slider:check_hover(x,y)
    --TODO: unlike buttons, this is using the pre-scaled values (i.e. *scale is included here and not in the dimensions of the widget). Be consistent
    if (self.is_vertical) then return (self.enabled and x>=self.x and x<self.x+self.percbar.breadth*self.scale*self.parent.atlas.scale and y>=self.y and y<self.y+self.length*self.scale*self.parent.atlas.scale)
    else return (self.enabled and x>=self.x and x<self.x+self.length*self.scale*self.parent.atlas.scale and y>=self.y and y<self.y+self.percbar.breadth*self.scale*self.parent.atlas.scale)
    end
end

function Slider:on_press(x,y,b)
    self:on_dragged(x,y)
end

function Slider:on_dragged(x,y,dx,dy)
    local scaled_length = self.length*self.scale*self.parent.atlas.scale
    local val = self.is_vertical and y/scaled_length or x/scaled_length
    self:set_value(val)
end

function Slider:set_value(value)
    if (value == self.percbar.value) then return end
    self.percbar:set_value(value)
    if (self.on_changed) then self:on_changed(self) end
end

function Slider:get_value()
    return self.percbar:get_value()
end

function Slider:draw(is_hovered,is_pressed)
    local x,y = math.floor(self.x+self.parent.x), math.floor(self.y+self.parent.y) -- TODO (the floor part should be optional, as a flag in the viewport for pixel art)
    --x,y = x-self.length*(self.scale-1)/2, y-self.h*(self.scale-1)/2 --TEMP!!

    local atlas = self.parent.atlas
    local defaults = self.parent.templates.slider -- parent menu's default slider values
    local quad
    self.percbar:draw(x,y,self.roation,self.scale*atlas.scale,self.scale*atlas.scale)
end

return Slider