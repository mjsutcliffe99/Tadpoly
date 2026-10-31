local animsys = require "care.anim.system"

local debug = {}

debug.on = false

--TODO: tidy this up (and make it more moddable, e.g. debug.add("sprite_count","number of sprites: ",spritesystem.getcount))...
function debug.draw()
    if (not debug.on) then return end
    local stats = love.graphics.getStats()
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(1,0,0,0.5)
    love.graphics.rectangle("fill",0,0,640,360)
    love.graphics.setColor(1,1,1,1)
    --love.graphics.setFont()
    love.graphics.print("Framerate: "..love.timer.getFPS(), 10, 10)
    love.graphics.print("Drawcalls: "..stats.drawcalls, 10, 50)
    love.graphics.print("Canvas Switches: "..stats.canvasswitches, 10, 90)
    love.graphics.print("Texture Memory (MB): "..math.floor(stats.texturememory/10000)/100, 10, 130)
    love.graphics.print("# Images: "..stats.images, 10, 170)
    love.graphics.print("# Canvases: "..stats.canvases, 10, 210)
    love.graphics.print("# Fonts: "..stats.fonts, 10, 250)
    love.graphics.print("# anim insts: "..#animsys.instances, 10, 290)
    love.graphics.setColor(r,g,b,a)
end

return debug