# Omarchy Rain Radar Belgium Netherlands Widget

![Rain radar popup preview](preview.png)

An Omarchy Shell bar widget backed by Buienradar. Click the bar value to see
the expected rainfall in mm/h for the current position, with five-minute
forecast samples shown as dots and a smooth monotone interpolation between
them. Horizontal guides mark drizzle, light rain, rain, and heavy rain.

## Location

The widget uses, in order:

1. latitude and longitude entered in the widget settings;
2. the location configured for Omarchy's Weather widget;
3. an approximate IP-based current location, tried across several providers
   (GeoJS, `ipwho.is`, then `ipapi.co`) to survive rate limits or outages.

The Buienradar forecast only covers Belgium and the Netherlands. Coordinates
are sent to `gps.buienradar.nl`. Middle-click the widget or press Enter in the
popup to refresh.
