using Toybox.Application as App;
using Toybox.WatchUi as Ui;
class LunarisApp extends App.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() as [Ui.Views] { return [new LunarisView()]; }
}
