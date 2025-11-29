// Vulpes Cursor Pulse - flash on newline (Enter), no movement trails
// Matches tmux active pane border: #ff0055

// ═══════════════════════════════════════════════════════════════════════════
// VULPES CONFIG
// ═══════════════════════════════════════════════════════════════════════════
const vec3 PULSE_COLOR = vec3(1.0, 0.0, 0.33);  // #ff0055 - tmux border red
const float PULSE_DURATION = 0.15;              // quick flash
const float PULSE_SIZE = 0.08;                  // glow radius
const float PULSE_INTENSITY = 0.6;              // max brightness
const float VERTICAL_THRESHOLD = 0.02;          // detect Enter (vertical jump)

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = texture(iChannel0, uv);

    // Normalize cursor positions
    vec2 currentPos = iCurrentCursor.xy / iResolution.xy;
    vec2 previousPos = iPreviousCursor.xy / iResolution.xy;

    // Calculate vertical distance (Enter = big vertical jump)
    float verticalDist = abs(currentPos.y - previousPos.y);
    float horizontalDist = abs(currentPos.x - previousPos.x);

    // Only trigger on Enter-like moves: significant vertical, cursor moved left (new line)
    bool isNewLine = verticalDist > VERTICAL_THRESHOLD && currentPos.x < previousPos.x + 0.1;

    if (isNewLine) {
        // Time since cursor changed
        float t = iTime - iTimeCursorChange;

        if (t < PULSE_DURATION) {
            // Distance from current cursor
            vec2 cursorCenter = currentPos;
            float dist = distance(uv, cursorCenter);

            // Pulse fades out over time
            float timeFade = 1.0 - (t / PULSE_DURATION);
            timeFade = timeFade * timeFade;  // ease out

            // Glow falloff from cursor
            float glow = smoothstep(PULSE_SIZE, 0.0, dist);

            // Combine
            float intensity = glow * timeFade * PULSE_INTENSITY;

            // Blend pulse color
            fragColor.rgb = mix(fragColor.rgb, PULSE_COLOR, intensity);
        }
    }
}
