#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float surfaceWidth;
    float surfaceHeight;
    float cornerRadius;
    float edgeWidth;
    float lensingStrength;
    float aberrationStrength;
};

layout(binding = 1) uniform sampler2D source;

float sdfRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

void main() {
    vec2 surfaceSize = vec2(max(surfaceWidth, 1.0), max(surfaceHeight, 1.0));
    vec2 uv = qt_TexCoord0;
    vec2 px = uv * surfaceSize;
    vec2 halfSize = surfaceSize * 0.5;
    vec2 fromCenter = px - halfSize;

    float r = min(cornerRadius, min(halfSize.x, halfSize.y));
    float d = sdfRoundedRect(fromCenter, halfSize, r);

    float aa = 1.0;
    float mask = 1.0 - smoothstep(-aa, 0.0, d);

    if (mask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float distInside = max(0.0, -d);
    float edgeFactor = 1.0 - smoothstep(0.0, max(edgeWidth, 0.5), distInside);

    vec2 radial = fromCenter / halfSize;
    float radialLen = length(radial);
    vec2 normal = radialLen > 1e-4 ? radial / radialLen : vec2(0.0);

    vec2 invSize = 1.0 / surfaceSize;
    vec2 lensOffset = -normal * (lensingStrength * edgeFactor) * invSize;
    vec2 abOffset = normal * (aberrationStrength * edgeFactor) * invSize;

    vec4 cR = texture(source, uv + lensOffset + abOffset);
    vec4 cG = texture(source, uv + lensOffset);
    vec4 cB = texture(source, uv + lensOffset - abOffset);

    vec3 color = vec3(cR.r, cG.g, cB.b);
    float alpha = cG.a;

    fragColor = vec4(color, alpha) * mask * qt_Opacity;
}
