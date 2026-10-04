# pixel-fonts

Outline fonts that `lib/pixelfx.py` rasterizes (1-bit, no antialiasing) into
dots for the pixel canvas, so text can dither / rain / de-explode in a face the
device firmware doesn't have. The device's own 5x7 font is embedded in
pixelfx.py itself (`font="gfx"`).

| key    | file            | crisp at | source / license |
|--------|-----------------|----------|------------------|
| `ocra` | OCRA.otf        | 11px     | OCR-A, Matthew Skala's outlines (ocr-0.3.1, tsukurimashou.org/ocr.php.en); free for any use |
| `ocrb` | ocrb10.otf      | 15px     | OCR-B outline, Skala / Norbert Schwarz (CTAN fonts/ocr-b-outline); free for any use |
| `micr` | GnuMICR.ttf     | 16px     | GnuMICR E-13B, Eric Sandeen, GPL-2 (github.com/alerque/gnumicr). Source `GnuMICR-GnuMICR.raw` and license `GnuMICR-COPYING` ship alongside, as the GPL requires. Digits + the four banking symbols only. |
