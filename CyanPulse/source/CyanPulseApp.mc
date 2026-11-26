using Toybox.Application as App;
using Toybox.WatchUi as Ui;
class CyanPulseApp extends App.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() as [Ui.Views] { return [new CyanPulseView()]; }
}
