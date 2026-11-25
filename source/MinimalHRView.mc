using Toybox.Application as App;
using Toybox.ActivityMonitor as AM;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.WatchUi as Ui;

// Designed specifically for the Forerunner 265S (360 x 360 AMOLED).
// All angles use screen coordinates: 0 = right, 90 = down.
class MinimalHRView extends Ui.WatchFace {
    const BLACK = 0x000000;
    const SILVER = 0xD8D8D4;
    const SHADOW = 0x686B6C;
    const HIGHLIGHT = 0xF6F5F0;
    const TICK = 0x777B7D;
    const TRACK = 0x7F8588;
    const BLUE = 0x41A5D5;
    const RED = 0xE25250;
    const DIM = 0x777B7D;
    const DEG = 0.01745329252;
    const HR_MIN = 40;
    const HR_MAX = 200;
    const HR_START = 205.0;
    const HR_SWEEP = 230.0;
    const HR_MAX_AGE = 180;
    var asleep = false;
    var lastPoll = -1;
    var heartRate = null;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void {
        asleep = true;
    }

    function onExitSleep() as Void {
        asleep = false;
        lastPoll = -1;
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(BLACK, BLACK);
        dc.clear();
        var clock = Sys.getClockTime();
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var hourAngle = (clock.hour % 12 + clock.min / 60.0) * 30.0 - 90.0;
        var minuteAngle = (clock.min + clock.sec / 60.0) * 6.0 - 90.0;

        if (asleep) {
            // AOD: only slim hands and four cardinal ticks. Move the entire
            // dial among eight positions over time to mitigate fixed pixels.
            var phase = (clock.hour * 60 + clock.min) % 8;
            var dx = [-8, 0, 8, 8, 8, 0, -8, -8];
            var dy = [-8, -8, -8, 0, 8, 8, 8, 0];
            cx += dx[phase];
            cy += dy[phase];
            dc.setAntiAlias(false);
            for (var j = 0; j < 4; j += 1) {
                radial(dc, cx, cy, j * 90.0, 145, 154, DIM, 1);
            }
            radial(dc, cx, cy, hourAngle, 0, 91, DIM, 2);
            radial(dc, cx, cy, clock.min * 6.0 - 90.0, 0, 133, DIM, 2);
            return;
        }

        dc.setAntiAlias(true);
        drawDial(dc, cx, cy);
        refreshHeartRate();
        drawGauge(dc, cx, cy + 64, App.Properties.getValue("showBpm") == true,
                  App.Properties.getValue("colorGauge") == true);
        // Draw time hands last so the time remains legible above complications.
        drawHand(dc, cx, cy, hourAngle, 94, 5);
        drawHand(dc, cx, cy, minuteAngle, 138, 4);
        dc.setColor(SHADOW, BLACK);
        dc.fillCircle(cx, cy, 6);
        dc.setColor(SILVER, BLACK);
        dc.fillCircle(cx, cy, 4);
        dc.setColor(HIGHLIGHT, BLACK);
        dc.fillCircle(cx - 1, cy - 1, 1);
    }

    function refreshHeartRate() {
        var now = Time.now().value();
        if (lastPoll >= 0 && now >= lastPoll && now - lastPoll < 5) {
            return;
        }
        lastPoll = now;
        heartRate = null;
        // Only use the newest sample. Do not fall back to older valid values
        // if the newest sample is invalid (e.g. off-wrist).
        if (AM has :getHeartRateHistory) {
            var samples = AM.getHeartRateHistory(1, true);
            var sample = samples.next();
            if (sample != null && sample.heartRate != null && sample.when != null) {
                var hr = sample.heartRate;
                var age = now - sample.when.value();
                if (hr != AM.INVALID_HR_SAMPLE && hr > 0 && age >= 0 && age <= HR_MAX_AGE) {
                    heartRate = hr;
                }
            }
        }
    }

    function px(cx, r, angle) {
        return (cx + r * Math.cos(angle * DEG)).toNumber();
    }

    function py(cy, r, angle) {
        return (cy + r * Math.sin(angle * DEG)).toNumber();
    }

