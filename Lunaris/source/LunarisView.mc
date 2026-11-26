using Toybox.ActivityMonitor as AM;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.WatchUi as Ui;

// 360 x 360 AMOLED, geocentric north-up lunar phase.
class LunarisView extends Ui.WatchFace {
    const BLACK=0x000000;
    const WHITE=0xF6F2E8;
    const GOLD=0xE5BD7D;
    const MUTED=0x9DABBF;
    var asleep=false;
    var heartRate=null;
    var lastPoll=-1;
    var lastLunar=-1;
    var lunar=null;
    var lunarAngle=null;
    var fullAt=null;
    var sky=null;
    var moonBitmap=null;
    var moonIndex=-1;
    var digitIds=[Rez.Drawables.Digit0,Rez.Drawables.Digit1,Rez.Drawables.Digit2,Rez.Drawables.Digit3,Rez.Drawables.Digit4,Rez.Drawables.Digit5,Rez.Drawables.Digit6,Rez.Drawables.Digit7,Rez.Drawables.Digit8,Rez.Drawables.Digit9];
    var moonIds=[Rez.Drawables.Moon00,Rez.Drawables.Moon01,Rez.Drawables.Moon02,Rez.Drawables.Moon03,Rez.Drawables.Moon04,Rez.Drawables.Moon05,Rez.Drawables.Moon06,Rez.Drawables.Moon07,Rez.Drawables.Moon08,Rez.Drawables.Moon09,Rez.Drawables.Moon10,Rez.Drawables.Moon11,Rez.Drawables.Moon12,Rez.Drawables.Moon13,Rez.Drawables.Moon14,Rez.Drawables.Moon15,Rez.Drawables.Moon16,Rez.Drawables.Moon17,Rez.Drawables.Moon18,Rez.Drawables.Moon19,Rez.Drawables.Moon20,Rez.Drawables.Moon21,Rez.Drawables.Moon22,Rez.Drawables.Moon23,Rez.Drawables.Moon24,Rez.Drawables.Moon25,Rez.Drawables.Moon26,Rez.Drawables.Moon27,Rez.Drawables.Moon28,Rez.Drawables.Moon29,Rez.Drawables.Moon30,Rez.Drawables.Moon31,Rez.Drawables.Moon32,Rez.Drawables.Moon33,Rez.Drawables.Moon34,Rez.Drawables.Moon35,Rez.Drawables.Moon36,Rez.Drawables.Moon37,Rez.Drawables.Moon38,Rez.Drawables.Moon39,Rez.Drawables.Moon40,Rez.Drawables.Moon41,Rez.Drawables.Moon42,Rez.Drawables.Moon43,Rez.Drawables.Moon44,Rez.Drawables.Moon45,Rez.Drawables.Moon46,Rez.Drawables.Moon47,Rez.Drawables.Moon48,Rez.Drawables.Moon49,Rez.Drawables.Moon50,Rez.Drawables.Moon51,Rez.Drawables.Moon52,Rez.Drawables.Moon53,Rez.Drawables.Moon54,Rez.Drawables.Moon55,Rez.Drawables.Moon56,Rez.Drawables.Moon57,Rez.Drawables.Moon58,Rez.Drawables.Moon59,Rez.Drawables.Moon60,Rez.Drawables.Moon61,Rez.Drawables.Moon62,Rez.Drawables.Moon63];
    var dateFont=Gfx.FONT_XTINY;
    var detailFont=Gfx.FONT_XTINY;
    var smallFont=Gfx.FONT_XTINY;
    var metricFont=Gfx.FONT_XTINY;
    var periodFont=Gfx.FONT_XTINY;
    var sleepFont=Gfx.FONT_NUMBER_MILD;

