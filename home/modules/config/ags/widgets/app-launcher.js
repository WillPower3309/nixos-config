const { query } = await Service.import("applications")

const WINDOW_NAME = "app-launcher"

const AppItem = app => Widget.Button({
    on_clicked: () => {
        App.closeWindow(WINDOW_NAME)
        app.launch()
    },
    attribute: { app },
    child: Widget.Box({
        vertical: true,
        spacing: 6,
        children: [
            Widget.Icon({
                icon: app.icon_name || "",
                size: 96,
            }),
            Widget.Label({
                class_name: "title",
                label: app.name,
                vpack: "center",
                truncate: "end",
            }),
        ],
    }),
})

const AppLauncher = () => {
    // list of application buttons
    let applications = query("").map(AppItem)

    // container holding the application buttons
    const list = Widget.FlowBox({})
    applications.forEach(app => {
        list.add(app)
    })

    // repopulate the box, so the most frequent apps are on top of the list
    function repopulate() {
        applications = query("").map(AppItem)
        list.children = applications
    }

    // search entry
    const entry = Widget.Entry({
        hexpand: true,
        css: "margin-bottom: 32px;",

        // to launch the first item on Enter
        on_accept: () => {
            // make sure we only consider visible (searched for) applications
            const results = applications.filter((item) => item.visible);
            if (results[0]) {
                App.toggleWindow(WINDOW_NAME)
                results[0].attribute.app.launch()
            }
        },

        // filter out the list
        on_change: ({ text }) => applications.forEach(item => {
            item.visible = item.attribute.app.match(text ?? "")
        }),
    })

    return Widget.Box({
        vertical: true,
        css: "margin: 128px;",
        children: [
            entry,
            // wrap the list in a scrollable
            Widget.Scrollable({
                hscroll: "never",
                child: list,
                vexpand: true,
            }),
        ],
        setup: self => self.hook(App, (_, windowName, visible) => {
            if (windowName !== WINDOW_NAME)
                return

            // when the applauncher shows up
            if (visible) {
                repopulate()
                entry.text = ""
                entry.grab_focus()
            }
        }),
    })
}

const AppLauncherRevealer = () => {
    return Widget.Revealer({
        transition: "crossfade",
        transitionDuration: 1000,
        child: AppLauncher(),
        setup: self => self.hook(App, (_, wname, visible) => {
            self.reveal_child = visible;
        }),
    })
}

// there needs to be only one instance
export const applauncher = Widget.Window({
    name: WINDOW_NAME,
    setup: self => self.keybind("Escape", () => {
        App.closeWindow(WINDOW_NAME) // TODO: close animation
    }),
    visible: false,
    keymode: "exclusive",
    anchor: ["top", "left", "right", "bottom"],
    exclusivity: "ignore",
    layer: "overlay",
    child: AppLauncherRevealer(),
})
