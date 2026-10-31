trig = {}

-- returns the angle from x1,y1 to x2,y2 in radians (with 0 being north)
function trig.angle_to(x1,y1,x2,y2)
    return math.atan2(y2-y1, x2-x1) + math.pi/2
end

function trig.distance_to(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

return trig