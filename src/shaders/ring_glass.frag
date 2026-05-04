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
    float clockLeft;
    float clockRight;
    float clockBottom;
    float clockRadius;
    float dockLeft;
    float dockRight;
    float dockTopY;
    float dockTopFlatLeft;
    float dockTopFlatRight;
    float dockCurveRun;
    float homeLeft;
    float homeRight;
    float homeTop;
    float homeBottom;
    float homeShoulderInset;
};

layout(binding = 1) uniform sampler2D source;

float sdfRoundedRect(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

float sdfSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
    return length(pa - (ba * h));
}

vec2 cubicPoint(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    float u = 1.0 - t;
    return (u * u * u * p0)
        + (3.0 * u * u * t * p1)
        + (3.0 * u * t * t * p2)
        + (t * t * t * p3);
}

float sdfCubicApprox(vec2 p, vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
    float dist = 1e20;
    vec2 prev = p0;

    for (int i = 1; i <= 24; i++) {
        float t = float(i) / 24.0;
        vec2 cur = cubicPoint(p0, p1, p2, p3, t);
        dist = min(dist, sdfSegment(p, prev, cur));
        prev = cur;
    }

    return dist;
}

float cubicYForX(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float x) {
    float lo = 0.0;
    float hi = 1.0;

    for (int i = 0; i < 12; i++) {
        float mid = (lo + hi) * 0.5;
        float midX = cubicPoint(p0, p1, p2, p3, mid).x;

        if (midX < x) {
            lo = mid;
        } else {
            hi = mid;
        }
    }

    return cubicPoint(p0, p1, p2, p3, (lo + hi) * 0.5).y;
}

float cubicXForY(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float y) {
    float lo = 0.0;
    float hi = 1.0;
    bool increasing = p3.y >= p0.y;

    for (int i = 0; i < 12; i++) {
        float mid = (lo + hi) * 0.5;
        float midY = cubicPoint(p0, p1, p2, p3, mid).y;

        if ((midY < y) == increasing) {
            lo = mid;
        } else {
            hi = mid;
        }
    }

    return cubicPoint(p0, p1, p2, p3, (lo + hi) * 0.5).x;
}

float clockBoundaryY(float x, float inset) {
    float r = max(clockRadius, 0.0);
    float leftCurveRight = clockLeft + r;
    float rightCurveLeft = clockRight - r;

    if (x < leftCurveRight) {
        return cubicYForX(
            vec2(clockLeft, inset),
            vec2(clockLeft + (r * 0.55), inset),
            vec2(clockLeft, clockBottom - (r * 0.55)),
            vec2(leftCurveRight, clockBottom),
            x
        );
    }

    if (x > rightCurveLeft) {
        return cubicYForX(
            vec2(rightCurveLeft, clockBottom),
            vec2(clockRight, clockBottom - (r * 0.55)),
            vec2(clockRight - (r * 0.55), inset),
            vec2(clockRight, inset),
            x
        );
    }

    return clockBottom;
}

float dockBoundaryY(float x, float innerBottom) {
    float top = min(dockTopY, innerBottom - 0.5);
    float bottom = max(innerBottom, top + 0.5);
    float run = max(dockCurveRun, 0.0);
    vec2 leftBottom = vec2(dockLeft, bottom);
    vec2 leftTop = vec2(dockTopFlatLeft, top);
    vec2 rightTop = vec2(dockTopFlatRight, top);
    vec2 rightBottom = vec2(dockRight, bottom);

    vec2 leftC1 = vec2(dockLeft + run, bottom);
    vec2 leftC2 = vec2(dockTopFlatLeft - (run * 0.55), top);
    vec2 rightC1 = vec2(dockTopFlatRight + (run * 0.55), top);
    vec2 rightC2 = vec2(dockRight - run, bottom);

    if (x < dockTopFlatLeft) {
        return cubicYForX(leftBottom, leftC1, leftC2, leftTop, x);
    }

    if (x > dockTopFlatRight) {
        return cubicYForX(rightTop, rightC1, rightC2, rightBottom, x);
    }

    return top;
}

float sdfHomePanel(vec2 px, float outerRight) {
    float left = homeLeft;
    float top = homeTop;
    float right = max(outerRight, homeRight + 1.0);
    float bottom = homeBottom;
    float height = max(bottom - top, 1.0);
    float s = min(max(homeShoulderInset, 0.0), height * 0.5);

    vec2 topRight = vec2(right, top);
    vec2 upperLeft = vec2(left, top + s);
    vec2 lowerLeft = vec2(left, bottom - s);
    vec2 bottomRight = vec2(right, bottom);

    vec2 topC1 = vec2(right, top + (s * 0.45));
    vec2 topC2 = vec2(left, top + (s * 0.55));
    vec2 bottomC1 = vec2(left, bottom - (s * 0.55));
    vec2 bottomC2 = vec2(right, bottom - (s * 0.45));

    float dist = min(
        min(sdfCubicApprox(px, topRight, topC1, topC2, upperLeft), sdfSegment(px, upperLeft, lowerLeft)),
        sdfCubicApprox(px, lowerLeft, bottomC1, bottomC2, bottomRight)
    );
    dist = min(dist, sdfSegment(px, bottomRight, topRight));

    float boundaryX = left;

    if (px.y < top + s) {
        boundaryX = cubicXForY(topRight, topC1, topC2, upperLeft, px.y);
    } else if (px.y > bottom - s) {
        boundaryX = cubicXForY(lowerLeft, bottomC1, bottomC2, bottomRight, px.y);
    }

    bool inside = px.x >= boundaryX
        && px.x <= right
        && px.y >= top
        && px.y <= bottom;

    return inside ? -dist : dist;
}

