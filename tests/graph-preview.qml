import QtQuick
import Quickshell
import qs.Commons
import "Plugin" as Rain

ShellRoot {
  id: previewRoot
  function samples(values) {
    return values.map(function(mm, i) {
      var minutes = i * 5
      return {mm: mm, time: (12 + Math.floor(minutes / 60)) + ":" + (minutes % 60 < 10 ? "0" : "") + minutes % 60}
    })
  }
  FloatingWindow {
    visible: true
    implicitWidth: preview.width
    implicitHeight: preview.height
    Rectangle {
      id: preview
      width: 620; height: 840
      color: Color.background
      Column {
        x: 24; y: 20; width: parent.width - 48; spacing: 10
        Repeater {
          model: [
            {title: "Drizzle and light rain", values: [0, 0, 0.02, 0.06, 0.15, 0.3, 0.7, 1.2, 0.8, 0.2, 0.03, 0, 0]},
            {title: "Heavy shower, then clearing", values: [0, 0.1, 0.5, 1, 3, 10, 35, 60, 20, 2, 0.1, 0, 0]},
            {title: "Dry throughout", values: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}
          ]
          delegate: Column {
            required property var modelData
            width: 572; spacing: 6
            Text {
              text: modelData.title
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: 16
            }
            Rain.RainGraph {
              width: parent.width; height: 230
              samples: previewRoot.samples(modelData.values)
            }
          }
        }
      }
    }
  }
  Timer {
    interval: 1000; running: true
    onTriggered: preview.grabToImage(function(result) {
      if (!result.saveToFile(Quickshell.env("RAIN_RADAR_TEST_CAPTURE"))) Qt.exit(1)
      else Qt.quit()
    })
  }
}
