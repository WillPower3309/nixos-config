import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  LazyLoader {
    id: root
    active: false

    PanelWindow {
      id: launcher
      color: Qt.rgba(0, 0, 0, 0.8)
      anchors.right: true

      //WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
          text: "test1"
          color: "white"
        }
        Text {
          text: "test2"
          color: "white"
        }

        Keys.onEscapePressed: root.active = false;
      }
    }
  }

  IpcHandler {
    target: "powermenu"
    function toggle(): void { root.active = !root.active; }
  }
}

