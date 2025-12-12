// Debug: Render HH:MM:SS with 7-segment style digits
float seg(vec2 p, float x1, float y1, float x2, float y2, float thick) {
  // Draw a line segment from (x1,y1) to (x2,y2)
  vec2 pa = p - vec2(x1, y1);
  vec2 ba = vec2(x2 - x1, y2 - y1);
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return smoothstep(thick, 0.0, length(pa - ba * h));
}

float digit(vec2 p, int d) {
  float result = 0.0;
  float th = 0.05;  // thickness

  // Standard 7-segment mapping from research
  // 0: a,b,c,e,f,g
  // 1: c,f
  // 2: a,c,d,e,g
  // 3: a,c,d,f,g
  // 4: b,c,d,f
  // 5: a,b,d,f,g
  // 6: a,b,d,e,f,g
  // 7: a,c,f
  // 8: a,b,c,d,e,f,g
  // 9: a,b,c,d,f,g

  // Top segment (a)
  if (d == 0 || d == 2 || d == 3 || d == 5 || d == 6 || d == 7 || d == 8 || d == 9) {
    result = max(result, seg(p, 0.2, 0.05, 0.8, 0.05, th));
  }

  // Top-left (b)
  if (d == 0 || d == 4 || d == 5 || d == 6 || d == 8 || d == 9) {
    result = max(result, seg(p, 0.15, 0.1, 0.15, 0.45, th));
  }

  // Top-right (c)
  if (d == 0 || d == 1 || d == 2 || d == 3 || d == 4 || d == 7 || d == 8 || d == 9) {
    result = max(result, seg(p, 0.85, 0.1, 0.85, 0.45, th));
  }

  // Middle (d)
  if (d == 2 || d == 3 || d == 4 || d == 5 || d == 6 || d == 8 || d == 9) {
    result = max(result, seg(p, 0.2, 0.5, 0.8, 0.5, th));
  }

  // Bottom-left (e)
  if (d == 0 || d == 2 || d == 6 || d == 8) {
    result = max(result, seg(p, 0.15, 0.55, 0.15, 0.9, th));
  }

  // Bottom-right (f)
  if (d == 0 || d == 1 || d == 3 || d == 4 || d == 5 || d == 6 || d == 8 || d == 9) {
    result = max(result, seg(p, 0.85, 0.55, 0.85, 0.9, th));
  }

  // Bottom (g)
  if (d == 0 || d == 2 || d == 3 || d == 5 || d == 6 || d == 8 || d == 9) {
    result = max(result, seg(p, 0.2, 0.95, 0.8, 0.95, th));
  }

  return result;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec4 color = texture(iChannel0, fragCoord / iResolution.xy);

  float timeSeconds = iTimeOfDay;

  // Extract hours, minutes, seconds properly
  float hours = mod(floor(timeSeconds / 3600.0), 24.0);
  float minutes = mod(floor(timeSeconds / 60.0), 60.0);
  float seconds = mod(floor(timeSeconds), 60.0);

  // Extract individual digits
  int h1 = int(hours / 10.0);
  int h2 = int(mod(hours, 10.0));
  int m1 = int(minutes / 10.0);
  int m2 = int(mod(minutes, 10.0));
  int s1 = int(seconds / 10.0);
  int s2 = int(mod(seconds, 10.0));

  vec2 center = iResolution.xy * 0.5;
  vec2 pixelPos = fragCoord - center;

  // Darken background
  float dist = length(pixelPos) / (iResolution.y * 0.25);
  float bgAlpha = smoothstep(1.1, 0.3, dist) * 0.5;
  color.rgb = mix(color.rgb, vec3(0.0), bgAlpha);

  vec3 digitColor = vec3(0.0, 1.0, 1.0);
  float digitWidth = 60.0;
  float digitHeight = 100.0;
  float spacing = 75.0;
  float baseX = -spacing * 2.5;

  // H1
  vec2 pos = (pixelPos - vec2(baseX, 0.0)) / vec2(digitWidth, digitHeight);
  if (abs(pos.x) < 1.0 && abs(pos.y) < 1.0) {
    float d = digit(pos + 0.5, h1);
    color.rgb = mix(color.rgb, digitColor, d);
  }

  // H2
  pos = (pixelPos - vec2(baseX + spacing, 0.0)) / vec2(digitWidth, digitHeight);
  if (abs(pos.x) < 1.0 && abs(pos.y) < 1.0) {
    float d = digit(pos + 0.5, h2);
    color.rgb = mix(color.rgb, digitColor, d);
  }

  // Colon 1
  vec2 colonPos = pixelPos - vec2(baseX + spacing * 1.5, 0.0);
  if (abs(colonPos.x) < 8.0 && ((abs(colonPos.y - 20.0) < 8.0) || (abs(colonPos.y + 20.0) < 8.0))) {
    color.rgb = digitColor;
  }

  // M1
  pos = (pixelPos - vec2(baseX + spacing * 2.2, 0.0)) / vec2(digitWidth, digitHeight);
  if (abs(pos.x) < 1.0 && abs(pos.y) < 1.0) {
    float d = digit(pos + 0.5, m1);
    color.rgb = mix(color.rgb, digitColor, d);
  }

  // M2
  pos = (pixelPos - vec2(baseX + spacing * 3.2, 0.0)) / vec2(digitWidth, digitHeight);
  if (abs(pos.x) < 1.0 && abs(pos.y) < 1.0) {
    float d = digit(pos + 0.5, m2);
    color.rgb = mix(color.rgb, digitColor, d);
  }

  // Colon 2
  colonPos = pixelPos - vec2(baseX + spacing * 3.7, 0.0);
  if (abs(colonPos.x) < 8.0 && ((abs(colonPos.y - 20.0) < 8.0) || (abs(colonPos.y + 20.0) < 8.0))) {
    color.rgb = digitColor;
  }

  // S1
  pos = (pixelPos - vec2(baseX + spacing * 4.4, 0.0)) / vec2(digitWidth, digitHeight);
  if (abs(pos.x) < 1.0 && abs(pos.y) < 1.0) {
    float d = digit(pos + 0.5, s1);
    color.rgb = mix(color.rgb, digitColor, d);
  }

  // S2
  pos = (pixelPos - vec2(baseX + spacing * 5.4, 0.0)) / vec2(digitWidth, digitHeight);
  if (abs(pos.x) < 1.0 && abs(pos.y) < 1.0) {
    float d = digit(pos + 0.5, s2);
    color.rgb = mix(color.rgb, digitColor, d);
  }

  fragColor = color;
}
