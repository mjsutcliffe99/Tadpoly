return love.graphics.newShader[[
    #ifdef VERTEX
    attribute vec3 VertexNormal;
    varying vec3 v_normal;
    #endif

    #ifdef PIXEL
    varying vec3 v_normal;
    #endif

    uniform float aspect;

    uniform vec3 cam_pos;
    uniform float cam_yaw;
    uniform float cam_pitch;

    uniform vec3 light_dir;
    uniform float lighting_strength;
    uniform float ambient;

    uniform vec2 uvOffset;
    uniform vec3 obj_pos;
    uniform vec3 obj_scale;
    uniform vec3 obj_rot;

    #ifdef VERTEX
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

    vec3 rotate_object(vec3 p)
    {
        // X rotation
        float cx = cos(obj_rot.x);
        float sx = sin(obj_rot.x);

        p.yz = vec2(
            p.y * cx - p.z * sx,
            p.y * sx + p.z * cx
        );

        // Y rotation
        float cy = cos(obj_rot.y);
        float sy = sin(obj_rot.y);

        p.xz = vec2(
            p.x * cy + p.z * sy,
        -p.x * sy + p.z * cy
        );

        // Z rotation
        float cz = cos(obj_rot.z);
        float sz = sin(obj_rot.z);

        p.xy = vec2(
            p.x * cz - p.y * sz,
            p.x * sz + p.y * cz
        );

        return p;
    }

    vec4 position(mat4 transform_projection, vec4 vertex_position)
    {
        vec3 p = vertex_position.xyz;

        p *= obj_scale;
        p = rotate_object(p);
        p += obj_pos;

        v_normal = normalize(rotate_object(VertexNormal));

        // world position relative to camera
        p -= cam_pos;

        // rotate the world opposite to the camera
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
        vec4 tex_color = Texel(tex, uv+uvOffset) * color;
        if (tex_color.a == 0) discard; // TODO: this could be toggleable - when enabled this allows fully transparent pixels to be ignored rather than overwriting whatever was behind it

        vec3 n = normalize(v_normal);
        vec3 l = normalize(light_dir);

        float diffuse = max(dot(n, l), 0.0);
        float lit_brightness = ambient + diffuse * 0.75;

        float brightness = mix(1.0, lit_brightness, lighting_strength);

        return vec4(tex_color.rgb * brightness, tex_color.a);
    }
    #endif
]]