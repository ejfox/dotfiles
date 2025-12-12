// Debug: 4 progress bars showing Hours, Minutes, Seconds, Fraction
// Visually proves iTimeOfDay is working and updating in real-time

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec4 color = texture(iChannel0, fragCoord);

  // Get seconds since midnight
  float timeSeconds = iTimeOfDay;

  // Calculate time components
  float hours = floor(timeSeconds / 3600.0);           // 0-24
  float minutes = floor(mod(timeSeconds, 3600.0) / 60.0); // 0-60
  float seconds = floor(mod(timeSeconds, 60.0));      // 0-60
  float fraction = mod(timeSeconds, 1.0);             // 0-1 (real-time within second)

  // Calculate fill amounts (0-1)
  float hoursFill = mod(hours, 24.0) / 24.0;
  float minutesFill = minutes / 60.0;
  float secondsFill = seconds / 60.0;
  float fractionFill = fraction; // Already 0-1

  // Bar dimensions
  float barHeight = 80.0;
  float barSpacing = 20.0;
  float barY = iResolution.y - (barHeight + barSpacing) * 1.0; // Top bar

  // Draw 4 bars
  for (int i = 0; i < 4; i++) {
    float y = iResolution.y - (barHeight + barSpacing) * float(i + 1);
    float fill = 0.0;
    vec3 barColor = vec3(1.0);

    if (i == 0) { // Hours
      fill = hoursFill;
      barColor = vec3(1.0, 0.4, 0.4); // Red for hours
    } else if (i == 1) { // Minutes
      fill = minutesFill;
      barColor = vec3(0.4, 1.0, 0.4); // Green for minutes
    } else if (i == 2) { // Seconds
      fill = secondsFill;
      barColor = vec3(0.4, 0.4, 1.0); // Blue for seconds
    } else if (i == 3) { // Fraction (sub-second)
      fill = fractionFill;
      barColor = vec3(1.0, 1.0, 0.4); // Yellow for fraction
    }

    // Check if pixel is in this bar
    if (fragCoord.y > y && fragCoord.y < y + barHeight) {
      // Bar background (dark)
      color.rgb = vec3(0.1, 0.1, 0.15);

      // Filled portion
      float fillWidth = fill * iResolution.x;
      if (fragCoord.x < fillWidth) {
        color.rgb = barColor;
      }

      // Top border (white)
      if (fragCoord.y > y + barHeight - 3.0) {
        color.rgb = vec3(1.0);
      }

      // Left border (white)
      if (fragCoord.x < 3.0) {
        color.rgb = vec3(1.0);
      }

      // Right border (white)
      if (fragCoord.x > iResolution.x - 3.0) {
        color.rgb = vec3(1.0);
      }

      // Bottom border (white)
      if (fragCoord.y < y + 3.0) {
        color.rgb = vec3(1.0);
      }
    }
  }

  fragColor = color;
}
