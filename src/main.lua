local Cam = require "cam"
local Cuboid = require "cuboid"
local Quad = require "quad"
local shaders = require "shaders"

local W, H = 1280, 720

local canvas
local depth
local cam
local cube_shader = shaders.cube_shader
local cubeA, cubeB

local tiles = {
    red     = {x = 64*0, y = 0, w = 64, h = 64},
    purple  = {x = 64*1, y = 0, w = 64, h = 64},
    cyan    = {x = 64*2, y = 0, w = 64, h = 64},
    green   = {x = 64*3, y = 0, w = 64, h = 64},
    orange  = {x = 64*4, y = 0, w = 64, h = 64},
    magenta = {x = 64*5, y = 0, w = 64, h = 64},
    window  = {x = 64*0, y = 64,w = 64, h = 64},
    smile   = {x = 64*1, y = 64,w = 64, h = 64}
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    canvas = love.graphics.newCanvas(W, H)
    depth  = love.graphics.newCanvas(W, H, { format = "depth24stencil8", readable = false })

    cam = Cam:new()
    local cube_texture = love.graphics.newImage("cube_texture.png")
    local atlas = love.graphics.newImage("tex.png")

    cubeA = Cuboid:new(atlas, {
        pos = {0,0,0}, pivot = {0,0,0}, rot = {0,0,0}, scale = {2,2,0.25},
        faces = {
            front = tiles.smile,  back  = tiles.window,
            left  = tiles.cyan, right = tiles.green,
            top   = tiles.orange, bottom = tiles.magenta,
        },
    })
    cubeB = Cuboid:new(atlas, {
        pos = {0,0,2}, pivot = {0,0,0}, rot = {0,0,0}, scale = {2,2,0.25},
        faces = {
            front = tiles.window,  back  = tiles.window,
            left  = tiles.cyan, right = tiles.green,
            top   = tiles.orange, bottom = tiles.magenta,
        },
    })
    cubeC = Cuboid:new(atlas, {
        pos = {0,0,4}, pivot = {0,0,0}, rot = {0,0,0}, scale = {2,2,0.25},
        faces = {
            front = tiles.window,  back  = tiles.smile,
            left  = tiles.cyan, right = tiles.green,
            top   = tiles.orange, bottom = tiles.magenta,
        },
    })
end

function love.update(dt)
    love.mouse.setRelativeMode(love.mouse.isDown(2))
    if (love.mouse.isDown(1)) then cubeB.rot[2] = cubeB.rot[2] + 1.5*dt end --TEMP
    cam:update(dt)

    --TEMP:
    love.window.setTitle(cam.x..", "..cam.y..", "..cam.z.." | "..cam.yaw..", "..cam.pitch)
end

function love.draw()
    love.graphics.setCanvas({ canvas, depthstencil = depth })
    love.graphics.clear(0.2,0,0.2,1)
    love.graphics.clear(false, false, true)

    love.graphics.setDepthMode("less", true)
    love.graphics.setFrontFaceWinding("cw")
    love.graphics.setMeshCullMode("back")
    love.graphics.setShader(cube_shader)

    cube_shader:send("aspect", W / H)
    cube_shader:send("cam_pos", {cam.x, cam.y, cam.z})
    cube_shader:send("cam_yaw", cam.yaw)
    cube_shader:send("cam_pitch", cam.pitch)
    cubeA:draw(cube_shader)
    cubeB:draw(cube_shader)
    cubeC:draw(cube_shader)

    love.graphics.setShader()
    love.graphics.setMeshCullMode("none")
    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    love.graphics.draw(canvas)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then cam:mousemoved(dx, dy) end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
