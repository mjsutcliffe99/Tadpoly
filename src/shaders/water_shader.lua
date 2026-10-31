return love.graphics.newShader[[
    #ifdef VERTEX
    attribute vec3 VertexNormal;

    uniform float time;

    uniform float wave_amp;
    uniform float wave_freq;
    uniform float wave_speed;

    uniform mat4 model;

    uniform vec3 cam_pos;
    uniform float cam_yaw;
    uniform float cam_pitch;
    uniform float aspect;

    varying vec3 v_normal;
    varying float v_wave;

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
        vec4 local = vertex_position;

        float w1 = sin(local.x * wave_freq + time * wave_speed);
        float w2 = sin(local.z * wave_freq * 0.73 + time * wave_speed * 1.31);
        float w3 = sin((local.x + local.z) * wave_freq * 0.41 + time * wave_speed * 0.77);

        float wave = (w1 + 0.6*w2 + 0.35*w3) / 1.95;

        local.y += wave * wave_amp;

        vec4 world = model * local;
        vec3 p = world.xyz;

        p -= cam_pos;
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
    #endif


    #ifdef PIXEL
    varying float v_wave;

    uniform vec4 water_color;
    uniform vec2 uv_scale;
    uniform vec2 uv_scroll;
    uniform float time;

    uniform float frame_count;
    uniform float frame_rate;

    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
    {
        float frame = floor(mod(time * frame_rate, frame_count));

        vec2 frame_size = vec2(1.0 / frame_count, 1.0);
        vec2 frame_offset = vec2(frame * frame_size.x, 0.0);

        vec2 local_uv = fract(uv * uv_scale + uv_scroll * time);

        vec2 atlas_uv = frame_offset + local_uv * frame_size;

        vec4 tex_color = Texel(tex, atlas_uv);

        float shimmer = 0.85 + v_wave * 0.15;

        vec4 final_color = tex_color * water_color;
        final_color.rgb *= shimmer;

        return final_color;
    }
    #endif
]]