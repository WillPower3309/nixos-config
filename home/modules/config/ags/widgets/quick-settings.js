const audio = await Service.import("audio")
const battery = await Service.import("battery")

const QUICK_SETTINGS_WINDOW_NAME = "quick-settings"

const BatteryInfo = () => Widget.Box({
    visible: battery.bind("available"),
    children: [
        Widget.Icon({ icon: battery.bind("icon_name") }),
        Widget.Label({ label: battery.bind("percent").as(p => `${p}%`) }),
    ],
})

const BrightnessSlider = () => {
    const Slider = () => Widget.Slider({
        draw_value: false,
        hexpand: true,
        value: Number(Utils.exec("light -G") * 100),
        on_change: ({ value }) => Utils.exec(`light -S ${value * 100}`),
    })

    return Widget.Box({
        children: [
            Widget.Icon("display-brightness-symbolic"),
            Slider(),
        ],
    })
}

const VolumeSlider = () => {
    const Slider = () => Widget.Slider({
        draw_value: false,
        hexpand: true,
        value: audio["speaker"].bind("volume"),
        on_change: ({ value, dragging }) => {
            if (dragging) {
                audio["speaker"].volume = value
                audio["speaker"].is_muted = false
            }
        },
    })

    return Widget.Box({
        children: [
            Widget.Icon({ icon: "audio-card-symbolic" }),
            Slider(),
        ],
    })
}

const Header = () => Widget.Box({
    vertical: true,
    children: [
        BatteryInfo(),
        BrightnessSlider(),
        VolumeSlider(),
    ],
})

const QuickSettingsContainer = () => Widget.Box({
    vertical: true,
    css: "min-width: 200px;",
    children: [
        Header(),
    ],
})

const QuickSettingsRevealer = () => Widget.Revealer({
    transition: "crossfade",
    transitionDuration: 1000,
    child: QuickSettingsContainer(),
    setup: self => self.hook(App, (_, wname, visible) => {
        self.reveal_child = visible
    }),
})

export function QuickSettings() {
    return Widget.Window({
        name: QUICK_SETTINGS_WINDOW_NAME,
        exclusivity: "exclusive",
        anchor: ["top", "right"],
        visible: false,
        child: QuickSettingsRevealer(),
    })
}
