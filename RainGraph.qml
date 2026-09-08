import QtQuick
import qs.Commons
import "GraphModel.js" as GraphModel

Canvas {
  id: graph
  property var samples: []
  property color foreground: Color.foreground
  property color accent: Color.accent

  readonly property var levels: [
    { value: 0, label: "0  DRY" },
    { value: 0.1, label: "0.1  DRIZZLE" },
    { value: 1.0, label: "1  LIGHT RAIN" },
    { value: 2.5, label: "2.5  RAIN" },
    { value: 10.0, label: "10  HEAVY RAIN" },
    { value: 50.0, label: "50 mm/h" }
  ]

  function traceCurve(ctx, points, tangents) {
    ctx.moveTo(points[0].x, points[0].y)
    if (points.length === 1) ctx.lineTo(points[0].x + Style.space(6), points[0].y)
    for (var i = 0; i < points.length - 1; i++) {
      var dx = points[i + 1].x - points[i].x
      ctx.bezierCurveTo(points[i].x + dx / 3, points[i].y + tangents[i] * dx / 3,
                        points[i + 1].x - dx / 3, points[i + 1].y - tangents[i + 1] * dx / 3,
                        points[i + 1].x, points[i + 1].y)
    }
  }

  onSamplesChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onForegroundChanged: requestPaint()
  onAccentChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var left = Style.space(10)
    var top = Style.space(10)
    var bottom = height - Style.space(28)

    ctx.font = Style.space(10) + "px " + Style.font.family
    var labelWidth = 0
    for (var l = 0; l < levels.length; l++) labelWidth = Math.max(labelWidth, ctx.measureText(levels[l].label).width)
    var right = width - labelWidth - Style.space(18)
    if (right <= left || bottom <= top) return
    ctx.textAlign = "left"
    ctx.textBaseline = "middle"
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      var level = levels[levelIndex]
      var levelY = GraphModel.yFor(level.value, top, bottom)
      ctx.strokeStyle = Util.alpha(foreground, level.value === 0 ? 0.35 : 0.12)
      ctx.lineWidth = 1
      ctx.setLineDash(level.value === 0 ? [] : [3, 5])
      ctx.beginPath()
      ctx.moveTo(left, levelY)
      ctx.lineTo(right, levelY)
      ctx.stroke()
      ctx.fillStyle = Util.alpha(foreground, 0.58)
      ctx.fillText(level.label, right + Style.space(10), levelY)
    }
    ctx.setLineDash([])

    if (!samples || samples.length === 0) return
    var step = samples.length > 1 ? (right - left) / (samples.length - 1) : 0
    var points = []
    for (var i = 0; i < samples.length; i++)
      points.push({ x: left + i * step, y: GraphModel.yFor(samples[i].mm, top, bottom) })

    var tangents = GraphModel.tangents(points)
    var fill = ctx.createLinearGradient(0, top, 0, bottom)
    fill.addColorStop(0, Util.alpha(accent, 0.42))
    fill.addColorStop(1, Util.alpha(accent, 0.10))
    ctx.fillStyle = fill
    ctx.beginPath()
    traceCurve(ctx, points, tangents)
    ctx.lineTo(points[points.length - 1].x + (points.length === 1 ? Style.space(6) : 0), bottom)
    ctx.lineTo(left, bottom)
    ctx.closePath()
    ctx.fill()

    ctx.strokeStyle = accent
    ctx.lineWidth = Style.space(2)
    ctx.lineJoin = "round"
    ctx.lineCap = "round"
    ctx.beginPath()
    traceCurve(ctx, points, tangents)
    ctx.stroke()

    ctx.fillStyle = Util.alpha(foreground, 0.65)
    ctx.textBaseline = "top"
    var indexes = samples.length === 1 ? [0] : (samples.length === 2 ? [0, 1] : [0, Math.floor((samples.length - 1) / 2), samples.length - 1])
    for (i = 0; i < indexes.length; i++) {
      var sampleIndex = indexes[i]
      ctx.textAlign = i === 0 ? "left" : (i === indexes.length - 1 ? "right" : "center")
      ctx.fillText(samples[sampleIndex].time, points[sampleIndex].x, bottom + Style.space(9))
    }
  }
}
