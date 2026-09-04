function trim(value) {
  return String(value === undefined || value === null ? "" : value).replace(/^\s+|\s+$/g, "")
}

function finiteNumber(value) {
  var number = parseFloat(trim(value))
  return isFinite(number) ? number : null
}

function parseWeatherLocation(raw) {
  try {
    var location = JSON.parse(String(raw || "{}"))
    var latitude = finiteNumber(location.latitude)
    var longitude = finiteNumber(location.longitude)
    if (latitude === null || longitude === null) return null
    return { name: trim(location.name), latitude: latitude, longitude: longitude }
  } catch (e) {
    return null
  }
}

function parseIpLocation(raw) {
  try {
    var location = JSON.parse(String(raw || "{}"))
    var latitude = finiteNumber(location.latitude)
    var longitude = finiteNumber(location.longitude)
    if (latitude === null || longitude === null) return null
    return {
      name: trim(location.city) || trim(location.region) || "Current position",
      latitude: latitude,
      longitude: longitude,
      country: trim(location.country_code).toUpperCase()
    }
  } catch (e) {
    return null
  }
}

// Buienradar encodes rainfall as a three-digit logarithmic value.
// 000 means dry; positive values convert to millimetres per hour.
function buienradarToMm(value) {
  var code = parseInt(value, 10)
  if (!isFinite(code) || code <= 0) return 0
  return Math.pow(10, (code - 109) / 32)
}

function parseRainText(raw) {
  var lines = String(raw || "").replace(/\r/g, "").split("\n")
  var values = []
  for (var i = 0; i < lines.length; i++) {
    var match = lines[i].match(/^\s*(\d{3})\|(\d{2}:\d{2})\s*$/)
    if (!match) continue
    values.push({ code: parseInt(match[1], 10), mm: buienradarToMm(match[1]), time: match[2] })
  }
  return values
}

function intensity(mm) {
  var value = finiteNumber(mm)
  if (value === null || value < 0.1) return "Dry"
  if (value < 1) return "Drizzle"
  if (value < 2.5) return "Light rain"
  if (value < 10) return "Rain"
  return "Heavy rain"
}

function formatMm(mm) {
  var value = finiteNumber(mm)
  if (value === null) return "—"
  if (value < 0.05) return "0"
  if (value < 1) return value.toFixed(2)
  if (value < 10) return value.toFixed(1)
  return String(Math.round(value))
}

function inCoverage(latitude, longitude) {
  var lat = finiteNumber(latitude)
  var lon = finiteNumber(longitude)
  return lat !== null && lon !== null && lat >= 49.3 && lat <= 54.0 && lon >= 2.0 && lon <= 7.8
}

if (typeof module !== "undefined") module.exports = {
  finiteNumber: finiteNumber,
  parseWeatherLocation: parseWeatherLocation,
  parseIpLocation: parseIpLocation,
  buienradarToMm: buienradarToMm,
  parseRainText: parseRainText,
  intensity: intensity,
  formatMm: formatMm,
  inCoverage: inCoverage
}
