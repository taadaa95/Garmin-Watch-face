# Minimal HR · v0.1.0

A minimalist analog Connect IQ watch face for Garmin Forerunner 265S (`fr265s`, 360×360 AMOLED).

## Design
- Pure black, silver analog hands, baton indices and subtle minute ticks.
- Lower 40–200 BPM analog gauge with moving needle; configurable numeric readout and blue/red accents.
- Colors are decorative scale accents, not personalized heart-rate zones or medical alerts.
- Latest ActivityMonitor heart-rate sample is checked at most every five seconds while awake, subject to Garmin's update cadence. Invalid, missing or older than 180 seconds hides the pointer and shows `--`. Values outside the dial range clamp the pointer; the number remains exact.
- Always-on mode draws only dim hands and cardinal markers, with an eight-position offset changing each minute. No heart rate is shown in AOD.
- No seconds hand, date, battery meter or network access.

## Build
1. Install Java, OpenSSL and the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).
2. Download the Forerunner 265S device definition and set the SDK as active.
3. Run `bash build.sh` from the repository root. If needed, set `CIQ_SDK` to the SDK directory. The script creates a developer signing key outside the repository if one is absent. Keep it private and reuse it for updates. Set `DEVELOPER_KEY` to use an existing key.
4. The output is `bin/MinimalHR.prg`.

On CachyOS, the SDK Manager may require legacy WebKitGTK libraries. An Ubuntu 22.04 Distrobox with precompiled dependencies was used successfully to install the SDK; compilation subsequently worked natively on CachyOS.

## Install
1. Connect the watch using a USB data cable and select MTP mode.
2. In Dolphin, open `mtp:/` (install `kio-extras` if needed), or use another MTP-capable file manager.
3. Copy only `bin/MinimalHR.prg` into the watch's `GARMIN/APPS` directory.
4. Safely disconnect, hold UP, select Watch Face, find Minimal HR and apply.
5. Use the watch face settings to toggle the BPM number and gauge colors. Settings behavior has not yet been verified on hardware.

## Simulator
Launch `connectiq` and run `monkeydo bin/MinimalHR.prg fr265s`. Test simulated heart rates, missing samples, time hands and low-power mode.

## Verification
- Compiled successfully with Connect IQ SDK 9.3.0.
- Installed on a physical Forerunner 265S; rendering and heart-rate readout confirmed by the owner.
- Battery consumption, always-on behavior and settings still require testing.

## References
- [Device reference](https://developer.garmin.com/connect-iq/device-reference/fr265s/)
- [ActivityMonitor API](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html)
- [Watch face guidelines](https://developer.garmin.com/connect-iq/articles/user-experience-guidelines/Watch_Faces.html)
