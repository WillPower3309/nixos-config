const WINDOW_NAME = "power-menu"

const SysButton = (icon, command) => Widget.Button({
    on_clicked: () => {
        Utils.execAsync(command)
        App.closeWindow(WINDOW_NAME)
    },
    child: Widget.Icon({
        icon,
        size: 42,
    }),
    css: `padding: 12px`,
})

const PowerMenuContainer = () => Widget.Box({
    children: [
        SysButton("system-shutdown-symbolic", "systemctl poweroff"),
        SysButton("system-reboot-symbolic", "systemctl reboot"),
        SysButton("weather-clear-night-symbolic", "systemctl suspend"),
    ],
    vertical: true,
    spacing: 24,
    css: `padding: 24px 12px 24px 24px`,
})

const PowerMenuRevealer = () => {
    return Widget.Revealer({
        transition: "crossfade",
        transitionDuration: 1000,
        child: PowerMenuContainer(),
        setup: self => self.hook(App, (_, wname, visible) => {
            self.reveal_child = visible;
        })
    })
}

export function PowerMenu() {
    return Widget.Window({
        name: WINDOW_NAME,
        setup: self => self.keybind("Escape", () => {
            App.closeWindow(WINDOW_NAME)
        }),
        visible: false,
        keymode: "exclusive",
        anchor: ["right"],
        child: PowerMenuRevealer(),
    })
}
