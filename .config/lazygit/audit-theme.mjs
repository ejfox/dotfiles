#!/usr/bin/env node
// Lazygit Theme Contrast Auditor using chroma.js
// Checks WCAG contrast ratios and suggests improvements

import chroma from 'chroma-js';
import { readFileSync, writeFileSync } from 'fs';
import { parse, stringify } from 'yaml';

const WCAG_AA_NORMAL = 4.5;
const WCAG_AA_LARGE = 3.0;
const WCAG_AAA_NORMAL = 7.0;

// Assume a light background for light theme (typical terminal white/off-white)
const ASSUMED_BG = '#ffffff';
const ASSUMED_DARK_BG = '#2d1a22'; // defaultFgColor inverted as potential bg

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

  // Try darkening or lightening to hit target contrast
  for (let i = 0; i <= 100; i++) {
    const adjusted = isLightBg
      ? c.darken(i * 0.05)
      : c.brighten(i * 0.05);

    if (getContrastRatio(adjusted, bg) >= targetRatio) {
      return adjusted.hex();
    }
  }
  return color; // couldn't improve
}

// Load theme
const themePath = '/Users/ejfox/.config/lazygit/vulpes-reddishnovember-light.yml';
const themeContent = readFileSync(themePath, 'utf-8');
const theme = parse(themeContent);

console.log('🦊 Vulpes Light Theme Contrast Audit\n');
console.log('=' .repeat(60));
console.log(`WCAG AA requires ${WCAG_AA_NORMAL}:1 for normal text, ${WCAG_AA_LARGE}:1 for large/bold\n`);

const colors = theme.gui.theme;
const improvements = {};

// Define what we're checking: [name, colorKey, background, description]
const checks = [
  // Text colors against white background
  ['defaultFgColor', 'defaultFgColor', ASSUMED_BG, 'Main text on white bg'],
  ['optionsTextColor', 'optionsTextColor', ASSUMED_BG, 'Options/menu text'],
  ['unstagedChangesColor', 'unstagedChangesColor', ASSUMED_BG, 'Unstaged changes indicator'],

  // Border colors (need less contrast but should be visible)
  ['activeBorderColor', 'activeBorderColor', ASSUMED_BG, 'Active panel border'],
  ['inactiveBorderColor', 'inactiveBorderColor', ASSUMED_BG, 'Inactive panel border'],
  ['searchingActiveBorderColor', 'searchingActiveBorderColor', ASSUMED_BG, 'Search active border'],

  // Text on colored backgrounds
  ['cherryPickedCommitFgColor', 'cherryPickedCommitFgColor', colors.cherryPickedCommitBgColor?.[0] || '#cc0044', 'Cherry-pick text on red bg'],
  ['markedBaseCommitFgColor', 'markedBaseCommitFgColor', colors.markedBaseCommitBgColor?.[0] || '#aa0033', 'Marked commit text on red bg'],

  // Selection backgrounds (check fg against them)
  ['defaultFgColor on selectedLineBgColor', 'defaultFgColor', colors.selectedLineBgColor?.[0] || '#e8c0d0', 'Text on selected row'],
  ['defaultFgColor on inactiveViewSelectedLineBgColor', 'defaultFgColor', colors.inactiveViewSelectedLineBgColor?.[0] || '#ddb8c8', 'Text on inactive selected'],

  // Branch colors
  ['main branch', null, ASSUMED_BG, 'Main branch name', '#aa0033'],
  ['develop branch', null, ASSUMED_BG, 'Develop branch name', '#cc0055'],
  ['feature branch', null, ASSUMED_BG, 'Feature branch name', '#dd3355'],
  ['fix branch', null, ASSUMED_BG, 'Fix branch name', '#dd2233'],
];

console.log('Color Contrast Analysis:\n');

