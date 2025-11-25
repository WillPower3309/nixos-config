import Quickshell
import Quickshell.I3
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      id: bar

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 30

      color: "black"

      RowLayout {
        anchors.fill: parent
        uniformCellSizes: true

        // Workspace Indicator
        Text {
          text: I3.focusedWorkspace.number
          color: "white"
          Layout.leftMargin: 15
        }

        // Clock
        Text {
          text: Time.time
          color: "white"
          Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
          Layout.rightMargin: 15
          Layout.alignment: Qt.AlignRight
          spacing: 10

          // System Tray
          Repeater {
            model: SystemTray.items
            delegate: IconImage {
              required property SystemTrayItem modelData
              source: modelData.icon
              implicitSize: bar.implicitHeight / 2

              MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                  if (mouse.button == Qt.LeftButton) {
                    modelData.activate()
                  } else if (mouse.button == Qt.MiddleButton) {
                    modelData.secondaryActivate()
                  } else if (mouse.button == Qt.RightButton) {
                    modelData.display(QsWindow.window, mapToItem(QsWindow.window.contentItem,mouse.x, mouse.y).x, mapToItem(QsWindow.window.contentItem,mouse.x, mouse.y).y)
                  }
                }
              }
            }
          }

          // Battery Indicator
          Text {
            text: `${Math.round(100 * UPower.displayDevice.percentage)}%`
            color: "white"
          }
        }
      }
    }
  }
}

