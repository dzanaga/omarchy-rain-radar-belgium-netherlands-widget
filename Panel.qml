import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.dzanaga.omarchy-rain-radar-belgium-netherlands-widget"
  ipcTarget: moduleName
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property var samples: []
  property var weatherLocation: null
  property var activeLocation: null
  property string errorMessage: ""
  property bool loading: false
  property int locationProviderIndex: 0
  property bool locationResponseAccepted: false
  readonly property var locationProviders: [
    "https://get.geojs.io/v1/ip/geo.json",
    "https://ipwho.is/",
    "https://ipapi.co/json/"
  ]

  readonly property int refreshMinutes: Math.max(5, parseInt(setting("refreshMinutes", 5), 10) || 5)
  readonly property var currentSample: samples.length > 0 ? samples[0] : null
  readonly property string currentMm: currentSample ? Model.formatMm(currentSample.mm) : "—"
  readonly property string currentIntensity: currentSample ? Model.intensity(currentSample.mm) : "Waiting for data"
  readonly property string barLabel: "󰖗 " + currentMm
  readonly property string tooltip: activeLocation
    ? ((activeLocation.name || "Current position") + ": " + currentMm + " mm/h · " + currentIntensity)
    : "Rain radar · locating…"

  function configuredOverride() {
    var latitude = Model.finiteNumber(setting("latitude", ""))
    var longitude = Model.finiteNumber(setting("longitude", ""))
    if (latitude === null || longitude === null) return null
    return { name: String(setting("locationName", "")) || "Configured position", latitude: latitude, longitude: longitude }
  }

  function resolveLocation() {
    var override = configuredOverride()
    if (override) { useLocation(override); return }
    if (weatherLocation) { useLocation(weatherLocation); return }
    if (!locationProc.running) {
      locationProviderIndex = 0
      startLocationLookup()
    }
  }

  function startLocationLookup() {
    if (locationProviderIndex >= locationProviders.length) {
      errorMessage = "Location lookup failed. Configure coordinates in widget settings."
      loading = false
      return
    }
    locationResponseAccepted = false
    loading = true
    locationProc.command = ["curl", "-fsS", "--max-time", "7", locationProviders[locationProviderIndex]]
    locationProc.running = true
  }

  function useLocation(location) {
    activeLocation = location
    if (!Model.inCoverage(location.latitude, location.longitude)) {
      errorMessage = "This position is outside Buienradar coverage (Belgium and the Netherlands)."
      samples = []
      loading = false
      return
    }
    fetchRain()
  }

  function fetchRain() {
    if (!activeLocation || rainProc.running) return
    errorMessage = ""
    loading = true
    var url = "https://gps.buienradar.nl/getrr.php?lat="
      + encodeURIComponent(String(activeLocation.latitude))
      + "&lon=" + encodeURIComponent(String(activeLocation.longitude))
    // Buienradar's documented URL currently redirects to its gadgets host.
    rainProc.command = ["curl", "-fsSL", "--max-time", "8", url]
    rainProc.running = true
  }

  function refresh() {
    locationFile.reload()
    resolveLocation()
  }

  function open() { controller.show(); refresh() }

  FileView {
    id: locationFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.weatherLocation = Model.parseWeatherLocation(text()); root.resolveLocation() }
    onLoadFailed: { root.weatherLocation = null; root.resolveLocation() }
  }

  Process {
    id: locationProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.configuredOverride() || root.weatherLocation) {
          root.resolveLocation()
          return
        }
        var location = Model.parseIpLocation(text)
        if (!location) return
        root.locationResponseAccepted = true
        root.useLocation(location)
      }
    }
    onExited: function(exitCode) {
      if (root.locationResponseAccepted || root.configuredOverride() || root.weatherLocation) return
      root.locationProviderIndex++
      Qt.callLater(root.startLocationLookup)
    }
  }

  Process {
    id: rainProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseRainText(text)
        if (parsed.length === 0) {
          root.errorMessage = "Buienradar returned no forecast values."
        } else {
          root.samples = parsed
          root.errorMessage = ""
        }
        root.loading = false
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.errorMessage = "Could not load the Buienradar forecast."
        root.loading = false
      }
    }
  }

  Timer {
    interval: root.refreshMinutes * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
    function status(): string {
      return JSON.stringify({
        loading: root.loading,
        provider: root.locationProviderIndex,
        location: root.activeLocation,
        samples: root.samples.length,
        currentMm: root.currentMm,
        error: root.errorMessage,
        locationProcess: locationProc.running,
        rainProcess: rainProc.running
      })
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: popup.fittedContentWidth(Style.space(560))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onReturnRequested: root.refresh()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        Row {
          width: parent.width
          spacing: Style.space(12)

          Column {
            width: parent.width - refreshButton.width - parent.spacing
            spacing: Style.space(4)

            Text {
              text: root.activeLocation ? (root.activeLocation.name || "Current position") : "Finding current position…"
              color: root.barForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }
            Text {
              text: root.currentMm + " mm/h  ·  " + root.currentIntensity
              color: root.samples.length ? Color.accent : Util.alpha(root.barForeground, 0.65)
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
          }

          Text {
            id: refreshButton
            text: root.loading ? "󰦖" : "󰑐"
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter

            RotationAnimator on rotation {
              running: root.loading
              from: 0; to: 360; duration: 800; loops: Animation.Infinite
            }
            TapHandler { enabled: !root.loading; onTapped: root.refresh() }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
          }
        }

        RainGraph {
          width: parent.width
          height: Style.space(235)
          samples: root.samples
          foreground: root.barForeground
          accent: Color.accent
          visible: root.samples.length > 0
        }

        Text {
          width: parent.width
          visible: root.errorMessage !== ""
          text: root.errorMessage
          wrapMode: Text.WordWrap
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width
          visible: root.samples.length > 0
          text: "Dots are Buienradar's 5-minute values; the line is a smooth interpolation. Updated " + Qt.formatTime(new Date(), "HH:mm") + "."
          wrapMode: Text.WordWrap
          color: Util.alpha(root.barForeground, 0.55)
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          text: "Data: Buienradar.nl"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.underline: sourceHover.hovered
          TapHandler { onTapped: Quickshell.execDetached(["xdg-open", "https://www.buienradar.nl"]) }
          HoverHandler { id: sourceHover; cursorShape: Qt.PointingHandCursor }
        }
      }
    }
  }
}
