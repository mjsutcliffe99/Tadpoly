local care = require "care"
local shaders = require "shaders"
local flux = require "care.third_party.flux"
local moonshine = require "care.third_party.moonshine"
local ObjLoader = require "obj_loader"
local picker = require "picker"
local camera_system = require "cam"
local mat4 = require "mat4"
local water = require "water"
local portal = require "portal"
local terrain = require "terrain"

viewport = {
    w = 1280,  -- the width of the canvas
    h = 720,   -- the height of the canvas
    scale = 1, -- upscaling required to fill the real screen
    canvas = nil,
    depth = nil,
    cam = nil,

    x = 0,
    y = 0,
    widget = nil,
    mx = -1,
    my = -1,

    on_mousemove = nil,
    on_press     = nil,
    on_release   = nil,

    hover_data = nil, -- nil or data returned from picker.pick
    selected_obj = nil,

    crt_on = false --TODO: moving scanlines as in Pixynery
}

local objects = {}

local cube_shader
local texture
local face_canvas
local billboard_mesh

--care.debug.on = true
local mouse_freed = true

local EditorMode = {
    TRANSLATE = 1,
    SCALE     = 2,
    ROTATE    = 3
}

local tex_atlas
local textures = {
    pink         = { x=64*4, y=64*2, w=64, h=64 },
    brick_red    = { x=64*0, y=128, w=64, h=64 },
    brick_blue   = { x=64*1, y=128, w=64, h=64 },
    brick_cyan   = { x=64*2, y=128, w=64, h=64 },
    brick_green  = { x=64*3, y=128, w=64, h=64 },
    brick_orange = { x=64*4, y=64, w=64, h=64 },
    brick_purple = { x=64*5, y=64, w=64, h=64 },
}

local gizmo = {
    visible = false,
    components = {
        nil, -- translation
        nil, -- scaling
        nil  -- rotation
    },
    is_relative = false -- relative or absolute orientation of the gizmo
}

function make_billboard_mesh()
    local format = {
        {"VertexPosition", "float", 3},
        {"VertexNormal",   "float", 3},
        {"VertexTexCoord", "float", 2},
    }

    local vertices = {
        {0,0,0,  0,0,1,  0,0},
        {0,0,0,  0,0,1,  1,0},
        {0,0,0,  0,0,1,  1,1},

        {0,0,0,  0,0,1,  0,0},
        {0,0,0,  0,0,1,  1,1},
        {0,0,0,  0,0,1,  0,1},
    }

    return love.graphics.newMesh(format, vertices, "triangles", "dynamic")
end

