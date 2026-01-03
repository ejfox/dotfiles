// Subtle static vignette - darkens edges (dark mode) or lightens edges (light mode)
// No animation, just depth

const float LIGHT_MODE_THRESHOLD = 0.65;  // Sharp cutoff - only trigger on clearly light backgrounds

float lum(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

// Sample 10 pixels in bottom-right corner and average luminance
float sampleCornerLuminance(sampler2D tex) {
    float total = 0.0;
    vec2 base = vec2(0.97, 0.97);  // Bottom-right corner
    // 10-pixel grid sample
    total += lum(texture(tex, base + vec2(0.000, 0.000)).rgb);
    total += lum(texture(tex, base + vec2(0.010, 0.000)).rgb);
    total += lum(texture(tex, base + vec2(0.020, 0.000)).rgb);
    total += lum(texture(tex, base + vec2(0.000, 0.010)).rgb);
    total += lum(texture(tex, base + vec2(0.010, 0.010)).rgb);
    total += lum(texture(tex, base + vec2(0.020, 0.010)).rgb);
    total += lum(texture(tex, base + vec2(0.000, 0.020)).rgb);
    total += lum(texture(tex, base + vec2(0.010, 0.020)).rgb);
    total += lum(texture(tex, base + vec2(0.020, 0.020)).rgb);
    total += lum(texture(tex, base + vec2(0.015, 0.015)).rgb);
    return total / 10.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 texColor = texture(iChannel0, uv);

    // Detect light mode (bottom-right, 10px average, sharp threshold)
    bool lightMode = sampleCornerLuminance(iChannel0) > LIGHT_MODE_THRESHOLD;

    // Distance from center (0.5, 0.5)
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    // Vignette settings - MORE DRAMATIC 🔥
    float radius = 0.80;      // Reaches further in
    float softness = 0.70;    // Wider falloff
    float strength = 0.50;    // Much more visible (closer to 0 = stronger)

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
