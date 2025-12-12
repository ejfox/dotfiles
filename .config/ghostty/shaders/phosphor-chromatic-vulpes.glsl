// Phosphor Persistence + Chromatic Aberration (Red-selective)
// Mimics old CRT phosphor ghosting + red channel misalignment

const float CHROMA_SHIFT = 0.0003;     // Chromatic aberration shift (barely perceptible)
const float LIGHT_MODE_THRESHOLD = 0.5;

float lum(vec3 c) {
  return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

bool isReddish(vec4 c) {
  // Must be substantially red
  return c.r > 0.4 && c.r > c.g * 1.2;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec4 color = texture(iChannel0, uv);

  // Detect light mode
  vec3 corner = texture(iChannel0, vec2(0.01, 0.99)).rgb;
  bool lightMode = lum(corner) > LIGHT_MODE_THRESHOLD;

  if (lightMode) {
    fragColor = color;
    return;
  }

  // ===== CHROMATIC ABERRATION (Full RGB offset) =====
  // Sample each channel at different positions for classic CRT fringing
  vec2 rOffset = vec2(CHROMA_SHIFT, 0.0);
  vec2 gOffset = vec2(0.0, 0.0);
  vec2 bOffset = vec2(-CHROMA_SHIFT, 0.0);

  float r = texture(iChannel0, uv + rOffset).r;
  float g = texture(iChannel0, uv + gOffset).g;
  float b = texture(iChannel0, uv + bOffset).b;

  vec3 chromaColor = vec3(r, g, b);

  // ===== PHOSPHOR PERSISTENCE (disabled - requires temporal access) =====
  // vec3 phosphor = vec3(0.0);
  // int samples = 12;
  // for (int i = 0; i < samples; i++) {
  //   float angle = float(i) / float(samples) * 6.28318;
  //   vec2 offset = vec2(cos(angle), sin(angle)) * PHOSPHOR_RADIUS;
  //   vec4 neighbor = texture(iChannel0, uv + offset);
  //   if (neighbor.r > 0.45 && neighbor.r > neighbor.g * 0.8) {
  //     phosphor += neighbor.rgb * (neighbor.r * 0.08);
  //   }
  // }

  // Combine: just chromatic aberration
  vec3 final = chromaColor;

  fragColor = vec4(final, 1.0);
}
