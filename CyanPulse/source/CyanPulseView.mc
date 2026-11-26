using Toybox.ActivityMonitor as AM;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.WatchUi as Ui;

// Original 360 x 360 AMOLED layout; all coordinates are native pixels.
class CyanPulseView extends Ui.WatchFace {
    const BLACK = 0x000000;
    const WHITE = 0xF8F9FA;
    const MUTED = 0xA8ADB2;
    const CYAN = 0x00E4EF;
    const TRACK = 0x33373B;
    const HR_MIN = 40;
    const HR_MAX = 200;
    const BIN_COUNT = 30;
    const BIN_SECONDS = 120;
    var asleep = false;
    var heartRate = null;
    var lastPoll = -1;
    var lastGraph = -1;
    var trend = new [30];
    var digitIds = [Rez.Drawables.Digit0, Rez.Drawables.Digit1, Rez.Drawables.Digit2, Rez.Drawables.Digit3, Rez.Drawables.Digit4, Rez.Drawables.Digit5, Rez.Drawables.Digit6, Rez.Drawables.Digit7, Rez.Drawables.Digit8, Rez.Drawables.Digit9];
    var dateFont = Gfx.FONT_XTINY;
    var metricFont = Gfx.FONT_XTINY;
    var periodFont = Gfx.FONT_XTINY;
    var labelFont = Gfx.FONT_XTINY;
    const DIM_WHITE = 0x6B6B6C;
    const DIM_MUTED = 0x484A4D;
    const DIM_CYAN = 0x006268;
    var dimDigitIds = [Rez.Drawables.DimDigit0, Rez.Drawables.DimDigit1, Rez.Drawables.DimDigit2, Rez.Drawables.DimDigit3, Rez.Drawables.DimDigit4, Rez.Drawables.DimDigit5, Rez.Drawables.DimDigit6, Rez.Drawables.DimDigit7, Rez.Drawables.DimDigit8, Rez.Drawables.DimDigit9];

    function initialize() {
        WatchFace.initialize();
        if (Gfx has :getVectorFont) {
            dateFont = font(20, Gfx.FONT_XTINY);
            metricFont = font(28, Gfx.FONT_XTINY);
            periodFont = font(20, Gfx.FONT_XTINY);
            labelFont = font(13, Gfx.FONT_XTINY);
        }
    }

    function font(size, fallback) {
        var f = Gfx.getVectorFont({:face=>"RobotoRegular", :size=>size});
        if (f != null) { return f; }
        return fallback;
    }

    function onEnterSleep() as Void { asleep = true; }
    function onExitSleep() as Void {
        asleep = false; lastPoll = -1; lastGraph = -1; Ui.requestUpdate();
    }

