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

// Compute outward surface normal via SDF gradient (finite differences).
// Gives perpendicular normals on flat sides and curved normals on corners,
// which produces correct edge-refraction for a rounded rectangle.
vec2 sdfNormal(vec2 p, vec2 halfSize, float r) {
    float eps = 0.5;
    float gx = sdfRoundedRect(p + vec2(eps, 0.0), halfSize, r)
             - sdfRoundedRect(p - vec2(eps, 0.0), halfSize, r);
    float gy = sdfRoundedRect(p + vec2(0.0, eps), halfSize, r)
             - sdfRoundedRect(p - vec2(0.0, eps), halfSize, r);
    float len = length(vec2(gx, gy));
    return len > 1e-4 ? vec2(gx, gy) / len : vec2(0.0);
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

    vec2 normal = sdfNormal(fromCenter, halfSize, r);

    vec2 invSize = 1.0 / surfaceSize;
    // Negative normal = inward push, simulating thick glass rim refracting light toward center
    vec2 lensOffset = -normal * (lensingStrength * edgeFactor) * invSize;
    vec2 abOffset = normal * (aberrationStrength * edgeFactor) * invSize;

    vec4 cR = texture(source, uv + lensOffset + abOffset);
    vec4 cG = texture(source, uv + lensOffset);
    vec4 cB = texture(source, uv + lensOffset - abOffset);

    vec3 color = vec3(cR.r, cG.g, cB.b);
    float alpha = cG.a;

    fragColor = vec4(color, alpha) * mask * qt_Opacity;
}
