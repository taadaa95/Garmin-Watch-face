# Cyan Pulse v0.1.6

A separate minimalist digital Connect IQ watch face for the Garmin Forerunner 265S (360 × 360 AMOLED). The app has a fresh UUID and output filename; it does not replace Minimal HR.

## Build and test

```sh
bash build.sh
monkeydo bin/CyanPulse.prg fr265s
```

Start `connectiq` in the existing `garmin-sdk` Distrobox first. Build on the CachyOS host. The script reuses the existing private signing key at `~/.config/minimal-hr/developer_key.der` (or `DEVELOPER_KEY`), never packages it. For hardware, copy `bin/CyanPulse.prg` to `GARMIN/Apps/` over USB/MTP and apply Cyan Pulse.

## Display

- Thin, rasterized time numerals, 12-hour format, no leading zero or seconds, small AM/PM.
- Date, cyan accent, current BPM and a 40–200 BPM proportional ring (not a medical or personal HR-zone indicator).
- True last-60-minute HR trend: 30 two-minute bins, average of valid samples per bin, missing bins left blank. Dynamic vertical scale with minimum 30 BPM span. No simulated values on the actual watch face. Latest HR is considered unavailable after 180 seconds. History is queried at most every 30 seconds while awake, latest HR every five seconds at most, subject to watch-face callback and sensor cadence.
- Battery percentage and proportional fill, dim full-size time and date standby display.

The preview is a native-resolution illustration using the actual time bitmaps and representative sample data; Garmin system-font metrics and actual sensor history may differ. Source has not yet been compiled or tested in the simulator or on hardware in this environment. No changes to the existing GitHub repository.

API: https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html

## v0.1.1
Replaced the segmented line approximation of the HR fill with a native clockwise arc, using the same radius and pen width as the background. Zero and full-scale readings are handled separately. All other rendering and data logic remain unchanged.


## v0.1.2
Scaled the overall layout up to better fill the 360×360 display. Enlarged the time bitmaps, raised the time block, expanded the heart-rate gauge, increased the graph height, widened the date accent line, and slightly enlarged the battery row while preserving the same overall design.

## v0.1.3
Always-on/low-power mode retains the normal time, AM/PM, date and accent line at identical coordinates and dimensions, using dimmed digit bitmaps and text colors. No positional pixel shifting. Heart-rate gauge, history graph and battery are omitted; sensor polling is suspended. Firmware still controls display brightness, timeout and power restrictions. Static pixel usage was checked for the dim time bitmaps; actual AOD compliance, text rendering and battery use require simulator/device testing.


## v0.1.4
Removed graph sample dots. Replaced the three-step per-column fill with a subtle, continuous vertical cyan-to-black gradient across the plot, rendered beneath the thin cyan trace. Missing readings still break the trace and fill; the 60-minute time axis, HR acquisition, normal layout and full-size dim-mode clock/date are unchanged. Isolated samples are not drawn as dots.


## v0.1.5
Fixes the graph rendering watchdog failure reported in v0.1.4. Replaces the nested pixel scan with a single vertical gradient made from native horizontal rectangle fills and native polygon/rectangle masks. Adjacent real samples are joined by a thin anti-aliased line, without dots. Missing intervals remain empty. No change to normal layout or dim mode. Runtime validation in the Garmin simulator and on hardware remains pending.


## v0.1.6
Increases gradient visibility with a brighter linear cyan-to-black fade anchored to the highest connected sample, rather than a dark quadratic fade anchored to the plot ceiling. Uses at most 30 native horizontal rectangle fills and the existing polygon masks; no per-pixel scan, no dots, no invented samples. Other display and AOD behavior are unchanged. Simulator and device validation still required.