-- TODO (currently this generates a new mesh every time and allows different textures and hence disallows instancing)
function gen_cuboid(texture)
    local u_scale = 1
    local v_scale = 1

    local w = 1
    local h = 1
    local d = 1

    local x0, y0, z0 = 0, 0, 0
    local x1, y1, z1 = w, h, d

    local vertices = { --TODO, use fan mode or whatever to only need 4 verts per face rather than 6
        -- FRONT (+Z)
        {0,0,d, 0,0,1, 0*u_scale, 0*v_scale, 0},
        {0,h,d, 0,0,1, 0*u_scale, h*v_scale, 0},
        {w,h,d, 0,0,1, w*u_scale, h*v_scale, 0},
        {0,0,d, 0,0,1, 0*u_scale, 0*v_scale, 0},
        {w,h,d, 0,0,1, w*u_scale, h*v_scale, 0},
        {w,0,d, 0,0,1, w*u_scale, 0*v_scale, 0},

        -- BACK (-Z)
        {w,0,0, 0,0,-1, 0*u_scale, 0*v_scale, 1},
        {w,h,0, 0,0,-1, 0*u_scale, h*v_scale, 1},
        {0,h,0, 0,0,-1, w*u_scale, h*v_scale, 1},
        {w,0,0, 0,0,-1, 0*u_scale, 0*v_scale, 1},
        {0,h,0, 0,0,-1, w*u_scale, h*v_scale, 1},
        {0,0,0, 0,0,-1, w*u_scale, 0*v_scale, 1},

        -- LEFT (-X)
        {0,0,0, -1,0,0, 0*u_scale, 0*v_scale, 2},
        {0,h,0, -1,0,0, 0*u_scale, h*v_scale, 2},
        {0,h,d, -1,0,0, d*u_scale, h*v_scale, 2},
        {0,0,0, -1,0,0, 0*u_scale, 0*v_scale, 2},
        {0,h,d, -1,0,0, d*u_scale, h*v_scale, 2},
        {0,0,d, -1,0,0, d*u_scale, 0*v_scale, 2},

        -- RIGHT (+X)
        {w,0,d, 1,0,0, 0*u_scale, 0*v_scale, 3},
        {w,h,d, 1,0,0, 0*u_scale, h*v_scale, 3},
        {w,h,0, 1,0,0, d*u_scale, h*v_scale, 3},
        {w,0,d, 1,0,0, 0*u_scale, 0*v_scale, 3},
        {w,h,0, 1,0,0, d*u_scale, h*v_scale, 3},
        {w,0,0, 1,0,0, d*u_scale, 0*v_scale, 3},

        -- TOP (+Y)
        {0,h,d, 0,1,0, 0*u_scale, 0*v_scale, 4},
        {0,h,0, 0,1,0, 0*u_scale, d*v_scale, 4},
        {w,h,0, 0,1,0, w*u_scale, d*v_scale, 4},
        {0,h,d, 0,1,0, 0*u_scale, 0*v_scale, 4},
        {w,h,0, 0,1,0, w*u_scale, d*v_scale, 4},
        {w,h,d, 0,1,0, w*u_scale, 0*v_scale, 4},

        -- BOTTOM (-Y)
        {0,0,0, 0,-1,0, 0*u_scale, 0*v_scale, 5},
        {0,0,d, 0,-1,0, 0*u_scale, d*v_scale, 5},
        {w,0,d, 0,-1,0, w*u_scale, d*v_scale, 5},
        {0,0,0, 0,-1,0, 0*u_scale, 0*v_scale, 5},
        {w,0,d, 0,-1,0, w*u_scale, d*v_scale, 5},
        {w,0,0, 0,-1,0, w*u_scale, 0*v_scale, 5},
    }

    local format = {
        {"VertexPosition", "float", 3},
        {"VertexNormal",   "float", 3},
        {"VertexTexCoord", "float", 2},
        {"FaceID",         "float", 1},
    }

    local mesh = love.graphics.newMesh(format, vertices, "triangles", "static")
    mesh:setTexture(texture)

    
    local atlas_w, atlas_h = tex_atlas:getDimensions()
    --
    local triangles = {}
    for i = 1, #vertices, 3 do
        table.insert(triangles, {i, i+1, i+2})
    end
    local obj = {
        name = "wall",
        mesh = mesh,
        vertices = vertices,
        triangles = triangles,
        texture = texture,
        pos = {0,0,0},
        rot = mat4.identity(),
        scale = {1,1,1},
        pivot = {0,0,0},
        uv_scale = {
            {1,1}, -- front
            {1,1}, -- back
            {1,1}, -- left
            {1,1}, -- right
            {1,1}, -- top
            {1,1}  -- bottom
        },
        uv_offset = {
            {0,0}, -- front
            {0,0}, -- back
            {0,0}, -- left
            {0,0}, -- right
            {0,0}, -- top
            {0,0}  -- bottom
        },
        tex_coords = {
            {textures["brick_red"].x    / atlas_w, textures["brick_red"].y    / atlas_h}, --TEMP
            {textures["brick_blue"].x   / atlas_w, textures["brick_blue"].y   / atlas_h},
            {textures["brick_cyan"].x   / atlas_w, textures["brick_cyan"].y   / atlas_h},
            {textures["brick_green"].x  / atlas_w, textures["brick_green"].y  / atlas_h},
            {textures["brick_orange"].x / atlas_w, textures["brick_orange"].y / atlas_h},
            {textures["brick_purple"].x / atlas_w, textures["brick_purple"].y / atlas_h}
        },
        tex_sizes = {
            {textures["brick_red"].w    / atlas_w, textures["brick_red"].h    / atlas_h}, --TEMP
            {textures["brick_blue"].w   / atlas_w, textures["brick_blue"].h   / atlas_h},
            {textures["brick_cyan"].w   / atlas_w, textures["brick_cyan"].h   / atlas_h},
            {textures["brick_green"].w  / atlas_w, textures["brick_green"].h  / atlas_h},
            {textures["brick_orange"].w / atlas_w, textures["brick_orange"].h / atlas_h},
            {textures["brick_purple"].w / atlas_w, textures["brick_purple"].h / atlas_h}
        },
        local_matrix = mat4.identity(),
        world_matrix = mat4.identity()
    }
    --

    return obj
end

function import_obj(mesh_path,tex_path)
    local vertices = ObjLoader.load(mesh_path)

    local format = {
        {"VertexPosition", "float", 3},
        {"VertexTexCoord", "float", 2},
        {"VertexNormal",   "float", 3},
    }

    local mesh = love.graphics.newMesh(format, vertices, "triangles")
    local texture = love.graphics.newImage(tex_path)
    texture:setFilter("nearest", "nearest")
    texture:setWrap("repeat", "repeat")
    mesh:setTexture(texture)
    return mesh
end