    function text(dc,x,y,f,s,c) {
        dc.setColor(c,Gfx.COLOR_TRANSPARENT);
        dc.drawText(x,y,f,s,Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
    function line(dc,x1,y1,x2,y2,c,w) {
        dc.setColor(c,BLACK); dc.setPenWidth(w); dc.drawLine(x1,y1,x2,y2);
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(BLACK,BLACK); dc.clear();
        var clock = Sys.getClockTime();
        var hour = clock.hour % 12; if (hour == 0) { hour = 12; }
        var period = "AM"; if (clock.hour >= 12) { period = "PM"; }
        // The date and clock share the exact same geometry in both modes.
        dc.setAntiAlias(true);
        drawDate(dc,asleep);
        drawTime(dc,hour,clock.min,period,asleep);
        // No HR history reads or battery drawing while in low power mode.
        if (asleep) { return; }
        refreshData();
        drawHeart(dc);
        drawGraph(dc);
        drawBattery(dc);
    }

    function drawDate(dc,dim) {
        var d = Gregorian.info(Time.now(),Time.FORMAT_SHORT);
        var days = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
        var months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
        text(dc,180,54,dateFont,days[d.day_of_week-1]+", "+months[d.month-1]+" "+d.day.toString(),dim ? DIM_WHITE : WHITE);
        line(dc,153,80,207,80,dim ? DIM_CYAN : CYAN,2);
    }

    function drawTime(dc,h,m,period,dim) {
        var values = [h,m/10,m%10];
        if (h>=10) { values = [h/10,h%10,m/10,m%10]; }
        var n = values.size();
        var pw = dc.getTextWidthInPixels(period,periodFont);
        // Keep the entire time and AM/PM centered, with no leading zero.
        var x = (360 - (n*64+23+10+pw))/2;
        var ids = digitIds;
        var colonId = Rez.Drawables.Colon;
        if (dim) { ids = dimDigitIds; colonId = Rez.Drawables.DimColon; }
        for (var i=0;i<n;i+=1) {
            if (i==n-2) { dc.drawBitmap(x,96,Ui.loadResource(colonId)); x+=23; }
            dc.drawBitmap(x,96,Ui.loadResource(ids[values[i]])); x+=64;
        }
        text(dc,x+10+pw/2,164,periodFont,period,dim ? DIM_MUTED : MUTED);
    }

    function refreshData() {
        var now = Time.now().value();
        if (!(AM has :getHeartRateHistory)) { return; }
        if (lastPoll<0 || now<lastPoll || now-lastPoll>=5) {
            lastPoll=now; heartRate=null;
            var latest = AM.getHeartRateHistory(1,true).next();
            if (latest!=null && latest.when!=null && latest.heartRate!=null) {
                var age=now-latest.when.value(); var hr=latest.heartRate;
                if (age>=0 && age<=180 && hr>0 && hr<AM.INVALID_HR_SAMPLE) { heartRate=hr; }
            }
        }
        if (lastGraph>=0 && now>=lastGraph && now-lastGraph<30) { return; }
        lastGraph=now;
        var sums=new [30]; var counts=new [30];
        for (var i=0;i<BIN_COUNT;i+=1) { sums[i]=0; counts[i]=0; trend[i]=null; }
        var it=AM.getHeartRateHistory(new Time.Duration(BIN_COUNT*BIN_SECONDS),true);
        var sample=it.next();
        while (sample!=null) {
            if (sample.when!=null && sample.heartRate!=null) {
                var dt=now-sample.when.value(); var value=sample.heartRate;
                if (dt>=0 && dt<BIN_COUNT*BIN_SECONDS && value>0 && value<AM.INVALID_HR_SAMPLE) {
                    var k=BIN_COUNT-1-dt/BIN_SECONDS;
                    sums[k]+=value; counts[k]+=1;
                }
            }
            sample=it.next();
        }
        for (var j=0;j<BIN_COUNT;j+=1) {
            if (counts[j]>0) { trend[j]=sums[j].toFloat()/counts[j]; }
        }
    }

    function drawHeart(dc) {
        var cx=90; var cy=242; var r=45;
        dc.setColor(TRACK,BLACK); dc.setPenWidth(5); dc.drawCircle(cx,cy,r);
        if (heartRate!=null) {
            var v=heartRate; if (v<HR_MIN) { v=HR_MIN; } if (v>HR_MAX) { v=HR_MAX; }
            // Garmin's native arcs use 90 degrees at 12 o'clock and
            // decreasing angles clockwise. Never draw a zero-length arc:
            // identical start and end angles mean a complete circle.
            var sweep=((v-HR_MIN)*360.0/(HR_MAX-HR_MIN)+0.5).toNumber();
            dc.setColor(CYAN,BLACK); dc.setPenWidth(5);
            if (sweep>=360) {
                dc.drawCircle(cx,cy,r);
            } else if (sweep>0) {
                var end=90-sweep;
                if (end<0) { end+=360; }
                dc.drawArc(cx,cy,r,Gfx.ARC_CLOCKWISE,90,end);
            }
        }
        // Small outline heart, drawn with native primitives.
        var pts=[[-8,-3],[-8,-6],[-5,-8],[-2,-8],[0,-5],[2,-8],[5,-8],[8,-6],[8,-3],[0,5],[-8,-3]];
        for (var i=1;i<pts.size();i+=1) { line(dc,cx+pts[i-1][0],220+pts[i-1][1],cx+pts[i][0],220+pts[i][1],CYAN,1); }
        var value="--"; if (heartRate!=null) { value=heartRate.toString(); }
        text(dc,cx,248,metricFont,value,WHITE);
        text(dc,cx,269,labelFont,"BPM",MUTED);
    }

    function pointY(value,low,high) { return (270-(value-low)*54.0/(high-low)).toNumber(); }
    function drawGraph(dc) {
        // Each column corresponds to a two-minute time bucket, not a sample index.
        line(dc,144,214,144,276,TRACK,1);
        var low=1000.0; var high=0.0; var valid=0;
        for (var i=0;i<BIN_COUNT;i+=1) {
            if (trend[i]!=null) {
                var v=trend[i]; if (v<low) { low=v; } if (v>high) { high=v; } valid+=1;
            }
        }
        if (valid==0) { text(dc,230,246,labelFont,"No HR history",MUTED); return; }
        if (high-low<30.0) { var mid=(high+low)/2.0; low=mid-15.0; high=mid+15.0; }
        else { low-=4.0; high+=4.0; }
        // Project each sample once. Missing readings stay missing.
        var ys = new [30];
        var segments = 0;
        var gradientTop = 276;
        for (var j=0;j<BIN_COUNT;j+=1) {
            ys[j]=null;
            if (trend[j]!=null) { ys[j]=pointY(trend[j],low,high); }
            if (j>0 && ys[j]!=null && ys[j-1]!=null) {
                segments+=1;
                if (ys[j]<gradientTop) { gradientTop=ys[j]; }
                if (ys[j-1]<gradientTop) { gradientTop=ys[j-1]; }
            }
        }
        if (segments==0) {
            text(dc,230,246,labelFont,"No HR trend yet",MUTED);
        } else {
            // Start the fade at the highest connected sample, so it stays
            // visible even when the history only occupies the middle of the
            // graph. Linear intensity, stronger cyan, black at the baseline.
            // Two-pixel horizontal bands keep the draw cost bounded (<=30).
            dc.setAntiAlias(false);
            var fadeHeight=276-gradientTop;
            for (var yy=gradientTop;yy<276;yy+=2) {
                var intensity=(276-yy-1).toFloat()/fadeHeight;
                var green=(120*intensity+0.5).toNumber();
                var blue=(132*intensity+0.5).toNumber();
                var height=2;
                if (yy+height>276) { height=276-yy; }
                dc.setColor(green*256+blue,BLACK);
                dc.fillRectangle(154,yy,146,height);
            }
            // Mask the portion above the trace and any missing intervals.
            // At most 29 native polygon/rectangle fills, no pixel loops.
            dc.setColor(BLACK,BLACK);
            for (var j=1;j<BIN_COUNT;j+=1) {
                var x1=154+(j-1)*5;
                var x2=x1+5;
                if (ys[j-1]!=null && ys[j]!=null) {
                    dc.fillPolygon([[x1,215],[x2,215],[x2,ys[j]],[x1,ys[j-1]]]);
                } else {
                    dc.fillRectangle(x1,216,6,60);
                }
            }
            // Restore the fine anti-aliased trace, without sample dots.
            dc.setAntiAlias(true);
            for (var j=1;j<BIN_COUNT;j+=1) {
                if (ys[j-1]!=null && ys[j]!=null) {
                    line(dc,154+(j-1)*5,ys[j-1],154+j*5,ys[j],CYAN,1);
                }
            }
        }
        text(dc,166,289,labelFont,"60m",MUTED);
        text(dc,296,289,labelFont,"now",MUTED);
    }

    function drawBattery(dc) {
        var b=Sys.getSystemStats().battery.toNumber();
        if (b<0) { b=0; } if (b>100) { b=100; }
        var s=b.toString()+"%"; var w=dc.getTextWidthInPixels(s,dateFont);
        var x=(360-(35+12+w))/2;
        dc.setColor(WHITE,BLACK); dc.setPenWidth(1); dc.drawRoundedRectangle(x,306,31,15,2); dc.fillRectangle(x+32,310,3,7);
        if (b>0) { dc.setColor(CYAN,BLACK); dc.fillRectangle(x+3,310,(25*b+99)/100,7); }
        text(dc,x+47+w/2,314,dateFont,s,WHITE);
    }
}
