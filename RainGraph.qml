import QtQuick
import qs.Commons

Canvas {
  id: graph
  property var samples: []
  property color foreground: Color.foreground
  property color accent: Color.accent

  readonly property var levels: [
    { value: 0.1, label: "DRIZZLE" },
    { value: 1.0, label: "LIGHT RAIN" },
    { value: 2.5, label: "RAIN" },
    { value: 10.0, label: "HEAVY RAIN" }
  ]

  function graphMax() {
    var maximum = 10
    for (var i = 0; i < samples.length; i++) maximum = Math.max(maximum, Number(samples[i].mm) || 0)
    return maximum <= 10 ? 12 : Math.ceil(maximum / 5) * 5
  }

  function yFor(value, top, bottom, maximum) {
    return bottom - Math.min(Math.max(Number(value) || 0, 0), maximum) / maximum * (bottom - top)
  }

  onSamplesChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var left = 12
    var right = width - 86
    var top = 12
    var bottom = height - 28
    var maximum = graphMax()

    ctx.font = "10px " + Style.font.family
    ctx.textAlign = "left"
    ctx.textBaseline = "middle"
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      var level = levels[levelIndex]
      var levelY = yFor(level.value, top, bottom, maximum)
      ctx.strokeStyle = Util.alpha(foreground, 0.18)
      ctx.lineWidth = 1
      ctx.setLineDash([4, 4])
      ctx.beginPath()
      ctx.moveTo(left, levelY)
      ctx.lineTo(right, levelY)
      ctx.stroke()
      ctx.fillStyle = Util.alpha(foreground, 0.58)
      ctx.fillText(level.label, right + 8, levelY)
    }
    ctx.setLineDash([])

    if (!samples || samples.length === 0) return
    var step = samples.length > 1 ? (right - left) / (samples.length - 1) : 0
    var points = []
    for (var i = 0; i < samples.length; i++)
      points.push({ x: left + i * step, y: yFor(samples[i].mm, top, bottom, maximum) })

    // Monotone cubic interpolation keeps the curve smooth without inventing
    // negative rainfall or overshooting sharp shower peaks.
    var slopes = []
    for (i = 0; i < points.length - 1; i++) slopes.push((points[i + 1].y - points[i].y) / Math.max(1, points[i + 1].x - points[i].x))
    var tangents = []
    tangents[0] = slopes[0] || 0
    for (i = 1; i < points.length - 1; i++) tangents[i] = slopes[i - 1] * slopes[i] <= 0 ? 0 : (slopes[i - 1] + slopes[i]) / 2
    tangents[points.length - 1] = slopes[slopes.length - 1] || 0

    ctx.strokeStyle = accent
    ctx.lineWidth = 2.5
    ctx.lineJoin = "round"
    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)
    for (i = 0; i < points.length - 1; i++) {
      var dx = points[i + 1].x - points[i].x
      ctx.bezierCurveTo(points[i].x + dx / 3, points[i].y + tangents[i] * dx / 3,
                        points[i + 1].x - dx / 3, points[i + 1].y - tangents[i + 1] * dx / 3,
                        points[i + 1].x, points[i + 1].y)
    }
    ctx.stroke()

    for (i = 0; i < points.length; i++) {
      ctx.fillStyle = accent
      ctx.beginPath()
      ctx.arc(points[i].x, points[i].y, 3, 0, Math.PI * 2)
      ctx.fill()
    }

    ctx.fillStyle = Util.alpha(foreground, 0.65)
    ctx.font = "10px " + Style.font.family
    ctx.textBaseline = "top"
    var indexes = [0, Math.floor((samples.length - 1) / 2), samples.length - 1]
    for (i = 0; i < indexes.length; i++) {
      var sampleIndex = indexes[i]
      ctx.textAlign = i === 0 ? "left" : (i === indexes.length - 1 ? "right" : "center")
      ctx.fillText(samples[sampleIndex].time, points[sampleIndex].x, bottom + 9)
    }
  }
}