float innerSdf(vec2 px, vec2 surfaceSize) {
    float inset = max(frameInset, 1.0);
    vec2 center = surfaceSize * 0.5;
    float attachPad = max(max(edgeWidth, inset), 1.0) + 8.0;

    float innerBottom = surfaceSize.y - inset;
    vec2 innerHalfSize = max(center - vec2(inset), vec2(1.0));
    float r = min(cornerRadius, min(innerHalfSize.x, innerHalfSize.y));
    float d = sdfRoundedRect(px - center, innerHalfSize, r);

    if (clockRight > clockLeft + 1.0 && clockBottom > inset + 1.0) {
        bool nearClock = px.x >= clockLeft
            && px.x <= clockRight
            && px.y <= clockBottom + attachPad;

        if (nearClock) {
            d = max(d, clockBoundaryY(px.x, inset) - px.y);
        }
    }

    float dockPad = max(edgeWidth, 1.0) + 2.0;
    bool nearDock = px.x >= dockLeft - dockPad
        && px.x <= dockRight + dockPad
        && px.y >= dockTopY - dockPad
        && px.y <= innerBottom + dockPad;

    if (nearDock
            && dockRight > dockLeft + 1.0
            && dockTopFlatRight > dockTopFlatLeft + 1.0
            && innerBottom > dockTopY + 1.0) {
        d = max(d, px.y - dockBoundaryY(px.x, innerBottom));
    }

    if (homeRight > homeLeft + 1.0 && homeBottom > homeTop + 1.0) {
        float d_home = sdfHomePanel(px, max(homeRight, surfaceSize.x) + attachPad);
        d = max(d, -d_home);
    }

    return d;
}

vec2 sdfNormal(vec2 px, vec2 surfaceSize) {
    float eps = 0.5;
    float gx = innerSdf(px + vec2(eps, 0.0), surfaceSize)
             - innerSdf(px - vec2(eps, 0.0), surfaceSize);
    float gy = innerSdf(px + vec2(0.0, eps), surfaceSize)
             - innerSdf(px - vec2(0.0, eps), surfaceSize);
    float len = length(vec2(gx, gy));
    return len > 1e-4 ? vec2(gx, gy) / len : vec2(0.0);
}

void main() {
    vec2 surfaceSize = vec2(max(surfaceWidth, 1.0), max(surfaceHeight, 1.0));
    vec2 uv = qt_TexCoord0;
    vec2 px = uv * surfaceSize;

    float d_inner = innerSdf(px, surfaceSize);

    // mask: 0 = inner content (transparent), 1 = ring frame (show blurred wallpaper)
    float aa = 1.0;
    float mask = smoothstep(-aa, aa, d_inner);

    if (mask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // Lensing at the inner ring edge.
    float distFromInner = max(0.0, d_inner);
    float edgeFactor = 1.0 - smoothstep(0.0, max(edgeWidth, 0.5), distFromInner);

    vec2 innerNormal = sdfNormal(px, surfaceSize);

    vec2 invSize = 1.0 / surfaceSize;
    vec2 lensOffset = -innerNormal * (lensingStrength * edgeFactor) * invSize;
    vec2 abOffset = innerNormal * (aberrationStrength * edgeFactor) * invSize;

    vec4 cR = texture(source, uv + lensOffset + abOffset);
    vec4 cG = texture(source, uv + lensOffset);
    vec4 cB = texture(source, uv + lensOffset - abOffset);

    vec3 color = vec3(cR.r, cG.g, cB.b);
    vec2 lightDir = normalize(vec2(-0.42, -0.9));
    vec2 shadowDir = normalize(vec2(0.54, 0.84));
    float rimLight = pow(max(dot(innerNormal, lightDir), 0.0), 0.72) * edgeFactor;
    float rimShadow = pow(max(dot(innerNormal, shadowDir), 0.0), 1.25) * edgeFactor;

    color += vec3(1.0, 0.97, 0.92) * rimLight * 0.1;
    color -= vec3(0.09, 0.1, 0.12) * rimShadow * 0.16;
    color = clamp(color, 0.0, 1.0);

    float alpha = cG.a;

    fragColor = vec4(color, alpha) * mask * qt_Opacity;
}
