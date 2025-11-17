import { applauncher } from "./widgets/app-launcher.js";
import { NotificationPopups } from "./widgets/notification-popups.js"
import { PowerMenu } from "./widgets/power-menu.js"
import { TopBar } from "./widgets/top-bar.js"

App.config({
    style: App.configDir + "/style.css",
    windows: [
        applauncher,
        NotificationPopups(),
        PowerMenu(),
        TopBar(),
    ],
})
