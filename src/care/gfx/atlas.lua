local json = require "care.third_party.json"
local viewport = require "care.gfx.viewport"

local Atlas = {}
Atlas.__index = Atlas

local function new(image_path,reg_path,scale,w,h)
    local self = setmetatable({
        image = love.graphics.newImage(image_path),
        register = reg_path and json.decode(love.filesystem.read(reg_path)) or {},
        quads = {},
        scale = scale or 1
    }, Atlas)
    self:gen_quads(w,h)
    self.image:setFilter(viewport.opts.scale_filter)
    return self
end

function Atlas:new(image_path,reg_path,scale)
    return new(image_path,reg_path,scale)
end

-- For fixed dimension tiles, fixed to a grid, with x,y being their tile position rather than pixel coords:
function Atlas:new_tilesheet(image_path,reg_path,w,h,scale)
    return new(image_path,reg_path,scale,w,h)
end

function Atlas:set_image(image_path)
    self.image = love.graphics.newImage(image_path)
end

function Atlas:set_register(reg_path)
    self.register = json.decode(love.filesystem.read(reg_path))
end

function Atlas:gen_quads(w,h)
    if not (w and h) then
        -- Normal atlas, allowing variable sprite dimensions and with x,y being pixel coords:
        for name,coords in pairs(self.register) do
            self.quads[name] = love.graphics.newQuad(coords.x,coords.y,coords.w,coords.h,self.image:getDimensions())
        end
    else
        -- Tilehseet atlas, with fixed tile dimensions, bound to a grid, and with x,y being the 1-indexed tile position in this grid:
        for name,coords in pairs(self.register) do
            self.quads[name] = love.graphics.newQuad((coords.x-1)*w,(coords.y-1)*h,w,h,self.image:getDimensions())
        end
    end
end

function Atlas:get_quad(name)
    return self.quads[name]
end

function Atlas:get_quads(names)
    local quads = {}
    for _,q in ipairs(names) do
        quads[#quads+1] = self:get_quad(q)
    end
    return quads
end

return Atlas