local viewport = require "care.gfx.viewport"

local mouse = {}

mouse.x = 0
mouse.y = 0
mouse.atlas = nil
mouse.cursor = nil
mouse.hotspot = {x=0,y=0}
mouse.visible = true -- Virtual mouse visibility (use love.mouse.setVisible to set the "real" mouse visibility)

function mouse.moved(x,y,dx,dy) -- update cached mouse position
    mouse.x = math.floor((x - viewport.offset_x) / viewport.scale)
    mouse.y = math.floor((y - viewport.offset_y) / viewport.scale)
end

function mouse.get_position()
    return mouse.x,mouse.y
end

function mouse.set_cursor(atlas,quad_name,hotx,hoty)
    mouse.atlas  = atlas
    mouse.cursor = atlas:get_quad(quad_name)
    if (hotx and hoty) then mouse.hotspot = {x=hotx,y=hoty} end
end

function mouse.draw()
    if (mouse.atlas and mouse.cursor and mouse.visible) then love.graphics.draw(mouse.atlas.image,mouse.cursor,mouse.x-mouse.hotspot.x,mouse.y-mouse.hotspot.y) end
end

--TEMP:
function mouse.is_inside_rect(x, y, w, h, r, sx, sy, ox, oy)
    local sx = sx or 1
    local sy = sy or 1
    local ox = ox or 0
    local oy = oy or 0
    local mx, my = mouse.get_position()

    if (ox==0 and oy==0) then return (mx>=x and mx<=x+w*sx and my>=0 and my<=y+h*sy) end

    -- move mouse into object-centered coordinates
    local dx = mx - x
    local dy = my - y

    -- undo rotation
    local cosr = math.cos(-r)
    local sinr = math.sin(-r)
    local localX = dx*cosr - dy*sinr
    local localY = dx*sinr + dy*cosr

    -- undo scale
    local px = (localX/sx) + ox
    local py = (localY/sy) + oy

    return (px>=0 and px<=w and py>=0 and py<=h)
end

return mouse