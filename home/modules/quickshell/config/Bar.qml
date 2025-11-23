import Quickshell
import Quickshell.I3
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 30

      color: "black"

      RowLayout {
        anchors.fill: parent

        Text {
          text: I3.focusedWorkspace.number
          color: "white"
          Layout.leftMargin: 10
          anchors.left: parent
        }

        Text {
          text: Time.time
          color: "white"
          anchors.centerIn: parent
        }

        Text {
          text: `${Math.round(100 * UPower.displayDevice.percentage)}%`
          color: "white"
          anchors.right: parent
          Layout.rightMargin: 10
          Layout.alignment: Qt.AlignRight
        }
      }
    }
  }
}

