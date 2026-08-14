import QtQuick

Canvas {
  id: root

  property var colors: []
  property real angle: 0

  onColorsChanged: requestPaint()
  onAngleChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  Component.onCompleted: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    if (!colors || colors.length < 2 || width <= 0 || height <= 0) return

    var radians = Number(angle || 0) * Math.PI / 180
    var dx = Math.cos(radians)
    var dy = Math.sin(radians)
    var reach = Math.abs(dx) * width / 2 + Math.abs(dy) * height / 2
    var centerX = width / 2
    var centerY = height / 2
    var gradient = ctx.createLinearGradient(
      centerX - dx * reach, centerY - dy * reach,
      centerX + dx * reach, centerY + dy * reach
    )

    for (var i = 0; i < colors.length; i++)
      gradient.addColorStop(i / (colors.length - 1), String(colors[i]))

    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, width, height)
  }
}
