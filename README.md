# Rain Radar Belgium & Netherlands

![Rain radar popup preview](preview.png)

An Omarchy Shell bar widget for Buienradar forecasts in Belgium and the
Netherlands. Click the widget to see the next hour of rain in mm/h. The chart
uses a shaded curve, a clear dry baseline, and a nonlinear scale that keeps
drizzle visible without letting heavy rain dominate the graph.

## Location

The widget can use:

- coordinates entered in its settings;
- the location from Omarchy Weather;
- approximate IP geolocation.

Choose **Change location** (or press **C**) to open the offline map. Click a
city or any point on the map, then choose **Use selected location**. Arbitrary
points are labeled with the nearest city and an **Area** suffix while keeping
their exact coordinates. **Use automatic location** restores automatic lookup.

The blue marker shows the automatic location. The orange marker shows the
selected forecast location. Map choices persist across shell restarts.

The forecast is provided by [Buienradar](https://www.buienradar.nl/) and is
limited to Belgium and the Netherlands. Coordinates are sent to
`gps.buienradar.nl` when a forecast is requested.

## Install

```bash
omarchy plugin add https://github.com/dzanaga/omarchy-rain-radar-belgium-netherlands-widget.git --enable
```

## Development

Validate the plugin and run the focused tests:

```bash
omarchy plugin validate .
node --test tests/*.test.cjs
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib/qt6/bin/qmltestrunner -input tests
```

`bash tests/check-panel.sh` runs an additional temporary Quickshell preview
with simulated forecasts. It does not modify the installed plugin.

Map outlines are bundled from [Natural Earth](MAP-SOURCES.md).
