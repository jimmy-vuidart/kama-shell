export type UserConfig = {
  dev: {
    scanPaths: string[]
    terminalCommand: string
    editorCommand: string
  }
  gaming: {
    libraryPaths: string[]
    additionalLaunchers: string[]
  }
  session: {
    lockCommand: string
    logoutCommand: string
    suspendCommand: string
    rebootCommand: string
    shutdownCommand: string
  }
}

export const defaultConfig: UserConfig = {
  dev: {
    scanPaths: ["~/Projects", "~/Code"],
    terminalCommand: "foot",
    editorCommand: "code",
  },
  gaming: {
    libraryPaths: ["~/.local/share/Steam"],
    additionalLaunchers: [],
  },
  session: {
    lockCommand: "loginctl lock-session",
    logoutCommand: "hyprctl dispatch exit",
    suspendCommand: "systemctl suspend",
    rebootCommand: "systemctl reboot",
    shutdownCommand: "systemctl poweroff",
  },
}
