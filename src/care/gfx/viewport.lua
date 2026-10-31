local viewport = {}

viewport.vw            = nil -- virtual width
viewport.vh            = nil -- virtual height
viewport.scale         = 1
viewport.offset_x      = 0
viewport.offset_y      = 0
viewport.canvas        = nil
viewport.pixel_perfect = nil
viewport.opts          = { -- initial default option value
    resizable       = true,      -- allows the window to be resizable
    pixel_perfect   = false,     -- enforce integer scaling (ensures consistent square virtual pixels but limits screen size options)
    scale_filter    = "nearest", -- "nearest" | "linear" (use nearest neighbour for pixel art games)
    fullscreen      = false,
    fullscreen_type = "desktop", -- "desktop" (i.e. borderless) | "exclusive" (i.e. true fullscreen)
    vsync           = 1,         -- cap rendering to display refresh rate. 0:off (uncapped - tearing possible) | 1:on (one refresh per frame) | 2:half-rate (e.g. 30fps)
    highdpi         = false
}

function viewport.setup(vw,vh,win_w,win_h,opts)
    opts = opts or {}
    for opt,val in pairs(viewport.opts) do
        if (opts[opt] == nil) then opts[opt] = val end -- use current (initially default) opts for any option is not specified
    end
    love.graphics.setDefaultFilter(opts.scale_filter, opts.scale_filter)
    love.window.setMode(win_w, win_h, {
        resizable      = opts.resizable,
        minwidth       = vw,
        minheight      = vh,
        fullscreen     = opts.fullscreen,
        fullscreentype = opts.fullscreen_type,
        vsync          = opts.vsync,
        highdpi        = opts.highdpi
    })
    viewport.pixel_perfect = opts.pixel_perfect
    viewport.set_dimensions(vw,vh)
end

function viewport.set_dimensions(vw,vh)
    viewport.vw = vw
    viewport.vh = vh
    viewport.canvas = love.graphics.newCanvas(vw, vh)
    viewport.resize()
end

function viewport.resize()
    local win_w, win_h = love.graphics.getDimensions()
    local sx = win_w / viewport.vw
    local sy = win_h / viewport.vh
    local scale = math.min(sx, sy) -- preserve aspect ratio
    if (viewport.pixel_perfect) then scale = math.floor(scale) end -- enforce integer multiple (i.e. pixel perfect scaling)
    viewport.scale = scale
    viewport.offset_x = math.floor((win_w - viewport.vw * viewport.scale) / 2)
    viewport.offset_y = math.floor((win_h - viewport.vh * viewport.scale) / 2)
end

function viewport.draw()
    love.graphics.draw(viewport.canvas, viewport.offset_x, viewport.offset_y, 0, viewport.scale, viewport.scale)
end

return viewport