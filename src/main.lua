local Cam = require "cam"
local shaders = require "shaders"

local W, H = 1280, 720

local canvas
local depth
local cam
local cube_shader = shaders.cube_shader
local cube_mesh

local function gen_cube(texture)
    local s = 0.5

    local vertices = {
        -- FRONT (+Z)
        {-s,-s, s, 0,1}, {-s, s, s, 0,0}, { s, s, s, 1,0},
        {-s,-s, s, 0,1}, { s, s, s, 1,0}, { s,-s, s, 1,1},

        -- BACK (-Z)
        { s,-s,-s, 0,1}, { s, s,-s, 0,0}, {-s, s,-s, 1,0},
        { s,-s,-s, 0,1}, {-s, s,-s, 1,0}, {-s,-s,-s, 1,1},

        -- LEFT (-X)
        {-s,-s,-s, 0,1}, {-s, s,-s, 0,0}, {-s, s, s, 1,0},
        {-s,-s,-s, 0,1}, {-s, s, s, 1,0}, {-s,-s, s, 1,1},

        -- RIGHT (+X)
        { s,-s, s, 0,1}, { s, s, s, 0,0}, { s, s,-s, 1,0},
        { s,-s, s, 0,1}, { s, s,-s, 1,0}, { s,-s,-s, 1,1},

        -- TOP (+Y)
        {-s, s, s, 0,1}, {-s, s,-s, 0,0}, { s, s,-s, 1,0},
        {-s, s, s, 0,1}, { s, s,-s, 1,0}, { s, s, s, 1,1},

        -- BOTTOM (-Y)
        {-s,-s,-s, 0,1}, {-s,-s, s, 0,0}, { s,-s, s, 1,0},
        {-s,-s,-s, 0,1}, { s,-s, s, 1,0}, { s,-s,-s, 1,1},
    }

    local format = {
        {"VertexPosition", "float", 3},
        {"VertexTexCoord", "float", 2},
    }

    local mesh = love.graphics.newMesh(format, vertices, "triangles", "static")
    mesh:setTexture(texture)
    return mesh
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    canvas = love.graphics.newCanvas(W, H)
    depth  = love.graphics.newCanvas(W, H, { format = "depth24stencil8", readable = false })

    cam = Cam:new()
    cube_mesh = gen_cube(love.graphics.newImage("cube_texture.png"))
end

function love.update(dt)
    love.mouse.setRelativeMode(love.mouse.isDown(2))
    cam:update(dt)

    --TEMP:
    love.window.setTitle(cam.x..", "..cam.y..", "..cam.z.." | "..cam.yaw..", "..cam.pitch)
end

function love.draw()
    love.graphics.setCanvas({ canvas, depthstencil = depth })
    love.graphics.clear(1,0,1,1)
    love.graphics.clear(false, false, true)

    love.graphics.setDepthMode("less", true)
    love.graphics.setFrontFaceWinding("cw")
    love.graphics.setMeshCullMode("back")
    love.graphics.setShader(cube_shader)

    cube_shader:send("aspect", W / H)
    cube_shader:send("cam_pos", {cam.x, cam.y, cam.z})
    cube_shader:send("cam_yaw", cam.yaw)
    cube_shader:send("cam_pitch", cam.pitch)
    love.graphics.draw(cube_mesh)

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
