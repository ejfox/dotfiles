// Subtle vignette - darkens edges like old monitor bezel

const float VIGNETTE_STRENGTH = 0.15;  // How much darkening
const float VIGNETTE_RADIUS = 1.2;     // How far out the vignette reaches
const float LIGHT_MODE_THRESHOLD = 0.5;

float lum(vec3 c) {
  return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec4 color = texture(iChannel0, uv);

  // Detect light mode
  vec3 corner = texture(iChannel0, vec2(0.01, 0.99)).rgb;
  bool lightMode = lum(corner) > LIGHT_MODE_THRESHOLD;

  // Calculate distance from center
  vec2 center = vec2(0.5, 0.5);
  vec2 diff = uv - center;
  float dist = length(diff) * VIGNETTE_RADIUS;

  // Vignette falloff
  float vignette = 1.0 - smoothstep(0.0, 1.0, dist);
  vignette = mix(1.0, vignette, VIGNETTE_STRENGTH);

  if (lightMode) {
    // Light mode: vignette is subtle brightening at edges
    color.rgb = mix(color.rgb, vec3(1.0), (1.0 - vignette) * 0.05);
  } else {
    // Dark mode: vignette darkens edges
    color.rgb *= vignette;
  }

  fragColor = color;
}
