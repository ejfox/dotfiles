// Debug shader - displays iTimeOfDay as a color bar in top-right corner
// Shows seconds since midnight (0-86400) as hue rotation

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec4 color = texture(iChannel0, uv);

  // Draw a bar in top-right corner (200px wide, 50px tall)
  vec2 bar_size = vec2(200.0, 50.0);
  vec2 bar_pos = iResolution.xy - bar_size;

  if (fragCoord.x > bar_pos.x && fragCoord.y > bar_pos.y) {
    // Map time_of_day (0-86400) to hue (0-360)
    float hue = mod(iTimeOfDay / 86400.0 * 360.0, 360.0);

    // Simple hue to RGB conversion
    float h = hue / 60.0;
    float c = 0.8;
    float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));

    vec3 rgb = vec3(0.0);
    if (h < 1.0) rgb = vec3(c, x, 0.0);
    else if (h < 2.0) rgb = vec3(x, c, 0.0);
    else if (h < 3.0) rgb = vec3(0.0, c, x);
    else if (h < 4.0) rgb = vec3(0.0, x, c);
    else if (h < 5.0) rgb = vec3(x, 0.0, c);
    else rgb = vec3(c, 0.0, x);

    color.rgb = rgb;
  }

  fragColor = color;
}
