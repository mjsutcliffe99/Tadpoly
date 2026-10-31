local mouse = require "care.input.mouse"

local Menu = {}
Menu.__index = Menu

function Menu:new(x, y, atlas, widgets)
    local self = setmetatable({
        x = x,
        y = y,
        atlas = atlas,
        widgets = {},
        hovered_widget = nil,
        active_widget = nil,
        templates = { -- used for setting menu-specific default widget values (e.g. mymenu.templates.button.label="click me")
            button      = {},
            slider      = {},
            imagebutton = {}
        }
    }, Menu)
    if (widgets) then self:add(widgets) end
    return self
end

function Menu:add(widgets)
    if (widgets == nil) then return
    elseif (type(widgets) ~= "table") then widgets = {widgets} end
    for _,w in ipairs(widgets) do
        w.parent = self
        self.widgets[#self.widgets+1] = w
    end
end

function Menu:update_hovered_widget()
    local mx, my = mouse.get_position() -- TODO: Love uses love.mouse.getPosition(), so maybe I should be using Camel casing for functions?
    local lx, ly = mx-self.x, my-self.y
    local prev_hovered_widget = self.hovered_widget
    self.hovered_widget = nil
    for i = #self.widgets,1,-1 do
        local w = self.widgets[i]
        if (w.visible and w:check_hover(lx, ly)) then
            self.hovered_widget = w
            break
        end
    end
    if (self.hovered_widget and self.hovered_widget ~= prev_hovered_widget and self.hovered_widget.on_hover_enter) then self.hovered_widget:on_hover_enter() end
    if (prev_hovered_widget and self.hovered_widget ~= prev_hovered_widget and prev_hovered_widget.on_hover_exit) then prev_hovered_widget:on_hover_exit() end
end

function Menu:mousepressed(x,y,b)
    if (b ~= 1) then return end -- must be lmb
    if (self.hovered_widget) then -- TODO: isn't this one frame behind since hovered_widget is calculated in update() after mousepressed?
        self.active_widget = self.hovered_widget
        if (self.active_widget.on_press) then self.active_widget:on_press(x-self.x-self.active_widget.x,y-self.y-self.active_widget.y,b) end
    end
end

function Menu:mousereleased(x,y,b)
    if (b ~= 1 or self.active_widget == nil) then return end -- must be lmb and must have an active widget
    if (self.active_widget.on_release) then self.active_widget:on_release(x-self.x-self.active_widget.x,y-self.y-self.active_widget.y,b) end
    if (self.active_widget == self.hovered_widget and self.active_widget.on_click) then self.active_widget:on_click(x-self.x-self.active_widget.x,y-self.active_widget.y-self.y,b) end
    self.active_widget = nil
end

function Menu:mousemoved(x,y,dx,dy)
    if (self.hovered_widget and self.hovered_widget.on_mousemove) then self.hovered_widget:on_mousemove(x-self.x-self.hovered_widget.x,y-self.y-self.hovered_widget.y,dx,dy) end
    if (self.active_widget and self.active_widget.on_dragged) then self.active_widget:on_dragged(x-self.x-self.active_widget.x,y-self.y-self.active_widget.y,dx,dy) end
end

function Menu:wheelmoved(dx,dy)
    if (self.hovered_widget and self.hovered_widget.on_wheelmove) then self.hovered_widget:on_wheelmove(dx,dy) end
end

function Menu:update(dt)
    self:update_hovered_widget()
    if (self.hovered_widget and self.hovered_widget.while_hover) then self.hovered_widget:while_hover() end
    if (self.active_widget and self.active_widget.while_press) then self.active_widget:while_press() end
end

function Menu:draw()
    for _,w in ipairs(self.widgets) do
        w:draw(w==self.hovered_widget,w==self.active_widget)
    end
end

-- e.g. test_menu:set_default_quads("button",{ quad_idle = "btn_idle", pressed = "btn_pressed", disabled = "btn_disabled" })
function Menu:set_default_quads(widget_type, defaults)
    for key,val in pairs(defaults) do
        self.templates[widget_type][key] = self.atlas:get_quad(val)
    end
end

return Menu