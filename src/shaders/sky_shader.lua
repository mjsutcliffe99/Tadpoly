return love.graphics.newShader([[
    uniform float aspect;

    uniform float cam_yaw;
    uniform float cam_pitch;
    
    uniform float sky_size;

    vec3 inverse_camera_rotate(vec3 p)
    {
        // inverse yaw
        float cy = cos(-cam_yaw);
        float sy = sin(-cam_yaw);
        p.xz = vec2(
            p.x * cy + p.z * sy,
        -p.x * sy + p.z * cy
        );

        // inverse pitch
        float cx = cos(-cam_pitch);
        float sx = sin(-cam_pitch);
        p.yz = vec2(
            p.y * cx - p.z * sx,
            p.y * sx + p.z * cx
        );

        return p;
    }
    
    vec4 position(mat4 transform_projection, vec4 vertex_position)
    {
        vec3 p = vertex_position.xyz * sky_size;

        // rotate with camera view, but do NOT subtract cam_pos
        p = inverse_camera_rotate(p);

        float near = 0.1;
        float far = 100.0;
        float fov = radians(70.0);
        float f = 1.0 / tan(fov / 2.0);

        return vec4(
            p.x * f / aspect,
        p.y * f,
            ((far + near) / (near - far)) * p.z + ((2.0 * far * near) / (near - far)),
        -p.z
        );
    }
]])