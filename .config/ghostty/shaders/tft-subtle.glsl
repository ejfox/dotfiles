// TFT Subtle - barely-there LCD subpixel effect

/** Size of TFT "pixels" - higher = smaller/subtler */
float resolution = 3.0;

/** Strength - lower = more subtle */
float strength = 0.20;

/** Light mode threshold */
const float LIGHT_MODE_THRESHOLD = 0.5;

float lum(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 color = texture(iChannel0, uv).rgb;

    // Detect light mode (bottom-left to avoid tmux bar at top)
    vec3 corner = texture(iChannel0, vec2(0.01, 0.99)).rgb;
    bool lightMode = lum(corner) > LIGHT_MODE_THRESHOLD;

    float scanline = step(1.2, mod(uv.y * iResolution.y, resolution));
    float grille   = step(1.2, mod(uv.x * iResolution.x, resolution));
    float mask = scanline * grille;

    if (lightMode) {
        // Light mode: add white to gaps (brighten)
        float addAmount = (1.0 - mask) * strength;
        color = mix(color, vec3(1.0), addAmount);
    } else {
        // Dark mode: darken gaps (original behavior)
        color *= max(1.0 - strength, mask);
    }

    fragColor = vec4(color, 1.0);
}
