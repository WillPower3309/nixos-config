import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

PanelWindow {
  color: "black"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Background

  // TODO: offset image so it isn't vertically compressed by top bar
  ClippingWrapperRectangle {
    anchors.fill: parent
    radius: 15
    Image {
      source: "assets/wallpaper.png"
    }
  }
}

