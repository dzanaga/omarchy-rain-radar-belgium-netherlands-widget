# Rain Radar Belgium & Netherlands

![Rain radar popup preview](preview.png)

## Introduction

Winter is coming... and rain with it. Let's get our raincoats ready and keep an eye on this handy rain radar widget.

An Omarchy Shell bar widget for Buienradar forecasts in Belgium and the
Netherlands. Click the widget to see the next 2 hours of rain in mm/h.

## Location

Choose **Change location** (or press **C**) to open the map. Click a
city or any point on the map, then choose **Use selected location**.  
**Use automatic location** restores automatic lookup (IP based).

The forecast is provided by [Buienradar](https://www.buienradar.nl/) and is
limited to Belgium and the Netherlands. Coordinates are sent to
`gps.buienradar.nl` when a forecast is requested.

## Install

```bash
omarchy plugin add https://github.com/dzanaga/omarchy-rain-radar-belgium-netherlands-widget.git --enable
```

## Remove

```bash
omarchy plugin remove io.github.dzanaga.omarchy-rain-radar-belgium-netherlands-widget
```

To also remove the saved map choice, delete
`~/.local/state/omarchy/settings/rain-radar-location.json`.

## License and data

The plugin code is licensed under [MIT](LICENSE). It requires the Omarchy
Shell environment and `curl`, which is used to request forecasts from
Buienradar and approximate IP location from the configured providers. The
bundled map outlines are Natural Earth public-domain data; see
[MAP-SOURCES.md](MAP-SOURCES.md).

The plugin reads Omarchy Weather's location file and only writes its own
`rain-radar-location.json` after the user explicitly saves a map selection.
It does not modify Omarchy configuration or other plugin state.


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
