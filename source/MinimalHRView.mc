using Toybox.Application as App;
using Toybox.ActivityMonitor as AM;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.WatchUi as Ui;

// Retro filament digital face, fixed 360x360 layout for fr265s.
class MinimalHRView extends Ui.WatchFace {
    const BLACK = 0x000000;
    const AMBER = 0xFFA23A;
    const CREAM = 0xFFE0B2;
    const HR_MIN = 40;
    const HR_MAX = 200;
    const HR_MAX_AGE = 180;
    var asleep = false;
    var lastPoll = -1;
    var heartRate = null;
    var glyphs = [[[[22,2],[17,3],[13,4],[10,7],[7,11],[5,17],[4,23],[3,30],[3,38],[3,46],[4,54],[5,60],[7,65],[10,69],[13,72],[17,73],[22,74],[27,73],[31,72],[34,69],[37,65],[39,60],[40,54],[41,46],[41,38],[41,30],[40,23],[39,17],[37,11],[34,7],[31,4],[27,3],[22,2]]],[[[9,17],[23,3],[23,74]],[[10,74],[37,74]]],[[[4,19],[5,15],[6,12],[7,9],[10,6],[12,4],[15,3],[18,2],[22,2],[26,2],[30,3],[33,5],[36,7],[38,10],[40,13],[41,17],[41,21],[40,26],[39,30],[37,33],[34,37],[30,40],[26,43],[21,46],[17,50],[14,53],[11,56],[8,59],[6,62],[5,65],[4,68],[3,71],[3,74],[41,74]]],[[[4,12],[6,10],[8,7],[11,6],[13,4],[15,3],[18,3],[20,2],[23,2],[27,2],[31,3],[34,5],[36,7],[38,10],[39,13],[40,17],[40,21],[39,25],[38,28],[36,31],[33,33],[30,35],[27,36],[23,37],[20,37],[24,37],[28,38],[32,39],[36,41],[38,44],[40,47],[42,50],[42,55],[42,60],[40,63],[39,67],[36,69],[33,71],[30,73],[26,74],[22,74],[19,74],[16,73],[13,72],[10,71],[8,70],[6,68],[4,66],[3,64]]],[[[32,74],[32,2],[3,49],[43,49]]],[[[39,2],[8,2],[5,36],[7,34],[10,32],[12,31],[15,30],[17,30],[20,30],[22,30],[25,30],[29,31],[33,32],[36,34],[38,37],[40,40],[41,44],[41,48],[41,53],[40,58],[39,62],[37,66],[35,69],[32,71],[29,73],[25,74],[21,74],[18,74],[15,73],[12,72],[10,71],[8,70],[6,68],[4,66],[3,64]]],[[[37,8],[33,5],[30,4],[26,3],[22,3],[18,4],[15,6],[12,9],[9,14],[7,19],[5,24],[4,30],[3,35],[3,40],[3,46],[3,51],[4,56],[5,61],[6,64],[8,67],[10,70],[13,72],[16,73],[19,74],[23,74],[27,74],[31,72],[34,70],[37,68],[39,65],[40,61],[41,57],[41,52],[40,47],[39,44],[37,40],[35,38],[32,36],[29,34],[26,33],[22,33],[18,33],[15,34],[12,35],[10,37],[7,40],[6,42],[5,45],[4,49]]],[[[3,3],[41,3],[15,74]]],[[[22,36],[18,36],[15,35],[12,33],[9,31],[7,29],[6,26],[5,23],[5,19],[5,15],[6,12],[8,9],[10,6],[12,4],[15,3],[18,2],[22,2],[26,2],[29,3],[33,4],[35,6],[37,9],[39,12],[40,15],[40,19],[40,23],[39,26],[37,29],[36,32],[33,34],[30,35],[26,36],[22,36],[17,36],[14,37],[10,39],[8,41],[6,44],[4,47],[3,51],[3,55],[3,60],[4,63],[6,67],[8,69],[11,71],[14,73],[18,74],[22,74],[26,74],[30,73],[33,71],[36,69],[38,67],[40,63],[41,60],[41,55],[41,51],[40,47],[38,44],[36,41],[33,39],[30,37],[26,36],[22,36]]],[[[39,27],[39,21],[38,16],[37,12],[35,8],[32,6],[29,4],[26,2],[22,2],[18,2],[14,4],[11,6],[8,8],[6,11],[4,15],[3,19],[3,24],[3,29],[4,33],[6,36],[8,39],[11,41],[14,43],[18,44],[22,44],[26,44],[29,43],[33,41],[35,39],[37,36],[39,33],[40,29],[40,25],[40,33],[40,40],[39,48],[37,55],[35,61],[32,66],[29,70],[25,73],[22,74],[19,74],[16,74],[14,74],[11,72],[9,71],[7,70],[6,68]]]];

