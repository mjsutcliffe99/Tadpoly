local mat4 = require "mat4"

local portal = {}

function portal.update_portal_camera(player_cam, input_portal, output_portal)
    local cam = output_portal.cam

    -- player position relative to input portal
    local rel = {
        player_cam.x - input_portal.pos[1],
        player_cam.y - input_portal.pos[2],
        player_cam.z - input_portal.pos[3],
    }

    -- world -> input local
    local input_inv_rot = mat4.transpose3(input_portal.rot)
    local local_pos = mat4.mulVec3(input_inv_rot, rel)

    -- output local -> world
    local world_offset = mat4.mulVec3(output_portal.rot, local_pos)

    cam.x = output_portal.pos[1] + world_offset[1]
    cam.y = output_portal.pos[2] + world_offset[2]
    cam.z = output_portal.pos[3] + world_offset[3]

    -- Camera orientation:
    -- output_rot * flip * inverse(input_rot) * player_rot
    local player_cam_rot_mat = mat4.rotateXYZ(player_cam.pitch, player_cam.yaw, 0) -- turn {yaw,pitch} to rotation matrix
    local cam_rot =
        mat4.mul(
            mat4.mul(output_portal.rot, input_inv_rot),
            player_cam_rot_mat
        )
    cam.yaw, cam.pitch = mat4.toYawPitch(cam_rot)
end

function portal.update_portal_cameras(player_cam, portal_blue, portal_orange)
    portal.update_portal_camera(player_cam, portal_blue, portal_orange)
    portal.update_portal_camera(player_cam, portal_orange, portal_blue)
end

return portal