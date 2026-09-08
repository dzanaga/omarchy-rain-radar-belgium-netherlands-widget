// A local equirectangular map, with longitude scaled at 52 degrees north.
// Both drawing and picking use this transform, including its letterboxing.
var bounds = { west: 2.0, east: 7.8, south: 49.3, north: 54.0 }
var longitudeScale = Math.cos(52 * Math.PI / 180)
var cities = [
  { name: "Bruges", latitude: 51.2093, longitude: 3.2247, dx: -9, dy: -10, align: "right" },
  { name: "Ghent", latitude: 51.0543, longitude: 3.7174, dx: -9, dy: 14, align: "right" },
  { name: "Brussels", latitude: 50.8503, longitude: 4.3517, dx: 9, dy: 0 },
  { name: "Antwerp", latitude: 51.2194, longitude: 4.4025, dx: 9, dy: -9 },
  { name: "Liège", latitude: 50.6326, longitude: 5.5797, dx: 9, dy: 0 },
  { name: "Namur", latitude: 50.4674, longitude: 4.8718, dx: -9, dy: 13, align: "right" },
  { name: "Rotterdam", latitude: 51.9244, longitude: 4.4777, dx: -9, dy: 12, align: "right" },
  { name: "Amsterdam", latitude: 52.3676, longitude: 4.9041, dx: -9, dy: -12, align: "right" },
  { name: "Utrecht", latitude: 52.0907, longitude: 5.1214, dx: 9, dy: -7 },
  { name: "Eindhoven", latitude: 51.4416, longitude: 5.4697, dx: 9, dy: -3 },
  { name: "Maastricht", latitude: 50.8514, longitude: 5.6910, dx: 9, dy: -12 },
  { name: "Arnhem", latitude: 51.9851, longitude: 5.8987, dx: 9, dy: 12 },
  { name: "Enschede", latitude: 52.2215, longitude: 6.8937, dx: 9, dy: -5 },
  { name: "Leeuwarden", latitude: 53.2012, longitude: 5.7999, dx: -9, dy: -12, align: "right" },
  { name: "Groningen", latitude: 53.2194, longitude: 6.5665, dx: 9, dy: 7 }
]

function viewport(width, height) {
  var scale = Math.max(0, Math.min((width - 32) / ((bounds.east - bounds.west) * longitudeScale), (height - 32) / (bounds.north - bounds.south)))
  return { scale: scale, x: (width - (bounds.east - bounds.west) * longitudeScale * scale) / 2,
    y: (height - (bounds.north - bounds.south) * scale) / 2 }
}

function project(latitude, longitude, width, height) {
  var v = viewport(width, height)
  return { x: v.x + (longitude - bounds.west) * longitudeScale * v.scale,
    y: v.y + (bounds.north - latitude) * v.scale }
}

function unproject(x, y, width, height) {
  var v = viewport(width, height)
  if (v.scale <= 0) return null
  var latitude = bounds.north - (y - v.y) / v.scale
  var longitude = bounds.west + (x - v.x) / (longitudeScale * v.scale)
  if (latitude < bounds.south || latitude > bounds.north || longitude < bounds.west || longitude > bounds.east) return null
  return { name: "Selected position", latitude: Number(latitude.toFixed(5)), longitude: Number(longitude.toFixed(5)) }
}

if (typeof module !== "undefined") module.exports = { bounds: bounds, cities: cities, project: project, unproject: unproject }
