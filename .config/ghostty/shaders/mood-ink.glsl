// Mood Ink - ambient vignette from screen colors + fresh text bloom
// Day: classy & refined | Night: neon & hacker-ified

const float LIGHT_MODE_THRESHOLD = 0.5;

// === DAY MODE - barely there, just a whisper ===
const float DAY_VIGNETTE_STRENGTH = 0.04;
const float DAY_VIGNETTE_RADIUS = 0.98;
const float DAY_INK_BLOOM = 0.01;
const float DAY_SATURATION = 0.1;

// === NIGHT MODE - matches old subtle settings, just with mood ===
const float NIGHT_VIGNETTE_STRENGTH = 0.25;  // was 0.75 inverted = 25%
const float NIGHT_VIGNETTE_RADIUS = 0.95;    // was 0.95 - only edges
const float NIGHT_INK_BLOOM = 0.21;          // matches old bloom
const float NIGHT_SATURATION = 0.6;          // vivid but not crazy
const float NIGHT_RED_BOOST = 1.3;           // subtle extra for reds

const float INK_CONTRAST_THRESH = 0.3;

// Bloom sample points (gaussian-ish distribution)
const vec2[12] bloomSamples = vec2[](
    vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
    vec2(0.707, 0.707), vec2(-0.707, 0.707), vec2(0.707, -0.707), vec2(-0.707, -0.707),
    vec2(2.0, 0.0), vec2(-2.0, 0.0), vec2(0.0, 2.0), vec2(0.0, -2.0)
);

float lum(vec3 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

// Extract the "mood" - dominant chromatic color on screen
vec3 sampleMood(sampler2D tex) {
    vec3 mood = vec3(0.0);
    float totalWeight = 0.0;

    // Sample a grid across the screen
    for (float y = 0.1; y < 1.0; y += 0.2) {
        for (float x = 0.1; x < 1.0; x += 0.2) {
            vec3 c = texture(tex, vec2(x, y)).rgb;
            float l = lum(c);

            // Weight by saturation - we want colorful pixels, not gray
            float maxC = max(max(c.r, c.g), c.b);
            float minC = min(min(c.r, c.g), c.b);
            float sat = (maxC > 0.0) ? (maxC - minC) / maxC : 0.0;

            // Also weight by brightness (but not too much)
            float weight = sat * (0.3 + l * 0.7);

            mood += c * weight;
            totalWeight += weight;
        }
    }

    return (totalWeight > 0.0) ? mood / totalWeight : vec3(0.5);
}

// Check if a pixel is "fresh ink" - high contrast against neighbors
float inkFreshness(sampler2D tex, vec2 uv, vec2 pixel, vec3 bgColor) {
    vec3 center = texture(tex, uv).rgb;
    float centerLum = lum(center);
    float bgLum = lum(bgColor);

    // Contrast against background
    float bgContrast = abs(centerLum - bgLum);

    // Local contrast (is this pixel different from neighbors?)
    float localContrast = 0.0;
    for (int i = 0; i < 4; i++) {
        vec3 neighbor = texture(tex, uv + bloomSamples[i] * pixel).rgb;
        localContrast += abs(centerLum - lum(neighbor));
    }
    localContrast /= 4.0;

    // Fresh ink = high contrast against bg AND has local variation (it's text, not a block)
    float freshness = smoothstep(INK_CONTRAST_THRESH, INK_CONTRAST_THRESH + 0.2, bgContrast);
    freshness *= smoothstep(0.02, 0.1, localContrast);

    return freshness;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixel = 1.0 / iResolution.xy;
    vec4 texColor = texture(iChannel0, uv);

    // Detect light/dark mode (bottom-left to avoid tmux bar)
    vec3 bgSample = texture(iChannel0, vec2(0.01, 0.99)).rgb;
    float bgLum = lum(bgSample);
    bool lightMode = bgLum > LIGHT_MODE_THRESHOLD;

    // Pick parameters based on mode
    float vignetteStrength = lightMode ? DAY_VIGNETTE_STRENGTH : NIGHT_VIGNETTE_STRENGTH;
    float vignetteRadius = lightMode ? DAY_VIGNETTE_RADIUS : NIGHT_VIGNETTE_RADIUS;
    float inkBloom = lightMode ? DAY_INK_BLOOM : NIGHT_INK_BLOOM;
    float satBoost = lightMode ? DAY_SATURATION : NIGHT_SATURATION;

    // Get the mood color from screen content
    vec3 mood = sampleMood(iChannel0);

    // Boost saturation of mood color
    float moodLum = lum(mood);
    vec3 moodSaturated = mix(vec3(moodLum), mood, 1.0 + satBoost);

    // === VIGNETTE ===
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center) * 1.4;
    float vignette = smoothstep(vignetteRadius, 1.0, dist);

    // Apply vignette
    vec3 vignetteColor;
    if (lightMode) {
        // Day: pure white vignette, NO mood tinting - keep it clean
        vignetteColor = vec3(1.0);
        texColor.rgb = mix(texColor.rgb, vignetteColor, vignette * vignetteStrength);
    } else {
        // Night: mood-colored vignette
        vignetteColor = moodSaturated * 0.4;
        texColor.rgb = mix(texColor.rgb, vignetteColor, vignette * vignetteStrength);
    }

    // === FRESH INK BLOOM ===
    float freshness = inkFreshness(iChannel0, uv, pixel, bgSample);

    if (freshness > 0.0) {
        vec3 bloom = vec3(0.0);
        for (int i = 0; i < 12; i++) {
            vec2 offset = bloomSamples[i] * pixel * 2.0;
            vec3 s = texture(iChannel0, uv + offset).rgb;
            bloom += s;
        }
        bloom /= 12.0;

        // Tint bloom toward the pixel's own color
        vec3 inkColor = texture(iChannel0, uv).rgb;

        if (lightMode) {
            // Day: neutral bloom, no color tinting
            texColor.rgb += bloom * freshness * inkBloom;
        } else {
            // Night: color-tinted bloom
            bloom = mix(bloom, inkColor, 0.5);

            // Extra boost for reds/pinks (vulpes neon)
            float redDominance = inkColor.r - max(inkColor.g, inkColor.b);
            if (redDominance > 0.15) {
                bloom.r *= NIGHT_RED_BOOST;
                freshness *= 1.3;
            }

            texColor.rgb += bloom * freshness * inkBloom;
        }
    }

    fragColor = texColor;
}
