const WINDOW_NAME = "power-menu"

const SysButton = (title, icon, command) => Widget.Button({
    on_clicked: () => {
        Utils.execAsync(command)
        App.closeWindow(WINDOW_NAME)
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
                SysButton("Shutdown", "system-shutdown-symbolic", "systemctl poweroff"),
                SysButton("Reboot", "system-reboot-symbolic", "systemctl reboot"),
                SysButton("Sleep", "weather-clear-night-symbolic", "systemctl suspend"),
            ],
        }),
    })
}