for (const [name, colorKey, bg, desc, directColor] of checks) {
  const color = directColor || (colors[colorKey]?.[0]);
  if (!color) continue;

  const ratio = getContrastRatio(color, bg);
  const passesAA = ratio >= WCAG_AA_NORMAL;
  const passesAALarge = ratio >= WCAG_AA_LARGE;
  const passesAAA = ratio >= WCAG_AAA_NORMAL;

  const status = passesAAA ? '✅ AAA' : passesAA ? '✅ AA ' : passesAALarge ? '⚠️  AA-L' : '❌ FAIL';

  console.log(`${status} ${name}`);
  console.log(`       Color: ${color} on ${bg}`);
  console.log(`       Ratio: ${ratio.toFixed(2)}:1`);
  console.log(`       Luminance: fg=${luminance(color).toFixed(3)}, bg=${luminance(bg).toFixed(3)}`);

  if (!passesAA) {
    const improved = adjustForContrast(color, bg, WCAG_AA_NORMAL);
    const newRatio = getContrastRatio(improved, bg);
    console.log(`       💡 Suggested: ${improved} (${newRatio.toFixed(2)}:1)`);

    if (colorKey && !directColor) {
      improvements[colorKey] = improved;
    }
  }
  console.log();
}

// Selection background visibility check
console.log('\n' + '=' .repeat(60));
console.log('Selection Background Visibility:\n');

const selectionBgs = [
  ['selectedLineBgColor', colors.selectedLineBgColor?.[0]],
  ['selectedRangeBgColor', colors.selectedRangeBgColor?.[0]],
  ['inactiveViewSelectedLineBgColor', colors.inactiveViewSelectedLineBgColor?.[0]],
];

for (const [name, color] of selectionBgs) {
  if (!color) continue;

  const contrastWithWhite = getContrastRatio(color, ASSUMED_BG);
  const lum = luminance(color);

  // For selection bg, we want it distinct from white but not too dark
  // Ideal: contrast 1.5-3.0 with white bg (visible but not overwhelming)
  const isGoodSelection = contrastWithWhite >= 1.3 && contrastWithWhite <= 3.5;

  console.log(`${isGoodSelection ? '✅' : '⚠️ '} ${name}: ${color}`);
  console.log(`       Contrast with white: ${contrastWithWhite.toFixed(2)}:1`);
  console.log(`       Luminance: ${lum.toFixed(3)}`);

  if (contrastWithWhite < 1.3) {
    // Too similar to white - darken it
    const darker = chroma(color).darken(0.5).hex();
    console.log(`       💡 Too faint - suggest: ${darker}`);
    improvements[name] = darker;
  } else if (contrastWithWhite > 3.5) {
    // Too dark for a subtle selection
    const lighter = chroma(color).brighten(0.3).hex();
    console.log(`       💡 Too dark - suggest: ${lighter}`);
  }
  console.log();
}

// Summary
console.log('\n' + '=' .repeat(60));
console.log('SUGGESTED IMPROVEMENTS:\n');

if (Object.keys(improvements).length === 0) {
  console.log('🎉 All colors pass accessibility checks!');
} else {
  for (const [key, value] of Object.entries(improvements)) {
    const original = colors[key]?.[0] || 'N/A';
    console.log(`${key}:`);
    console.log(`  Before: ${original}`);
    console.log(`  After:  ${value}`);
    console.log();
  }

  // Offer to write updated theme
  console.log('\nWriting improved theme to vulpes-reddishnovember-light-improved.yml...');

  const improvedTheme = JSON.parse(JSON.stringify(theme));
  for (const [key, value] of Object.entries(improvements)) {
    if (improvedTheme.gui.theme[key]) {
      improvedTheme.gui.theme[key][0] = value;
    }
  }

  const outputPath = '/Users/ejfox/.config/lazygit/vulpes-reddishnovember-light-improved.yml';
  writeFileSync(outputPath, stringify(improvedTheme));
  console.log(`✅ Written to ${outputPath}`);
}
