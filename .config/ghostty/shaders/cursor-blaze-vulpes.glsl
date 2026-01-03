// Vulpes Cursor Blaze - velocity-reactive hot pink trail
// Based on https://gist.github.com/chardskarth/95874c54e29da6b5a36ab7b50ae2d088

float ease(float x) {
    return pow(1.0 - x, 10.0);
}

float sdBox(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float blend(float t)
{
    float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

float antialising(float distance) {
    return 1. - smoothstep(0., normalize(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y);
    float condition2 = step(a.x, b.x) * step(b.y, a.y);
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

// ═══════════════════════════════════════════════════════════════════════════
// VULPES CONFIG
// ═══════════════════════════════════════════════════════════════════════════
const vec4 TRAIL_COLOR = vec4(1.0, 0.0, 0.33, 1.0);         // #ff0055 tmux border red
const vec4 TRAIL_COLOR_ACCENT = vec4(0.45, 0.15, 0.29, 1.0); // #73264a tmux inactive border
// Light mode variants - deeper/darker for contrast on white
const vec4 TRAIL_COLOR_LIGHT = vec4(0.85, 0.0, 0.28, 1.0);        // darker pink
const vec4 TRAIL_COLOR_ACCENT_LIGHT = vec4(0.35, 0.1, 0.22, 1.0); // deeper accent
const float BASE_DURATION = 0.32;   // small moves: noticeable but not crazy
const float MAX_DURATION = 0.65;    // big moves: longer but reasonable
const float DRAW_THRESHOLD = 1.5;
const float TELEPORT_THRESHOLD = 0.25;  // >25% screen = pane switch, no trail
const bool HIDE_TRAILS_ON_THE_SAME_LINE = false;
const float LIGHT_MODE_THRESHOLD = 0.65;  // Sharp cutoff

float calcLum(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

// Sample 10 pixels in bottom-right corner and average luminance
float sampleCornerLuminance(sampler2D tex) {
    float total = 0.0;
    vec2 base = vec2(0.97, 0.97);
    total += calcLum(texture(tex, base + vec2(0.000, 0.000)).rgb);
    total += calcLum(texture(tex, base + vec2(0.010, 0.000)).rgb);
    total += calcLum(texture(tex, base + vec2(0.020, 0.000)).rgb);
    total += calcLum(texture(tex, base + vec2(0.000, 0.010)).rgb);
    total += calcLum(texture(tex, base + vec2(0.010, 0.010)).rgb);
    total += calcLum(texture(tex, base + vec2(0.020, 0.010)).rgb);
    total += calcLum(texture(tex, base + vec2(0.000, 0.020)).rgb);
    total += calcLum(texture(tex, base + vec2(0.010, 0.020)).rgb);
    total += calcLum(texture(tex, base + vec2(0.020, 0.020)).rgb);
    total += calcLum(texture(tex, base + vec2(0.015, 0.015)).rgb);
    return total / 10.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // Detect light mode (bottom-right, 10px average, sharp threshold)
    bool lightMode = sampleCornerLuminance(iChannel0) > LIGHT_MODE_THRESHOLD;

    // Pick colors based on mode
    vec4 trailColor = lightMode ? TRAIL_COLOR_LIGHT : TRAIL_COLOR;
    vec4 trailAccent = lightMode ? TRAIL_COLOR_ACCENT_LIGHT : TRAIL_COLOR_ACCENT;

    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

    vec4 newColor = vec4(fragColor);

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    float cursorSize = max(currentCursor.z, currentCursor.w);
    float trailThreshold = DRAW_THRESHOLD * cursorSize;
    float lineLength = distance(centerCC, centerCP);

    bool isFarEnough = lineLength > trailThreshold;
    bool isOnSeparateLine = HIDE_TRAILS_ON_THE_SAME_LINE ? currentCursor.y != previousCursor.y : true;
    bool isTeleport = lineLength > TELEPORT_THRESHOLD;  // pane switch detection

    if (isFarEnough && isOnSeparateLine && !isTeleport) {
        // Velocity: 0.0 (small) to 1.0 (big jump)
        float velocity = clamp(lineLength * 4.0, 0.0, 1.0);

        // Duration scales with velocity
        float duration = mix(BASE_DURATION, MAX_DURATION, velocity);

        // Opacity: small moves = 45%, big moves = 85% 🔥
        float opacityScale = mix(0.45, 0.85, velocity);

        float progress = blend(clamp((iTime - iTimeCursorChange) / duration, 0.0, 1.0));
        float easedProgress = ease(progress);

        float distanceToEnd = distance(vu.xy, centerCC);
        float alphaModifier = distanceToEnd / (lineLength * easedProgress);

        if (alphaModifier > 1.0) {
            alphaModifier = 1.0;
        }

        float sdfCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
        float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

        // Final alpha combines distance fade + velocity scaling
        float finalAlpha = (1.0 - alphaModifier) * opacityScale;

        newColor = mix(newColor, trailAccent, 1.0 - smoothstep(sdfTrail, -0.01, 0.001));
        newColor = mix(newColor, trailColor, antialising(sdfTrail));
        newColor = mix(fragColor, newColor, finalAlpha);
        fragColor = mix(newColor, fragColor, step(sdfCursor, 0));
    }
}
