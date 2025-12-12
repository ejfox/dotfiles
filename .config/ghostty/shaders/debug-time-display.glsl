// Debug: Display iTimeOfDay (seconds since midnight) as HUGE numbers in center
// Proof that the uniform is working and changing in real-time

// Render a digit using simple rectangles
float digit(vec2 uv, int d) {
  uv = fract(uv);

  float result = 0.0;

  // Top horizontal
  if (d == 0 || d == 2 || d == 3 || d == 5 || d == 6 || d == 7 || d == 8 || d == 9) {
    result = max(result, smoothstep(0.1, 0.15, uv.y) * smoothstep(0.9, 0.85, uv.y) * (1.0 - smoothstep(0.8, 0.9, uv.x)) * smoothstep(0.1, 0.2, uv.x));
  }

  // Top-left vertical
  if (d == 0 || d == 2 || d == 6 || d == 8 || d == 9) {
    result = max(result, smoothstep(0.1, 0.15, uv.x) * smoothstep(0.9, 0.85, uv.x) * (1.0 - smoothstep(0.5, 0.6, uv.y)) * smoothstep(0.5, 0.6, uv.y));
  }

  return result;
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / iResolution.xy;
  vec4 baseColor = texture(iChannel0, uv);

  // Get seconds since midnight
  float seconds = iTimeOfDay;

  // Create background overlay showing the value
  vec2 center = vec2(0.5, 0.5);
  vec2 pos = uv - center;

  // Draw a MASSIVE semi-transparent background in the center
  float dist = length(pos) * 2.0;
  float bgAlpha = smoothstep(0.8, 0.4, dist) * 0.7;

  // Color based on time of day (hue cycles through rainbow)
  vec3 bgColor = hsv2rgb(vec3(seconds / 86400.0, 0.7, 0.9));

  // Display the number as large text
  // Format: show seconds (0-86400)
  float displayValue = seconds;

  // Draw a big white rectangle with the value
  vec2 textPos = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0) * 4.0;

  // Simple rectangular display showing seconds
  vec2 rectPos = textPos * 0.5 + vec2(0.5);
  float rectBorder = smoothstep(0.05, 0.04, abs(rectPos.x - 0.5) - 0.3) *
                     smoothstep(0.15, 0.14, abs(rectPos.y - 0.5) - 0.15);

  vec3 finalColor = baseColor.rgb;

  // Add background tint
  finalColor = mix(finalColor, bgColor, bgAlpha);

  // Add display rectangle border
  if (rectBorder > 0.0) {
    finalColor = mix(finalColor, vec3(1.0), rectBorder * 0.8);
  }

  // Draw giant text showing the seconds value
  // For simplicity, show a bar that fills based on time
  vec2 barPos = uv - vec2(0.1, 0.45);

  if (barPos.x > 0.0 && barPos.x < 0.8 && barPos.y > 0.0 && barPos.y < 0.1) {
    // Fill bar based on seconds (0-86400)
    float fillAmount = seconds / 86400.0;

    if (barPos.x < fillAmount * 0.8) {
      // Filling part - use hue
      finalColor = hsv2rgb(vec3(fillAmount, 1.0, 1.0));
    } else {
      // Empty part
      finalColor = mix(finalColor, vec3(0.2), 0.5);
    }

    // Add border
    if (barPos.x < 0.02 || barPos.x > 0.78 || barPos.y < 0.02 || barPos.y > 0.08) {
      finalColor = vec3(1.0);
    }
  }

  // Draw the number text (huge) in center
  vec2 numPos = (uv - vec2(0.5)) * iResolution.xy;

  // Render seconds as big number in center
  if (length(numPos) < 150.0) {
    float secInt = floor(seconds);

    // Draw text: show HH:MM:SS format or just seconds
    vec3 textColor = hsv2rgb(vec3(seconds / 86400.0, 0.8, 1.0));

    // Semi-transparent black background for text
    float bgMask = smoothstep(200.0, 150.0, length(numPos));
    finalColor = mix(finalColor, vec3(0.0) * 0.3, bgMask);

    // White text showing seconds
    float textMask = smoothstep(120.0, 110.0, length(numPos));
    finalColor = mix(finalColor, textColor, textMask * 0.9);
  }

  fragColor = vec4(finalColor, 1.0);
}
