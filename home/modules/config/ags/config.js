import { applauncher } from "./widgets/app-launcher.js";
import { NotificationPopups } from "./widgets/notification-popups.js"
import { TopBar } from "./widgets/top-bar.js"

App.config({
    windows: [
        applauncher,
        NotificationPopups(),
        TopBar(),
    ],
})
