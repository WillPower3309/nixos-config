const audio = await Service.import("audio")
const battery = await Service.import("battery")
const bluetooth = await Service.import("bluetooth")
const network = await Service.import("network");
const notifications = await Service.import("notifications")
const systemtray = await Service.import("systemtray")

const QUICK_SETTINGS_WINDOW_NAME = "quick-settings"

const date = Variable("", {
    poll: [1000, 'date "+%H:%M:%S %b %e."'],
})

const Clock = () => Widget.Label({
    class_name: "clock",
    label: date.bind(),
})

const QuickSettingsWindow = () => {
    const Settings = () => Widget.Box({
        vertical: true,
        css: "min-width: 12px;",
        children: [],
    })

    return Widget.Window({
        name: QUICK_SETTINGS_WINDOW_NAME,
        exclusivity: "exclusive",
        anchor: ["top", "right"],
        child: Settings(),
    })
}

const StatusIconsButton = () => {
    const VolumeIcon = () => Widget.Icon().hook(audio.speaker, self => {
        const audioIcons = {
            muted: "audio-volume-muted-symbolic",
            low: "audio-volume-low-symbolic",
            medium: "audio-volume-medium-symbolic",
            high: "audio-volume-high-symbolic",
            overamplified: "audio-volume-overamplified-symbolic",
        }
        const vol = audio.speaker.is_muted ? 0 : audio.speaker.volume
        const { muted, low, medium, high, overamplified } = audioIcons
        const cons = [[101, overamplified], [67, high], [34, medium], [1, low], [0, muted]]
        self.icon = cons.find(([n]) => n <= vol * 100)?.[1] || ""
    })

    const BluetoothIcon = () => Widget.Overlay({
        class_name: "bluetooth",
        passThrough: true,
        visible: bluetooth.bind("available"),
        child: Widget.Icon({
            icon: `bluetooth-${bluetooth.bind("enabled") ? "active" : "disabled"}-symbolic`,
        }),
        overlay: Widget.Label({
            hpack: "end",
            vpack: "start",
            label: bluetooth.bind("connected_devices").as(c => `${c.length}`),
            visible: bluetooth.bind("connected_devices").as(c => c.length > 0),
        }),
    })

    const NetworkIcon = () => Widget.Icon().hook(network, self => {
        const icon = network[network.primary || "wifi"]?.icon_name
        self.icon = icon || ""
        self.visible = network.available && !!icon
    })

    const BatteryIcon = () => Widget.Icon().hook(battery, self => {
        self.icon = battery.charging || battery.charged
                ? icons.battery.charging : battery.icon_name
        self.visible = battery.available
    })

    return Widget.Button({
        on_clicked: () => App.toggleWindow(QUICK_SETTINGS_WINDOW_NAME),
        child: Widget.Box({
            children: [
                VolumeIcon(),
                BluetoothIcon(),
                NetworkIcon(),
                BatteryIcon(),
            ],
            spacing: 8,
        }),
    })
}

const SysTray = () => {
    const items = systemtray.bind("items")
        .as(items => items.map(item => Widget.Button({
            child: Widget.Icon({ icon: item.bind("icon") }),
            on_primary_click: (_, event) => item.activate(event),
            on_secondary_click: (_, event) => item.openMenu(event),
            tooltip_markup: item.bind("tooltip_markup"),
            css: "padding: 0; background-color: transparent;",
        })))

    return Widget.Box({
        children: items,
        spacing: 8,
    })
}

export function TopBar(monitor = 0) {
    return Widget.Window({
        name: `bar-${monitor}`, // name has to be unique
        class_name: "bar",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
            start_widget: Widget.Box(),
            center_widget: Clock(),
            end_widget: Widget.Box({
                hpack: "end",
                spacing: 8,
                children: [
                    SysTray(),
                    StatusIconsButton(),
                ],
            })
        }),
        setup() {
            App.addWindow(QuickSettingsWindow())
        },
    })
}

