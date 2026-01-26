#!/usr/bin/env node
// Ghostty Theme Contrast Auditor using chroma.js

import chroma from 'chroma-js';
import { readFileSync, writeFileSync } from 'fs';

const WCAG_AA_NORMAL = 4.5;
const WCAG_AA_LARGE = 3.0;

function getContrastRatio(fg, bg) {
  return chroma.contrast(fg, bg);
}

function luminance(color) {
  return chroma(color).luminance();
}

function adjustForContrast(color, bg, targetRatio = WCAG_AA_NORMAL) {
  let c = chroma(color);
  const bgLum = luminance(bg);
  const isLightBg = bgLum > 0.5;

  for (let i = 0; i <= 100; i++) {
    const adjusted = isLightBg ? c.darken(i * 0.05) : c.brighten(i * 0.05);
    if (getContrastRatio(adjusted, bg) >= targetRatio) {
      return adjusted.hex();
    }
  }
  return color;
}

// Parse Ghostty theme format (palette = 0=#color)
function parseGhosttyTheme(content) {
  const theme = { palette: {} };
  for (const line of content.split('\n')) {
    if (line.startsWith('#') || !line.trim()) continue;
    const match = line.match(/^(\S+)\s*=\s*(.+)$/);
    if (!match) continue;
    const [, key, value] = match;
    if (key === 'palette') {
      // Format: palette = 0=#2b2b2b
      const paletteMatch = value.match(/^(\d+)=(#[0-9a-fA-F]+)$/);
      if (paletteMatch) {
        theme.palette[paletteMatch[1]] = paletteMatch[2];
      }
    } else {
      theme[key] = value;
    }
  }
  return theme;
}

// Standard ANSI color names
const ANSI_NAMES = [
  'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white',
  'bright-black', 'bright-red', 'bright-green', 'bright-yellow',
  'bright-blue', 'bright-magenta', 'bright-cyan', 'bright-white'
];

// Load theme
const themePath = '/Users/ejfox/.config/ghostty/themes/vulpes-reddishnovember-light';
const content = readFileSync(themePath, 'utf-8');
const theme = parseGhosttyTheme(content);

const bg = theme.background || '#ffffff';
const fg = theme.foreground || '#000000';

console.log('🦊 Vulpes Light Ghostty Theme Contrast Audit\n');
console.log('='.repeat(60));
console.log(`Background: ${bg} (luminance: ${luminance(bg).toFixed(3)})`);
console.log(`Foreground: ${fg}`);
console.log(`WCAG AA requires ${WCAG_AA_NORMAL}:1 for normal text\n`);

const improvements = {};

// Check main foreground
console.log('MAIN COLORS:\n');
const fgRatio = getContrastRatio(fg, bg);
const fgPass = fgRatio >= WCAG_AA_NORMAL;
console.log(`${fgPass ? '✅' : '❌'} foreground: ${fg}`);
console.log(`   Ratio: ${fgRatio.toFixed(2)}:1`);
if (!fgPass) {
  const improved = adjustForContrast(fg, bg);
  console.log(`   💡 Suggested: ${improved} (${getContrastRatio(improved, bg).toFixed(2)}:1)`);
  improvements.foreground = improved;
}
console.log();

// Check cursor
if (theme['cursor-color']) {
  const cursorRatio = getContrastRatio(theme['cursor-color'], bg);
  const cursorPass = cursorRatio >= WCAG_AA_LARGE;
  console.log(`${cursorPass ? '✅' : '⚠️ '} cursor-color: ${theme['cursor-color']}`);
  console.log(`   Ratio: ${cursorRatio.toFixed(2)}:1`);
  console.log();
}

// Check selection
if (theme['selection-background'] && theme['selection-foreground']) {
  const selRatio = getContrastRatio(theme['selection-foreground'], theme['selection-background']);
  const selPass = selRatio >= WCAG_AA_NORMAL;
  console.log(`${selPass ? '✅' : '❌'} selection: ${theme['selection-foreground']} on ${theme['selection-background']}`);
  console.log(`   Ratio: ${selRatio.toFixed(2)}:1`);
  console.log();
}

// Check palette colors
console.log('ANSI PALETTE:\n');

for (let i = 0; i < 16; i++) {
  const color = theme.palette[i];
  if (!color) continue;

  const ratio = getContrastRatio(color, bg);
  const passes = ratio >= WCAG_AA_NORMAL;
  const passesLarge = ratio >= WCAG_AA_LARGE;

  const status = passes ? '✅' : passesLarge ? '⚠️ ' : '❌';
  const name = ANSI_NAMES[i].padEnd(14);

  console.log(`${status} ${i.toString().padStart(2)}) ${name} ${color}  ${ratio.toFixed(2)}:1`);

  // Flag if green slots aren't actually green
  if ((i === 2 || i === 10) && !color.toLowerCase().includes('0') ) {
    const hue = chroma(color).hsl()[0];
    if (hue < 60 || hue > 180) {
      console.log(`      ⚠️  ANSI green slot has non-green hue (${hue.toFixed(0)}°)`);
    }
  }

  if (!passes) {
    const improved = adjustForContrast(color, bg);
    console.log(`      💡 Suggested: ${improved} (${getContrastRatio(improved, bg).toFixed(2)}:1)`);
    improvements[`palette-${i}`] = improved;
  }
}

// Summary
console.log('\n' + '='.repeat(60));
console.log('ISSUES FOUND:\n');

// Check for missing actual greens
const green = theme.palette[2];
const brightGreen = theme.palette[10];
if (green && brightGreen) {
  const greenHue = chroma(green).hsl()[0];
  const brightGreenHue = chroma(brightGreen).hsl()[0];

  if ((greenHue < 60 || greenHue > 180) && (brightGreenHue < 60 || brightGreenHue > 180)) {
    console.log('🚨 NO ACTUAL GREENS IN PALETTE!');
    console.log('   ANSI slots 2 and 10 should be green for:');
    console.log('   - Git diff additions');
    console.log('   - Success messages');
    console.log('   - Many CLI tools expect green here\n');

    // Suggest vulpes-compatible greens (from the gitconfig)
    const suggestedGreen = '#2d8659';  // Darker for light bg
    const suggestedBrightGreen = '#1a7a4a';
    console.log(`   💡 Suggested palette 2:  ${suggestedGreen} (${getContrastRatio(suggestedGreen, bg).toFixed(2)}:1)`);
    console.log(`   💡 Suggested palette 10: ${suggestedBrightGreen} (${getContrastRatio(suggestedBrightGreen, bg).toFixed(2)}:1)`);
    improvements['palette-2'] = suggestedGreen;
    improvements['palette-10'] = suggestedBrightGreen;
  }
}

if (Object.keys(improvements).length === 0) {
  console.log('🎉 All colors pass accessibility checks!');
} else {
  console.log('\nSUGGESTED FIXES:');
  for (const [key, value] of Object.entries(improvements)) {
    console.log(`  ${key}: ${value}`);
  }
}