    var frame = null;
    var bpmLabel = null;
    var colon = null;
    var blankTube = null;
    var digits = [null,null,null,null,null,null,null,null,null,null];
    var digitIds = [Rez.Drawables.Digit0,Rez.Drawables.Digit1,Rez.Drawables.Digit2,Rez.Drawables.Digit3,Rez.Drawables.Digit4,Rez.Drawables.Digit5,Rez.Drawables.Digit6,Rez.Drawables.Digit7,Rez.Drawables.Digit8,Rez.Drawables.Digit9];
    var dateFont = Gfx.FONT_XTINY;
    var smallFont = Gfx.FONT_XTINY;

    function initialize() {
        WatchFace.initialize();
        // Scale the native typeface to fit the 360 px face. A safe fallback
        // remains available if the firmware does not expose scalable fonts.
        if (Gfx has :getVectorFont) {
            var f = Gfx.getVectorFont({:font=>Gfx.FONT_SMALL,:scale=>0.60});
            if (f != null) { dateFont = f; }
            f = Gfx.getVectorFont({:font=>Gfx.FONT_XTINY,:scale=>0.55});
            if (f != null) { smallFont = f; }
        }
    }

    function onEnterSleep() as Void { asleep = true; }
    function onExitSleep() as Void {
        asleep = false;
        lastPoll = -1;
        Ui.requestUpdate();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(BLACK, BLACK); dc.clear();
        var clock=Sys.getClockTime();
        var h=clock.hour%12; if (h==0) { h=12; }
        var period="AM"; if (clock.hour>=12) { period="PM"; }
        dc.setAntiAlias(!asleep);
        if (asleep) {
            drawLowPower(dc,h,clock.min,period,clock.hour);
            return;
        }
        if (frame==null) { frame=Ui.loadResource(Rez.Drawables.RetroFrame); }
        if (colon==null) { colon=Ui.loadResource(Rez.Drawables.RetroColon); }
        dc.drawBitmap(0,0,frame);
        drawDate(dc);
        drawDigital(dc,h,clock.min,period);
        refreshHeartRate();
        drawStatus(dc);
        drawGauge(dc);
    }

    function digitBitmap(digit) {
        if (digits[digit]==null) { digits[digit]=Ui.loadResource(digitIds[digit]); }
        return digits[digit];
    }

    function drawDigital(dc,h,m,period) {
        // Four fixed positions, with an unlit glass tube for 1-9.
        // Minutes and colon never jump when the hour changes to/from 10.
        var values=[h/10,h%10,m/10,m%10];
        var w=70; var gap=4; var cw=20;
        var x=(360-(4*w+2*gap+cw))/2;
        for (var i=0;i<4;i+=1) {
            if (i==2) { dc.drawBitmap(x,82,colon); x+=cw; }
            else if (i>0) { x+=gap; }
            if (i==0 && h<10) {
                if (blankTube==null) { blankTube=Ui.loadResource(Rez.Drawables.BlankTube); }
                dc.drawBitmap(x,82,blankTube);
            } else { dc.drawBitmap(x,82,digitBitmap(values[i])); }
            x+=w;
        }
        fitLabel(dc,180,216,smallFont,period,AMBER,54);
    }

    function drawLowPower(dc,h,m,period,rawHour) {
        var values=[h/10,h%10,m/10,m%10];
        var phase=(rawHour*60+m)%8;
        var dx=[-8,0,8,8,8,0,-8,-8]; var dy=[-8,-8,-8,0,8,8,8,0];
        var w=42; var gap=5; var cw=12;
        var x=(360-(4*w+2*gap+cw))/2+dx[phase]; var y=145+dy[phase];
        for (var i=0;i<4;i+=1) {
            if (i==2) {
                dc.setColor(0x804018,BLACK);
                dc.fillCircle(x+6,y+20,2); dc.fillCircle(x+6,y+42,2); x+=cw;
            } else if (i>0) { x+=gap; }
            if (i!=0 || h>=10) { strokeGlyph(dc,glyphs[values[i]],x+5,y,0.73,0x804018,2); }
            x+=w;
        }
        fitLabel(dc,180+dx[phase],y+70,smallFont,period,0x804018,54);
    }

