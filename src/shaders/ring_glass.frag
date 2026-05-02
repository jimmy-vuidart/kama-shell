#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float surfaceWidth;
    float surfaceHeight;
    float frameInset;
    float cornerRadius;
    float edgeWidth;
    float lensingStrength;
    float aberrationStrength;
    float dockLeft;
    float dockRight;
    float dockTopY;
};

layout(binding = 1) uniform sampler2D source;

float sdfRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

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
    vec2 center = surfaceSize * 0.5;
    vec2 fromCenter = px - center;

    // Inner content area: inset from all edges, rounded corners.
    float inset = max(frameInset, 1.0);
    vec2 innerHalfSize = max(center - vec2(inset), vec2(1.0));
    float r = min(cornerRadius, min(innerHalfSize.x, innerHalfSize.y));
    float d_inner = sdfRoundedRect(fromCenter, innerHalfSize, r);

    // Dock notch: the dock sits between dockTopY and the inner bottom edge.
    // It is part of the ring frame, so subtract it from the inner content area.
    // SDF CSG: inner_corrected = inner_rect MINUS dock_bump = max(d_inner, -d_dock)
    float innerBottom = surfaceSize.y - inset;
    float dockBumpH = max(0.5, innerBottom - dockTopY);
    float dockBumpW = max(0.5, dockRight - dockLeft);
    vec2 dockBumpCenter = vec2((dockLeft + dockRight) * 0.5, dockTopY + dockBumpH * 0.5);
    vec2 dockBumpHalfSize = vec2(dockBumpW * 0.5, dockBumpH * 0.5);
    float d_dock = sdfRoundedRect(px - dockBumpCenter, dockBumpHalfSize, 0.0);
    float d_inner_corrected = max(d_inner, -d_dock);

    // mask: 0 = inner content (transparent), 1 = ring frame (show blurred wallpaper)
    float aa = 1.0;
    float mask = smoothstep(-aa, aa, d_inner_corrected);

    if (mask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // Lensing at the inner ring edge.
    float distFromInner = max(0.0, d_inner_corrected);
    float edgeFactor = 1.0 - smoothstep(0.0, max(edgeWidth, 0.5), distFromInner);

    vec2 innerNormal = sdfNormal(fromCenter, innerHalfSize, r);

    vec2 invSize = 1.0 / surfaceSize;
    vec2 lensOffset = -innerNormal * (lensingStrength * edgeFactor) * invSize;
    vec2 abOffset = innerNormal * (aberrationStrength * edgeFactor) * invSize;

    vec4 cR = texture(source, uv + lensOffset + abOffset);
    vec4 cG = texture(source, uv + lensOffset);
    vec4 cB = texture(source, uv + lensOffset - abOffset);

    vec3 color = vec3(cR.r, cG.g, cB.b);
    float alpha = cG.a;

    fragColor = vec4(color, alpha) * mask * qt_Opacity;
}
