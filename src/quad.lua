-- a rectangular region of a texture, in pixels
local Quad = {}

function Quad.new(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

return Quad
