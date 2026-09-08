import QtQuick
import Quickshell
import qs.Commons
import "Plugin" as Rain

ShellRoot {
  id: test
  property int phase: -1
  property int ticks: 0
  function check(value, message) { if (!value) { console.error("FAIL: " + message); Qt.exit(1) } }
  Rain.Panel { id: panel }
  Timer {
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      test.ticks++
      if (test.ticks > 80) { console.error("Timeout phase " + test.phase); Qt.exit(1); return }
      if (test.phase === -1) {
        panel.weatherLocation = {name: "Brussels", latitude: 50.8503, longitude: 4.3517}
        panel.resolveLocation()
        test.phase = 0
      }
      if (test.phase === 0 && panel.selectionLoaded && panel.samples.length > 0) {
        panel.beginLocationPicker()
        panel.draftLocation = {name: "Amsterdam", latitude: 52.3676, longitude: 4.9041}
        panel.saveSelection(false)
        test.phase++
      } else if (test.phase === 1 && !panel.savingSelection) {
        test.check(panel.activeLocation.name === "Amsterdam", "selection applies")
        panel.beginLocationPicker()
        panel.draftLocation = {name: "Antwerp", latitude: 51.2194, longitude: 4.4025}
        panel.saveSelection(false)
        test.phase++
      } else if (test.phase === 2 && !panel.savingSelection && !panel.loading) {
        test.check(panel.activeLocation.name === "Antwerp", "latest city wins")
        test.check(panel.samples.length > 0 && panel.samples[0].code === 0, "old Amsterdam response discarded")
        panel.settings = {latitude: "52.0907", longitude: "5.1214", locationName: "Utrecht"}
        Qt.callLater(function() {
          test.check(panel.activeLocation.name === "Utrecht", "edited coordinate settings supersede saved map choice")
          panel.draftLocation = {name: "Invalid", latitude: 90, longitude: 5}
          panel.saveSelection(false)
          test.check(!panel.savingSelection, "out-of-coverage keyboard choice rejected")
          panel.saveSelection(true)
          test.phase++
        })
      } else if (test.phase === 3 && !panel.savingSelection && !panel.loading) {
        test.check(panel.selection.mode === "automatic", "automatic choice persists")
        test.check(panel.activeLocation === panel.automaticLocation, "automatic position restored")
        panel.open()
        panel.beginLocationPicker()
        panel.draftLocation = {name: "Amsterdam", latitude: 52.3676, longitude: 4.9041}
        test.phase++
        test.ticks = 0
      } else if (test.phase === 4 && test.ticks > 10) {
        for (var i = 0; i < panel.data.length; i++) {
          var child = panel.data[i]
          if (child.contentWidth !== undefined && child.contentItem) {
            child.contentItem[0].grabToImage(function(result) {
              if (Quickshell.env("RAIN_RADAR_TEST_CAPTURE")) test.check(result.saveToFile(Quickshell.env("RAIN_RADAR_TEST_CAPTURE")), "save screenshot")
              console.log("PASS: selection, rapid changes, persistence, automatic reset, settings edits, invalid coordinates, full picker render")
              Qt.quit()
            })
            test.phase++
            return
          }
        }
        console.error("Popup not found")
        Qt.exit(1)
      }
    }
  }
}
