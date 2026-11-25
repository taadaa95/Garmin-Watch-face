using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Lang as Lang;

class MinimalHRApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Ui.Views] {
        return [new MinimalHRView()];
    }

    function getSettingsView() as [Ui.Views, Ui.InputDelegates] {
        var menu = new Ui.Menu2({:title => "Minimal HR"});
        menu.addItem(new Ui.ToggleMenuItem("BPM number", null, "showBpm", App.Properties.getValue("showBpm") == true, {}));
        menu.addItem(new Ui.ToggleMenuItem("Gradient pulse gauge", null, "colorGauge", App.Properties.getValue("colorGauge") == true, {}));
        return [menu, new MinimalHRSettingsDelegate()];
    }

    function onSettingsChanged() as Void {
        Ui.requestUpdate();
    }
}

class MinimalHRSettingsDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();
        if (item instanceof Ui.ToggleMenuItem && id instanceof Lang.String) {
            if (id.equals("showBpm") || id.equals("colorGauge")) {
                App.Properties.setValue(id, (item as Ui.ToggleMenuItem).isEnabled());
            }
        }
    }

    function onBack() as Void {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
}
