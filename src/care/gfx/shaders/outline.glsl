extern vec2 textureSize;
extern vec4 outlineColor;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc)
{
    vec4 center = Texel(texture, tc);

    if (center.a > 0.0) {
        return center * color;
    }

    vec2 px = 1.0 / textureSize;

    float a =
        Texel(texture, tc + vec2( px.x, 0.0)).a +
        Texel(texture, tc + vec2(-px.x, 0.0)).a +
        Texel(texture, tc + vec2(0.0,  px.y)).a +
        Texel(texture, tc + vec2(0.0, -px.y)).a +
        Texel(texture, tc + vec2( px.x,  px.y)).a +
        Texel(texture, tc + vec2(-px.x,  px.y)).a +
        Texel(texture, tc + vec2( px.x, -px.y)).a +
        Texel(texture, tc + vec2(-px.x, -px.y)).a;

    if (a > 0.0) {
        return outlineColor;
    }

    return vec4(0.0);
}