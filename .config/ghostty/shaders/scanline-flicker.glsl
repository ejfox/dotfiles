// Subtle scanline flicker - gentle CRT warmth
// Adds organic movement without being distracting

const float FLICKER_INTENSITY = 0.015;  // Very subtle
const float FLICKER_SPEED = 8.0;        // Hz-ish
const float SCANLINE_DENSITY = 1.0;     // Every line
const float LIGHT_MODE_THRESHOLD = 0.65;

float lum(vec3 c) {
  return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec4 color = texture(iChannel0, uv);

  // Skip in light mode
  if (lum(texture(iChannel0, vec2(0.97, 0.97)).rgb) > LIGHT_MODE_THRESHOLD) {
    fragColor = color;
    return;
  }

  // Scanline position
  float line = fragCoord.y * SCANLINE_DENSITY;

  // Gentle flicker - combines slow drift with faster pulse
  float slowDrift = sin(iTime * 0.7) * 0.5 + 0.5;
  float fastPulse = sin(iTime * FLICKER_SPEED + line * 0.01) * 0.5 + 0.5;
  float flicker = mix(slowDrift, fastPulse, 0.3);

  // Subtle brightness variation per scanline
  float scanlinePhase = sin(line * 3.14159);
  float variation = scanlinePhase * flicker * FLICKER_INTENSITY;

  color.rgb += variation;

  fragColor = color;
}
