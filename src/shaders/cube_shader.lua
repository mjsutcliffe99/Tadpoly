return love.graphics.newShader[[
    uniform float aspect;

    uniform vec3 cam_pos;
    uniform float cam_yaw;
    uniform float cam_pitch;

    #ifdef VERTEX
    vec3 inverse_camera_rotate(vec3 p)
    {
        float cy = cos(-cam_yaw);
        float sy = sin(-cam_yaw);

        p.xz = vec2(
            p.x * cy + p.z * sy,
           -p.x * sy + p.z * cy
        );

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
        vec3 p = vertex_position.xyz;

        p -= cam_pos;
        p = inverse_camera_rotate(p);

        float near = 0.1;
        float far = 100.0;
        float fov = radians(70.0);
        float f = 1.0 / tan(fov / 2.0);

        // y is negated because LOVE canvases are stored upside down
        return vec4(
            p.x * f / aspect,
            -p.y * f,
            ((far + near) / (near - far)) * p.z + ((2.0 * far * near) / (near - far)),
            -p.z
        );
    }
    #endif
]]
