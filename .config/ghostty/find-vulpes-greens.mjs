#!/usr/bin/env node
// Find harmonious greens for Vulpes palette using color theory

import chroma from 'chroma-js';

const WCAG_AA = 4.5;
const LIGHT_BG = '#f7f7f7';
const DARK_BG = '#000000';

// Extract the vulpes reds from the light theme
const vulpesReds = [
  '#c7004c', // palette 1 - red
  '#e0001e', // selection bg
  '#fa0070', // cursor
  '#501630', // foreground
  '#dd006b', // palette 3 (adjusted yellow)
  '#e10054', // palette 9 (adjusted bright red)
];

console.log('🦊 Vulpes Green Finder - Color Theory Edition\n');
console.log('='.repeat(60));

// Analyze the vulpes red palette
console.log('\nANALYZING VULPES REDS:\n');

const hslData = vulpesReds.map(color => {
  const [h, s, l] = chroma(color).hsl();
  return { color, h: h || 0, s, l };
});

hslData.forEach(({ color, h, s, l }) => {
  console.log(`${color}  H:${h.toFixed(0).padStart(3)}°  S:${(s*100).toFixed(0).padStart(3)}%  L:${(l*100).toFixed(0).padStart(3)}%`);
});

// Find average hue of the reds
const avgHue = hslData.reduce((sum, d) => sum + d.h, 0) / hslData.length;
const avgSat = hslData.reduce((sum, d) => sum + d.s, 0) / hslData.length;
console.log(`\nAverage red hue: ${avgHue.toFixed(0)}° (${avgHue > 330 || avgHue < 30 ? 'red-pink range' : 'other'})`);
console.log(`Average saturation: ${(avgSat * 100).toFixed(0)}%`);

// Color theory: find harmonious greens
console.log('\n' + '='.repeat(60));
console.log('COLOR THEORY APPROACHES:\n');

// 1. Complementary (180° opposite)
const complementaryHue = (avgHue + 180) % 360;
console.log(`1. COMPLEMENTARY (180° from ${avgHue.toFixed(0)}°): ${complementaryHue.toFixed(0)}°`);

// 2. Split-complementary (150° and 210°)
const splitComp1 = (avgHue + 150) % 360;
const splitComp2 = (avgHue + 210) % 360;
console.log(`2. SPLIT-COMPLEMENTARY: ${splitComp1.toFixed(0)}° and ${splitComp2.toFixed(0)}°`);

// 3. Triadic (120° apart)
const triadic1 = (avgHue + 120) % 360;
const triadic2 = (avgHue + 240) % 360;
console.log(`3. TRIADIC: ${triadic1.toFixed(0)}° and ${triadic2.toFixed(0)}°`);

// Green hue range is roughly 90-150°
console.log(`\nGreen hue range: 90° - 150°`);
console.log(`Looking for harmonious hues that fall in or near green range...`);

// Function to generate green candidates and test contrast
function findAccessibleGreen(targetHue, saturation, bg, label) {
  console.log(`\n${label} (target hue: ${targetHue.toFixed(0)}°):`);

  const results = [];

  // Try different lightness values to find ones that pass contrast
  for (let l = 0.15; l <= 0.55; l += 0.05) {
    for (let s = 0.5; s <= 1.0; s += 0.1) {
      const color = chroma.hsl(targetHue, s, l);
      const hex = color.hex();
      const contrast = chroma.contrast(hex, bg);

      if (contrast >= WCAG_AA) {
        results.push({ hex, contrast, h: targetHue, s, l });
      }
    }
  }

  // Sort by how close saturation is to vulpes average (high sat)
  results.sort((a, b) => Math.abs(b.s - avgSat) - Math.abs(a.s - avgSat));

  // Return top 3
  return results.slice(0, 3);
}

// Test different green hues
const greenCandidates = [];

// Pure complementary
if (complementaryHue >= 80 && complementaryHue <= 160) {
  greenCandidates.push(...findAccessibleGreen(complementaryHue, avgSat, LIGHT_BG, 'Complementary green'));
}

// Split complementary options
[splitComp1, splitComp2].forEach((hue, i) => {
  if (hue >= 80 && hue <= 160) {
    greenCandidates.push(...findAccessibleGreen(hue, avgSat, LIGHT_BG, `Split-comp ${i+1}`));
  }
});

