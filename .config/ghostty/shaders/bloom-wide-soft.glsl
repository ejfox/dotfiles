// Soft wide-radius bloom - dreamy glow layer
// Super subtle, big radius, affects all bright pixels

const float BLOOM_INTENSITY = 0.025;  // Very subtle
const float BLOOM_RADIUS = 8.0;       // Big and soft
const float LUM_THRESHOLD = 0.3;      // Bloom brighter pixels
const float LIGHT_MODE_THRESHOLD = 0.65;

// Fewer samples but spread wider
const vec3[12] samples = {
  vec3(1.0, 0.0, 1.0),
  vec3(0.5, 0.866, 0.9),
  vec3(-0.5, 0.866, 0.8),
  vec3(-1.0, 0.0, 0.7),
  vec3(-0.5, -0.866, 0.6),
  vec3(0.5, -0.866, 0.5),
  vec3(0.707, 0.707, 0.45),
  vec3(-0.707, 0.707, 0.4),
  vec3(-0.707, -0.707, 0.35),
  vec3(0.707, -0.707, 0.3),
  vec3(0.0, 1.0, 0.25),
  vec3(0.0, -1.0, 0.2)
};

float lum(vec3 c) {
  return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

float sampleCornerLuminance(sampler2D tex) {
  float total = 0.0;
  vec2 base = vec2(0.97, 0.97);
  for (int i = 0; i < 4; i++) {
    total += lum(texture(tex, base + vec2(float(i) * 0.01, 0.0)).rgb);
  }
  return total / 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec4 color = texture(iChannel0, uv);

  // Skip in light mode
  if (sampleCornerLuminance(iChannel0) > LIGHT_MODE_THRESHOLD) {
    fragColor = color;
    return;
  }

  vec2 step = vec2(BLOOM_RADIUS) / iResolution.xy;
  vec3 bloom = vec3(0.0);

  for (int i = 0; i < 12; i++) {
    vec3 s = samples[i];
    vec3 c = texture(iChannel0, uv + s.xy * step).rgb;
    float l = lum(c);

    if (l > LUM_THRESHOLD) {
      bloom += c * s.z * l;
    }
  }

  color.rgb += bloom * BLOOM_INTENSITY;
  fragColor = color;
}
