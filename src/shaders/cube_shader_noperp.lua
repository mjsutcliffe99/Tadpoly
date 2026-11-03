return love.graphics.newShader[[
    uniform float aspect;

    uniform vec3 cam_pos;
    uniform float cam_yaw;
    uniform float cam_pitch;

    uniform mat4 model;

    varying vec2 affine_uv_times_w;
    varying float affine_w;

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
        vec3 p = (model * vertex_position).xyz;

        p -= cam_pos;
        p = inverse_camera_rotate(p);

        float near = 0.1;
        float far = 100.0;
        float fov = radians(70.0);
        float f = 1.0 / tan(fov / 2.0);
        // y is negated because LOVE canvases are stored upside down
        vec4 clip_position = vec4(
            p.x * f / aspect,
            -p.y * f,
            ((far + near) / (near - far)) * p.z + ((2.0 * far * near) / (near - far)),
            -p.z
        );

        // Cancel perspective correction for UVs only, not for geometry or depth.
        affine_w = clip_position.w;
        affine_uv_times_w = VertexTexCoord.xy * clip_position.w;

        return clip_position;
    }
    #endif
    #ifdef PIXEL
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
    {
        // The ratio of these perspective-interpolated varyings is screen-linear UV.
        vec2 uncorrected_uv = affine_uv_times_w / affine_w;
        vec4 tex_color = Texel(tex, uncorrected_uv) * color;
        if (tex_color.a == 0.0) discard; // fully transparent pixels are ignored rather than overwriting whatever is behind them

        return tex_color;
    }
    #endif
]]
