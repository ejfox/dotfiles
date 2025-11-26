// Subtle static vignette - darkens edges, focuses center
// No animation, just depth

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 texColor = texture(iChannel0, uv);

    // Distance from center (0.5, 0.5)
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    // Vignette settings - VERY subtle
    float radius = 0.95;      // Only darkens very edges
    float softness = 0.55;    // Very gradual fade
    float strength = 0.75;    // Barely darker (closer to 1 = less effect)

    // Calculate vignette
    float vignette = smoothstep(radius, radius - softness, dist);
    vignette = mix(strength, 1.0, vignette);

    // Apply
    fragColor = vec4(texColor.rgb * vignette, texColor.a);
}
