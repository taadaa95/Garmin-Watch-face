# Minimal HR v0.2.5 — Visible unlit leading tube

Forerunner 265S / 360×360. Retro Nixie-style watch face with detailed tube artwork, 12-hour AM/PM, date, BPM, pulse gauge and battery percentage.

## Changes from v0.2.4
- The first slot now shows a matching unlit glass housing with dim wire mesh for hours 1–9. No leading zero.
- All other graphics, layout, fonts and low-power rendering are unchanged.

## Previous changes from v0.2.3
- Main tube sprites now measure 70×128 pixels instead of 64×112 (two-digit hours) or 76×112 (single-digit hours). All numerals have identical dimensions.
- Four positions are always reserved, with the first unlit for hours 1–9; no leading zero. The colon and minute digits stay in the same positions at 9:59 → 10:00 and 12:59 → 1:00.
- AM/PM moves down slightly. The low-power layout also reserves four positions, retaining its existing burn-in offset.
- Date, BPM, battery, gauge and their fonts are unchanged. Removed unused second set of digit bitmaps to reduce duplicated resources.

## Build/test
Run `bash build.sh` then `monkeydo bin/MinimalHR.prg fr265s` with the simulator running. Reuses the same app ID and signing key. Check single- and double-digit hours, including 9:59 and 10:00, and low-power mode. Source and asset geometry checked locally; no Garmin SDK or simulator test performed here. GitHub is unchanged.
