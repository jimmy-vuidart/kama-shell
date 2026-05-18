#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 surfaceSize;
    vec4 innerRect;
    vec4 clockRect;
    vec4 statusRect;
    vec4 homeRect;
    vec4 dockRect;
    float cornerRadius;
    float clockRadius;
    float statusRadius;
    float homeRadius;
    float dockCurveRun;
    float supportWidth;
    float borderWidth;
    float highlightWidth;
    vec4 fillTop;
    vec4 fillUpper;
    vec4 fillMiddle;
    vec4 fillBottom;
    vec4 supportColor;
    vec4 borderColor;
    vec4 highlightColor;
};

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

vec4 fillAt(float y) {
    float t = clamp(y / max(surfaceSize.y, 1.0), 0.0, 1.0);
    vec4 upper = mix(fillTop, fillUpper, smoothstep(0.0, 0.16, t));
    vec4 lower = mix(fillMiddle, fillBottom, smoothstep(0.62, 1.0, t));
    return mix(upper, lower, smoothstep(0.16, 0.62, t));
}

void main() {
    vec2 p = qt_TexCoord0 * surfaceSize;
    vec2 innerCenter = (innerRect.xy + innerRect.zw) * 0.5;
    vec2 innerHalf = (innerRect.zw - innerRect.xy) * 0.5;
    float inner = sdRoundedBox(p - innerCenter, innerHalf, cornerRadius);

    vec2 clockCenter = (clockRect.xy + clockRect.zw) * 0.5;
    vec2 clockHalf = (clockRect.zw - clockRect.xy) * 0.5;
    float clock = sdRoundedBox(p - clockCenter, clockHalf, clockRadius);

    vec2 statusCenter = (statusRect.xy + statusRect.zw) * 0.5;
    vec2 statusHalf = (statusRect.zw - statusRect.xy) * 0.5;
    float status = sdRoundedBox(p - statusCenter, statusHalf, statusRadius);

    vec2 homeCenter = (homeRect.xy + homeRect.zw) * 0.5;
    vec2 homeHalf = (homeRect.zw - homeRect.xy) * 0.5;
    float home = sdRoundedBox(p - homeCenter, homeHalf, homeRadius);

    vec2 dockCenter = (dockRect.xy + dockRect.zw) * 0.5;
    vec2 dockHalf = max((dockRect.zw - dockRect.xy) * 0.5, vec2(1.0));
    float dock = sdRoundedBox(
        p - dockCenter,
        dockHalf + vec2(dockCurveRun, 0.0),
        max(8.0, dockCurveRun * 0.35)
    );

    float cutout = smin(inner, clock, 18.0);
    cutout = smin(cutout, status, 18.0);
    cutout = smin(cutout, home, 20.0);
    cutout = smin(cutout, dock, 24.0);

    float outer = -min(min(p.x, surfaceSize.x - p.x), min(p.y, surfaceSize.y - p.y));
    float ring = smax(outer, -cutout, 1.0);
    float aa = max(fwidth(ring), 0.75);
    float alpha = 1.0 - smoothstep(0.0, aa, ring);

    vec4 color = fillAt(p.y);
    float edge = abs(cutout);
    color = mix(color, supportColor, 1.0 - smoothstep(supportWidth, supportWidth + aa, edge));
    color = mix(color, borderColor, 1.0 - smoothstep(borderWidth, borderWidth + aa, edge));
    color = mix(color, highlightColor, (1.0 - smoothstep(highlightWidth, highlightWidth + aa, edge)) * 0.45);
    fragColor = color * alpha * qt_Opacity;
}
