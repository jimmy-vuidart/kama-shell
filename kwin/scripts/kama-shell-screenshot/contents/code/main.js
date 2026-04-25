var launcherServices = [
    "org.kde.klauncher6",
    "org.kde.klauncher5",
    "org.kde.klauncher"
];

function runScreenshotHelper() {
    tryLaunchHelper(0);
}

function tryLaunchHelper(index) {
    if (index >= launcherServices.length) {
        print("No KLauncher service found for Kama Shell screenshot helper");
        return;
    }

    var serviceName = launcherServices[index];

    callDBus(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus",
        "NameHasOwner",
        serviceName,
        function(hasOwner) {
            if (!hasOwner) {
                tryLaunchHelper(index + 1);
                return;
            }

            callDBus(
                serviceName,
                "/KLauncher",
                "org.kde.KLauncher",
                "exec_blind",
                readConfig("helperPath", ""),
                [],
                [],
                "0"
            );
        }
    );
}

registerShortcut(
    "KamaShellScreenshotFullscreen",
    "Copy a full-screen screenshot to the clipboard",
    "Print",
    runScreenshotHelper
);
