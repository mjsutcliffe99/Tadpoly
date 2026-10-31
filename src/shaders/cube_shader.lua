return love.graphics.newShader[[
    #ifdef VERTEX
    attribute vec3 VertexNormal;
    attribute float FaceID;

    varying vec3 v_normal;
    varying float v_face_id;
    #endif

    #ifdef PIXEL
    varying vec3 v_normal;
    varying float v_face_id;
    #endif

    uniform float aspect;

    uniform vec3 cam_pos;
    uniform float cam_yaw;
    uniform float cam_pitch;

    uniform vec3 light_dir;
    uniform float lighting_strength;
    uniform float ambient;

    uniform mat4 model;

    uniform vec2 uv_scales[6];
    uniform vec2 uv_offsets[6];
    uniform vec2 tex_coords[6];
    uniform vec2 tex_sizes[6];

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
        vec4 world = model * vertex_position;
        vec3 p = world.xyz;

        v_normal = normalize((model * vec4(VertexNormal, 0.0)).xyz);
        v_face_id = FaceID;

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
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
    {
        int face_id = int(v_face_id + 0.5);
        vec2 face_uv_scale = uv_scales[face_id];
        vec2 face_uv_offset = uv_offsets[face_id];
        vec2 face_atlas_pos = tex_coords[face_id];
        vec2 face_atlas_size = tex_sizes[face_id];

        vec2 local_uv = fract(uv * face_uv_scale + face_uv_offset);
        vec2 atlas_uv = face_atlas_pos + local_uv * face_atlas_size;

        vec4 tex_color = Texel(tex, atlas_uv) * color;

        if (tex_color.a == 0.0) discard;

        vec3 n = normalize(v_normal);
        vec3 l = normalize(light_dir);

        float diffuse = max(dot(n, l), 0.0);
        float lit_brightness = ambient + diffuse * 0.75;
        float brightness = mix(1.0, lit_brightness, lighting_strength);

        return vec4(tex_color.rgb * brightness, tex_color.a);
    }
    #endif
]]