function love.load()
    love.graphics.setDefaultFilter("nearest","nearest")
    love.window.setMode(1280, 720, {
        resizable      = false,
        minwidth       = 1280,
        minheight      = 720,
        fullscreen     = false,
        fullscreentype = "desktop",
        vsync          = 1,
        highdpi        = false,
        depth          = 24
    })
    love.mouse.setRelativeMode(not mouse_freed)
    viewport.canvas = love.graphics.newCanvas(viewport.w, viewport.h)
    viewport.depth  = love.graphics.newCanvas(viewport.w, viewport.h, {
        format = "depth24stencil8",
        readable = false,
    })

    viewport.cam = camera_system:new()

    local img_atlas = love.graphics.newImage("tex.png")
    local atlas_w, atlas_h = img_atlas:getDimensions()
    tex_atlas = love.graphics.newCanvas(atlas_w, atlas_h)
    local prevCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(tex_atlas)
    --love.graphics.clear(1,0,1,1)
    love.graphics.draw(img_atlas)
    love.graphics.setCanvas(prevCanvas)

    -- INIT GIZMOS
    local positions = {
        {2,0,0}, -- x translation
        {4,0,0}, -- x scaling
        {6,0,0}, -- x roation
        {0,2,0}, -- y translation
        {0,4,0}, -- y scaling
        {0,6,0}, -- y rotation
        {0,0,2}, -- z translation
        {0,0,4}, -- z scaling
        {0,0,6}  -- z rotation
    }
    local dirs = {
        {1,0,0}, -- x
        {0,1,0}, -- y
        {0,0,1}  -- z
    }
    for i=1,9 do
        local component = gen_cuboid(tex_atlas)
        component.pos  = positions[i]
        component.mode = (i-1)%3 + 1
        component.dir  = dirs[math.floor((i-1)/3)+1]
        component.tex_coords = {
            {textures["pink"].x    / atlas_w, textures["pink"].y    / atlas_h}, --TEMP
            {textures["pink"].x   / atlas_w, textures["pink"].y   / atlas_h},
            {textures["pink"].x   / atlas_w, textures["pink"].y   / atlas_h},
            {textures["pink"].x  / atlas_w, textures["pink"].y  / atlas_h},
            {textures["pink"].x / atlas_w, textures["pink"].y / atlas_h},
            {textures["pink"].x / atlas_w, textures["pink"].y / atlas_h}
        }
        component.name = "Gizmo"
        gizmo.components[i] = component
    end
    --

    screen_effect = moonshine(moonshine.effects.scanlines).chain(moonshine.effects.crt).chain(moonshine.effects.chromasep)
    screen_effect.parameters = {
        chromasep = {angle = 0.5, radius = 4},
        scanlines = {thickness = 0.2, width = 4, opacity = 0.25}
    }

    --
    test_menu = care.ui.menu:new(0,0,test_atlas,{
        care.ui.imagebutton:new(viewport.x,viewport.y,viewport.w,viewport.h,nil,{
            on_mousemove = function(imgbtn,x,y,dx,dy) viewport.on_mousemove(x,y,dx,dy) end,
            on_press = function(imgbtn,x,y,b) viewport.on_press(x,y,b) end,
            on_release = function(imgbtn,x,y,b) viewport.on_release(x,y,b) end
        })
    })
    viewport.widget = test_menu.widgets[1] --TEMP
    viewport.widget.scale = viewport.scale
    viewport.widget:set_graphics({ idle = viewport.canvas })
    --

    sky_img = love.graphics.newImage("skybox.png")
    sky_img:setFilter("nearest", "nearest")
    sky_img:setWrap("clamp", "clamp")
    sky_mesh = make_skybox_mesh(1)
    sky_mesh:setTexture(sky_img)
    sky_shader = shaders.sky_shader
    
    texture = love.graphics.newImage("cube_textureB.png")
    texture:setFilter("nearest", "nearest")
    texture:setWrap("repeat", "repeat")

    face_canvas = love.graphics.newCanvas(320,180)
    face_canvas:setFilter("nearest", "nearest")
    face_canvas:setWrap("repeat", "repeat")
    love.graphics.setCanvas(face_canvas)
    love.graphics.clear(1,0,0,0.5)
    love.graphics.setCanvas()

    ----------

    portal_blue_canvas = love.graphics.newCanvas(1280,720)
    portal_blue_canvas_depth = love.graphics.newCanvas(1280,720, {
        format = "depth24stencil8",
        readable = false,
    })
    portal_orange_canvas = love.graphics.newCanvas(1280,720)
    portal_orange_canvas_depth = love.graphics.newCanvas(1280,720, {
        format = "depth24stencil8",
        readable = false,
    })

    --TEMP:
    love.graphics.setCanvas(portal_blue_canvas)
    love.graphics.clear(0,0,1,1)
    love.graphics.setCanvas(portal_orange_canvas)
    love.graphics.clear(1,0,0,1)
    love.graphics.setCanvas()
    --

    portal_blue   = gen_cuboid(portal_orange_canvas)
    portal_orange = gen_cuboid(portal_blue_canvas)

    portal_blue.canvas   = portal_blue_canvas
    portal_orange.canvas = portal_orange_canvas
    portal_blue.canvas_depth   = portal_blue_canvas_depth
    portal_orange.canvas_depth = portal_orange_canvas_depth

    portal_blue.tex_coords   = {{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}}
    portal_blue.tex_sizes    = {{1,1},{1,1},{1,1},{1,1},{1,1},{1,1}}
    portal_orange.tex_coords = {{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}}
    portal_orange.tex_sizes  = {{1,1},{1,1},{1,1},{1,1},{1,1},{1,1}}

    portal_blue.pos   = {-2,-3,4}
    portal_orange.pos = { 2,-3,0}

    portal_blue.scale   = {3.2,1.8,0.1}
    portal_orange.scale = {3.2,1.8,0.1}

    portal_blue.cam = camera_system:new()
    portal_orange.cam = camera_system:new()

    ----------

    tex_enemy = love.graphics.newImage("enemy.png")
    tex_enemy:setFilter("nearest", "nearest")
    billboard_mesh = make_billboard_mesh()

    cube_obj = gen_cuboid(tex_atlas) --texture
    cube_obj.pos = {0,1,0}
    cube_objB = gen_cuboid(tex_atlas)
    -- TODO: gen_cuboid currently generates a new mesh every time
    cube_objB.scale = {5,1,0.25} --TEMP
    cube_objB.pivot = {0.5,0.5,0.5}
    cube_objB.name = "big wall"
    --[[cube_objB.uv = {
        {5,1},    -- front
        {5,1},    -- back
        {0.25,1}, -- left
        {0.25,1}, -- right
        {5,0.25}, -- top
        {5,0.25}  -- bottom
    }]]

    car = import_obj("car4.obj","car4.png")

    local grass_tex = love.graphics.newImage("grass.png") --TEMP
    terrain_obj = terrain.generate(5,5,5,5,grass_tex)
    terrain.raise_vertex(terrain_obj, 2,2, -3)

    objects[#objects+1] = cube_obj
    objects[#objects+1] = cube_objB
    --objects[#objects+1] = car
    objects[#objects+1] = portal_blue
    objects[#objects+1] = portal_orange

    local water_tex = love.graphics.newImage("water.png") --TEMP
    water_tex:setWrap("repeat","repeat")
    water_tex:setFilter("nearest","nearest")
    ocean_mesh = water.make_water_grid(100, 100, 300, 300, water_tex)

    mesh_shader = shaders.mesh_shader
    cube_shader = shaders.cube_shader
end

function love.update(dt)
    flux.update(dt)

    local speed = viewport.cam.speed
    if love.keyboard.isDown("lshift") then
        speed = speed * 2
    end

    care.debug.on = false
    if love.keyboard.isDown("c") then
        care.debug.on = true
    end

    --TEMP:
    mouse_freed = not love.mouse.isDown(2)
    if not editor.dragging then
        love.mouse.setRelativeMode(not mouse_freed)
    end

    ----
    local move_speed = 2.5
    local rot_speed = 2.5
    local scale_speed = 2.5
    local invert = love.keyboard.isDown("lalt") and -1 or 1
    local scale_factor = scale_speed ^ (dt * invert)
    if love.keyboard.isDown("kp1") then cube_objB.pos[1]   = cube_objB.pos[1]   + move_speed*dt*invert end
    if love.keyboard.isDown("kp2") then cube_objB.pos[2]   = cube_objB.pos[2]   + move_speed*dt*invert end
    if love.keyboard.isDown("kp3") then cube_objB.pos[3]   = cube_objB.pos[3]   + move_speed*dt*invert end
    if love.keyboard.isDown("kp4") then cube_objB.scale[1] = cube_objB.scale[1]*scale_factor end
    if love.keyboard.isDown("kp5") then cube_objB.scale[2] = cube_objB.scale[2]*scale_factor end
    if love.keyboard.isDown("kp6") then cube_objB.scale[3] = cube_objB.scale[3]*scale_factor end
    if love.keyboard.isDown("kp7") then cube_objB.rot = mat4.mul(cube_objB.rot, mat4.rotateX(rot_speed*dt*invert)) end
    if love.keyboard.isDown("kp8") then cube_objB.rot = mat4.mul(cube_objB.rot, mat4.rotateY(rot_speed*dt*invert)) end
    if love.keyboard.isDown("kp9") then cube_objB.rot = mat4.mul(cube_objB.rot, mat4.rotateZ(rot_speed*dt*invert)) end
    local face_id = 1 --TEMP
    cube_objB.uv_scale[face_id] = {cube_objB.scale[1],cube_objB.scale[2]} --TEMP
    cube_objB.uv_offset[face_id] = { --TEMP
        -cube_objB.pivot[1] * (cube_objB.uv_scale[face_id][1] - 1),
        -cube_objB.pivot[2] * (cube_objB.uv_scale[face_id][2] - 1),
    }
    ----

    local forward_x = -math.sin(viewport.cam.yaw)
    local forward_z = -math.cos(viewport.cam.yaw)

    local right_x = math.cos(viewport.cam.yaw)
    local right_z = -math.sin(viewport.cam.yaw)

    if love.keyboard.isDown("w") then
        viewport.cam.x = viewport.cam.x + forward_x * speed * dt
        viewport.cam.z = viewport.cam.z + forward_z * speed * dt
    end

    if love.keyboard.isDown("s") then
        viewport.cam.x = viewport.cam.x - forward_x * speed * dt
        viewport.cam.z = viewport.cam.z - forward_z * speed * dt
    end

    if love.keyboard.isDown("d") then
        viewport.cam.x = viewport.cam.x + right_x * speed * dt
        viewport.cam.z = viewport.cam.z + right_z * speed * dt
    end

    if love.keyboard.isDown("a") then
        viewport.cam.x = viewport.cam.x - right_x * speed * dt
        viewport.cam.z = viewport.cam.z - right_z * speed * dt
    end

    local limit = math.rad(89)
    if love.keyboard.isDown("up") then
        viewport.cam.pitch = viewport.cam.pitch - rot_speed * dt
        viewport.cam.pitch = math.max(-limit, math.min(limit, viewport.cam.pitch))
    end
    if love.keyboard.isDown("down") then
        viewport.cam.pitch = viewport.cam.pitch + rot_speed * dt
        viewport.cam.pitch = math.max(-limit, math.min(limit, viewport.cam.pitch))
    end
    if love.keyboard.isDown("left") then
        viewport.cam.yaw = viewport.cam.yaw + rot_speed * dt
    end
    if love.keyboard.isDown("right") then
        viewport.cam.yaw = viewport.cam.yaw - rot_speed * dt
    end

    if love.keyboard.isDown("space") then
        viewport.cam.y = viewport.cam.y - speed * dt
    end

    if love.keyboard.isDown("lctrl") then
        viewport.cam.y = viewport.cam.y + speed * dt
    end

    --love.window.setTitle("Cam: "..(math.floor(cam.x*100)/100)..", "..(math.floor(cam.y*100)/100)..", "..(math.floor(cam.z*100)/100)) --TEMP

    --------------------------------

    test_menu:update(dt)

    ------

    t = (t or 0) + dt

    love.graphics.setCanvas(face_canvas)
    --love.graphics.clear(0, 1, 0, 0.5)
    --[[love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 32 + math.cos(t) * 16, 32, 8)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Hello", 8, 8)
    love.graphics.setColor(1, 1, 1, 1)]]
    love.graphics.draw(viewport.canvas, 0, 0, 0, 320/viewport.w, 180/viewport.h)
    love.graphics.setCanvas()

    water_time = (water_time or 0) + dt

    --

    -- PORTALS:
    portal.update_portal_cameras(viewport.cam,portal_blue,portal_orange)
    draw_world(portal_orange.cam,portal_orange.canvas,portal_orange.canvas_depth)
    draw_world(portal_blue.cam,portal_blue.canvas,portal_blue.canvas_depth)
    love.graphics.setCanvas()

    --

    love.window.setTitle(viewport.cam.x..", "..viewport.cam.y..", "..viewport.cam.z.." | "..viewport.cam.yaw..", "..viewport.cam.pitch)
end

function draw_world(cam,canvas,canvas_depth)
    love.graphics.setCanvas({
        canvas,
        depthstencil = canvas_depth,
    })
    local w, h = viewport.w, viewport.h
    love.graphics.clear(1,0,1,1)
    love.graphics.clear(false, false, true)

    -- draw skybox:
    love.graphics.setShader(sky_shader)
    love.graphics.setDepthMode("always", false) -- commenting out this line can fake reduced render distance
    love.graphics.setFrontFaceWinding("cw")
    sky_shader:send("aspect", w / h)
    sky_shader:send("cam_yaw", cam.yaw)
    sky_shader:send("cam_pitch", cam.pitch)
    sky_shader:send("sky_size", 10.0)
    love.graphics.draw(sky_mesh)
    --

    love.graphics.setDepthMode("less", true)
    love.graphics.setFrontFaceWinding("ccw")
    love.graphics.setMeshCullMode("back")
    love.graphics.setShader(cube_shader)

    --[[for _, root in ipairs(scene_roots) do
        update_world_matrix(root, nil)
    end]]

    cube_shader:send("aspect", w / h)
    cube_shader:send("cam_pos", {cam.x, cam.y, cam.z})
    cube_shader:send("cam_yaw", cam.yaw)
    cube_shader:send("cam_pitch", cam.pitch)
    cube_shader:send("light_dir", {1, 0, 0})
    cube_shader:send("lighting_strength", 1.0)
    cube_shader:send("ambient", 1.0)--0.25)
    
    for i,obj in ipairs(objects) do
        update_world_matrix(obj, nil) --TEMP (need only change this when object is transformed)
        cube_shader:send("uv_scales",
            obj.uv_scale[1],
            obj.uv_scale[2],
            obj.uv_scale[3],
            obj.uv_scale[4],
            obj.uv_scale[5],
            obj.uv_scale[6]
        )
        cube_shader:send("uv_offsets",
            obj.uv_offset[1],
            obj.uv_offset[2],
            obj.uv_offset[3],
            obj.uv_offset[4],
            obj.uv_offset[5],
            obj.uv_offset[6]
        )
        cube_shader:send("tex_coords",
            obj.tex_coords[1],
            obj.tex_coords[2],
            obj.tex_coords[3],
            obj.tex_coords[4],
            obj.tex_coords[5],
            obj.tex_coords[6]
        )
        cube_shader:send("tex_sizes",
            obj.tex_sizes[1],
            obj.tex_sizes[2],
            obj.tex_sizes[3],
            obj.tex_sizes[4],
            obj.tex_sizes[5],
            obj.tex_sizes[6]
        )
        cube_shader:send("model", obj.world_matrix)
        love.graphics.draw(obj.mesh)
    end

    --

    love.graphics.setShader(mesh_shader)
    
    mesh_shader:send("aspect", w / h)
    mesh_shader:send("cam_pos", {cam.x, cam.y, cam.z})
    mesh_shader:send("cam_yaw", cam.yaw)
    mesh_shader:send("cam_pitch", cam.pitch)
    mesh_shader:send("light_dir", {1, 0, 0})
    mesh_shader:send("lighting_strength", 1.0)
    mesh_shader:send("ambient", 1.0)--0.25)
    mesh_shader:send("uvOffset", {0,0})

    mesh_shader:send("obj_pos", {1,0,2})
    mesh_shader:send("obj_scale", {0.25,0.25,0.25})
    mesh_shader:send("obj_rot", {0,0,0})
    --mesh_shader:send("uv_scale", {1,1})
    love.graphics.draw(car)
    mesh_shader:send("obj_pos", {0,0,0})
    mesh_shader:send("obj_scale", {1,1,1})
    mesh_shader:send("obj_rot", {0,0,0})

    love.graphics.draw(terrain_obj.mesh)

    draw_billboard(0, 0, 1.5, tex_enemy, 1, 1, cam)
    draw_billboard(0, 0, 3.0, tex_enemy, 1, 1, cam)

    ----------------
    ocean_obj = {
        pos = {0,0,0},
        rot = mat4.identity(),
        scale = {1,1,1},
        pivot = {0,0,0},
        mesh = ocean_mesh
    }
    update_world_matrix(ocean_obj)
    water.draw(ocean_obj,cam,water_time)
end

function love.draw()
    draw_world(viewport.cam,viewport.canvas,viewport.depth)
    local cam = viewport.cam
    
    ----------------
    -- GIZMO:
    if (gizmo.visible) then
        love.graphics.clear(false, false, true) -- clear only the depth buffer to draw gizmo meshes above all else
        love.graphics.setShader(cube_shader)
        local selected_obj = viewport.selected_obj

        local gizmo_group_obj = {}
        gizmo_group_obj.children = gizmo.components
        local s = gizmo_world_scale_for_screen_size(selected_obj, cam, 20)
        gizmo_group_obj.pos = {
            selected_obj.pos[1],
            selected_obj.pos[2],
            selected_obj.pos[3],
        }
        gizmo_group_obj.scale = {s, s, s}
        if (gizmo.is_relative) then
            gizmo_group_obj.rot = selected_obj.rot
        else
            gizmo_group_obj.rot = mat4.identity()
        end
        gizmo_group_obj.pivot = {0,0,0}
        update_world_matrix(gizmo_group_obj, nil) --TEMP (need only change this when object is transformed)

        for i,obj in ipairs(gizmo.components) do
            cube_shader:send("uv_scales",
                obj.uv_scale[1],
                obj.uv_scale[2],
                obj.uv_scale[3],
                obj.uv_scale[4],
                obj.uv_scale[5],
                obj.uv_scale[6]
            )
            cube_shader:send("uv_offsets",
                obj.uv_offset[1],
                obj.uv_offset[2],
                obj.uv_offset[3],
                obj.uv_offset[4],
                obj.uv_offset[5],
                obj.uv_offset[6]
            )
            cube_shader:send("tex_coords",
                obj.tex_coords[1],
                obj.tex_coords[2],
                obj.tex_coords[3],
                obj.tex_coords[4],
                obj.tex_coords[5],
                obj.tex_coords[6]
            )
            cube_shader:send("tex_sizes",
                obj.tex_sizes[1],
                obj.tex_sizes[2],
                obj.tex_sizes[3],
                obj.tex_sizes[4],
                obj.tex_sizes[5],
                obj.tex_sizes[6]
            )
            cube_shader:send("model", obj.world_matrix)
            love.graphics.draw(obj.mesh)
        end
    end
    ----------------

    love.graphics.setShader()
    love.graphics.setMeshCullMode("none")
    love.graphics.setDepthMode()

    love.graphics.setCanvas()
    --[[if (viewport.crt_on) then
        screen_effect(function() love.graphics.draw(viewport.canvas,0,0,0,viewport.scale,viewport.scale) end)
    else
        love.graphics.draw(viewport.canvas,0,0,0,viewport.scale,viewport.scale)
    end]]

    ----
    test_menu:draw()
    care.debug.draw()
end

function love.keypressed(key, scancode, isrepeat)
    if (key == "return") then
        flux.to(objects[2].pos, 1, {[1] = objects[2].pos[1]+1}):ease("linear"):after(2, {[2] = objects[2].pos[2]+1}):ease("linear"):after(2, {[3] = objects[2].pos[3]+1}):ease("linear")
    elseif (key == "escape") then
        love.event.quit()
    elseif (key == "r") then gizmo.is_relative = not gizmo.is_relative --TEMP
    end
end

function love.mousemoved(x, y, dx, dy)
    test_menu:mousemoved(x,y,dx,dy)
    care.input.mouse.moved(x,y,dx,dy)
end

function love.mousepressed(x,y,b)
    test_menu:mousepressed(x,y,b)
end

function love.mousereleased(x,y,b)
    test_menu:mousereleased(x,y,b)
end

function viewport.on_mousemove(x,y,dx,dy)
    viewport.mx, viewport.my = x/viewport.scale, y/viewport.scale
    local hovered = picker.pick(viewport.mx, viewport.my, viewport.cam, objects)
    viewport.hover_data = hovered
    
    ----------------

    if editor.dragging then
        local obj = editor.object

        local sx = editor.drag_screen_axis[1]
        local sy = editor.drag_screen_axis[2]

        editor.drag_pixels = editor.drag_pixels + dx*sx + dy*sy

        local amount = editor.drag_pixels * editor.units_per_pixel

        if (editor.mode == EditorMode.TRANSLATE) then
            obj.pos[1] = editor.drag_start_pos[1] + editor.drag_world_axis[1]*amount
            obj.pos[2] = editor.drag_start_pos[2] + editor.drag_world_axis[2]*amount
            obj.pos[3] = editor.drag_start_pos[3] + editor.drag_world_axis[3]*amount
        elseif (editor.mode == EditorMode.SCALE) then
            if (not gizmo.is_relative) then -- TODO: or scaling set to uniform (lock axes) mode
                local factor = (editor.drag_start_max_scale + amount) / editor.drag_start_max_scale
                factor = math.max(0.001, factor)

                obj.scale[1] = editor.drag_start_scale[1] * factor
                obj.scale[2] = editor.drag_start_scale[2] * factor
                obj.scale[3] = editor.drag_start_scale[3] * factor
            else
                obj.scale[1] = editor.drag_start_scale[1] + editor.drag_local_axis[1]*amount
                obj.scale[2] = editor.drag_start_scale[2] + editor.drag_local_axis[2]*amount
                obj.scale[3] = editor.drag_start_scale[3] + editor.drag_local_axis[3]*amount
            end
        elseif (editor.mode == EditorMode.ROTATE) then
            local delta
            --TEMP:
            if     editor.drag_local_axis[1] ~= 0 then delta = mat4.rotateX(-amount)
            elseif editor.drag_local_axis[2] ~= 0 then delta = mat4.rotateY(-amount)
            else                                       delta = mat4.rotateZ(-amount)
            end
            if (gizmo.is_relative) then obj.rot = mat4.mul(editor.drag_start_rot, delta)
            else                        obj.rot = mat4.mul(delta, editor.drag_start_rot)
            end
        end

        return
    end

    ----------------

    if not mouse_freed then
        viewport.cam.yaw = viewport.cam.yaw - dx * viewport.cam.sensitivity
        viewport.cam.pitch = viewport.cam.pitch + dy * viewport.cam.sensitivity
        
        local limit = math.rad(89)
        viewport.cam.pitch = math.max(-limit, math.min(limit, viewport.cam.pitch))
    end
end

function viewport.on_press(x,y,b)
    local hover_gizmo_data = gizmo.visible and picker.pick(viewport.mx, viewport.my, viewport.cam, gizmo.components) or nil
    
    if (b==1 and hover_gizmo_data) then -- if hovering a gizmo
        local local_axis = hover_gizmo_data.object.dir
        local world_axis = local_axis
        if (gizmo.is_relative) then
            world_axis = mat4.mulVec3(viewport.selected_obj.rot, local_axis)
        end
        begin_axis_drag(viewport.selected_obj,viewport.cam,viewport.mx,viewport.my,local_axis,world_axis,hover_gizmo_data.object.mode)
    elseif (b==1 and viewport.hover_data) then -- if hovering an object
        select_object(viewport.hover_data.object)
    else
        select_object()
    end
end

function viewport.on_release(x,y,b)
    if (b == 1 and editor.dragging) then
        editor.dragging = false
        love.mouse.setRelativeMode(false)
    end
end

function get_camera_right_up(cam)
    local yaw = cam.yaw
    local pitch = -1*cam.pitch

    -- camera right vector
    local right = {
        x = math.cos(yaw),
        y = 0,
        z = -math.sin(yaw),
    }

    -- camera up vector, including pitch
    local up = {
        x = -math.sin(yaw) * math.sin(pitch),
        y = math.cos(pitch),
        z = -math.cos(yaw) * math.sin(pitch),
    }

    return right, up
end

function draw_billboard(x, y, z, texture, width, height, cam)
    width = width or 1
    height = height or 1

    local right, up = get_camera_right_up(cam)

    local hw = width / 2
    local hh = height / 2

    local function vertex(rx, uy, u, v)
        return {
            x + right.x * rx + up.x * uy,
            y + right.y * rx + up.y * uy,
            z + right.z * rx + up.z * uy,

            0, 0, 1,

            u, v
        }
    end

    local vertices = {
        vertex(-hw, -hh, 0, 0),
        vertex( hw,  hh, 1, 1),
        vertex( hw, -hh, 1, 0),

        vertex(-hw, -hh, 0, 0),
        vertex(-hw,  hh, 0, 1),
        vertex( hw,  hh, 1, 1),
    }

    texture:setFilter("nearest", "nearest")
    texture:setWrap("repeat", "repeat")
    billboard_mesh:setVertices(vertices)
    billboard_mesh:setTexture(texture)

    love.graphics.draw(billboard_mesh)
end

function make_skybox_mesh(size)
    local s = size or 1

    local cell_w = 1 / 4
    local cell_h = 1 / 3

    local function uv(cx, cy, u, v)
        return cx * cell_w + u * cell_w,
               cy * cell_h + v * cell_h
    end

    local function face(v1, v2, v3, v4, cx, cy)
        local u0,v0 = uv(cx,cy,0,0)
        local u1,v1u = uv(cx,cy,1,0)
        local u2,v2u = uv(cx,cy,1,1)
        local u3,v3u = uv(cx,cy,0,1)

        return {
            {v1[1],v1[2],v1[3], u0,v0},
            {v3[1],v3[2],v3[3], u2,v2u},
            {v2[1],v2[2],v2[3], u1,v1u},

            {v1[1],v1[2],v1[3], u0,v0},
            {v4[1],v4[2],v4[3], u3,v3u},
            {v3[1],v3[2],v3[3], u2,v2u},
        }
    end

    local p = {
        LBF = {-s,-s, s},
        RBF = { s,-s, s},
        RTF = { s, s, s},
        LTF = {-s, s, s},

        LBB = {-s,-s,-s},
        RBB = { s,-s,-s},
        RTB = { s, s,-s},
        LTB = {-s, s,-s},
    }

    local verts = {}

    local function add(f)
        for _,v in ipairs(f) do
            table.insert(verts, v)
        end
    end

    -- atlas positions:
    -- 0100
    -- 1111
    -- 0100

    add(face(p.LBB, p.RBB, p.RBF, p.LBF, 1, 0)) -- top
    add(face(p.LTF, p.RTF, p.RTB, p.LTB, 1, 2)) -- bottom

    add(face(p.LBB, p.LBF, p.LTF, p.LTB, 0, 1)) -- left
    add(face(p.LBF, p.RBF, p.RTF, p.LTF, 1, 1)) -- front
    add(face(p.RBF, p.RBB, p.RTB, p.RTF, 2, 1)) -- right
    add(face(p.RBB, p.LBB, p.LTB, p.RTB, 3, 1)) -- back

    local format = {
        {"VertexPosition", "float", 3},
        {"VertexTexCoord", "float", 2},
    }

    return love.graphics.newMesh(format, verts, "triangles")
end

----------------
-- mat4 stuff --
----------------

function build_local_matrix(obj)
    local T = mat4.translate(obj.pos[1], obj.pos[2], obj.pos[3])
    local R = obj.rot
    local S = mat4.scale(obj.scale[1], obj.scale[2], obj.scale[3])
    local P = mat4.translate(-obj.pivot[1], -obj.pivot[2], -obj.pivot[3])

    -- model = T * R * S * T(-pivot)
    return mat4.mul(T, mat4.mul(R, mat4.mul(S, P)))
end

function update_world_matrix(obj, parent_world)
    obj.local_matrix = build_local_matrix(obj)

    if parent_world then
        obj.world_matrix = mat4.mul(parent_world, obj.local_matrix)
    else
        obj.world_matrix = obj.local_matrix
    end

    if obj.children then
        for _, child in ipairs(obj.children) do
            update_world_matrix(child, obj.world_matrix)
        end
    end
end

----------------

editor = {
    object = nil,
    dragging = false,
    mode = nil,
    drag_local_axis = nil, -- for local rotation composition
    drag_world_axis = nil, -- for drawing/projecting/moving/scaling
    drag_plane_point = nil,
    drag_plane_normal = nil,
    drag_start_hit = nil,
    drag_start_pos = nil,
    drag_start_scale = nil,
    drag_start_max_scale = nil,
    drag_start_rot = nil,
    drag_pixels = 0
}

local function dot(a,b)
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

local function cross(a,b)
    return {
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1],
    }
end

local function sub(a,b)
    return {a[1]-b[1], a[2]-b[2], a[3]-b[3]}
end

local function add(a,b)
    return {a[1]+b[1], a[2]+b[2], a[3]+b[3]}
end

local function mul(a,s)
    return {a[1]*s, a[2]*s, a[3]*s}
end

local function len(a)
    return math.sqrt(dot(a,a))
end

local function normalize(a)
    local l = len(a)
    if l < 0.000001 then return {0,0,0} end
    return {a[1]/l, a[2]/l, a[3]/l}
end

local function ray_plane_intersection(ray_origin, ray_dir, plane_point, plane_normal)
    local denom = dot(ray_dir, plane_normal)

    -- ray is almost parallel to plane
    if math.abs(denom) < 0.000001 then
        return nil
    end

    local t = dot(sub(plane_point, ray_origin), plane_normal) / denom

    if t < 0 then
        return nil
    end

    return add(ray_origin, mul(ray_dir, t))
end

function begin_axis_drag(obj, camera, mx, my, local_axis, world_axis, mode)
    local p0x, p0y = camera:world_to_screen(obj.pos)

    local axis_end = {
        obj.pos[1] + world_axis[1],
        obj.pos[2] + world_axis[2],
        obj.pos[3] + world_axis[3],
    }

    local p1x, p1y = camera:world_to_screen(axis_end)

    if not p0x or not p1x then return end

    local sx = p1x - p0x
    local sy = p1y - p0y
    local slen = math.sqrt(sx*sx + sy*sy)

    if slen < 0.0001 then return end

    sx = sx / slen
    sy = sy / slen

    editor.dragging = true
    editor.mode = mode
    editor.object = obj

    editor.drag_local_axis = local_axis
    editor.drag_world_axis = world_axis

    editor.drag_start_mouse = {mx, my}
    editor.drag_start_pos = {obj.pos[1], obj.pos[2], obj.pos[3]}
    editor.drag_start_scale = {obj.scale[1], obj.scale[2], obj.scale[3]}
    editor.drag_start_max_scale = math.max(obj.scale[1],obj.scale[2],obj.scale[3])
    editor.drag_start_rot = mat4.copy(obj.rot)

    editor.drag_screen_axis = {sx, sy}
    editor.drag_pixels = 0
    editor.units_per_pixel = 0.01

    love.mouse.setRelativeMode(true)
end

----------------

function select_object(obj)
    viewport.selected_obj = obj
    gizmo.visible = (obj~=nil)
end

function distance3(a, b)
    local dx = a[1] - b[1]
    local dy = a[2] - b[2]
    local dz = a[3] - b[3]
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function gizmo_world_scale_for_screen_size(obj, cam, desired_pixels)
    local depth = select(3, cam:world_to_screen(obj.pos))
    if not depth then return 0 end

    local fov = math.rad(70)
    local pixels_per_world_unit_at_depth =
        viewport.h / (2 * math.tan(fov / 2) * depth)

    return desired_pixels / pixels_per_world_unit_at_depth
end