    function fitLabel(dc,x,y,font,value,color,maxWidth) {
        // Bound the entire text width, including three-digit HR and 100%.
        // Vector scaling is optional; fallback font never overlaps other fields.
        var f=font;
        if (dc.getTextWidthInPixels(value,f)>maxWidth && (Gfx has :getVectorFont)) {
            var factor=(maxWidth.toFloat()/dc.getTextWidthInPixels(value,f))*0.96;
            var smaller=Gfx.getVectorFont({:font=>f,:scale=>factor});
            if (smaller!=null) { f=smaller; }
        }
        if (dc.getTextWidthInPixels(value,f)>maxWidth) { f=Gfx.FONT_XTINY; }
        textAt(dc,x,y,f,value,color);
    }

    function drawDate(dc) {
        var date=Gregorian.info(Time.now(),Time.FORMAT_SHORT);
        var days=["SUN","MON","TUE","WED","THU","FRI","SAT"];
        var months=["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
        var label=days[date.day_of_week-1]+", "+months[date.month-1]+" "+date.day.toString();
        fitLabel(dc,180,53,dateFont,label,CREAM,234);
    }

    function drawStatus(dc) {
        // Use the same clean type family as the date for BPM and battery,
        // rather than the custom metric glyphs, to keep the typography unified.
        var metricFont = dateFont;
        var unitFont = smallFont;

        if (App.Properties.getValue("showBpm")==true) {
            var hrValue = "--";
            if (heartRate != null) { hrValue = heartRate.toString(); }
            fitLabel(dc,122,249,metricFont,hrValue,CREAM,46);
            fitLabel(dc,162,249,unitFont,"BPM",AMBER,38);
        } else {
            fitLabel(dc,130,249,smallFont,"PULSE",AMBER,78);
        }

        var battery=Sys.getSystemStats().battery.toNumber();
        if (battery<0) { battery=0; } if (battery>100) { battery=100; }
        for (var i=0;i<5;i+=1) {
            var pct=battery-i*20; if (pct<0) { pct=0; } if (pct>20) { pct=20; }
            dc.setColor(0x3D1809,BLACK); dc.fillRectangle(197+i*6,242,5,12);
            var w=(pct*5+19)/20;
            if (w>0) { dc.setColor(0xFFA526,BLACK); dc.fillRectangle(197+i*6,242,w,12); }
        }
        fitLabel(dc,276,249,metricFont,battery.toString()+"%",CREAM,62);
    }

    function drawGauge(dc) {
        var colors=[0xFFC034,0xFFB62F,0xFFAC2A,0xFFA225,0xFF9820,0xFF8E1B,0xFF8416,0xFF7A11,0xFF700C,0xFF6608,0xFF5C05,0xFF5204,0xFF4803,0xFF3E03,0xFF3403,0xFF2403];
        if (heartRate==null) { return; }
        var v=heartRate; if (v<HR_MIN) { v=HR_MIN; } if (v>HR_MAX) { v=HR_MAX; }
        var lit=(v-HR_MIN)*16/(HR_MAX-HR_MIN); if (lit==0) { lit=1; }
        for (var i=0;i<lit;i+=1) {
            var c=AMBER; if (App.Properties.getValue("colorGauge")==true) { c=colors[i]; }
            dc.setColor(c,BLACK); dc.fillRoundedRectangle(83+i*12,286,10,17,2);
        }
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


    function line(dc,x1,y1,x2,y2,color,width) {
        dc.setColor(color, BLACK);
        dc.setPenWidth(width);
        dc.drawLine(x1,y1,x2,y2);
    }

    function textAt(dc,x,y,font,value,color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x,y,font,value,Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function strokeGlyph(dc,paths,x,y,s,color,width) {
        dc.setColor(color, BLACK);
        dc.setPenWidth(width);
        for (var j=0;j<paths.size();j+=1) {
            var p=paths[j];
            for (var k=1;k<p.size();k+=1) {
                var x1=(x+p[k-1][0]*s).toNumber();
                var y1=(y+p[k-1][1]*s).toNumber();
                var x2=(x+p[k][0]*s).toNumber();
                var y2=(y+p[k][1]*s).toNumber();
                dc.drawLine(x1,y1,x2,y2);
            }
            // Rounded terminals are characteristic of wire numerals.
            var r=width/2;
            if (r>0) {
                dc.fillCircle((x+p[0][0]*s).toNumber(),(y+p[0][1]*s).toNumber(),r);
                dc.fillCircle((x+p[p.size()-1][0]*s).toNumber(),(y+p[p.size()-1][1]*s).toNumber(),r);
            }
        }
    }

}
