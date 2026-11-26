# Lunaris v0.1.4

An independent 360 × 360 AMOLED Connect IQ lunar watch face for Garmin Forerunner 265S (fr265s).

## Features
- 12-hour clock, AM/PM, date, heart rate, battery percentage.
- Large Moon, illuminated fraction and countdown to the next full moon.
- Daily UTC ephemeris knots calculated with Swiss Ephemeris (Moshier), interpolated at runtime. New/full moon times are computed from apparent geocentric ecliptic longitude crossings. Data coverage: Jan 1 2024 through Dec 31 2037 UTC. Outside that range lunar data is explicitly unavailable.
- The phase artwork has 64 states, so the visible terminator is quantized to 5.625 degrees. Numerical illumination is interpolated from daily phase angle knots. This is not a planetarium-grade rendering: fixed north-up orientation, no local sky angle, libration or eclipses. No network/location permission required.
- Lunar artwork uses the full illuminated disk from the approved AI concept (NOT NASA photographic data). To replace it with real lunar geography use the optional instructions below. The astronomical calculations are independent of the artwork.
- AOD: dim time-only, pixel shifting, no sensor/phase polling while asleep. Actual brightness/timeout controlled by Garmin.

## Changes in v0.1.4
- Converted all clock digits and colon from opaque black RGB cells to transparent antialiased PNGs.
- Removed rectangular star exclusion zones; 700 stars span the continuous sky outside the lunar disk. Rebuilt all 64 matching tiles.
- Heart and battery outlines use a transparent drawing background. Layout, astronomy, Moon size and AOD unchanged.
- Asset transparency and tile alignment validated locally; simulator and device test pending.

## Changes in v0.1.3
- Enlarged the lunar disk from 180 to 216 pixels (44% more area) and rebuilt all 64 states using the new full-Moon concept texture.
- Brighter and denser starfield, visible star clusters and blue halo; shifted time/date and side metrics upward to provide clearance.
- Retained the illumination and next full moon countdown. Existing ephemeris, app ID, and always-on display unchanged.
- Updated renderer uses matching indexed sky pixels outside the lunar disk to avoid tile seams.

## Changes in v0.1.2
- Removed the lunar phase name beneath the Moon. Retained the illumination percentage and next full moon countdown. All artwork and lunar calculations unchanged.

## Changes in v0.1.1
- Removed the decorative star-and-lines header and lunar-age row.
- More visible, varied stars across the night sky; matching sky tiles regenerated for all 64 phases.
- Moon size, time, HR, battery, lunar calculations and always-on display unchanged.

## Build & test
```sh
bash build.sh
monkeydo bin/Lunaris.prg fr265s
```
Uses existing SDK and signing key at `$HOME/.config/minimal-hr/developer_key.der`. Keep the key private. Launch the simulator before monkeydo. Install by copying only `bin/Lunaris.prg` into GARMIN/APPS. New application UUID allows coexistence with Minimal HR and Cyan Pulse.

## Optional NASA imagery
The pre-rendered assets are included; no Python or internet is needed to compile. If you want true lunar surface imagery, download the NASA Goddard LRO-based full-Moon visualization from https://commons.wikimedia.org/wiki/File:Full_Moon_(15984763045).jpg (NASA Goddard Space Flight Center, CC BY 2.0 https://creativecommons.org/licenses/by/2.0/; modified via crop, resize, shading and palette quantization). Then, with Python, Pillow and NumPy installed, run:
```sh
python tools/render_moons.py --moon /path/to/full-moon.jpg
bash build.sh
```
The generator can also recreate the initial artwork without `--moon`. The source crop is included. No font files are distributed; the clock uses raster assets from Cyan Pulse and native Garmin fonts for smaller text.

Ephemeris reference: https://www.astro.com/swisseph/swephprg.htm (swe_pheno_ut and swe_calc_ut). Only numerical outputs of the Moshier ephemeris are included, not its library. No real-time internet access. Source structure and resource references checked; Connect IQ SDK compilation and device memory/power testing still required.
