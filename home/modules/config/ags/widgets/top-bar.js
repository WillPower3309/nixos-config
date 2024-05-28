const audio = await Service.import("audio")
const battery = await Service.import("battery")
const bluetooth = await Service.import("bluetooth")
const network = await Service.import("network");
const notifications = await Service.import("notifications")
const systemtray = await Service.import("systemtray")

const date = Variable("", {
    poll: [1000, 'date "+%H:%M:%S %b %e."'],
})

function Clock() {
    return Widget.Label({
        class_name: "clock",
        label: date.bind(),
    })
}

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
    visible: bluetooth.bind("enabled"),
    child: Widget.Icon({
        icon: "bluetooth-active-symbolic",
    }),
    overlay: Widget.Label({
        hpack: "end",
        vpack: "start",
        label: bluetooth.bind("connected_devices").as(c => `${c.length}`),
        visible: bluetooth.bind("connected_devices").as(c => c.length > 0),
    }),
})

const NetworkIcon = () => Widget.Icon().hook(audio.speaker, self => {
    const icon = network[network.primary || "wifi"]?.icon_name
    self.icon = icon || ""
    self.visible = !!icon
})

const BatteryIcon = () => Widget.Icon().hook(battery, self => {
    self.icon = battery.charging || battery.charged
            ? icons.battery.charging : battery.icon_name
})

function SysTray() {
    const items = systemtray.bind("items")
        .as(items => items.map(item => Widget.Button({
            child: Widget.Icon({ icon: item.bind("icon") }),
            on_primary_click: (_, event) => item.activate(event),
            on_secondary_click: (_, event) => item.openMenu(event),
            tooltip_markup: item.bind("tooltip_markup"),
        })))

    return Widget.Box({
        children: items,
    })
}

// layout of the bar
function Left() {
    return Widget.Box({
        spacing: 8,
        children: [],
    })
}

function Center() {
    return Widget.Box({
        spacing: 8,
        child: Clock(),
    })
}

function Right() {
    return Widget.Box({
        hpack: "end",
        spacing: 8,
        children: [
            SysTray(),
            VolumeIcon(),
            BluetoothIcon(),
            NetworkIcon(),
            BatteryIcon(),
        ],
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
            start_widget: Left(),
            center_widget: Center(),
            end_widget: Right(),
        }),
    })
}

