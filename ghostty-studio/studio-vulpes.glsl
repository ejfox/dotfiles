// studio-vulpes: the vulpes neon look, made SAFE for a green key.
// The background (#00ff00) is treated as "transparent": effects only touch text, and any
// glow that spills onto the background is MIXED toward the glow color (not added), so a
// chroma key reads it as semi-transparent pink glow over whatever you composite under it.
// Pure background with no glow stays exactly #00ff00.

// The key as the SHADER sees it: Ghostty hands shaders display-space colors, so #00ff00
// isn't (0,1,0) here. Read it from the bottom-right padding, which is always background.
vec3 KEY;

// TUNING KNOBS
const float GLOW = 0.95;          // neon bloom strength
const float GLOW_RADIUS = 3.2;    // in pixels (scaled by the sample pattern below)
const float GLOW_MAX = 0.80;      // cap so the key never fully disappears under glow
const float FRINGE = 1.4;         // chromatic split on text, in pixels
const float SCAN = 0.20;          // scanline depth on text (0 = off)
const float SCAN_PERIOD = 4.0;    // pixels per scanline
const float FLICKER = 0.025;      // phosphor shimmer, black mode only (needs custom-shader-animation)
// glow tint = the theme's cursor color (the studio rotates vulpes through its monthly hues)
#define GLOW_TINT iCurrentCursorColor.rgb

// 1 = background key, 0 = ink. Soft so anti-aliased text edges count as partial ink.
float keyness(vec3 c) {
  return 1.0 - smoothstep(0.18, 0.55, distance(c, KEY));
}

const vec2 TAPS[16] = vec2[](
  vec2( 1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0,-1.0),
  vec2( 0.7, 0.7), vec2(-0.7, 0.7), vec2(0.7,-0.7), vec2(-0.7,-0.7),
  vec2( 2.0, 0.0), vec2(-2.0, 0.0), vec2(0.0, 2.0), vec2(0.0,-2.0),
  vec2( 1.4, 1.4), vec2(-1.4, 1.4), vec2(1.4,-1.4), vec2(-1.4,-1.4)
);

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 px = 1.0 / iResolution.xy;
  vec2 uv = fragCoord / iResolution.xy;
  KEY = texture(iChannel0, vec2(1.0) - 4.0 * px).rgb;
  vec3 c = texture(iChannel0, uv).rgb;
  float k = keyness(c);

  // glow: gather nearby ink, weighted by how saturated it is (so any theme hue glows,
  // and white/grey text stays crisp)
  float glow = 0.0;
  for (int i = 0; i < 16; i++) {
    vec2 o = TAPS[i] * GLOW_RADIUS * px;
    vec3 s = texture(iChannel0, uv + o).rgb;
    float ink = 1.0 - keyness(s);
    float sat = max(max(s.r, s.g), s.b) - min(min(s.r, s.g), s.b);
    glow += ink * sat * 1.2 * (i < 8 ? 1.0 : 0.55);
  }
  glow = clamp(glow / 10.0 * GLOW, 0.0, 1.0);

  // green-key mode (`studio greenscreen`): never glow onto the background, keep it a flat
  // exact key so studio-alpha's unmix is exact; studio-alpha adds the glow back as true
  // transparency. On the plain black background the glow is drawn right here.
  bool keyMode = KEY.g - max(KEY.r, KEY.b) > 0.5;
  if (keyMode) glow *= (1.0 - k);

  if (k > 0.98) {
    if (keyMode || glow < 0.02) { fragColor = vec4(KEY, 1.0); return; }
    fragColor = vec4(mix(KEY, GLOW_TINT, min(glow, GLOW_MAX)), 1.0);
    return;
  }

  // ink: chromatic fringe (only borrow a channel from a neighbour that is also ink)
  vec3 r = texture(iChannel0, uv + vec2(FRINGE, 0.0) * px).rgb;
  vec3 b = texture(iChannel0, uv - vec2(FRINGE, 0.0) * px).rgb;
  vec3 ink = c;
  ink.r = mix(r.r, c.r, keyness(r));
  ink.b = mix(b.b, c.b, keyness(b));

  // scanlines + shimmer on the ink only
  float scan = 1.0 - SCAN * (0.5 + 0.5 * cos(6.2831853 * fragCoord.y / SCAN_PERIOD));
  // no shimmer on greenscreen: a still terminal must give identical frames, or every
  // frame of the ProRes take is unique (huge file, slow alpha pass)
  float shimmer = keyMode ? 1.0 : 1.0 - FLICKER * (0.5 + 0.5 * sin(iTime * 9.0 + fragCoord.y * 0.02));
  ink *= scan * shimmer;
  ink += GLOW_TINT * glow * 0.25;          // a little self-glow so pink text "burns"

  // anti-aliased edges: blend ink back toward the key by how background-ish the pixel was
  vec3 bg = mix(KEY, GLOW_TINT, min(glow, GLOW_MAX));
  fragColor = vec4(mix(ink, bg, k), 1.0);
}
