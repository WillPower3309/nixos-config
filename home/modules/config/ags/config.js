import { applauncher } from "./widgets/app-launcher.js";
import { NotificationPopups } from "./widgets/notification-popups.js"

App.config({
    windows: [
        applauncher,
        NotificationPopups(),
    ],
})