// Triadic options
[triadic1, triadic2].forEach((hue, i) => {
  if (hue >= 80 && hue <= 160) {
    greenCandidates.push(...findAccessibleGreen(hue, avgSat, LIGHT_BG, `Triadic ${i+1}`));
  }
});

// Also try classic green hues that might work
[100, 110, 120, 130, 140, 150, 160].forEach(hue => {
  greenCandidates.push(...findAccessibleGreen(hue, avgSat, LIGHT_BG, `Green ${hue}°`));
});

// Dedupe and sort by contrast
const seen = new Set();
const uniqueGreens = greenCandidates.filter(g => {
  if (seen.has(g.hex)) return false;
  seen.add(g.hex);
  return true;
}).sort((a, b) => b.contrast - a.contrast);

console.log('\n' + '='.repeat(60));
console.log('TOP GREEN CANDIDATES FOR LIGHT THEME:\n');

uniqueGreens.slice(0, 10).forEach((g, i) => {
  const [h, s, l] = chroma(g.hex).hsl();
  console.log(`${(i+1).toString().padStart(2)}. ${g.hex}  contrast: ${g.contrast.toFixed(2)}:1  H:${h.toFixed(0)}° S:${(s*100).toFixed(0)}% L:${(l*100).toFixed(0)}%`);
});

// Now find greens for dark theme
console.log('\n' + '='.repeat(60));
console.log('TOP GREEN CANDIDATES FOR DARK THEME:\n');

const darkGreens = [];
[100, 110, 120, 130, 140, 150].forEach(hue => {
  for (let l = 0.45; l <= 0.75; l += 0.05) {
    for (let s = 0.5; s <= 1.0; s += 0.1) {
      const color = chroma.hsl(hue, s, l);
      const hex = color.hex();
      const contrast = chroma.contrast(hex, DARK_BG);

      if (contrast >= WCAG_AA) {
        darkGreens.push({ hex, contrast, h: hue, s, l });
      }
    }
  }
});

const seenDark = new Set();
const uniqueDarkGreens = darkGreens.filter(g => {
  if (seenDark.has(g.hex)) return false;
  seenDark.add(g.hex);
  return true;
}).sort((a, b) => {
  // Prefer higher saturation (more vibrant, matches vulpes aesthetic)
  return b.s - a.s;
});

uniqueDarkGreens.slice(0, 10).forEach((g, i) => {
  const [h, s, l] = chroma(g.hex).hsl();
  console.log(`${(i+1).toString().padStart(2)}. ${g.hex}  contrast: ${g.contrast.toFixed(2)}:1  H:${h.toFixed(0)}° S:${(s*100).toFixed(0)}% L:${(l*100).toFixed(0)}%`);
});

// Final recommendation
console.log('\n' + '='.repeat(60));
console.log('🎯 RECOMMENDED VULPES GREENS:\n');

// Pick greens with high saturation to match vulpes vibrance
const lightPick = uniqueGreens.find(g => g.s >= 0.8) || uniqueGreens[0];
const darkPick = uniqueDarkGreens.find(g => g.s >= 0.9) || uniqueDarkGreens[0];

console.log(`LIGHT THEME: ${lightPick.hex}`);
console.log(`  Contrast: ${lightPick.contrast.toFixed(2)}:1 on ${LIGHT_BG}`);
console.log(`  HSL: ${lightPick.h.toFixed(0)}°, ${(lightPick.s*100).toFixed(0)}%, ${(lightPick.l*100).toFixed(0)}%`);

console.log(`\nDARK THEME: ${darkPick.hex}`);
console.log(`  Contrast: ${darkPick.contrast.toFixed(2)}:1 on ${DARK_BG}`);
console.log(`  HSL: ${darkPick.h.toFixed(0)}°, ${(darkPick.s*100).toFixed(0)}%, ${(darkPick.l*100).toFixed(0)}%`);

// Show them together with the reds for visual harmony check
console.log('\n' + '='.repeat(60));
console.log('PALETTE PREVIEW (copy these hex codes to a color picker):\n');
console.log('Vulpes Reds:');
vulpesReds.forEach(c => console.log(`  ${c}`));
console.log('\nRecommended Greens:');
console.log(`  ${lightPick.hex} (light theme)`);
console.log(`  ${darkPick.hex} (dark theme)`);
