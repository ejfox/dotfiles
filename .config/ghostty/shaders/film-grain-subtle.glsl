// Subtle film grain - analog texture without the noise
// Adds gentle organic movement to the image

const float GRAIN_INTENSITY = 0.012;  // Barely there
const float GRAIN_SPEED = 0.15;       // Slow drift
const float LIGHT_MODE_THRESHOLD = 0.65;

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float lum(vec3 c) {
  return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

float sampleCornerLuminance(sampler2D tex) {
  return lum(texture(tex, vec2(0.97, 0.97)).rgb);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec4 color = texture(iChannel0, uv);

  // Skip in light mode
  if (sampleCornerLuminance(iChannel0) > LIGHT_MODE_THRESHOLD) {
    fragColor = color;
    return;
  }

  // Animated grain
  float t = iTime * GRAIN_SPEED;
  float grain = noise(fragCoord.xy * 0.5 + t * 100.0);
  grain = (grain - 0.5) * 2.0;  // Center around 0

  // Apply grain, slightly more visible in darker areas
  float brightness = lum(color.rgb);
  float grainAmount = GRAIN_INTENSITY * (1.0 - brightness * 0.5);

  color.rgb += grain * grainAmount;

  fragColor = color;
}
