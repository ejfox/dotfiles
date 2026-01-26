#!/usr/bin/env node
// Find VIBRANT harmonious greens for Vulpes palette

import chroma from 'chroma-js';

const WCAG_AA = 4.5;
const LIGHT_BG = '#f7f7f7';
const DARK_BG = '#000000';

// Vulpes signature: high saturation, punchy colors
const VULPES_AVG_HUE = 337;  // red-pink
const VULPES_AVG_SAT = 0.93; // very saturated

// Complementary hue for 337° is 157° (teal-green)
// This should harmonize best with the reds
const COMPLEMENTARY_HUE = 157;
const SPLIT_COMP_HUE = 127; // more pure green

console.log('🦊 Vulpes Green Finder v2 - Vibrant Edition\n');
console.log('='.repeat(60));
console.log(`Vulpes red hue: ${VULPES_AVG_HUE}° | Saturation: ${(VULPES_AVG_SAT*100).toFixed(0)}%`);
console.log(`Complementary green: ${COMPLEMENTARY_HUE}° (teal-green)`);
console.log(`Split-comp green: ${SPLIT_COMP_HUE}° (true green)`);

// For light theme: need darker greens but still saturated
console.log('\n' + '='.repeat(60));
console.log('LIGHT THEME CANDIDATES (need dark + saturated):\n');

const lightCandidates = [];

// Test hues from 120° (pure green) to 160° (teal)
for (let hue = 120; hue <= 165; hue += 5) {
  // High saturation like vulpes
  for (let sat = 0.7; sat <= 1.0; sat += 0.1) {
    // Darker lightness for contrast on light bg
    for (let lit = 0.20; lit <= 0.40; lit += 0.05) {
      const color = chroma.hsl(hue, sat, lit);
      const hex = color.hex();
      const contrast = chroma.contrast(hex, LIGHT_BG);

      if (contrast >= WCAG_AA && contrast <= 10) { // Not too dark either
        lightCandidates.push({
          hex,
          contrast,
          hue,
          sat,
          lit,
          // Score: prefer closer to complementary hue + higher saturation
          score: (1 - Math.abs(hue - COMPLEMENTARY_HUE) / 50) * sat
        });
      }
    }
  }
}

lightCandidates.sort((a, b) => b.score - a.score);

console.log('By color harmony score (complementary hue + high saturation):');
lightCandidates.slice(0, 8).forEach((c, i) => {
  const harmony = Math.abs(c.hue - COMPLEMENTARY_HUE) <= 15 ? '✨ complementary' :
                  Math.abs(c.hue - SPLIT_COMP_HUE) <= 15 ? '🎯 split-comp' : '';
  console.log(`${(i+1).toString().padStart(2)}. ${c.hex}  ${c.contrast.toFixed(2)}:1  H:${c.hue}° S:${(c.sat*100).toFixed(0)}% L:${(c.lit*100).toFixed(0)}%  ${harmony}`);
});

// For dark theme: need lighter greens but still saturated
console.log('\n' + '='.repeat(60));
console.log('DARK THEME CANDIDATES (need bright + saturated):\n');

const darkCandidates = [];

for (let hue = 120; hue <= 165; hue += 5) {
  for (let sat = 0.7; sat <= 1.0; sat += 0.1) {
    // Brighter for dark bg
    for (let lit = 0.45; lit <= 0.65; lit += 0.05) {
      const color = chroma.hsl(hue, sat, lit);
      const hex = color.hex();
      const contrast = chroma.contrast(hex, DARK_BG);

      if (contrast >= WCAG_AA) {
        darkCandidates.push({
          hex,
          contrast,
          hue,
          sat,
          lit,
          score: (1 - Math.abs(hue - COMPLEMENTARY_HUE) / 50) * sat
        });
      }
    }
  }
}

darkCandidates.sort((a, b) => b.score - a.score);

console.log('By color harmony score:');
darkCandidates.slice(0, 8).forEach((c, i) => {
  const harmony = Math.abs(c.hue - COMPLEMENTARY_HUE) <= 15 ? '✨ complementary' :
                  Math.abs(c.hue - SPLIT_COMP_HUE) <= 15 ? '🎯 split-comp' : '';
  console.log(`${(i+1).toString().padStart(2)}. ${c.hex}  ${c.contrast.toFixed(2)}:1  H:${c.hue}° S:${(c.sat*100).toFixed(0)}% L:${(c.lit*100).toFixed(0)}%  ${harmony}`);
});

// Final picks
const lightPick = lightCandidates[0];
const darkPick = darkCandidates[0];

console.log('\n' + '='.repeat(60));
console.log('🎯 FINAL RECOMMENDATIONS:\n');

console.log(`LIGHT THEME GREEN: ${lightPick.hex}`);
console.log(`  H:${lightPick.hue}° S:${(lightPick.sat*100).toFixed(0)}% L:${(lightPick.lit*100).toFixed(0)}%`);
console.log(`  Contrast: ${lightPick.contrast.toFixed(2)}:1 on ${LIGHT_BG}`);
console.log(`  ${Math.abs(lightPick.hue - COMPLEMENTARY_HUE) <= 15 ? '✨ Complementary to vulpes red!' : ''}`);

console.log(`\nDARK THEME GREEN: ${darkPick.hex}`);
console.log(`  H:${darkPick.hue}° S:${(darkPick.sat*100).toFixed(0)}% L:${(darkPick.lit*100).toFixed(0)}%`);
console.log(`  Contrast: ${darkPick.contrast.toFixed(2)}:1 on ${DARK_BG}`);
console.log(`  ${Math.abs(darkPick.hue - COMPLEMENTARY_HUE) <= 15 ? '✨ Complementary to vulpes red!' : ''}`);

// Visual comparison
console.log('\n' + '='.repeat(60));
console.log('VISUAL HARMONY CHECK:\n');
console.log('Vulpes Reds (for comparison):');
console.log('  #c7004c  (337°, 100%, 39%)');
console.log('  #fa0070  (333°, 100%, 49%)');
console.log('  #e10054  (338°, 100%, 44%)');
console.log('\nNew Greens:');
console.log(`  ${lightPick.hex}  (${lightPick.hue}°, ${(lightPick.sat*100).toFixed(0)}%, ${(lightPick.lit*100).toFixed(0)}%) - light theme`);
console.log(`  ${darkPick.hex}  (${darkPick.hue}°, ${(darkPick.sat*100).toFixed(0)}%, ${(darkPick.lit*100).toFixed(0)}%) - dark theme`);
console.log('\n→ Both at ~157° (complementary) with 100% saturation');
console.log('→ Should create vibrant red/teal harmony');
