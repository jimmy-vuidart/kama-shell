var launcherServices = [
    "org.kde.klauncher6",
    "org.kde.klauncher5",
    "org.kde.klauncher"
];

function runCommand(command, args) {
    tryLaunchCommand(0, command, args);
}

function tryLaunchCommand(index, command, args) {
    if (index >= launcherServices.length) {
        print("No KLauncher service found for Kama Shell shortcut command");
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
                tryLaunchCommand(index + 1, command, args);
                return;
            }

            callDBus(
                serviceName,
                "/KLauncher",
                "org.kde.KLauncher",
                "exec_blind",
                command,
                args,
                [],
                "0"
            );
        }
    );
}

function currentScreenName() {
    var output = null;

    try {
        if (workspace.activeScreen) {
            output = workspace.activeScreen;
        }
    } catch (error) {
    }

    try {
        if (!output && workspace.activeWindow && workspace.activeWindow.output) {
            output = workspace.activeWindow.output;
        }
    } catch (error) {
    }

    try {
        if (!output && workspace.screenAt && workspace.cursorPos) {
            output = workspace.screenAt(workspace.cursorPos);
        }
    } catch (error) {
    }

    return output && output.name ? String(output.name) : "";
}

function toggleLauncher() {
    var qsPath = readConfig("qsPath", "/usr/bin/qs");
    var shellEntry = readConfig("shellEntry", "");
    var screenName = currentScreenName();
    var args = ["ipc"];

    if (shellEntry.length > 0) {
        args.push("--path");
        args.push(shellEntry);
    }

    args.push("--any-display");
    args.push("call");
    args.push("kama-shell");
    args.push("toggleLauncher");

    if (screenName.length > 0) {
        args.push(screenName);
    }

    runCommand(qsPath, args);
}

registerShortcut(
    "KamaShellToggleLauncher",
    "Toggle the Kama Shell app launcher",
    readConfig("launcherShortcut", "Meta"),
    toggleLauncher
);