    function radial(dc, cx, cy, angle, inner, outer, color, width) {
        dc.setColor(color, BLACK);
        dc.setPenWidth(width);
        dc.drawLine(px(cx, inner, angle), py(cy, inner, angle),
                    px(cx, outer, angle), py(cy, outer, angle));
    }

    function drawDial(dc, cx, cy) {
        for (var i = 0; i < 60; i += 1) {
            var a = i * 6.0 - 90.0;
            if (i % 5 == 0) {
                var inside = 144;
                if (i % 15 == 0) { inside = 140; }
                radial(dc, cx, cy, a, inside, 163, SHADOW, 5);
                radial(dc, cx, cy, a, inside + 1, 162, SILVER, 3);
                radial(dc, cx, cy, a, inside + 2, 161, HIGHLIGHT, 1);
            } else {
                radial(dc, cx, cy, a, 158, 164, TICK, 1);
            }
        }
    }

    function drawHand(dc, cx, cy, angle, length, width) {
        radial(dc, cx, cy, angle, -9, length, SHADOW, width + 2);
        radial(dc, cx, cy, angle, -8, length - 1, SILVER, width);
        radial(dc, cx, cy, angle, 6, length - 3, HIGHLIGHT, 1);
        dc.setColor(SILVER, BLACK);
        dc.fillCircle(px(cx, length - 1, angle), py(cy, length - 1, angle), 2);
    }

    function hrAngle(hr) {
        var v = hr;
        if (v < HR_MIN) { v = HR_MIN; }
        if (v > HR_MAX) { v = HR_MAX; }
        return HR_START - HR_SWEEP * ((v - HR_MIN) / 160.0);
    }

    function arc(dc, cx, cy, radius, start, end, color, width) {
        dc.setColor(color, BLACK);
        dc.setPenWidth(width);
        // Use line segments instead of platform-specific arc direction rules.
        var a = start;
        while (a > end) {
            var b = a - 3.0;
            if (b < end) { b = end; }
            dc.drawLine(px(cx, radius, a), py(cy, radius, a),
                        px(cx, radius, b), py(cy, radius, b));
            a = b;
        }
    }

    function centered(dc, x, y, font, text, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function drawGauge(dc, cx, cy, showBpm, colorGauge) {
        arc(dc, cx, cy, 74, HR_START, HR_START - HR_SWEEP, TRACK, 1);
        if (colorGauge) {
            arc(dc, cx, cy, 75, hrAngle(40), hrAngle(60), BLUE, 3);
            arc(dc, cx, cy, 75, hrAngle(160), hrAngle(200), RED, 3);
        }
        for (var hr = HR_MIN; hr <= HR_MAX; hr += 10) {
            var a = hrAngle(hr);
            var major = (hr - HR_MIN) % 40 == 0;
            var inner = 67;
            var width = 1;
            if (major) { inner = 63; width = 2; }
            radial(dc, cx, cy, a, inner, 71, SILVER, width);
            if (major) {
                centered(dc, px(cx, 49, a), py(cy, 49, a), Gfx.FONT_XTINY, hr.toString(), SILVER);
            }
        }

        // The pointer is independent of the optional digital number.
        // Out-of-range values saturate at the closest end of the scale.
        if (heartRate != null) {
            var needleAngle = hrAngle(heartRate);
            radial(dc, cx, cy, needleAngle, 0, 59, SHADOW, 4);
            radial(dc, cx, cy, needleAngle, 0, 58, HIGHLIGHT, 2);
            dc.setColor(SILVER, BLACK);
            dc.fillCircle(cx, cy, 3);
        } else {
            dc.setColor(SHADOW, BLACK);
            dc.fillCircle(cx, cy, 3);
        }

        if (showBpm) {
            var reading = "--";
            if (heartRate != null) { reading = heartRate.toString(); }
            centered(dc, cx, cy - 42, Gfx.FONT_MEDIUM, reading, HIGHLIGHT);
            centered(dc, cx, cy - 17, Gfx.FONT_XTINY, "BPM", TICK);
        } else {
            centered(dc, cx, cy - 20, Gfx.FONT_XTINY, "BPM", TICK);
            if (heartRate == null) {
                centered(dc, cx, cy - 39, Gfx.FONT_XTINY, "--", TICK);
            }
        }
    }
}
