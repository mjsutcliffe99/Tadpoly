local Cam = require "cam"
local Cuboid = require "cuboid"
local Quad = require "quad"
local shaders = require "shaders"

local W, H = 1280, 720

local canvas
local depth
local cam
local cube_shader = shaders.cube_shader_noperp
local cubeA, cubeB, cubeC
local skybox, tex_skybox --TEMP
local corrected = false
local drawBars = true

local tiles = {
    red     = {x = 64*0, y = 0, w = 64, h = 64},
    purple  = {x = 64*1, y = 0, w = 64, h = 64},
    cyan    = {x = 64*2, y = 0, w = 64, h = 64},
    green   = {x = 64*3, y = 0, w = 64, h = 64},
    orange  = {x = 64*4, y = 0, w = 64, h = 64},
    magenta = {x = 64*5, y = 0, w = 64, h = 64},
    window_r= {x = 64*0, y = 64,w = 64, h = 64},
    window_g= {x = 64*3, y = 64,w = 64, h = 64},
    smile   = {x = 64*1, y = 128,w = 64, h = 64},
    spine_1 = {x = 0,  y = 128,w = 8, h = 64},
    spine_2 = {x = 8, y = 128,w = 8, h = 64},
    spine_3 = {x = 16, y = 128,w = 8, h = 64},
    --TEMP:
    sky_top    = {x=256,y=0,w=256,h=256},
    sky_bottom = {x=256,y=512,w=256,h=256},
    sky_front  = {x=256,y=256,w=256,h=256},
    sky_back   = {x=256*3,y=256,w=256,h=256},
    sky_left   = {x=0,y=256,w=256,h=256},
    sky_right  = {x=512,y=256,w=256,h=256},
    --TEMP:
    chess = {x = 64*3, y = 128,w = 64, h = 64},
    none  = {x = 64*4, y = 128,w = 64, h = 64}
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(W, H, {
        --[[resizable      = opts.resizable,
        minwidth       = vw,
        minheight      = vh,
        fullscreen     = opts.fullscreen,
        fullscreentype = opts.fullscreen_type,
        vsync          = opts.vsync,
        highdpi        = opts.highdpi]]
    })

    love.graphics.setFont(love.graphics.newFont(24))

    canvas = love.graphics.newCanvas(W, H)
    depth  = love.graphics.newCanvas(W, H, { format = "depth24stencil8", readable = false })

    cam = Cam:new()
    local cube_texture = love.graphics.newImage("cube_texture.png")
    local atlas = love.graphics.newImage("tex.png")

    --[[cubeA = Cuboid:new(atlas, {
        pos = {0,0,0}, pivot = {0,0,0}, rot = {0,0,0}, scale = {2,2,0.25},
        faces = {
            front = tiles.smile,  back  = tiles.window_r,
            left  = tiles.spine_1, right = tiles.spine_1,
            top   = tiles.orange, bottom = tiles.magenta,
        },
    })
    cubeB = Cuboid:new(atlas, {
        pos = {0,0,2}, pivot = {0,0,0}, rot = {0,0,0}, scale = {2,2,0.25},
        faces = {
            front = tiles.window_g,  back  = tiles.window_g,
            left  = tiles.spine_2, right = tiles.spine_2,
            top   = tiles.orange, bottom = tiles.magenta,
        },
    })
    cubeC = Cuboid:new(atlas, {
        pos = {0,0,4}, pivot = {0,0,0}, rot = {0,0,0}, scale = {2,2,0.25},
        faces = {
            front = tiles.chess,  back  = tiles.smile,
            left  = tiles.spine_3, right = tiles.spine_3,
            top   = tiles.orange, bottom = tiles.magenta,
        },
    })
    tex_skybox = love.graphics.newImage("tex_skybox.png") --TEMP
    skybox = Cuboid:new(tex_skybox, {
        pos = {0,0,0}, pivot = {0,0,0}, rot = {0,0,0}, scale = {20,20,20},
        faces = {
            front = tiles.sky_front, back  = tiles.sky_back,
            left  = tiles.sky_left, right = tiles.sky_right,
            top   = tiles.sky_top, bottom = tiles.sky_bottom,
        },
    })]]
    cube = Cuboid:new(atlas, {
        pos = {0,0,0}, pivot = {0,0,0.5}, rot = {0,0,0}, scale = {1,1,1},
        faces = {
            front = tiles.chess, back  = tiles.chess,
            left  = tiles.chess, right = tiles.chess,
            top   = tiles.chess, bottom = tiles.chess,
        },
    })
end

function love.update(dt)
    love.mouse.setRelativeMode(true) --TEMP love.mouse.isDown(2))
    local spd = 1.0
    if (love.mouse.isDown(1)) then cube.rot[2] = cube.rot[2] + spd*dt end --TEMP
    if (love.mouse.isDown(2)) then cube.rot[2] = cube.rot[2] - spd*dt end --TEMP
    cam:update(dt)

    --TEMP:
    --skybox.pos = {cam.x,cam.y,cam.z}
    love.window.setTitle(cam.x..", "..cam.y..", "..cam.z.." | "..cam.yaw..", "..cam.pitch)
end

function love.draw()
    love.graphics.setCanvas({ canvas, depthstencil = depth })
    love.graphics.clear(0.3,0.3,0.3,1)
    love.graphics.clear(false, false, true)

    if (drawBars) then
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0,0,0,0.3)
        local gap = 64/cam.z
        for i=1,20 do
            love.graphics.line(W/2-i*gap,0,W/2-i*gap,H)
            love.graphics.line(W/2+i*gap,0,W/2+i*gap,H)
        end
        love.graphics.setColor(1,1,1,1)
    end

    love.graphics.setDepthMode("less", true)
    love.graphics.setFrontFaceWinding("cw")
    love.graphics.setMeshCullMode("back")
    love.graphics.setShader(cube_shader)

    cube_shader:send("aspect", W / H)
    cube_shader:send("cam_pos", {cam.x, cam.y, cam.z})
    cube_shader:send("cam_yaw", cam.yaw)
    cube_shader:send("cam_pitch", cam.pitch)
    --[[skybox:draw(cube_shader)
    cubeA:draw(cube_shader)
    cubeB:draw(cube_shader)
    cubeC:draw(cube_shader)]]
    cube:draw(cube_shader, cam)

    love.graphics.setShader()
    love.graphics.setMeshCullMode("none")
    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    love.graphics.draw(canvas)
    love.graphics.print("Perspective Correction: "..(corrected and "on" or "off"),10,10)
end

function love.mousemoved(x, y, dx, dy)
    --cam:mousemoved(dx, dy) --if love.mouse.isDown(2) then cam:mousemoved(dx, dy) end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "q" then
        corrected = not corrected
        cube_shader = corrected and shaders.cube_shader or shaders.cube_shader_noperp
    end
end
