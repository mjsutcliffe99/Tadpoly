local shader = {}

local outline_shader = love.graphics.newShader("care/gfx/shaders/outline.glsl")

function shader.draw_outlined(texture, quad, x, y, r, sx, sy, ox, oy, col)
    sx  = sx  or 1
    sy  = sy  or 1
    ox  = ox  or 0
    oy  = oy  or 0
    r   = r   or 0
    col = col or {1,1,1,1}

    outline_shader:send("textureSize", {texture:getWidth(), texture:getHeight()})
    outline_shader:send("outlineColor", col)

    love.graphics.setShader(outline_shader)
    love.graphics.draw(texture, quad, x, y, r, sx, sy, ox, oy)
    love.graphics.setShader()
    love.graphics.draw(texture, quad, x, y, r, sx, sy, ox, oy)
end

--TEMP:
--[[
function shader.draw(texture, quad, x, y, r, sx, sy, ox, oy, selected_shader, opts)
    sx   = sx   or 1
    sy   = sy   or 1
    ox   = ox   or 0
    oy   = oy   or 0
    r    = r    or 0
    opts = opts or {}

    for key,val in pairs(opts) do
        selected_shader:send(key, val)
    end

    love.graphics.setShader(selected_shader)
    love.graphics.draw(texture, quad, x, y, r, sx, sy, ox, oy)
    love.graphics.setShader()
end]]

return shader