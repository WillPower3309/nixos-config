const WINDOW_NAME = "power-menu"

const SysButton = (title, icon, command) => Widget.Button({
    on_clicked: () => {
        App.closeWindow(WINDOW_NAME)
        Utils.execAsync(command)
    },
    child: Widget.Box({
        vertical: true,
        class_name: "system-button",
        children: [
            Widget.Icon(icon),
            Widget.Label({ label: title }),
        ],
    }),
})

export function PowerMenu() {
    return Widget.Window({
        name: WINDOW_NAME,
        setup: self => self.keybind("Escape", () => {
            App.closeWindow(WINDOW_NAME)
        }),
        visible: false,
        keymode: "exclusive",
        child: Widget.Box({
            children: [
                SysButton("Shutdown", "system-shutdown-symbolic", "shutdown"),
                SysButton("Reboot", "system-reboot-symbolic", "reboot"),
                SysButton("Sleep", "weather-clear-night-symbolic", "systemctl suspend"),
            ],
        }),
    })
}
