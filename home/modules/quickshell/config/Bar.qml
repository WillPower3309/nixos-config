import Quickshell
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
          text: Time.time
          color: "white"
        }

        Text {
          text: `${100 * UPower.displayDevice.percentage}%`
          color: "white"
        }
      }
    }
  }
}

