// Subtle static vignette - darkens edges (dark mode) or lightens edges (light mode)
// No animation, just depth

const float LIGHT_MODE_THRESHOLD = 0.5;

float lum(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 texColor = texture(iChannel0, uv);

    // Detect light mode (bottom-left to avoid tmux bar at top)
    vec3 corner = texture(iChannel0, vec2(0.01, 0.99)).rgb;
    bool lightMode = lum(corner) > LIGHT_MODE_THRESHOLD;

    // Distance from center (0.5, 0.5)
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    // Vignette settings - VERY subtle
    float radius = 0.95;      // Only affects very edges
    float softness = 0.55;    // Very gradual fade
    float strength = 0.75;    // Barely visible (closer to 1 = less effect)

    // Calculate vignette amount (0 at edges, 1 at center)
    float vignette = smoothstep(radius, radius - softness, dist);

    if (lightMode) {
        // Light mode: lighten edges with white
        float whiteAmount = (1.0 - vignette) * (1.0 - strength);
        fragColor = vec4(mix(texColor.rgb, vec3(1.0), whiteAmount), texColor.a);
    } else {
        // Dark mode: darken edges (original behavior)
        vignette = mix(strength, 1.0, vignette);
        fragColor = vec4(texColor.rgb * vignette, texColor.a);
    }
}