    function initialize() {
        WatchFace.initialize();
        lunar=new LunarData();
        if (Gfx has :getVectorFont) {
            dateFont=font(16,Gfx.FONT_XTINY);
            detailFont=font(14,Gfx.FONT_XTINY);
            smallFont=font(11,Gfx.FONT_XTINY);
            metricFont=font(24,Gfx.FONT_XTINY);
            periodFont=font(16,Gfx.FONT_XTINY);
            sleepFont=font(44,Gfx.FONT_NUMBER_MILD);
        }
    }
    function font(size,fallback) {
        var f=Gfx.getVectorFont({:face=>"RobotoRegular",:size=>size});
        if (f!=null) { return f; } return fallback;
    }
    function text(dc,x,y,f,s,c) {
        dc.setColor(c,Gfx.COLOR_TRANSPARENT);
        dc.drawText(x,y,f,s,Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
    function line(dc,x1,y1,x2,y2,c,w) {
        dc.setColor(c,Gfx.COLOR_TRANSPARENT); dc.setPenWidth(w); dc.drawLine(x1,y1,x2,y2);
    }
    function onEnterSleep() as Void { asleep=true; }
    function onExitSleep() as Void { asleep=false; lastPoll=-1; lastLunar=-1; Ui.requestUpdate(); }
    function onUpdate(dc as Gfx.Dc) as Void {
        dc.setColor(BLACK,BLACK); dc.clear();
        var clock=Sys.getClockTime(); var h=clock.hour%12; if (h==0) { h=12; }
        var period="AM"; if (clock.hour>=12) { period="PM"; }
        dc.setAntiAlias(!asleep);
        if (asleep) {
            var p=(clock.hour*60+clock.min)%8;
            var xs=[-8,0,8,8,8,0,-8,-8]; var ys=[-8,-8,-8,0,8,8,8,0];
            text(dc,180+xs[p],172+ys[p],sleepFont,h.toString()+":"+clock.min.format("%02d"),0x66686A);
            text(dc,180+xs[p],210+ys[p],smallFont,period,0x66686A); return;
        }
        if (sky==null) { sky=Ui.loadResource(Rez.Drawables.Sky); }
        dc.drawBitmap(0,0,sky);
        var now=Time.now().value(); refreshLunar(now); refreshHeart(now);
        // The tile contains a matching portion of the sky background and halo.
        if (lunarAngle!=null) {
            var idx=(lunarAngle*64.0/360.0+0.5).toNumber()%64;
            if (idx!=moonIndex || moonBitmap==null) {
                moonBitmap=null;
                moonBitmap=Ui.loadResource(moonIds[idx]); moonIndex=idx;
            }
            dc.drawBitmap(70,112,moonBitmap);
        } else { text(dc,180,224,detailFont,"Lunar data unavailable",MUTED); }
        drawHeader(dc,h,clock.min,period);
        drawDetails(dc,now);
    }
    function refreshLunar(now) {
        if (lastLunar>=0 && now>=lastLunar && now-lastLunar<60) { return; }
        lastLunar=now; lunarAngle=lunar.angleAt(now);
        fullAt=null;
        if (lunarAngle!=null) {
            fullAt=lunar.nextFull(now);
        }
    }
    function refreshHeart(now) {
        if (lastPoll>=0 && now>=lastPoll && now-lastPoll<5) { return; }
        lastPoll=now; heartRate=null;
        if (AM has :getHeartRateHistory) {
            var s=AM.getHeartRateHistory(1,true).next();
            if (s!=null && s.when!=null && s.heartRate!=null) {
                var age=now-s.when.value(); var hr=s.heartRate;
                if (age>=0 && age<=180 && hr>0 && hr!=AM.INVALID_HR_SAMPLE) { heartRate=hr; }
            }
        }
    }
    function drawHeader(dc,h,m,period) {
        var d=Gregorian.info(Time.now(),Time.FORMAT_SHORT);
        var days=["SUN","MON","TUE","WED","THU","FRI","SAT"];
        var months=["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
        text(dc,180,34,dateFont,days[d.day_of_week-1]+", "+months[d.month-1]+" "+d.day.toString(),GOLD);
        var values=[h,m/10,m%10]; if (h>=10) { values=[h/10,h%10,m/10,m%10]; }
        var n=values.size(); var pw=dc.getTextWidthInPixels(period,periodFont);
        var x=(360-(n*49+18+7+pw))/2;
        for (var i=0;i<n;i+=1) {
            if (i==n-2) { dc.drawBitmap(x,44,Ui.loadResource(Rez.Drawables.Colon)); x+=18; }
            dc.drawBitmap(x,44,Ui.loadResource(digitIds[values[i]])); x+=49;
        }
        text(dc,x+7+pw/2,101,periodFont,period,GOLD);
    }
    function phaseName(a) {
        if (a<6 || a>=354) { return "NEW MOON"; }
        if (a<84) { return "WAXING CRESCENT"; }
        if (a<96) { return "FIRST QUARTER"; }
        if (a<174) { return "WAXING GIBBOUS"; }
        if (a<186) { return "FULL MOON"; }
        if (a<264) { return "WANING GIBBOUS"; }
        if (a<276) { return "LAST QUARTER"; }
        return "WANING CRESCENT";
    }
    function drawDetails(dc,now) {
        var cx=45; var cy=143;
        var pts=[[-8,-3],[-8,-6],[-5,-8],[-2,-8],[0,-5],[2,-8],[5,-8],[8,-6],[8,-3],[0,5],[-8,-3]];
        for (var i=1;i<pts.size();i+=1) { line(dc,cx+pts[i-1][0],cy+pts[i-1][1],cx+pts[i][0],cy+pts[i][1],GOLD,1); }
        var hr="--"; if (heartRate!=null) { hr=heartRate.toString(); }
        text(dc,cx,163,metricFont,hr,WHITE); text(dc,cx,182,smallFont,"BPM",GOLD);
        var battery=Sys.getSystemStats().battery.toNumber(); if (battery<0) { battery=0; } if (battery>100) { battery=100; }
        cx=315;
        dc.setColor(GOLD,Gfx.COLOR_TRANSPARENT); dc.setPenWidth(1); dc.drawRoundedRectangle(cx-13,136,25,12,2); dc.fillRectangle(cx+13,139,2,6);
        if (battery>0) { dc.fillRectangle(cx-10,139,(19*battery+99)/100,6); }
        text(dc,cx,163,metricFont,battery.toString()+"%",WHITE);
        if (lunarAngle!=null) {
            var illumination=((1-Math.cos(lunarAngle*0.01745329252))*50+0.5).toNumber();
            if (fullAt!=null) {
                var days=(fullAt-now)/86400.0;
                // Always use the next full moon event, not the mean synodic period.
                var countdown=days.format("%.1f")+"d";
                if (days<1) { countdown=((fullAt-now)/3600.0).format("%.1f")+"h"; }
                text(dc,180,341,smallFont,illumination.toString()+"% LIT  |  FULL IN "+countdown,WHITE);
            } else { text(dc,180,341,smallFont,illumination.toString()+"% ILLUMINATED",WHITE); }
        }
    }
}
